import 'package:intl/intl.dart';

class Formatters {
  /// Format bytes to human readable string (e.g. 14.5 MB, 1.2 GB)
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 2 : 1)} ${suffixes[i]}';
  }

  /// Format download speed (e.g. 2.4 MB/s)
  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  /// Format duration to mm:ss or hh:mm:ss
  static String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hourStr = hours.toString().padLeft(2, '0');
      return '$hourStr:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Format estimated time remaining
  static String formatEta(double secondsRemaining) {
    if (secondsRemaining.isInfinite || secondsRemaining.isNaN || secondsRemaining <= 0) {
      return '--';
    }
    final int secs = secondsRemaining.round();
    if (secs < 60) {
      return '${secs}s';
    }
    final int mins = secs ~/ 60;
    final int remainingSecs = secs % 60;
    return '${mins}m ${remainingSecs}s';
  }

  /// Format compact view counts (e.g. 1.2M views)
  static String formatCount(int? count) {
    if (count == null) return '';
    return NumberFormat.compact().format(count);
  }

  /// Sanitize filename for safe saving on Android/Windows filesystem
  static String sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.isEmpty) return 'video';
    return sanitized.length > 120 ? sanitized.substring(0, 120) : sanitized;
  }
}
