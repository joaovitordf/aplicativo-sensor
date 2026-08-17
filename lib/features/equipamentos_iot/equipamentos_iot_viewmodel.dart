import 'package:flutter/material.dart';
import 'package:sensortech/core/auth_extensions.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';
import 'package:sensortech/data/models/cliente_detailed_model.dart';
import 'package:sensortech/data/models/solution_model.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';
import 'package:sensortech/data/services/cliente_service.dart';
import 'package:sensortech/data/services/solution_service.dart';

class EquipamentosIotViewModel extends ChangeNotifier {
  final AuthController _auth;
  final EquipamentoIotService _equipamentoService;
  final ClienteService _clienteService;
  final SolutionService _solutionService;

  EquipamentosIotViewModel({
    required AuthController auth,
    required EquipamentoIotService equipamentoService,
    required ClienteService clienteService,
    required SolutionService solutionService,
  })  : _auth = auth,
        _equipamentoService = equipamentoService,
        _clienteService = clienteService,
        _solutionService = solutionService;

  bool _isLoading = false;
  String? _errorMessage;

  List<EquipamentoIot> _allEquipamentos = [];
  List<EquipamentoIot> _filteredEquipamentos = [];
  List<ClienteDetailed> _clientes = [];
  List<Solution> _solutions = [];

  int? _selectedClienteId;
  int? _selectedStatus; // null = Todos, 1 = Ativos, 0 = Inativos
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuperAdmin => _auth.isSuperAdmin;

  List<EquipamentoIot> get equipamentos => _filteredEquipamentos;
  List<ClienteDetailed> get clientes => _clientes;
  List<Solution> get solutions => _solutions;

  int? get selectedClienteId => _selectedClienteId;
  int? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  int get totalCount => _allEquipamentos.length;
  int get activeCount => _allEquipamentos.where((e) => e.isAtivo).length;
  int get inactiveCount => _allEquipamentos.where((e) => !e.isAtivo).length;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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

      final solResult = await solFutures;
      final cliResult = await cliFutures;
      final eqResult = await eqFuture;

      _solutions = solResult;
      _clientes = cliResult;
      var rawList = eqResult;

      // Map client names onto equipment items
      _allEquipamentos = rawList.map((item) {
        final clientName = _findClienteNome(item.idCliente);
        return item.copyWith(nomeCliente: clientName);
      }).toList();

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Erro ao carregar equipamentos IoT. Tente novamente.';
      debugPrint('[EquipamentosIotViewModel] loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  void setSelectedCliente(int? clienteId) {
    _selectedClienteId = clienteId;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedStatus(int? status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEquipamentos = _allEquipamentos.where((item) {
      // Filter by Client if user selected one
      if (_selectedClienteId != null && item.idCliente != _selectedClienteId) {
        return false;
      }

      // Filter by Status (1 = Ativo, 0 = Inativo)
      if (_selectedStatus != null) {
        if (_selectedStatus == 1 && !item.isAtivo) return false;
        if (_selectedStatus == 0 && item.isAtivo) return false;
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
