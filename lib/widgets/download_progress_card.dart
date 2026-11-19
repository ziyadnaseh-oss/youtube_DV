import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_task.dart';
import '../providers/downloader_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final task = provider.activeTask;

    if (task == null) return const SizedBox.shrink();

    final isProcessing = task.status == DownloadStatus.merging ||
        task.status == DownloadStatus.converting;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator & Cancel button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.downloading_rounded,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.stageMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Cancel Download',
                  onPressed: () => provider.cancelActiveDownload(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isProcessing
                  ? const LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    )
                  : LinearProgressIndicator(
                      value: task.progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    ),
            ),
            const SizedBox(height: 10),

            // Stats row: Percentage, Downloaded/Total, Speed, ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Percentage
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRed,
                  ),
                ),

                // Downloaded / Total
                Text(
                  '${Formatters.formatFileSize(task.downloadedBytes)} / ${Formatters.formatFileSize(task.totalBytes)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),

                // Speed
                if (!isProcessing && task.speedBytesPerSec > 0)
                  Text(
                    Formatters.formatSpeed(task.speedBytesPerSec),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                // ETA
                if (!isProcessing && task.etaSeconds > 0)
                  Text(
                    'ETA: ${Formatters.formatEta(task.etaSeconds)}',
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }
}
