import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';
import 'package:sensortech/data/services/cliente_service.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';
import 'package:sensortech/data/services/solution_service.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/equipamentos_iot/equipamentos_iot_viewmodel.dart';
import 'package:sensortech/features/home/homepage.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';
import 'package:sensortech/shared/widgets/searchable_dropdown.dart';

class EquipamentosIotPage extends StatelessWidget {
  const EquipamentosIotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EquipamentosIotViewModel(
        auth: Provider.of<AuthController>(context, listen: false),
        equipamentoService:
            Provider.of<EquipamentoIotService>(context, listen: false),
        clienteService: Provider.of<ClienteService>(context, listen: false),
        solutionService: Provider.of<SolutionService>(context, listen: false),
      )..loadData(),
      child: const _EquipamentosIotPageView(),
    );
  }
}

class _EquipamentosIotPageView extends StatefulWidget {
  const _EquipamentosIotPageView();

  @override
  State<_EquipamentosIotPageView> createState() =>
      _EquipamentosIotPageViewState();
}

class _EquipamentosIotPageViewState extends State<_EquipamentosIotPageView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EquipamentosIotViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Page Header (fixed)
            _buildHeader(context, viewModel),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.loadData(),
                child: viewModel.isLoading && viewModel.equipamentos.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Filters & Search Card
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: _buildFilterCard(viewModel),
                            ),
                          ),

                          // Error Message Banner
                          if (viewModel.errorMessage != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          viewModel.errorMessage!,
                                          style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 13),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.refresh, size: 20),
                                        onPressed: () => viewModel.loadData(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Items List or Empty State
                          if (viewModel.equipamentos.isEmpty &&
                              !viewModel.isLoading)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            )
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              sliver: SliverList.separated(
                                itemCount: viewModel.equipamentos.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = viewModel.equipamentos[index];
                                  return _buildEquipamentoCard(
                                      item, viewModel);
                                },
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, EquipamentosIotViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 24, color: kPalettePrimaryDark),
            tooltip: 'Voltar ao Início',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 4),
          const Icon(Icons.memory, color: kPaletteDeepBlue, size: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Equipamentos IoT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPalettePrimaryDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPaletteAccentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${viewModel.equipamentos.length} ${viewModel.equipamentos.length == 1 ? 'item' : 'itens'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPaletteDeepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(EquipamentosIotViewModel viewModel) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => viewModel.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar por nome, modelo, IP ou local...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: kPaletteDeepBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: kPaletteAccentBlue, width: 1.5),
                ),
              ),
            ),

            // Client Dropdown (Super Admin only)
            if (viewModel.isSuperAdmin && viewModel.clientes.isNotEmpty) ...[
              const SizedBox(height: 12),
              SearchableDropdown<int?>(
                hint: 'Todos os Clientes',
                value: viewModel.selectedClienteId,
                items: [
                  const SearchableDropdownItem(
                    label: 'Todos os Clientes',
                    value: null,
                  ),
                  ...viewModel.clientes.map((c) => SearchableDropdownItem(
                        label: '${c.id} - ${c.displayName}',
                        value: c.id,
                      )),
                ],
                onChanged: (val) => viewModel.setSelectedCliente(val),
              ),
            ],

            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip(
                      'Todos (${viewModel.totalCount})', 'all', viewModel),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                      'Ativos (${viewModel.activeCount})', 'ativo', viewModel,
                      icon: Icons.check_circle_outline,
                      activeColor: const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                      'Inativos (${viewModel.inactiveCount})', 'inativo', viewModel,
                      icon: Icons.highlight_off,
                      activeColor: const Color(0xFFC62828)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String label, String filterKey, EquipamentosIotViewModel viewModel,
      {IconData? icon, Color? activeColor}) {
    final isSelected = viewModel.selectedFilter == filterKey;
    final primaryColor = activeColor ?? kPaletteDeepBlue;

    return InkWell(
      onTap: () => viewModel.setSelectedFilter(filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (activeColor ?? Colors.grey.shade700),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipamentoCard(
      EquipamentoIot item, EquipamentosIotViewModel viewModel) {
    final solutions = viewModel.getSolucoesLabels(item);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID, Nome, and Status Badge (Ativo / Inativo)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${item.id ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF455A64),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name and Client
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nomeEquipamento,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (viewModel.isSuperAdmin &&
                          (item.nomeCliente?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.business,
                                size: 13, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.nomeCliente!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPalettePrimaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Badge (Ativo / Inativo)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isOnline
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isOnline
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFFFFCDD2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.isOnline ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20, thickness: 0.8),

            // Model & Solutions
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (item.modeloEquipamento != null &&
                    item.modeloEquipamento!.isNotEmpty)
                  _buildTagChip(Icons.devices, item.modeloEquipamento!,
                      const Color(0xFFF1F5F9), const Color(0xFF334155)),
                if (solutions.isNotEmpty)
                  ...solutions.map(
                    (sol) => _buildTagChip(
                        Icons.extension,
                        sol,
                        kPaletteLightBlue.withValues(alpha: 0.2),
                        kPaletteDeepBlue),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Metadata Details (Cadastro)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (item.ipEquipamento != null &&
                      item.ipEquipamento!.trim().isNotEmpty) ...[
                    _buildDetailRow(
                      Icons.wifi,
                      'IP',
                      item.ipEquipamento!,
                    ),
                    const SizedBox(height: 6),
                  ],
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Cadastro',
                    _formatDate(item.dataHora),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botão Acionar Sirene (Bloqueado quando Inativo)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: item.isOnline
                    ? () => _showSireneConfirmationModal(
                        context, item, viewModel)
                    : null,
                icon: Icon(
                  item.isOnline ? Icons.campaign : Icons.campaign_outlined,
                  size: 20,
                ),
                label: Text(
                  item.isOnline
                      ? 'Acionar Sirene'
                      : 'Sirene Indisponível (Inativo)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: item.isOnline ? 2 : 0,
                ),
              ),
            ),

            if (!item.isOnline) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: Colors.orange.shade800),
                  const SizedBox(width: 4),
                  Text(
                    'Equipamento inativo. O envio para sirene está bloqueado.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSireneConfirmationModal(
    BuildContext context,
    EquipamentoIot item,
    EquipamentosIotViewModel viewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SireneConfirmationDialog(
          equipamento: item,
          onConfirm: () {
            viewModel.acionarSirene(id: item.id ?? 0);
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Comando de sirene enviado com sucesso!'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagChip(
      IconData icon, String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: valueColor ?? Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum equipamento encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar seus filtros de busca ou verifique a conexão.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal de confirmação para acionamento da sirene.
/// O botão de confirmar fica desabilitado por 3 segundos como medida de segurança.
class _SireneConfirmationDialog extends StatefulWidget {
  final EquipamentoIot equipamento;
  final VoidCallback onConfirm;

  const _SireneConfirmationDialog({
    required this.equipamento,
    required this.onConfirm,
  });

  @override
  State<_SireneConfirmationDialog> createState() =>
      _SireneConfirmationDialogState();
}

class _SireneConfirmationDialogState extends State<_SireneConfirmationDialog> {
  bool _isButtonEnabled = false;
  int _remainingSeconds = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isButtonEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Acionar Sirene',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja acionar a sirene?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.memory, size: 18, color: Color(0xFF455A64)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipamento.nomeEquipamento,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'ID: #${widget.equipamento.id ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação acionará a sirene do equipamento por 5 segundos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isButtonEnabled ? widget.onConfirm : null,
                icon: Icon(
                  _isButtonEnabled ? Icons.campaign : Icons.hourglass_top,
                  size: 18,
                ),
                label: Text(
                  _isButtonEnabled
                      ? 'Confirmar'
                      : 'Aguarde (${_remainingSeconds}s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled
                      ? const Color(0xFFD32F2F)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: _isButtonEnabled ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
