import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';
import 'package:sensortech/data/models/camera_model.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/data/services/camera_service.dart';
import 'package:sensortech/features/auth/auth_controller.dart';

class ValaViewModel extends ChangeNotifier {
  final PpeService _ppeService;
  final CameraService _cameraService;
  final AuthController _auth;

  ValaViewModel({
    required PpeService ppeService,
    required CameraService cameraService,
    required AuthController auth,
  })  : _ppeService = ppeService,
        _cameraService = cameraService,
        _auth = auth {
    final now = DateTime.now();
    selectedStartDate = now.subtract(const Duration(days: 6));
    selectedEndDate = now;
    selectedEpi = 'presenca_vala';
    loadCameras();
    loadEvents();
  }

  // ─── State ──────────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isLoadingCameras = false;
  bool isDownloading = false;
  String? errorMessage;
  String? successMessage;

  List<PpeEvent> events = [];
  List<Camera> cameras = [];
  int currentPage = 1;
  int maxKnownPage = 1;
  bool hasNextPage = true;

  // Filters
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String? startTime;
  String? endTime;
  String? selectedEpi = 'presenca_vala';
  int? selectedCameraId;

  // Full-screen modal state
  int? selectedIndex;
  PpeEvent? get selectedEvent =>
      (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < events.length)
          ? events[selectedIndex!]
          : null;

  int? get clientId => _auth.clientId;
  String? get token => _auth.token;

  // ─── Data Loading ───────────────────────────────────────────────────────────
  Future<void> loadEvents({int page = 1}) async {
    final cId = clientId;
    if (cId == null) {
      errorMessage = 'ID do cliente não encontrado.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    currentPage = page;
    if (page == 1) {
      maxKnownPage = 1;
    }
    notifyListeners();

    try {
      final startStr = selectedStartDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedStartDate!)
          : null;
      final endStr = selectedEndDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedEndDate!)
          : null;

      List<PpeEvent> fetched;
      if (selectedEpi == 'todas') {
        final results = await Future.wait([
          _ppeService.getEvents(
            clientId: cId,
            page: page,
            start: startStr,
            end: endStr,
            startTime: startTime,
            endTime: endTime,
            epi: 'presenca_vala',
            cameraId: selectedCameraId,
          ),
          _ppeService.getEvents(
            clientId: cId,
            page: page,
            start: startStr,
            end: endStr,
            startTime: startTime,
            endTime: endTime,
            epi: 'presenca_escora',
            cameraId: selectedCameraId,
          ),
        ]);
        final combined = <PpeEvent>[...results[0], ...results[1]];
        final seen = <int>{};
        final unique = <PpeEvent>[];
        for (final ev in combined) {
          if (seen.add(ev.id)) {
            unique.add(ev);
          }
        }
        unique.sort((a, b) {
          final tA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });
        fetched = unique;
      } else {
        fetched = await _ppeService.getEvents(
          clientId: cId,
          page: page,
          start: startStr,
          end: endStr,
          startTime: startTime,
          endTime: endTime,
          epi: (selectedEpi != null && selectedEpi!.isNotEmpty)
              ? selectedEpi!
              : 'presenca_vala',
          cameraId: selectedCameraId,
        );
      }

      if (page > 1 && fetched.isEmpty) {
        // Chegou ao fim dos resultados
        hasNextPage = false;
        isLoading = false;
        successMessage = 'Você chegou à última página.';
        notifyListeners();
        return;
      }

      events = fetched;
      currentPage = page;
      hasNextPage = fetched.length >= 20;
      if (page > maxKnownPage) {
        maxKnownPage = page;
      }
      if (hasNextPage && page + 1 > maxKnownPage) {
        maxKnownPage = page + 1;
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Erro ao carregar eventos de vala: $e';
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page < 1 || isLoading) return;
    loadEvents(page: page);
  }

  List<int> getVisiblePages() {
    int maxPage = max(currentPage + (hasNextPage ? 1 : 0), maxKnownPage);
    const maxVisible = 5;
    final half = maxVisible ~/ 2;
    int start = (currentPage - half).clamp(1, maxPage);
    int end = (start + maxVisible - 1).clamp(1, maxPage);
    if (end - start < maxVisible - 1) {
      start = (end - maxVisible + 1).clamp(1, maxPage);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  Future<void> loadCameras() async {
    final cId = clientId;
    if (cId == null) return;

    isLoadingCameras = true;
    notifyListeners();

    try {
      final list = await _cameraService.getCamerasByClient(cId);
      list.sort((a, b) => a.displayId.compareTo(b.displayId));
      cameras = list;
    } catch (e) {
      debugPrint('[ValaViewModel] Error loading cameras: $e');
      cameras = [];
    } finally {
      isLoadingCameras = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    selectedStartDate = start;
    selectedEndDate = end;
    notifyListeners();
  }

  void setTimes(String? start, String? end) {
    startTime = start;
    endTime = end;
    notifyListeners();
  }

  void setEpiFilter(String? epi) {
    selectedEpi = (epi == null || epi.isEmpty) ? 'presenca_vala' : epi;
    notifyListeners();
  }

  void setSelectedCamera(int? cameraId) {
    selectedCameraId = cameraId;
    notifyListeners();
  }

  String getCameraHintText() {
    if (isLoadingCameras) return 'Carregando câmeras...';
    if (cameras.isEmpty) return 'Nenhuma câmera encontrada';
    if (selectedCameraId == null) return 'Todas as Câmeras';
    final camera =
        cameras.where((c) => c.displayId == selectedCameraId).firstOrNull;
    return camera != null && camera.nomeCamera.isNotEmpty
        ? '${camera.displayId} - ${camera.nomeCamera}'
        : 'Câmera $selectedCameraId';
  }

  void clearFilters() {
    final now = DateTime.now();
    selectedStartDate = now.subtract(const Duration(days: 6));
    selectedEndDate = now;
    startTime = null;
    endTime = null;
    selectedEpi = 'presenca_vala';
    selectedCameraId = null;
    loadEvents(page: 1);
  }

  // ─── Modal Navigation ───────────────────────────────────────────────────────
  void selectEvent(int index) {
    if (index >= 0 && index < events.length) {
      selectedIndex = index;
      notifyListeners();
    }
  }

  void closeModal() {
    selectedIndex = null;
    notifyListeners();
  }

  void nextImage() {
    if (selectedIndex != null && selectedIndex! < events.length - 1) {
      selectedIndex = selectedIndex! + 1;
      notifyListeners();
    }
  }

  void previousImage() {
    if (selectedIndex != null && selectedIndex! > 0) {
      selectedIndex = selectedIndex! - 1;
      notifyListeners();
    }
  }

  String getSelectedImageUrl() {
    final ev = selectedEvent;
    final cId = clientId;
    if (ev == null || cId == null) return '';
    return _ppeService.buildImageUrl(ev.id, cId);
  }

  String getEventImageUrl(PpeEvent ev) {
    final cId = clientId;
    if (cId == null) return '';
    return _ppeService.buildImageUrl(ev.id, cId);
  }

  // ─── Download Handling ──────────────────────────────────────────────────────
  Future<void> downloadCurrentImage() async {
    final ev = selectedEvent;
    if (ev != null) {
      await downloadEvent(ev);
    }
  }

  Future<void> downloadEvent(PpeEvent event) async {
    final cId = clientId;
    if (cId == null) return;

    isDownloading = true;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        await Permission.notification.request();
        await Permission.storage.request();
      }

      Directory saveDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final root = extDir.path.split('/Android').first;
          saveDir = Directory('$root/Download');
          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }
        } else {
          saveDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
      } else {
        final home = Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '.';
        saveDir = Directory('$home/Downloads');
        if (!await saveDir.exists()) {
          saveDir = await getApplicationDocumentsDirectory();
        }
      }

      final tsStr = event.timestamp != null
          ? DateFormat('yyyyMMdd_HHmmss').format(event.timestamp!)
          : '${event.id}';
      final fileName = 'vala_${event.id}_$tsStr.jpg';
      final savePath = '${saveDir.path}/$fileName';

      await _ppeService.downloadImageFile(
        eventId: event.id,
        clientId: cId,
        savePath: savePath,
      );

      successMessage = 'Download concluído: $fileName';
      await _showDownloadNotification(fileName, savePath, success: true);
    } catch (e) {
      errorMessage = 'Erro ao baixar imagem: $e';
      await _showDownloadNotification('Erro', e.toString(), success: false);
    } finally {
      isDownloading = false;
      notifyListeners();
    }

    Future.delayed(const Duration(seconds: 4), () {
      successMessage = null;
      errorMessage = null;
      notifyListeners();
    });
  }

  Future<void> _showDownloadNotification(
    String title,
    String body, {
    required bool success,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      await plugin.initialize(const InitializationSettings(android: android));

      await plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        success ? 'Download concluído' : 'Erro no download',
        success ? 'Salvo em Downloads: $title' : body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sensortech_downloads',
            'Downloads',
            channelDescription: 'Notificações de download de imagens',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    } catch (_) {}
  }
}
