import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_option.dart';
import '../providers/downloader_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../services/ytdl_service.dart';
import '../widgets/download_progress_card.dart';
import '../widgets/format_selector.dart';
import '../widgets/url_input_card.dart';
import '../widgets/video_preview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _onUpdateEnginePressed(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 30),
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 14),
            Text('Updating download engine...'),
          ],
        ),
      ),
    );

    try {
      final message = await YtdlService().updateEngine();
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update failed: ${e.toString().replaceFirst('Exception: ', '')}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onDownloadPressed(BuildContext context) {
    final provider = context.read<DownloaderProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    provider.startDownload(
      onSuccess: (savedPath) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B5E20),
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Download Complete!',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        'Saved to Downloads folder',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'OPEN FILE',
              textColor: Colors.yellowAccent,
              onPressed: () {
                provider.openFile(savedPath);
              },
            ),
          ),
        );
      },
      onError: (error) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    final currentVideo = provider.currentVideo;
    final selectedOption = provider.selectedOption;
    final activeTask = provider.activeTask;
    final isDownloading = activeTask != null && activeTask.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'YT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Downloader',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Update yt-dlp Engine',
            icon: const Icon(Icons.system_update_alt_rounded),
            onPressed: () => _onUpdateEnginePressed(context),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeProvider.toggleTheme(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. URL Input Card
              const UrlInputCard(),
              const SizedBox(height: 16),

              // 2. Active Download Progress Card (if downloading)
              if (activeTask != null) ...[
                const DownloadProgressCard(),
                const SizedBox(height: 16),
              ],

              // 3. Video Metadata Preview Card
              if (currentVideo != null) ...[
                VideoPreviewCard(
                  video: currentVideo,
                  onClear: () => provider.clearCurrentVideo(),
                ),
                const SizedBox(height: 16),

                // 4. Quality & Format Selector
                const FormatSelector(),
                const SizedBox(height: 16),

                // 5. Download Action Button
                if (selectedOption != null)
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isDownloading ? null : () => _onDownloadPressed(context),
                      icon: isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_download_rounded, size: 22),
                      label: Text(
                        isDownloading
                            ? 'Downloading...'
                            : selectedOption.type == DownloadFormatType.video
                                ? 'Download Video • ${Formatters.formatFileSize(selectedOption.totalSizeBytes)}'
                                : 'Download ${selectedOption.targetAudioFormat.name.toUpperCase()} • ${Formatters.formatFileSize(selectedOption.totalSizeBytes)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
