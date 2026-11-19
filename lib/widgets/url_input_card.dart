import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/downloader_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class UrlInputCard extends StatefulWidget {
  const UrlInputCard({super.key});

  @override
  State<UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends State<UrlInputCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _controller.text = data.text!.trim();
      _fetchVideo();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty or does not contain text.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearInput() {
    _controller.clear();
    context.read<DownloaderProvider>().clearCurrentVideo();
  }

  void _fetchVideo() {
    _focusNode.unfocus();
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      context.read<DownloaderProvider>().fetchVideo(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final isFetching = provider.isFetching;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Video Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (provider.currentVideo != null)
                  TextButton.icon(
                    onPressed: () {
                      _controller.clear();
                      provider.clearCurrentVideo();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('New URL'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppTheme.primaryRed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Text Input with Paste & Clear Buttons
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isFetching,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _fetchVideo(),
              decoration: InputDecoration(
                hintText: 'Paste YouTube link (video, shorts, youtu.be)...',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: _clearInput,
                      ),
                    IconButton(
                      tooltip: 'Paste from Clipboard',
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      onPressed: isFetching ? null : _pasteFromClipboard,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fetch Video Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: isFetching || _controller.text.trim().isEmpty
                    ? null
                    : _fetchVideo,
                icon: isFetching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 20),
                label: Text(
                  isFetching ? 'Fetching Video Details...' : 'Fetch Video',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Quick Demo Link Chips
            if (provider.currentVideo == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Try sample: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('Big Buck Bunny', style: TextStyle(fontSize: 11)),
                    onPressed: isFetching
                        ? null
                        : () {
                            _controller.text = AppConstants.sampleUrls[0];
                            _fetchVideo();
                          },
                  ),
                ],
              ),
            ],

            // Error Display Banner
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
