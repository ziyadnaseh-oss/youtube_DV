import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class StorageService {
  /// Request appropriate storage permissions based on Android SDK version.
  /// Completely skips Permission.storage on Android 13+ (SDK >= 33).
  /// Includes a 5-second timeout fallback so permission checks can never block a download.
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      return await _checkAndRequestPermissions().timeout(
        const Duration(seconds: 5),
        onTimeout: () => true, // Fallback on timeout so download is never blocked
      );
    } catch (_) {
      return true; // Fallback on any unexpected error
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13+ (API 33+): Scoped storage handles public Downloads or app files.
      // Never ask for legacy Permission.storage, which hangs or is permanently denied.
      if (sdkInt >= 33) {
        return true;
      }

      if (sdkInt >= 30) {
        // Android 11 & 12 (API 30-32)
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) return true;

        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        // Android 10 and below (API 24-29)
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (_) {
      return true;
    }
  }

  /// Get the target directory for saving downloads.
  /// Attempts the public /storage/emulated/0/Download first.
  /// Falls back to getDownloadsDirectory() or getExternalStorageDirectory().
  Future<Directory> getPublicDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final publicDir = Directory(AppConstants.defaultDownloadDir);
      try {
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        // Test writability with a hidden check file
        final testFile = File('${publicDir.path}/.write_test_${DateTime.now().millisecondsSinceEpoch}');
        await testFile.writeAsString('ok');
        await testFile.delete();
        return publicDir;
      } catch (_) {
        // If public folder is write-restricted by scoped storage, fallback
      }

      final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (extDirs != null && extDirs.isNotEmpty) {
        return extDirs.first;
      }

      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return extDir;
      }
    }

    // iOS or Desktop fallback
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }

    return await getApplicationDocumentsDirectory();
  }

  /// Get a directory for temporary intermediate files (video/audio parts before muxing)
  /// Inside getTemporaryDirectory() which requires zero permissions.
  Future<Directory> getTemporaryFolder() async {
    final tempBase = await getTemporaryDirectory();
    final workingDir = Directory('${tempBase.path}/${AppConstants.tempFolder}');
    if (!await workingDir.exists()) {
      await workingDir.create(recursive: true);
    }
    return workingDir;
  }

  /// Resolves an unused destination file path in the public Downloads directory.
  Future<String> resolveUniqueDestinationPath(
    String baseTitle,
    String extension,
  ) async {
    final targetDir = await getPublicDownloadsDirectory();
    final sanitized = Formatters.sanitizeFileName(baseTitle);
    final extWithDot = extension.startsWith('.') ? extension : '.$extension';

    String candidate = '${targetDir.path}/$sanitized$extWithDot';
    int counter = 1;

    while (await File(candidate).exists()) {
      candidate = '${targetDir.path}/$sanitized ($counter)$extWithDot';
      counter++;
    }

    return candidate;
  }

  /// Write or copy a completed file from temporary storage to public /storage/emulated/0/Download
  /// with automatic fallback to app downloads directory if restricted by scoped storage.
  Future<String> saveFinalFile({
    required File tempFile,
    required String baseTitle,
    required String extension,
  }) async {
    final destPath = await resolveUniqueDestinationPath(baseTitle, extension);
    try {
      final destFile = File(destPath);
      await destFile.parent.create(recursive: true);
      await tempFile.copy(destPath);
      return destPath;
    } catch (_) {
      // Fallback: Copy to external downloads or documents directory
      final fallbackDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      Directory fallbackDir;
      if (fallbackDirs != null && fallbackDirs.isNotEmpty) {
        fallbackDir = fallbackDirs.first;
      } else {
        fallbackDir = await getApplicationDocumentsDirectory();
      }

      final sanitized = Formatters.sanitizeFileName(baseTitle);
      final extWithDot = extension.startsWith('.') ? extension : '.$extension';
      String candidate = '${fallbackDir.path}/$sanitized$extWithDot';
      int counter = 1;
      while (await File(candidate).exists()) {
        candidate = '${fallbackDir.path}/$sanitized ($counter)$extWithDot';
        counter++;
      }

      await tempFile.copy(candidate);
      return candidate;
    }
  }

  /// Clean up all files in the temporary directory
  Future<void> cleanupTempFolder() async {
    try {
      final tempDir = await getTemporaryFolder();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (final f in files) {
          try {
            f.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Delete specific file safely
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
