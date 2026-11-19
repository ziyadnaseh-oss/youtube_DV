import 'dart:async';
import '../models/video_metadata.dart';
import '../models/download_option.dart';
import 'ytdl_service.dart';

class YouTubeService {
  final YtdlService _ytdl = YtdlService();

  /// Parse and validate YouTube URL or bare video ID.
  String? parseVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Bare 11-char video ID
    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(trimmed)) return trimmed;

    // Full URL patterns
    final patterns = [
      RegExp(r'(?:youtube\.com/watch\?.*v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com/shorts/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com/embed/)([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(trimmed);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// Fetch video metadata AND download options in a single network call.
  Future<({VideoMetadata metadata, List<DownloadOption> options})> fetchAll(String url) async {
    final raw = await _ytdl.getInfo(url);
    final metadata = _parseMetadata(raw, url);
    final options = _parseOptions(raw, url);
    return (metadata: metadata, options: options);
  }

  /// Legacy compat — calls fetchAll internally.
  Future<VideoMetadata> fetchVideoMetadata(String url) async {
    final raw = await _ytdl.getInfo(url);
    return _parseMetadata(raw, url);
  }

  /// Legacy compat — reconstructs URL from videoId and calls getInfo.
  Future<List<DownloadOption>> fetchDownloadOptions(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    final raw = await _ytdl.getInfo(url);
    return _parseOptions(raw, url);
  }

  // ─── Parsing helpers ───────────────────────────────────────────────────────

  VideoMetadata _parseMetadata(Map<Object?, Object?> raw, String originalUrl) {
    final title = (raw['title'] as String? ?? 'Unknown Title').trim();
    final author = (raw['uploader'] as String? ?? raw['channel'] as String? ?? 'Unknown').trim();
    final thumbnail = raw['thumbnail'] as String? ?? '';
    final durationSec = (raw['duration'] as num?)?.toDouble();
    final duration = durationSec != null ? Duration(seconds: durationSec.round()) : null;

    // Extract video ID from URL
    final videoId = parseVideoId(originalUrl) ??
        (raw['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString());

    return VideoMetadata(
      id: videoId,
      title: title,
      author: author,
      duration: duration,
      thumbnailUrl: thumbnail,
      originalUrl: originalUrl,
    );
  }

  List<DownloadOption> _parseOptions(Map<Object?, Object?> raw, String originalUrl) {
    final List<Object?> rawFormats = raw['formats'] as List<Object?>? ?? [];

    final formats = rawFormats
        .whereType<Map<Object?, Object?>>()
        .toList();

    final List<DownloadOption> options = [];

    // ── VIDEO OPTIONS ────────────────────────────────────────────────────────
    // Standard height tiers we care about
    const List<int> standardHeights = [2160, 1440, 1080, 720, 480, 360];

    // Collect video-only or muxed formats that have actual video codec
    final videoFormats = formats.where((f) {
      final vcodec = f['vcodec'] as String? ?? 'none';
      final height = (f['height'] as num?)?.toInt() ?? 0;
      return vcodec != 'none' && vcodec.isNotEmpty && height > 0 && _isStandardHeight(height, standardHeights);
    }).toList();

    // Group by standard tier (each tier → best fps variant, prefer mp4)
    final Map<int, Map<Object?, Object?>> bestPerTier = {};

    for (final f in videoFormats) {
      final height = (f['height'] as num?)?.toInt() ?? 0;
      final tier = _nearestTier(height, standardHeights);
      if (tier == null) continue;

      final existing = bestPerTier[tier];
      if (existing == null) {
        bestPerTier[tier] = f;
      } else {
        // Prefer mp4 container
        final fExt = (f['ext'] as String? ?? '').toLowerCase();
        final exExt = (existing['ext'] as String? ?? '').toLowerCase();
        final fFps = (f['fps'] as num?)?.toInt() ?? 0;
        final exFps = (existing['fps'] as num?)?.toInt() ?? 0;

        // mp4 > webm; then higher fps
        final fScore = (fExt == 'mp4' ? 1000 : 0) + fFps;
        final exScore = (exExt == 'mp4' ? 1000 : 0) + exFps;
        if (fScore > exScore) {
          bestPerTier[tier] = f;
        }
      }
    }

    // Also find the best audio-only format for pairing
    final audioOnlyFormats = formats.where((f) {
      final vcodec = f['vcodec'] as String? ?? 'none';
      final acodec = f['acodec'] as String? ?? 'none';
      return (vcodec == 'none' || vcodec.isEmpty) && acodec != 'none' && acodec.isNotEmpty;
    }).toList();

    // Find best muxed (has both video and audio) per tier
    final muxedFormats = formats.where((f) {
      final vcodec = f['vcodec'] as String? ?? 'none';
      final acodec = f['acodec'] as String? ?? 'none';
      final height = (f['height'] as num?)?.toInt() ?? 0;
      return vcodec != 'none' && vcodec.isNotEmpty &&
          acodec != 'none' && acodec.isNotEmpty &&
          height > 0;
    }).toList();

    final Map<int, Map<Object?, Object?>> bestMuxedPerTier = {};
    for (final f in muxedFormats) {
      final height = (f['height'] as num?)?.toInt() ?? 0;
      final tier = _nearestTier(height, standardHeights);
      if (tier == null) continue;
      final existing = bestMuxedPerTier[tier];
      if (existing == null) {
        bestMuxedPerTier[tier] = f;
      } else {
        final fFps = (f['fps'] as num?)?.toInt() ?? 0;
        final exFps = (existing['fps'] as num?)?.toInt() ?? 0;
        if (fFps > exFps) bestMuxedPerTier[tier] = f;
      }
    }

    // Build video DownloadOptions
    for (final tier in standardHeights) {
      final videoFmt = bestPerTier[tier];
      final muxedFmt = bestMuxedPerTier[tier];

      if (videoFmt == null && muxedFmt == null) continue;

      // Prefer muxed for 720p and below; adaptive for 1080p+
      final useMuxed = muxedFmt != null && tier <= 720;
      final fmt = useMuxed ? muxedFmt : (videoFmt ?? muxedFmt!);

      final fmtId = fmt['format_id'] as String? ?? fmt['formatId'] as String? ?? '';
      final fps = (fmt['fps'] as num?)?.toInt() ?? 30;
      final ext = (fmt['ext'] as String? ?? 'mp4').toLowerCase();
      final isMuxed = useMuxed;

      // Size estimate
      int sizeBytes = _estimateSize(fmt, audioOnlyFormats, isMuxed);

      // yt-dlp format string
      String formatId;
      if (isMuxed) {
        formatId = fmtId;
      } else {
        // bestvideo[format_id=X]+bestaudio/best
        formatId = fmtId.isNotEmpty
            ? '$fmtId+bestaudio/best[ext=m4a]/bestaudio'
            : 'bestvideo[height<=$tier]+bestaudio/best';
      }

      final tierLabel = _tierLabel(tier);
      final fpsLabel = fps > 0 && fps != 30 ? '${fps}fps · ' : '';
      final containerLabel = ext == 'webm' ? 'WebM' : 'MP4';

      options.add(DownloadOption(
        type: DownloadFormatType.video,
        label: tierLabel,
        subLabel: '$fpsLabel$containerLabel${isMuxed ? ' · Fast' : ''}',
        qualityKey: '${tier}p',
        formatId: formatId,
        height: tier,
        fps: fps,
        ext: ext,
        isMuxed: isMuxed,
        totalSizeBytes: sizeBytes,
        videoId: originalUrl,
      ));
    }

    // ── AUDIO OPTIONS ────────────────────────────────────────────────────────
    if (audioOnlyFormats.isNotEmpty) {
      // Sort by abr descending
      audioOnlyFormats.sort((a, b) {
        final aAbr = (a['abr'] as num?)?.toDouble() ?? 0;
        final bAbr = (b['abr'] as num?)?.toDouble() ?? 0;
        return bAbr.compareTo(aAbr);
      });

      // High quality: highest abr
      final highFmt = audioOnlyFormats.first;
      final highAbr = (highFmt['abr'] as num?)?.toInt() ?? 128;
      final highSize = (highFmt['filesize'] as num?)?.toInt() ??
          (highFmt['filesize_approx'] as num?)?.toInt() ?? 0;

      options.add(DownloadOption(
        type: DownloadFormatType.audio,
        label: 'High Quality',
        subLabel: '~$highAbr kbps · MP3 / M4A',
        qualityKey: 'audio_high',
        formatId: 'bestaudio/best',
        totalSizeBytes: highSize,
        targetAudioFormat: AudioTargetFormat.mp3,
        videoId: originalUrl,
      ));

      // Standard quality: find one around 64–96 kbps
      final stdFmt = audioOnlyFormats.lastWhere(
        (f) => ((f['abr'] as num?)?.toInt() ?? 0) >= 48,
        orElse: () => audioOnlyFormats.last,
      );
      if (stdFmt != highFmt) {
        final stdAbr = (stdFmt['abr'] as num?)?.toInt() ?? 64;
        final stdFmtId = stdFmt['format_id'] as String? ?? stdFmt['formatId'] as String? ?? '';
        final stdSize = (stdFmt['filesize'] as num?)?.toInt() ??
            (stdFmt['filesize_approx'] as num?)?.toInt() ?? 0;

        options.add(DownloadOption(
          type: DownloadFormatType.audio,
          label: 'Standard Quality',
          subLabel: '~$stdAbr kbps · MP3 / M4A',
          qualityKey: 'audio_std',
          formatId: stdFmtId.isNotEmpty ? '$stdFmtId/bestaudio' : 'worstaudio/worst',
          totalSizeBytes: stdSize,
          targetAudioFormat: AudioTargetFormat.mp3,
          videoId: originalUrl,
        ));
      }
    } else {
      // Fallback: no audio-only streams found — use bestaudio
      options.add(DownloadOption(
        type: DownloadFormatType.audio,
        label: 'Best Audio',
        subLabel: 'MP3 / M4A',
        qualityKey: 'audio_best',
        formatId: 'bestaudio/best',
        totalSizeBytes: 0,
        targetAudioFormat: AudioTargetFormat.mp3,
        videoId: originalUrl,
      ));
    }

    return options;
  }

  // ─── Utility helpers ───────────────────────────────────────────────────────

  bool _isStandardHeight(int h, List<int> tiers) {
    return _nearestTier(h, tiers) != null;
  }

  int? _nearestTier(int height, List<int> tiers) {
    for (final t in tiers) {
      // Allow ±20% tolerance to snap non-standard heights to nearest tier
      if ((height - t).abs() <= t * 0.2) return t;
    }
    return null;
  }

  String _tierLabel(int height) {
    switch (height) {
      case 2160: return '4K · 2160p Ultra HD';
      case 1440: return '2K · 1440p Quad HD';
      case 1080: return '1080p Full HD';
      case 720: return '720p HD';
      case 480: return '480p SD';
      case 360: return '360p SD';
      default: return '${height}p';
    }
  }

  int _estimateSize(Map<Object?, Object?> videoFmt, List<Map<Object?, Object?>> audioFormats, bool isMuxed) {
    final videoSize = (videoFmt['filesize'] as num?)?.toInt() ??
        (videoFmt['filesize_approx'] as num?)?.toInt() ?? 0;
    if (isMuxed || audioFormats.isEmpty) return videoSize;

    // Add best audio stream size
    final audioFmt = audioFormats.first;
    final audioSize = (audioFmt['filesize'] as num?)?.toInt() ??
        (audioFmt['filesize_approx'] as num?)?.toInt() ?? 0;
    return videoSize + audioSize;
  }

  void dispose() {}
}
