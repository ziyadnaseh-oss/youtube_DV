import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../models/download_option.dart';
import '../models/download_task.dart';
import '../models/video_metadata.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';

class DownloaderProvider extends ChangeNotifier {
  YouTubeService? _ytService;
  DownloadService? _downloadService;
  StorageService? _storageService;

  DownloaderProvider({
    YouTubeService? ytService,
    DownloadService? downloadService,
    StorageService? storageService,
  }) {
    if (ytService != null) _ytService = ytService;
    if (downloadService != null) _downloadService = downloadService;
    if (storageService != null) _storageService = storageService;
  }

  YouTubeService get ytService => _ytService ??= YouTubeService();
  DownloadService get downloadService => _downloadService ??= DownloadService();
  StorageService get storageService => _storageService ??= StorageService();

  // State
  bool _isFetching = false;
  String? _errorMessage;
  VideoMetadata? _currentVideo;
  List<DownloadOption> _allOptions = [];
  DownloadFormatType _selectedFormatType = DownloadFormatType.video;
  AudioTargetFormat _selectedAudioFormat = AudioTargetFormat.mp3;
  DownloadOption? _selectedOption;

  DownloadTask? _activeTask;
  final List<DownloadTask> _history = [];

  // Getters
  bool get isFetching => _isFetching;
  String? get errorMessage => _errorMessage;
  VideoMetadata? get currentVideo => _currentVideo;
  DownloadFormatType get selectedFormatType => _selectedFormatType;
  AudioTargetFormat get selectedAudioFormat => _selectedAudioFormat;
  DownloadOption? get selectedOption => _selectedOption;
  DownloadTask? get activeTask => _activeTask;
  List<DownloadTask> get history => List.unmodifiable(_history);

  /// Options filtered by currently active tab (Video vs Audio)
  List<DownloadOption> get visibleOptions {
    return _allOptions.where((opt) => opt.type == _selectedFormatType).map((opt) {
      if (opt.type == DownloadFormatType.audio) {
        return opt.copyWith(targetAudioFormat: _selectedAudioFormat);
      }
      return opt;
    }).toList();
  }

  /// Fetch video metadata and manifest from a YouTube URL
  Future<void> fetchVideo(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter a YouTube video URL';
      notifyListeners();
      return;
    }

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ytService.fetchAll(trimmed);
      final metadata = result.metadata;
      // Inject the original URL into every option so DownloadService can use it
      final options = result.options.map((opt) => opt.copyWith(videoId: trimmed)).toList();

      _currentVideo = metadata;
      _allOptions = options;

      // Automatically select highest resolution video by default
      final videoOptions = options.where((o) => o.type == DownloadFormatType.video).toList();
      if (videoOptions.isNotEmpty) {
        _selectedFormatType = DownloadFormatType.video;
        _selectedOption = videoOptions.first;
      } else if (options.isNotEmpty) {
        _selectedFormatType = DownloadFormatType.audio;
        _selectedOption = options.first;
      }
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '');
      // Hide raw googlevideo.com URLs and long stack traces from user
      final errorMsg = _sanitizeErrorMessage(rawMsg);
      _errorMessage = errorMsg;
      _currentVideo = null;
      _allOptions = [];
      _selectedOption = null;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Switch between Video tab and Audio tab
  void setFormatType(DownloadFormatType type) {
    _selectedFormatType = type;
    final available = visibleOptions;
    if (available.isNotEmpty) {
      _selectedOption = available.first;
    } else {
      _selectedOption = null;
    }
    notifyListeners();
  }

  /// Switch audio target format (MP3 vs M4A)
  void setAudioFormat(AudioTargetFormat format) {
    _selectedAudioFormat = format;
    if (_selectedOption != null && _selectedOption!.type == DownloadFormatType.audio) {
      _selectedOption = _selectedOption!.copyWith(targetAudioFormat: format);
    }
    notifyListeners();
  }

  /// Select specific quality/resolution
  void selectOption(DownloadOption option) {
    if (option.type == DownloadFormatType.audio) {
      _selectedOption = option.copyWith(targetAudioFormat: _selectedAudioFormat);
    } else {
      _selectedOption = option;
    }
    notifyListeners();
  }

  /// Clear the currently fetched video card
  void clearCurrentVideo() {
    _currentVideo = null;
    _allOptions = [];
    _selectedOption = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Start download with the selected option
  Future<void> startDownload({
    required void Function(String filePath) onSuccess,
    required void Function(String error) onError,
  }) async {
    if (_currentVideo == null || _selectedOption == null) {
      onError('Please select a video quality to download.');
      return;
    }

    if (_activeTask != null && _activeTask!.isRunning) {
      onError('A download is already in progress.');
      return;
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      videoTitle: _currentVideo!.title,
      thumbnailUrl: _currentVideo!.thumbnailUrl,
      option: _selectedOption!,
      status: DownloadStatus.downloading,
      stageMessage: 'Starting download...',
      createdAt: DateTime.now(),
    );

    _activeTask = task;
    notifyListeners();

    try {
      final savedPath = await downloadService.download(
        videoTitle: _currentVideo!.title,
        option: _selectedOption!,
        onProgress: (update) {
          if (_activeTask == null) return;
          DownloadStatus currentStatus = DownloadStatus.downloading;
          if (update.progress >= 0.95 && update.progress < 1.0) {
            currentStatus = _selectedOption!.type == DownloadFormatType.video
                ? DownloadStatus.merging
                : DownloadStatus.converting;
          } else if (update.progress >= 1.0) {
            currentStatus = DownloadStatus.completed;
          }

          _activeTask = _activeTask!.copyWith(
            status: currentStatus,
            stageMessage: update.stageMessage,
            progress: update.progress,
            downloadedBytes: update.downloadedBytes,
            totalBytes: update.totalBytes,
            speedBytesPerSec: update.speedBytesPerSec,
            etaSeconds: update.etaSeconds,
          );
          notifyListeners();
        },
      );

      if (savedPath != null) {
        final completedTask = _activeTask!.copyWith(
          status: DownloadStatus.completed,
          stageMessage: 'Saved to Downloads folder',
          progress: 1.0,
          savedFilePath: savedPath,
        );
        _activeTask = null;
        _history.insert(0, completedTask);
        notifyListeners();
        onSuccess(savedPath);
      } else {
        // Cancelled
        _activeTask = null;
        notifyListeners();
      }
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '');
      final errorMsg = _sanitizeErrorMessage(rawMsg);
      if (_activeTask != null) {
        final failedTask = _activeTask!.copyWith(
          status: DownloadStatus.failed,
          stageMessage: 'Failed',
          errorMessage: errorMsg,
        );
        _history.insert(0, failedTask);
      }
      _activeTask = null;
      notifyListeners();
      onError(errorMsg);
    }
  }

  /// Cancel current ongoing download
  Future<void> cancelActiveDownload() async {
    if (_activeTask != null) {
      if (_downloadService != null) {
        await _downloadService!.cancel();
      }
      _activeTask = null;
      notifyListeners();
    }
  }

  /// Open file using OpenFilex
  Future<void> openFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint('Could not open file: ${result.message}');
    }
  }

  /// Share downloaded file
  Future<void> shareFile(String filePath, String title) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)], text: title));
  }

  /// Delete a file from history and disk
  Future<void> deleteHistoryItem(DownloadTask task) async {
    if (task.savedFilePath != null) {
      await storageService.deleteFile(task.savedFilePath!);
    }
    _history.removeWhere((item) => item.id == task.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _ytService?.dispose();
    super.dispose();
  }

  /// Clean up raw error messages: hide long googlevideo URLs and
  /// multi-line stack traces behind a concise user-friendly message.
  String _sanitizeErrorMessage(String raw) {
    if (raw.contains('googlevideo.com') || raw.contains('SocketException') || raw.contains('ClientException')) {
      return 'Download failed due to a network error. Please check your connection and try again.';
    }
    if (raw.contains('Failed host lookup')) {
      return 'Could not reach YouTube servers. Please check your internet connection.';
    }
    if (raw.contains('VideoUnavailableException') || raw.contains('Video is unavailable')) {
      return 'This video is unavailable or restricted. Try a different video.';
    }
    // Truncate excessively long messages
    if (raw.length > 200) {
      return '${raw.substring(0, 150)}... (see logs for details)';
    }
    return raw;
  }
}
