import 'package:flutter/foundation.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/data/services/camera_service.dart';
import 'package:sensortech/data/services/vms_service.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/data/models/camera_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel for the Câmera VMS Grade (grid listing) screen.
/// Loads cameras via CameraService, builds Recording entries (segments are lazy
/// loaded when the user opens a specific camera player).
class CameraVmsGradeViewModel extends ChangeNotifier {
  final AuthController _auth;
  final CameraService _cameraService;

  CameraVmsGradeViewModel({
    required AuthController auth,
    required CameraService cameraService,
  })  : _auth = auth,
        _cameraService = cameraService;

  // ─── State ──────────────────────────────────────────────────────────────────
  bool isLoading = true;
  String? dataError;

  /// All recordings — the full unfiltered source.
  List<Recording> _allRecordings = [];

  /// Recordings after applying search/filter criteria.
  List<Recording> filteredRecordings = [];

  /// Map of camera ID to local thumbnail file path.
  Map<String, String> thumbnails = {};

  // ─── Filter state ─────────────────────────────────────────────────────────
  String searchText = '';

  // ─── Initialization ─────────────────────────────────────────────────────────
  Future<void> loadData() async {
    isLoading = true;
    dataError = null;
    notifyListeners();

    try {
      await _loadCameras();
      await _loadThumbnails();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      dataError = 'Erro ao carregar câmeras. Tente novamente.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadThumbnails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final recording in _allRecordings) {
        final id = recording.cameraInfo?.id.toString() ??
            recording.name.replaceAll('/', '_');
        final path = prefs.getString('thumb_$id');
        if (path != null) {
          thumbnails[id] = path;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[VMS Grade] Error loading thumbnails: $e');
    }
  }

  Future<void> refreshThumbnails() async {
    await _loadThumbnails();
  }

  /// Load cameras for the logged-in client and build Recording entries.
  Future<void> _loadCameras() async {
    final clienteId = _auth.clientId;
    if (clienteId == null) {
      _allRecordings = [];
      applyFilters();
      return;
    }

    final allCameras = await _cameraService.getCamerasByClient(clienteId);

    _allRecordings = allCameras.map((camera) {
      final pathName = camera.vmsPathName; // e.g. "8/45"
      return Recording(
        name: pathName,
        segments: [], // lazy loaded
        cameraInfo: camera,
      );
    }).toList()
      ..sort((a, b) {
        final idA = a.cameraInfo?.id ?? 0;
        final idB = b.cameraInfo?.id ?? 0;
        return idA.compareTo(idB);
      });

    applyFilters();
  }

  // ─── Filtering ──────────────────────────────────────────────────────────────
  void applyFilters() {
    final q = searchText.trim().toLowerCase();

    filteredRecordings = _allRecordings.where((r) {
      if (q.isNotEmpty) {
        final name = r.name.toLowerCase();
        final cameraName = r.cameraInfo?.nomeCamera.toLowerCase() ?? '';
        if (!name.contains(q) && !cameraName.contains(q)) return false;
      }
      return true;
    }).toList();

    notifyListeners();
  }

  void onSearchChange(String text) {
    searchText = text;
    applyFilters();
  }

  // ─── Display helpers ────────────────────────────────────────────────────────
  String formatarTipoConexao(Camera? camera) {
    if (camera == null) return '';
    return VmsService.formatarTipoConexao(
      camera.tipoConexao,
      linkcamera: camera.linkcamera,
      linkHLS: camera.linkHLS,
      idP2p: camera.idCameraP2p,
    );
  }
}
