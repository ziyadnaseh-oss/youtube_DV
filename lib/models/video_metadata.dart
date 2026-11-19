class VideoMetadata {
  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;
  final DateTime? uploadDate;
  final int? viewCount;
  final String description;
  final String originalUrl;

  const VideoMetadata({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    this.uploadDate,
    this.viewCount,
    this.description = '',
    required this.originalUrl,
  });
}
