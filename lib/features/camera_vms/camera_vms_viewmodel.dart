import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:sensortech/data/services/vms_service.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';

/// ViewModel for the Câmera VMS player page.
/// Receives a pre-selected Recording from the Grade screen, lazy-loads
/// its segments, and manages video playback and linked IoT status.
class CameraVmsViewModel extends ChangeNotifier {
  final VmsService _vmsService;
  final EquipamentoIotService? _equipamentoService;

  bool _isDisposed = false;

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  CameraVmsViewModel({
    required VmsService vmsService,
    EquipamentoIotService? equipamentoService,
  })  : _vmsService = vmsService,
        _equipamentoService = equipamentoService;

  // ─── State ───────────────────────────────────────────────────────────────
  Recording? selectedRecording;

  bool isLoading = true;
  String? dataError;
  String? playerError;

  // ─── Linked IoT Equipment State ──────────────────────────────────────────
  EquipamentoIot? linkedIotEquipamento;
  bool isIotLoading = false;
  String? iotError;

  DateTime selectedDate = DateTime.now();
  List<RecordingSegment> segmentsForSelectedDate = [];
  int currentSegmentIndex = -1;

  VideoPlayerController? videoController;
  double playbackSpeed = 1.0;
  bool isPlaying = false;
  String? currentHlsUrl;
  String? currentSegmentUrl;

  final List<int?> fallbackDurations = [null, 600, 300];

  int _sessionId = 0;
  bool _isTransitioningSegment = false;

  // ─── Initialization (from Grade) ──────────────────────────────────────────
  Future<void> loadForRecording(Recording recording) async {
    isLoading = true;
    dataError = null;
    playerError = null;
    selectedRecording = recording;
    _safeNotifyListeners();

    // Fetch linked IoT Equipment status concurrently if idRasp exists
    final idRasp = recording.cameraInfo?.idRasp;
    if (idRasp != null && idRasp > 0) {
      _fetchLinkedIotEquipment(idRasp);
    } else {
      linkedIotEquipamento = null;
      isIotLoading = false;
    }

    try {
      debugPrint('[VMS] Loading segments for camera: ${recording.name}');
      if (recording.segments.isEmpty) {
        final segments =
            await _vmsService.loadSegmentsForCamera(recording.name);
        debugPrint(
            '[VMS] Loaded ${segments.length} segments for ${recording.name}');
        recording.segments = segments;
      }

      if (_isDisposed) return;

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
      _safeNotifyListeners();

      // Start live stream
      _startLiveStreamForRecording(recording);
    } catch (e) {
      if (_isDisposed) return;
      dataError = 'Erro ao carregar segmentos. Tente novamente.';
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ─── Linked IoT Equipment Methods ────────────────────────────────────────
  Future<void> _fetchLinkedIotEquipment(int idRasp) async {
    final eqService = _equipamentoService;
    if (eqService == null) return;
    isIotLoading = true;
    iotError = null;
    _safeNotifyListeners();

    try {
      final list = await eqService.list();
      if (_isDisposed) return;
      // Match by id or idRasp
      final matches = list.where((eq) => eq.id == idRasp || eq.idRasp == idRasp);
      if (matches.isNotEmpty) {
        linkedIotEquipamento = matches.first;
      } else {
        linkedIotEquipamento = null;
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('[CameraVmsViewModel] Error fetching linked IoT equipment: $e');
      iotError = e.toString();
    } finally {
      if (!_isDisposed) {
        isIotLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> refreshIotStatus() async {
    final idRasp = selectedRecording?.cameraInfo?.idRasp;
    if (idRasp != null && idRasp > 0) {
      await _fetchLinkedIotEquipment(idRasp);
    }
  }

  /// Aciona a sirene para o equipamento IoT vinculado à câmera.
  /// Envia a requisição POST /api/v1/equipamentosiot/timer com { "id": id, "seconds": seconds }
  Future<void> acionarSirene({required int id, int seconds = 5}) async {
    final eqService = _equipamentoService;
    if (eqService == null) return;
    try {
      debugPrint('[CameraVmsViewModel] Enviando requisição para acionar sirene: id=$id, seconds=$seconds');
      await eqService.acionarSirene(id: id, seconds: seconds);
    } catch (e) {
      debugPrint('[CameraVmsViewModel] Erro ao acionar sirene: $e');
      rethrow;
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
    final url = _vmsService.getSegmentUrl(
      cameraPath: selectedRecording!.name,
      segment: segment,
      nextSegment: nextSegment,
      overrideDuration: overrideDuration,
      format: 'mp4',
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

    // Only process auto-advance for recordings (currentSegmentIndex >= 0)
    if (currentSegmentIndex >= 0 &&
        currentSegmentIndex < segmentsForSelectedDate.length &&
        value.isInitialized) {
      final currentSeg = segmentsForSelectedDate[currentSegmentIndex];
      final nextSeg = currentSegmentIndex + 1 < segmentsForSelectedDate.length
          ? segmentsForSelectedDate[currentSegmentIndex + 1]
          : null;
      final expectedDurationSec =
          _vmsService.calculateSegmentDuration(currentSeg, nextSeg);

      // Only consider naturally completed if:
      // 1. Played at least almost the entire duration (expectedDurationSec - 2) AND > 5s
      // 2. OR video reported a valid full duration (> 5s) and position reached within 500ms of it and isCompleted
      final isNaturallyCompleted = (expectedDurationSec > 5 &&
              position.inSeconds >= (expectedDurationSec - 2) &&
              (value.isCompleted || !value.isPlaying)) ||
          (duration.inSeconds >= 5 &&
              duration.inSeconds >= (expectedDurationSec - 5) &&
              position >= duration - const Duration(milliseconds: 500) &&
              value.isCompleted);

      if (isNaturallyCompleted && !_isTransitioningSegment) {
        _isTransitioningSegment = true;
        if (currentSegmentIndex < segmentsForSelectedDate.length - 1) {
          final nextIndex = currentSegmentIndex + 1;
          debugPrint(
              '[Segment] Segment $currentSegmentIndex (${expectedDurationSec}s) finished. Advancing to segment $nextIndex');
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!_isDisposed && _isTransitioningSegment) {
              playSegment(nextIndex);
            }
          });
        } else {
          if (isPlaying) {
            isPlaying = false;
            notifyListeners();
          }
        }
        return;
      }
    }

    final nowPlaying = value.isPlaying;
    if (nowPlaying != isPlaying) {
      isPlaying = nowPlaying;
      notifyListeners();
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
