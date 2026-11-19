# ==============================================================================
# Flutter
# ==============================================================================
# Keep Flutter engine JNI bridges
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ==============================================================================
# youtubedl-android (yt-dlp, FFmpeg, Python)
# ==============================================================================
-keep class com.yausername.** { *; }
-keepclassmembers class com.yausername.** { *; }
-dontwarn com.yausername.**

-keep class io.github.junkfood02.** { *; }
-keepclassmembers class io.github.junkfood02.** { *; }
-dontwarn io.github.junkfood02.**

-keep class org.apache.commons.** { *; }
-keepclassmembers class org.apache.commons.** { *; }
-dontwarn org.apache.commons.**

-keep class com.fasterxml.jackson.** { *; }
-keepclassmembers class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# ==============================================================================
# FFmpegKit (ffmpeg_kit_flutter_new)
# ==============================================================================
# Keep all FFmpegKit Java/Kotlin classes and their JNI-reachable members
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
-keepclassmembers class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.**

# ==============================================================================
# OkHttp & Okio (used by youtube_explode_dart via Ktor/OkHttp)
# ==============================================================================
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# OkHttp platform detection — suppress missing class warnings
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# ==============================================================================
# Ktor (used by youtube_explode_dart)
# ==============================================================================
-keep class io.ktor.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn io.ktor.**
-dontwarn kotlinx.coroutines.**
-dontwarn kotlinx.serialization.**

# ==============================================================================
# open_filex
# ==============================================================================
-keep class com.crazecoder.openfile.** { *; }
-dontwarn com.crazecoder.openfile.**

# ==============================================================================
# share_plus
# ==============================================================================
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ==============================================================================
# permission_handler
# ==============================================================================
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ==============================================================================
# device_info_plus
# ==============================================================================
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# ==============================================================================
# path_provider
# ==============================================================================
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ==============================================================================
# AndroidX / FileProvider
# ==============================================================================
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.app.** { *; }
-dontwarn androidx.**

# ==============================================================================
# General JNI / Native method safety
# ==============================================================================
# Prevent stripping of classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations (used by Android system calls)
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep enum values referenced via reflection
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ==============================================================================
# Kotlin metadata & coroutines (required for kotlinx.coroutines to work)
# ==============================================================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Lazy {
    *;
}

# ==============================================================================
# Suppress common third-party warnings that are not actual runtime issues
# ==============================================================================
-dontwarn java.lang.invoke.**
-dontwarn sun.misc.**
-dontwarn com.google.android.gms.**
