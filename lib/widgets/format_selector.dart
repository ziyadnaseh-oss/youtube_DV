import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_option.dart';
import '../providers/downloader_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class FormatSelector extends StatelessWidget {
  const FormatSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final selectedType = provider.selectedFormatType;
    final options = provider.visibleOptions;
    final selectedOption = provider.selectedOption;
    final selectedAudioFormat = provider.selectedAudioFormat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Quality & Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Segmented Button: Video vs Audio
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DownloadFormatType>(
                segments: const [
                  ButtonSegment<DownloadFormatType>(
                    value: DownloadFormatType.video,
                    icon: Icon(Icons.videocam_rounded, size: 18),
                    label: Text('Video (MP4)'),
                  ),
                  ButtonSegment<DownloadFormatType>(
                    value: DownloadFormatType.audio,
                    icon: Icon(Icons.music_note_rounded, size: 18),
                    label: Text('Audio Only'),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<DownloadFormatType> newSelection) {
                  provider.setFormatType(newSelection.first);
                },
              ),
            ),

            // Audio Format Chooser (MP3 vs M4A)
            if (selectedType == DownloadFormatType.audio) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Audio Format: ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('MP3'),
                    selected: selectedAudioFormat == AudioTargetFormat.mp3,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setAudioFormat(AudioTargetFormat.mp3);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('M4A'),
                    selected: selectedAudioFormat == AudioTargetFormat.m4a,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setAudioFormat(AudioTargetFormat.m4a);
                      }
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Quality Options List
            if (options.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No formats available for this selection',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final isSelected = selectedOption?.qualityKey == opt.qualityKey;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => provider.selectOption(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryRed.withValues(alpha: 0.08)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryRed
                              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Radio indicator
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? AppTheme.primaryRed : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),

                          // Quality Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.subLabel,
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
                          ),

                          // File Size Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryRed.withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              Formatters.formatFileSize(opt.totalSizeBytes),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppTheme.primaryRed : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
