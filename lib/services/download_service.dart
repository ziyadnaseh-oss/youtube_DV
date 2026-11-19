import 'dart:async';
import '../models/download_option.dart';
import 'ytdl_service.dart';

class DownloadProgressUpdate {
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final double etaSeconds;
  final String stageMessage;

  const DownloadProgressUpdate({
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speedBytesPerSec,
    required this.etaSeconds,
    required this.stageMessage,
  });
}

/// Manages downloads via the native youtubedl-android backend.
class DownloadService {
  final YtdlService _ytdl = YtdlService();
  String? _activeProcessId;
  StreamSubscription<Map<Object?, Object?>>? _progressSub;

  /// Start downloading. Returns the saved file path, or null if cancelled.
  Future<String?> download({
    required String videoTitle,
    required DownloadOption option,
    required void Function(DownloadProgressUpdate update) onProgress,
  }) async {
    _activeProcessId = DateTime.now().millisecondsSinceEpoch.toString();
    final processId = _activeProcessId!;

    final isAudio = option.type == DownloadFormatType.audio;
    final audioFmt = option.targetAudioFormat == AudioTargetFormat.mp3 ? 'mp3' : 'm4a';
    final formatId = option.formatId;

    // Retrieve URL — stored in videoId by DownloaderProvider.fetchVideo
    final videoId = option.videoId ?? '';
    final url = videoId.startsWith('http')
        ? videoId
        : 'https://www.youtube.com/watch?v=$videoId';

    // Notify: starting
    onProgress(const DownloadProgressUpdate(
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      speedBytesPerSec: 0,
      etaSeconds: 0,
      stageMessage: 'Starting download…',
    ));

    // Listen to progress events BEFORE starting the download
    _progressSub = _ytdl.progressStream.listen((event) {
      if (event['processId'] != processId) return;

      // Native sends 0.0–1.0
      final progress = ((event['progress'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
      final eta = (event['etaSeconds'] as num?)?.toDouble() ?? 0.0;
      final line = event['line'] as String? ?? '';

      String stage = line.trim();
      if (stage.isEmpty) {
        if (progress < 0.05) {
          stage = 'Starting download…';
        } else if (progress >= 0.95) {
          stage = isAudio ? 'Converting audio…' : 'Merging streams…';
        } else {
          stage = isAudio ? 'Downloading audio…' : 'Downloading video…';
        }
      }

      onProgress(DownloadProgressUpdate(
        progress: progress,
        downloadedBytes: 0,
        totalBytes: option.totalSizeBytes,
        speedBytesPerSec: 0,
        etaSeconds: eta,
        stageMessage: stage,
      ));
    });

    try {
      // This blocks until the download completes or fails (native executes synchronously on IO thread)
      final result = await _ytdl.download(
        url: url,
        processId: processId,
        formatId: formatId,
        isAudioOnly: isAudio,
        audioFormat: audioFmt,
      );

      if (result == null) return null; // cancelled

      // Send final 100%
      onProgress(DownloadProgressUpdate(
        progress: 1.0,
        downloadedBytes: option.totalSizeBytes,
        totalBytes: option.totalSizeBytes,
        speedBytesPerSec: 0,
        etaSeconds: 0,
        stageMessage: 'Saved to Downloads folder',
      ));

      return result['filePath'] as String?;
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
      _activeProcessId = null;
    }
  }

  /// Cancel the active download.
  Future<void> cancel() async {
    final pid = _activeProcessId;
    if (pid != null) {
      await _ytdl.cancel(pid);
    }
    await _progressSub?.cancel();
    _progressSub = null;
    _activeProcessId = null;
  }
}
