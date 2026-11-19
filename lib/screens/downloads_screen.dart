import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/downloader_provider.dart';
import '../utils/theme.dart';
import '../widgets/download_item_tile.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final history = provider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_download_outlined,
                      size: 64,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No downloads yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Downloaded videos & audios will appear here\nand in your device\'s public Downloads folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final task = history[index];
                return DownloadItemTile(task: task);
              },
            ),
    );
  }
}
