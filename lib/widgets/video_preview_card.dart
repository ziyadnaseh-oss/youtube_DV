import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/video_metadata.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class VideoPreviewCard extends StatelessWidget {
  final VideoMetadata video;
  final VoidCallback onClear;

  const VideoPreviewCard({
    super.key,
    required this.video,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Duration pill overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              // Floating Duration Badge
              if (video.duration != null)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      Formatters.formatDuration(video.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Channel Name & Verification Icon
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle_rounded,
                      size: 18,
                      color: AppTheme.primaryRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        video.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Views & Upload Date
                Row(
                  children: [
                    if (video.viewCount != null) ...[
                      Text(
                        '${Formatters.formatCount(video.viewCount)} views',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (video.uploadDate != null)
                      Text(
                        DateFormat.yMMMd().format(video.uploadDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
