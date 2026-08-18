import 'package:flutter/material.dart';
import 'package:sensortech/core/auth_extensions.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';
import 'package:sensortech/data/models/cliente_detailed_model.dart';
import 'package:sensortech/data/models/solution_model.dart';
import 'package:sensortech/data/models/camera_model.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';
import 'package:sensortech/data/services/cliente_service.dart';
import 'package:sensortech/data/services/solution_service.dart';
import 'package:sensortech/data/services/camera_service.dart';

class EquipamentosIotViewModel extends ChangeNotifier {
  final AuthController _auth;
  final EquipamentoIotService _equipamentoService;
  final ClienteService _clienteService;
  final SolutionService _solutionService;
  final CameraService _cameraService;

  EquipamentosIotViewModel({
    required AuthController auth,
    required EquipamentoIotService equipamentoService,
    required ClienteService clienteService,
    required SolutionService solutionService,
    required CameraService cameraService,
  })  : _auth = auth,
        _equipamentoService = equipamentoService,
        _clienteService = clienteService,
        _solutionService = solutionService,
        _cameraService = cameraService;

  bool _isLoading = false;
  String? _errorMessage;

  List<EquipamentoIot> _rawMappedEquipamentos = [];
  List<EquipamentoIot> _allEquipamentos = [];
  List<EquipamentoIot> _filteredEquipamentos = [];
  List<ClienteDetailed> _clientes = [];
  List<Solution> _solutions = [];
  List<Camera> _clientCameras = [];
  final Map<int, Set<int>> _cachedClientRaspIds = {};

  int? _selectedClienteId;
  String _selectedFilter = 'all'; // 'all', 'online', 'offline', 'ativo', 'inativo'
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuperAdmin => _auth.isSuperAdmin;

  List<EquipamentoIot> get equipamentos => _filteredEquipamentos;
  List<ClienteDetailed> get clientes => _clientes;
  List<Solution> get solutions => _solutions;
  List<Camera> get clientCameras => _clientCameras;

  int? get selectedClienteId => _selectedClienteId;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  int get totalCount => _allEquipamentos.length;
  int get activeCount => _allEquipamentos.where((e) => e.isOnline).length;
  int get inactiveCount => _allEquipamentos.where((e) => !e.isOnline).length;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentClientId = _auth.clientId;

      // 1. Load solutions catalog
      final solFutures = _solutionService.list().catchError((e) {
        debugPrint('[EquipamentosIotViewModel] Error loading solutions: $e');
        return <Solution>[];
      });

      // 2. Load clients to display client names and allow admin filtering
      final cliFutures = _clienteService.getClientes().catchError((e) {
        debugPrint('[EquipamentosIotViewModel] Error loading clients: $e');
        return <ClienteDetailed>[];
      });

      // 3. Load equipment list from IoT backend
      final eqFuture = _equipamentoService.list().catchError((e) {
        debugPrint('[EquipamentosIotViewModel] Error loading equipment: $e');
        return <EquipamentoIot>[];
      });

      // 4. Load client cameras to obtain valid idRasp hardware mappings
      final camFuture = (currentClientId != null && currentClientId > 0)
          ? _cameraService.getCamerasByClient(currentClientId).catchError((e) {
              debugPrint('[EquipamentosIotViewModel] Error loading cameras for client $currentClientId: $e');
              return <Camera>[];
            })
          : Future.value(<Camera>[]);

      final solResult = await solFutures;
      final cliResult = await cliFutures;
      final eqResult = await eqFuture;
      final camResult = await camFuture;

      _solutions = solResult;
      _clientes = cliResult;
      _clientCameras = camResult;

      if (currentClientId != null && currentClientId > 0) {
        final raspIds = <int>{};
        for (final cam in camResult) {
          if (cam.idRasp != null && cam.idRasp! > 0) {
            raspIds.add(cam.idRasp!);
          }
        }
        _cachedClientRaspIds[currentClientId] = raspIds;
      }

      // Map client names onto equipment items
      _rawMappedEquipamentos = eqResult.map((item) {
        final clientName = _findClienteNome(item.idCliente);
        return item.copyWith(nomeCliente: clientName);
      }).toList();

      _filterEquipamentosForCurrentRole();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Erro ao carregar equipamentos IoT. Tente novamente.';
      debugPrint('[EquipamentosIotViewModel] loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterEquipamentosForCurrentRole() {
    final currentClientId = _auth.clientId;

    if (!isSuperAdmin && currentClientId != null && currentClientId > 0) {
      final allowedRaspIds = _cachedClientRaspIds[currentClientId] ?? <int>{};

      _allEquipamentos = _rawMappedEquipamentos.where((item) {
        final matchesRasp = (item.id != null && allowedRaspIds.contains(item.id)) ||
            (item.idRasp != null && allowedRaspIds.contains(item.idRasp));
        final matchesClient = item.idCliente == currentClientId;

        return matchesRasp || matchesClient;
      }).toList();
    } else {
      _allEquipamentos = List.from(_rawMappedEquipamentos);
    }
  }

  String _findClienteNome(int idCliente) {
    if (idCliente == 0) return '';
    try {
      final client = _clientes.firstWhere((c) => c.id == idCliente);
      return client.displayName.isNotEmpty ? client.displayName : client.razaoSocial;
    } catch (_) {
      return 'Cliente #$idCliente';
    }
  }

  List<String> getSolucoesLabels(EquipamentoIot item) {
    final ids = <int>{};
    if (item.idSolucoes != null && item.idSolucoes!.isNotEmpty) {
      ids.addAll(item.idSolucoes!);
    }
    if (item.solucoes != null && item.solucoes!.isNotEmpty) {
      for (final s in item.solucoes!) {
        ids.add(s.idSolucao);
      }
    }

    if (ids.isEmpty) return [];

    return ids.map((id) {
      try {
        final sol = _solutions.firstWhere((s) => s.id == id);
        return sol.label.isNotEmpty ? sol.label : 'Solução $id';
      } catch (_) {
        return 'Solução $id';
      }
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  Future<void> setSelectedCliente(int? clienteId) async {
    _selectedClienteId = clienteId;

    if (clienteId != null && clienteId > 0 && !_cachedClientRaspIds.containsKey(clienteId)) {
      try {
        final cameras = await _cameraService.getCamerasByClient(clienteId);
        final raspIds = <int>{};
        for (final cam in cameras) {
          if (cam.idRasp != null && cam.idRasp! > 0) {
            raspIds.add(cam.idRasp!);
          }
        }
        _cachedClientRaspIds[clienteId] = raspIds;
      } catch (e) {
        debugPrint('[EquipamentosIotViewModel] Error caching cameras for client $clienteId: $e');
      }
    }

    _applyFilters();
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEquipamentos = _allEquipamentos.where((item) {
      // Filter by Client if user/admin selected one
      if (_selectedClienteId != null) {
        final allowedRaspIds = _cachedClientRaspIds[_selectedClienteId] ?? <int>{};
        final matchesRasp = (item.id != null && allowedRaspIds.contains(item.id)) ||
            (item.idRasp != null && allowedRaspIds.contains(item.idRasp));
        final matchesClient = item.idCliente == _selectedClienteId;

        if (!matchesRasp && !matchesClient) {
          return false;
        }
      }

      // Filter by Status (Ativo = Online/Conectado, Inativo = Offline)
      switch (_selectedFilter) {
        case 'ativo':
        case 'online':
          if (!item.isOnline) return false;
          break;
        case 'inativo':
        case 'offline':
          if (item.isOnline) return false;
          break;
        case 'all':
        default:
          break;
      }

      // Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = item.nomeEquipamento.toLowerCase().contains(query);
        final modelMatch =
            item.modeloEquipamento?.toLowerCase().contains(query) ?? false;
        final ipMatch =
            item.ipEquipamento?.toLowerCase().contains(query) ?? false;
        final locMatch =
            item.enderecoInstalacao?.toLowerCase().contains(query) ?? false;
        final clientMatch =
            item.nomeCliente?.toLowerCase().contains(query) ?? false;
        final idMatch = item.id != null && item.id.toString().contains(query);
        final raspMatch =
            item.idRasp != null && item.idRasp.toString().contains(query);

        return nameMatch ||
            modelMatch ||
            ipMatch ||
            locMatch ||
            clientMatch ||
            idMatch ||
            raspMatch;
      }

      return true;
    }).toList();
  }

  /// Aciona a sirene para o equipamento com o [id] fornecido (simulação segura).
  Future<void> acionarSirene({required int id, int seconds = 5}) async {
    try {
      await _equipamentoService.acionarSirene(id: id, seconds: seconds);
    } catch (e) {
      debugPrint('[EquipamentosIotViewModel] Erro ao acionar sirene: $e');
      rethrow;
    }
  }
}

