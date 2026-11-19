import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_option.dart';
import '../models/download_task.dart';
import '../providers/downloader_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class DownloadItemTile extends StatelessWidget {
  final DownloadTask task;

  const DownloadItemTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DownloaderProvider>();
    final isVideo = task.option.type == DownloadFormatType.video;
    final isSuccess = task.status == DownloadStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or Format Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 48,
                    child: task.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            task.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.black12,
                              child: Icon(
                                isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryRed.withValues(alpha: 0.1),
                            child: Icon(
                              isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.videoTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Format tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isVideo
                                  ? 'MP4 • ${task.option.label}'
                                  : '${task.option.targetAudioFormat.name.toUpperCase()} • ${task.option.label}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Size
                          Text(
                            Formatters.formatFileSize(task.totalBytes),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // If error occurred
            if (task.status == DownloadStatus.failed) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${task.errorMessage ?? "Download failed"}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            // Action Buttons
            if (isSuccess && task.savedFilePath != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.savedFilePath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open / Play',
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        color: AppTheme.primaryRed, size: 24),
                    onPressed: () => provider.openFile(task.savedFilePath!),
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () =>
                        provider.shareFile(task.savedFilePath!, task.videoTitle),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => provider.deleteHistoryItem(task),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
