enum DownloadFormatType { video, audio }

enum AudioTargetFormat { mp3, m4a }

class DownloadOption {
  final DownloadFormatType type;
  final String label; // e.g. "1080p60 Full HD", "720p HD", "High Quality (192 kbps)"
  final String subLabel; // e.g. "60 FPS • MP4", "High Quality • MP3"
  final String qualityKey; // e.g. "1080p_60", "720p", "audio_high"
  final String? formatId; // yt-dlp format_id string, e.g. "137" or "bestvideo[height<=1080]+bestaudio/best"
  final String? videoFormatId;
  final String? audioFormatId;
  final int? height;
  final int? fps;
  final String? ext;
  final bool isMuxed;
  final int totalSizeBytes;
  final AudioTargetFormat targetAudioFormat;
  final String? videoId;

  const DownloadOption({
    required this.type,
    required this.label,
    required this.subLabel,
    required this.qualityKey,
    this.formatId,
    this.videoFormatId,
    this.audioFormatId,
    this.height,
    this.fps,
    this.ext,
    this.isMuxed = false,
    required this.totalSizeBytes,
    this.targetAudioFormat = AudioTargetFormat.mp3,
    this.videoId,
  });

  /// Copy with alternative target audio format (mp3 vs m4a)
  DownloadOption copyWith({
    AudioTargetFormat? targetAudioFormat,
    String? videoId,
    String? formatId,
  }) {
    return DownloadOption(
      type: type,
      label: label,
      subLabel: subLabel,
      qualityKey: qualityKey,
      formatId: formatId ?? this.formatId,
      videoFormatId: videoFormatId,
      audioFormatId: audioFormatId,
      height: height,
      fps: fps,
      ext: ext,
      isMuxed: isMuxed,
      totalSizeBytes: totalSizeBytes,
      targetAudioFormat: targetAudioFormat ?? this.targetAudioFormat,
      videoId: videoId ?? this.videoId,
    );
  }
}
