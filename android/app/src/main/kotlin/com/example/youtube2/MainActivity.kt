package com.example.youtube2

import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.mapper.VideoFormat
import com.yausername.youtubedl_android.mapper.VideoInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.youtube2/ytdl"
    private val EVENT_CHANNEL = "com.example.youtube2/ytdl_events"
    private val TAG = "MainActivity_YTDL"

    private var eventSink: EventChannel.EventSink? = null
    @Volatile private var isInitialized = false
    @Volatile private var initError: String? = null
    private val initLock = Any()

    private val safeScope = CoroutineScope(Dispatchers.IO + CoroutineExceptionHandler { _, throwable ->
        Log.e(TAG, "Unhandled coroutine error: ${throwable.message}", throwable)
    })

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Initialize YoutubeDL and FFmpeg on a background thread safely, then silently auto-update yt-dlp
        safeScope.launch {
            val (success, _) = initYoutubeDLSync()
            if (success) {
                try {
                    Log.i(TAG, "Checking for yt-dlp update in background...")
                    val status = YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel._STABLE)
                    val ver = try { YoutubeDL.getInstance().version(applicationContext) } catch (_: Throwable) { "" }
                    Log.i(TAG, "yt-dlp silent update result: $status, current version: $ver")
                } catch (t: Throwable) {
                    Log.w(TAG, "yt-dlp silent auto-update notice: ${t.message}")
                }
            }
        }

        // 2. Setup EventChannel for streaming live progress to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // 3. Setup MethodChannel for init, getInfo, download, cancel, and updateEngine
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    safeScope.launch {
                        val (success, err) = initYoutubeDLSync()
                        withContext(Dispatchers.Main) {
                            if (success) {
                                result.success(true)
                            } else {
                                result.error("INIT_FAILED", err ?: "Native initialization failed", null)
                            }
                        }
                    }
                }
                "updateEngine" -> {
                    safeScope.launch {
                        try {
                            val (initOk, initErrMsg) = initYoutubeDLSync()
                            if (!initOk) {
                                withContext(Dispatchers.Main) {
                                    result.error("INIT_FAILED", initErrMsg ?: "Native initialization failed", null)
                                }
                                return@launch
                            }

                            val status = YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel._STABLE)
                            val currentVer = try { YoutubeDL.getInstance().version(applicationContext) } catch (_: Throwable) { "" }
                            val msg = when (status) {
                                YoutubeDL.UpdateStatus.DONE -> {
                                    if (!currentVer.isNullOrBlank()) "Updated to version $currentVer" else "Updated to latest version"
                                }
                                YoutubeDL.UpdateStatus.ALREADY_UP_TO_DATE -> {
                                    if (!currentVer.isNullOrBlank()) "Already up to date ($currentVer)" else "Already up to date"
                                }
                                else -> "Engine update completed"
                            }

                            withContext(Dispatchers.Main) {
                                result.success(msg)
                            }
                        } catch (t: Throwable) {
                            Log.e(TAG, "updateEngine failed: ${t.message}", t)
                            val cleanMsg = cleanErrorMessage(t.message ?: t.toString())
                            withContext(Dispatchers.Main) {
                                result.error("UPDATE_FAILED", cleanMsg, null)
                            }
                        }
                    }
                }
                "getInfo" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "URL must not be empty", null)
                        return@setMethodCallHandler
                    }

                    safeScope.launch {
                        try {
                            val (initOk, initErrMsg) = initYoutubeDLSync()
                            if (!initOk) {
                                withContext(Dispatchers.Main) {
                                    result.error("INIT_FAILED", initErrMsg ?: "Native initialization failed", null)
                                }
                                return@launch
                            }

                            val request = YoutubeDLRequest(url)
                            request.addOption("--no-warnings")
                            val info: VideoInfo = YoutubeDL.getInstance().getInfo(request)

                            val formatsList = mutableListOf<Map<String, Any?>>()
                            info.formats?.forEach { f: VideoFormat ->
                                val fMap = mutableMapOf<String, Any?>()
                                fMap["format_id"] = f.formatId
                                fMap["ext"] = f.ext
                                fMap["resolution"] = f.format
                                fMap["width"] = f.width
                                fMap["height"] = f.height
                                fMap["fps"] = f.fps
                                fMap["vcodec"] = f.vcodec
                                fMap["acodec"] = f.acodec
                                fMap["filesize"] = f.fileSize
                                fMap["filesize_approx"] = f.fileSizeApproximate
                                fMap["abr"] = f.abr
                                fMap["asr"] = f.asr
                                fMap["tbr"] = f.tbr
                                fMap["format_note"] = f.formatNote
                                fMap["url"] = f.url
                                formatsList.add(fMap)
                            }

                            val resultMap = mapOf(
                                "id" to (info.id ?: ""),
                                "title" to (info.title ?: ""),
                                "uploader" to (info.uploader ?: ""),
                                "duration" to info.duration.toLong(),
                                "thumbnail" to (info.thumbnail ?: ""),
                                "description" to (info.description ?: ""),
                                "formats" to formatsList
                            )

                            withContext(Dispatchers.Main) {
                                result.success(resultMap)
                            }
                        } catch (t: Throwable) {
                            Log.e(TAG, "getInfo failed: ${t.message}", t)
                            val cleanMsg = cleanErrorMessage(t.message ?: t.toString())
                            withContext(Dispatchers.Main) {
                                result.error("GET_INFO_FAILED", cleanMsg, null)
                            }
                        }
                    }
                }
                "download" -> {
                    val url = call.argument<String>("url")
                    val processId = call.argument<String>("processId") ?: System.currentTimeMillis().toString()
                    val format = call.argument<String>("formatId")
                    val isAudioOnly = call.argument<Boolean>("isAudioOnly") ?: false
                    val audioFormat = call.argument<String>("audioFormat") ?: "mp3"
                    val audioQuality = call.argument<String>("audioQuality") ?: "192"
                    val customOutputPath = call.argument<String>("outputPath")

                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "URL must not be empty", null)
                        return@setMethodCallHandler
                    }

                    safeScope.launch {
                        try {
                            val (initOk, initErrMsg) = initYoutubeDLSync()
                            if (!initOk) {
                                withContext(Dispatchers.Main) {
                                    result.error("INIT_FAILED", initErrMsg ?: "Native initialization failed", null)
                                }
                                return@launch
                            }

                            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            if (!downloadDir.exists()) downloadDir.mkdirs()

                            val outTemplate = if (!customOutputPath.isNullOrBlank()) {
                                customOutputPath
                            } else {
                                "${downloadDir.absolutePath}/%(title)s.%(ext)s"
                            }

                            val request = YoutubeDLRequest(url)
                            request.addOption("--no-warnings")
                            request.addOption("-o", outTemplate)
                            request.addOption("--no-mtime")

                            if (isAudioOnly) {
                                val aFmt = if (!format.isNullOrBlank()) format else "bestaudio/best"
                                request.addOption("-f", aFmt)
                                request.addOption("-x")
                                request.addOption("--audio-format", audioFormat)
                                request.addOption("--audio-quality", audioQuality)
                            } else {
                                val vFmt = if (!format.isNullOrBlank()) format else "bestvideo[height<=1080]+bestaudio/best"
                                request.addOption("-f", vFmt)
                                request.addOption("--merge-output-format", "mp4")
                            }

                            var resolvedFilePath: String? = null

                            val response = YoutubeDL.getInstance().execute(request, processId) { progress, etaInSeconds, line ->
                                if (line != null) {
                                    val destMatch = Pattern.compile("\\[(?:download|Merger|ExtractAudio)\\]\\s+(?:Destination:\\s+|Merging formats into \")([^\"]+)").matcher(line)
                                    if (destMatch.find()) {
                                        resolvedFilePath = destMatch.group(1)?.trim()
                                    }
                                }

                                val eventData = mapOf(
                                    "processId" to processId,
                                    "progress" to (progress.toDouble() / 100.0).coerceIn(0.0, 1.0),
                                    "etaSeconds" to etaInSeconds.toDouble(),
                                    "line" to (line ?: "")
                                )
                                runOnUiThread {
                                    eventSink?.success(eventData)
                                }
                            }

                            if (resolvedFilePath.isNullOrBlank()) {
                                val destMatch = Pattern.compile("\\[(?:download|Merger|ExtractAudio)\\]\\s+(?:Destination:\\s+|Merging formats into \")([^\"]+)").matcher(response.out ?: "")
                                if (destMatch.find()) {
                                    resolvedFilePath = destMatch.group(1)?.trim()
                                }
                            }

                            withContext(Dispatchers.Main) {
                                result.success(mapOf(
                                    "success" to true,
                                    "filePath" to resolvedFilePath,
                                    "out" to (response.out ?: "")
                                ))
                            }
                        } catch (t: Throwable) {
                            Log.e(TAG, "download failed: ${t.message}", t)
                            val cleanMsg = cleanErrorMessage(t.message ?: t.toString())
                            withContext(Dispatchers.Main) {
                                result.error("DOWNLOAD_FAILED", cleanMsg, null)
                            }
                        }
                    }
                }
                "cancel" -> {
                    val processId = call.argument<String>("processId")
                    if (!processId.isNullOrBlank()) {
                        safeScope.launch {
                            val success = try {
                                YoutubeDL.getInstance().destroyProcessById(processId)
                            } catch (t: Throwable) {
                                false
                            }
                            withContext(Dispatchers.Main) {
                                result.success(success)
                            }
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initYoutubeDLSync(): Pair<Boolean, String?> {
        if (isInitialized) return Pair(true, null)
        synchronized(initLock) {
            if (isInitialized) return Pair(true, null)
            return try {
                YoutubeDL.getInstance().init(applicationContext)
                try {
                    FFmpeg.getInstance().init(applicationContext)
                } catch (t: Throwable) {
                    Log.w(TAG, "FFmpeg init warning: ${t.message}")
                }
                isInitialized = true
                initError = null
                Log.i(TAG, "YoutubeDL and FFmpeg initialized successfully")
                Pair(true, null)
            } catch (t: Throwable) {
                val msg = t.message ?: t.toString()
                initError = msg
                Log.e(TAG, "Failed to initialize YoutubeDL: $msg", t)
                Pair(false, msg)
            }
        }
    }

    private fun cleanErrorMessage(raw: String): String {
        val lines = raw.lines()
        val errorLine = lines.findLast { it.trim().startsWith("ERROR:") }
        if (errorLine != null) {
            return errorLine.trim().removePrefix("ERROR:").trim()
        }
        val meaningful = lines.map { it.trim() }.filter { it.isNotEmpty() && !it.startsWith("WARNING:") }
        return meaningful.lastOrNull() ?: raw
    }
}
