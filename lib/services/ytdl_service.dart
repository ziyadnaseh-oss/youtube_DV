import 'dart:async';
import 'package:flutter/services.dart';

const MethodChannel _methodChannel = MethodChannel('com.example.youtube2/ytdl');
const EventChannel _eventChannel = EventChannel('com.example.youtube2/ytdl_events');

/// Dart bridge to the native youtubedl-android MethodChannel + EventChannel.
class YtdlService {
  static final YtdlService _instance = YtdlService._internal();
  factory YtdlService() => _instance;
  YtdlService._internal();

  Stream<Map<Object?, Object?>>? _progressStream;

  /// Broadcast stream of progress events from the native side.
  /// Each event is a Map with keys: processId, progress, etaSeconds, line.
  Stream<Map<Object?, Object?>> get progressStream {
    _progressStream ??= _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .asBroadcastStream();
    return _progressStream!;
  }

  /// Initialize youtubedl-android (call once at app start; native side is idempotent).
  Future<bool> init() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('init');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('YtdlService.init failed: ${e.message}');
    }
  }

  /// Fetch video info (title, thumbnail, duration, formats).
  /// Returns a raw Map mirroring the JSON from youtubedl-android VideoInfo.
  Future<Map<Object?, Object?>> getInfo(String url) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>('getInfo', {'url': url});
      if (result == null) throw Exception('getInfo returned null');
      return result;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch video info');
    }
  }

  /// Start a download. Returns a Map with { filePath, processId } on success, or null if cancelled.
  Future<Map<Object?, Object?>?> download({
    required String url,
    required String processId,
    String? formatId,
    bool isAudioOnly = false,
    String audioFormat = 'mp3',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>('download', {
        'url': url,
        'processId': processId,
        'formatId': ?formatId,
        'isAudioOnly': isAudioOnly,
        'audioFormat': audioFormat,
      });
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') return null;
      throw Exception(e.message ?? 'Download failed');
    }
  }

  /// Cancel an in-progress download by processId.
  Future<bool> cancel(String processId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('cancel', {'processId': processId});
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Update the embedded yt-dlp binary to the latest version.
  Future<String> updateEngine() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('updateEngine');
      return result ?? 'Engine update completed';
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to update engine');
    }
  }
}
