import 'download_option.dart';

enum DownloadStatus {
  idle,
  queued,
  downloading,
  merging,
  converting,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String videoTitle;
  final String thumbnailUrl;
  final DownloadOption option;
  final DownloadStatus status;
  final String stageMessage;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final double etaSeconds;
  final String? savedFilePath;
  final String? errorMessage;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    required this.videoTitle,
    required this.thumbnailUrl,
    required this.option,
    this.status = DownloadStatus.idle,
    this.stageMessage = 'Ready',
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.etaSeconds = 0.0,
    this.savedFilePath,
    this.errorMessage,
    required this.createdAt,
  });

  bool get isRunning =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.merging ||
      status == DownloadStatus.converting;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;

  DownloadTask copyWith({
    DownloadStatus? status,
    String? stageMessage,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speedBytesPerSec,
    double? etaSeconds,
    String? savedFilePath,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id,
      videoTitle: videoTitle,
      thumbnailUrl: thumbnailUrl,
      option: option,
      status: status ?? this.status,
      stageMessage: stageMessage ?? this.stageMessage,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      savedFilePath: savedFilePath ?? this.savedFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }
}
