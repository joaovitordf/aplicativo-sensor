import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:sensortech/data/services/vms_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:sensortech/data/models/recording_model.dart';

/// ViewModel for the Câmera VMS player page.
/// Receives a pre-selected Recording from the Grade screen, lazy-loads
/// its segments, and manages video playback.
class CameraVmsViewModel extends ChangeNotifier {
  final VmsService _vmsService;

  bool _isDisposed = false;

  CameraVmsViewModel({
    required VmsService vmsService,
  }) : _vmsService = vmsService;

  // ─── State ───────────────────────────────────────────────────────────────
  Recording? selectedRecording;

  bool isLoading = true;
  String? dataError;
  String? playerError;

  DateTime selectedDate = DateTime.now();
  List<RecordingSegment> segmentsForSelectedDate = [];
  int currentSegmentIndex = -1;

  VideoPlayerController? videoController;
  double playbackSpeed = 1.0;
  bool isPlaying = false;
  String? currentHlsUrl;
  String? currentSegmentUrl;

  final List<int?> fallbackDurations = [null, 600, 300];

  bool _thumbnailCaptured = false;
  int _sessionId = 0;
  bool _isTransitioningSegment = false;

  // ─── Initialization (from Grade) ──────────────────────────────────────────
  Future<void> loadForRecording(Recording recording) async {
    isLoading = true;
    dataError = null;
    playerError = null;
    selectedRecording = recording;
    notifyListeners();

    try {
      debugPrint('[VMS] Loading segments for camera: ${recording.name}');
      if (recording.segments.isEmpty) {
        final segments =
            await _vmsService.loadSegmentsForCamera(recording.name);
        debugPrint(
            '[VMS] Loaded ${segments.length} segments for ${recording.name}');
        recording.segments = segments;
      }

      isLoading = false;

      // Auto-select the most recent date that has recordings
      if (recording.segments.isNotEmpty) {
        final dates = recording.recordingDates;
        selectedDate = dates.last;
        debugPrint(
            '[VMS] Auto-selected most recent recording date: ${selectedDate.toIso8601String()}');
      }

      _updateSegmentsForSelectedDate();
      debugPrint(
          '[VMS] Segments for selected date: ${segmentsForSelectedDate.length}');
      notifyListeners();

      // Start live stream
      _startLiveStreamForRecording(recording);
    } catch (e) {
      dataError = 'Erro ao carregar segmentos. Tente novamente.';
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Recording Selection ──────────────────────────────────────────────────
  void selectRecordingDirectly(Recording recording) {
    disposeVideoPlayer();
    selectedRecording = recording;
    currentSegmentIndex = -1;
    isLoading = false;
    _updateSegmentsForSelectedDate();
    notifyListeners();
    _startLiveStreamForRecording(recording);
  }

  void _startLiveStreamForRecording(Recording recording) {
    final camera = recording.cameraInfo;

    if (camera != null) {
      // Strategy 1: External HLS URL (direct .m3u8 link)
      final hlsLink = camera.linkHLS.trim();
      if (hlsLink.isNotEmpty && hlsLink.contains('.m3u8')) {
        _startLiveStream(hlsLink, isDirectUrl: true);
        return;
      }

      // Strategy 2: RTSP URL
      final rtspLink = camera.linkcamera.trim();
      if (rtspLink.startsWith('rtsp://')) {
        _startLiveStream(rtspLink, isDirectUrl: true);
        return;
      }
    }

    // Strategy 3: VMS path-based HLS (default fallback)
    _startLiveStream(recording.name);
  }

  // ─── Date/Segment ─────────────────────────────────────────────────────────
  void _updateSegmentsForSelectedDate() {
    if (selectedRecording == null) {
      segmentsForSelectedDate = [];
    } else {
      segmentsForSelectedDate =
          selectedRecording!.getSegmentsForDate(selectedDate);
    }
    currentSegmentIndex = -1;
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    _updateSegmentsForSelectedDate();
    notifyListeners();
  }

  // ─── HLS / Live Stream ───────────────────────────────────────────────────
  void _startLiveStream(String source, {bool isDirectUrl = false}) {
    disposeVideoPlayer();
    playerError = null;
    String hlsUrl;
    if (isDirectUrl) {
      hlsUrl = source;
    } else {
      final encodedPath =
          source.split('/').map(Uri.encodeComponent).join('/');
      hlsUrl = '${_vmsService.hlsUrl}/$encodedPath/index.m3u8';
    }
    currentHlsUrl = hlsUrl;
    currentSegmentUrl = null;
    _initializeLiveStreamWithRetry(hlsUrl);
  }

  void _initializeLiveStreamWithRetry(String url, [int attempt = 0]) {
    if (_isDisposed || url != currentHlsUrl) return;

    debugPrint('[HLS] Initializing stream (Attempt $attempt): $url');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    controller
        .initialize()
        .timeout(const Duration(seconds: 10))
        .then((_) {
      if (_isDisposed || url != currentHlsUrl) {
        controller.dispose();
        return;
      }

      videoController?.dispose();

      videoController = controller;
      videoController!.play();
      isPlaying = true;
      videoController!.addListener(_videoListener);
      notifyListeners();

      // Capture thumbnail after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed &&
            url == currentHlsUrl &&
            videoController != null &&
            videoController!.value.isInitialized) {
          _captureThumbnail(url);
        }
      });
    }).catchError((error) {
      if (_isDisposed || url != currentHlsUrl) {
        controller.dispose();
        return;
      }

      debugPrint(
          '[HLS] Error or Timeout loading stream (Attempt $attempt): $error');
      controller.dispose();

      if (attempt < 2) {
        Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)), () {
          if (!_isDisposed && url == currentHlsUrl) {
            _initializeLiveStreamWithRetry(url, attempt + 1);
          }
        });
      } else {
        playerError =
            'Transmissão ao vivo indisponível (câmera offline ou sem stream HLS)';
        notifyListeners();
      }
    });
  }

  // ─── Segment Playback ─────────────────────────────────────────────────────
  void playSegment(int index) {
    if (index < 0 || index >= segmentsForSelectedDate.length) return;
    _sessionId++;
    _isTransitioningSegment = false;
    playerError = null;
    disposeVideoPlayer();
    _initSegmentPlayback(index, 0, _sessionId);
  }

  void _initSegmentPlayback(int index, int fallbackLevel, int sessionId) {
    if (_isDisposed || sessionId != _sessionId) return;
    if (fallbackLevel >= fallbackDurations.length) {
      playerError =
          'Erro ao carregar gravação. Tente selecionar outro segmento.';
      notifyListeners();
      return;
    }
    final segment = segmentsForSelectedDate[index];
    final nextSegment = index + 1 < segmentsForSelectedDate.length
        ? segmentsForSelectedDate[index + 1]
        : null;
    final overrideDuration = fallbackDurations[fallbackLevel];
    final format = (fallbackLevel > 0) ? 'mp4' : 'fmp4';
    final url = _vmsService.getSegmentUrl(
      cameraPath: selectedRecording!.name,
      segment: segment,
      nextSegment: nextSegment,
      overrideDuration: overrideDuration,
      format: format,
    );
    currentSegmentUrl = url;
    currentHlsUrl = null;
    _playSegmentWithRetry(index, url, 0, fallbackLevel, sessionId);
  }

  void _playSegmentWithRetry(
      int index, String url, int attempt, int fallbackLevel, int sessionId) {
    if (_isDisposed || sessionId != _sessionId || url != currentSegmentUrl) {
      return;
    }

    debugPrint(
        '[Segment] Initializing segment $index (Fallback Level $fallbackLevel, Attempt $attempt): $url');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    controller
        .initialize()
        .timeout(const Duration(seconds: 10))
        .then((_) {
      if (_isDisposed || sessionId != _sessionId || url != currentSegmentUrl) {
        controller.dispose();
        return;
      }

      disposeVideoPlayer();

      videoController = controller;
      currentSegmentIndex = index;
      _isTransitioningSegment = false;
      videoController!.setPlaybackSpeed(playbackSpeed);
      videoController!.play();
      isPlaying = true;
      videoController!.addListener(_videoListener);
      notifyListeners();

      // Capture thumbnail after a safe delay if not already captured
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed &&
            sessionId == _sessionId &&
            url == currentSegmentUrl &&
            videoController != null &&
            videoController!.value.isInitialized) {
          _captureThumbnail(url);
        }
      });
    }).catchError((error) {
      if (_isDisposed || sessionId != _sessionId || url != currentSegmentUrl) {
        controller.dispose();
        return;
      }

      debugPrint(
          '[Segment] Error or Timeout loading segment (Attempt $attempt): $error');
      controller.dispose();

      if (attempt < 2) {
        Future.delayed(Duration(milliseconds: 800 * (attempt + 1)), () {
          if (!_isDisposed && sessionId == _sessionId && url == currentSegmentUrl) {
            _playSegmentWithRetry(index, url, attempt + 1, fallbackLevel, sessionId);
          }
        });
      } else if (fallbackLevel + 1 < fallbackDurations.length) {
        debugPrint(
            '[Segment] Failed level $fallbackLevel. Switching to next fallback.');
        _initSegmentPlayback(index, fallbackLevel + 1, sessionId);
      } else {
        playerError = 'Erro ao carregar gravação. Tente novamente.';
        notifyListeners();
      }
    });
  }

  void _videoListener() {
    if (_isDisposed || videoController == null) return;
    final value = videoController!.value;
    if (value.hasError) {
      debugPrint('[Segment] Video player error: ${value.errorDescription}');
      return;
    }

    final position = value.position;
    final duration = value.duration;

    // Check if video reached the end
    if (duration > Duration.zero &&
        position >= duration &&
        !_isTransitioningSegment) {
      _isTransitioningSegment = true;
      if (currentSegmentIndex >= 0 &&
          currentSegmentIndex < segmentsForSelectedDate.length - 1) {
        playSegment(currentSegmentIndex + 1);
      } else {
        if (isPlaying) {
          isPlaying = false;
          notifyListeners();
        }
      }
      return;
    }

    final nowPlaying = value.isPlaying;
    if (nowPlaying != isPlaying) {
      isPlaying = nowPlaying;
      notifyListeners();
    }
  }

  // ─── Thumbnail Capture ────────────────────────────────────────────────────
  Future<void> _captureThumbnail(String originalUrl) async {
    if (_thumbnailCaptured || selectedRecording == null || _isDisposed) return;

    try {
      final cameraInfo = selectedRecording!.cameraInfo;
      final id = cameraInfo?.id.toString() ??
          selectedRecording!.name.replaceAll('/', '_');

      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('thumb_$id')) {
        _thumbnailCaptured = true;
        return;
      }

      _thumbnailCaptured = true;
      final appDir = await getApplicationDocumentsDirectory();

      String targetUrl = originalUrl;

      // Native Android MediaMetadataRetriever fails to extract frames from live .m3u8.
      // If we are playing HLS but have recorded segments, extract from the most recent segment.
      if (originalUrl.contains('.m3u8') &&
          selectedRecording!.segments.isNotEmpty) {
        final lastSegment = selectedRecording!.segments.last;
        targetUrl = _vmsService.getSegmentUrl(
          cameraPath: selectedRecording!.name,
          segment: lastSegment,
          nextSegment: null,
          overrideDuration: 10,
        );
        debugPrint(
            '[VMS] Swapped .m3u8 for static segment URL for thumbnail: $targetUrl');
      }

      debugPrint('[VMS] Capturing thumbnail from: $targetUrl');
      final xFile = await VideoThumbnail.thumbnailFile(
        video: targetUrl,
        thumbnailPath: appDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 50,
      );
      final String path = xFile.path;

      if (path.isNotEmpty) {
        debugPrint('[VMS] Thumbnail captured at $path');
        await prefs.setString('thumb_$id', path);
      } else {
        _thumbnailCaptured = false;
      }
    } catch (e) {
      debugPrint('[VMS] Failed to capture thumbnail: $e');
      _thumbnailCaptured = false;
    }
  }

  // ─── Playback Controls ────────────────────────────────────────────────────
  void togglePlayPause() {
    if (videoController == null || !videoController!.value.isInitialized) {
      return;
    }
    if (videoController!.value.isPlaying) {
      videoController!.pause();
    } else {
      videoController!.play();
    }
    isPlaying = videoController!.value.isPlaying;
    notifyListeners();
  }

  void previousSegment() {
    if (currentSegmentIndex > 0) playSegment(currentSegmentIndex - 1);
  }

  void nextSegment() {
    if (currentSegmentIndex < segmentsForSelectedDate.length - 1) {
      playSegment(currentSegmentIndex + 1);
    }
  }

  void changePlaybackSpeed(double speed) {
    playbackSpeed = speed;
    videoController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────
  void disposeVideoPlayer() {
    videoController?.removeListener(_videoListener);
    videoController?.pause();
    videoController?.dispose();
    videoController = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    currentHlsUrl = null;
    currentSegmentUrl = null;
    disposeVideoPlayer();
    super.dispose();
  }
}
