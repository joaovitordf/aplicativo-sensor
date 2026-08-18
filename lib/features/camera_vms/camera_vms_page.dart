import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:sensortech/core/app_config.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/data/models/camera_model.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';
import 'package:sensortech/shared/widgets/full_screen_player.dart';
import 'package:sensortech/shared/widgets/date_picker_dialog.dart';
import 'package:sensortech/features/camera_vms/camera_vms_viewmodel.dart';
import 'package:sensortech/data/services/vms_service.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';

/// Player screen for a specific camera.
/// Receives a pre-selected [Recording] from the Grade screen.
class CameraVmsPage extends StatelessWidget {
  final Recording recording;

  const CameraVmsPage({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraVmsViewModel(
        vmsService: Provider.of<VmsService>(context, listen: false),
        equipamentoService:
            Provider.of<EquipamentoIotService>(context, listen: false),
      )..loadForRecording(recording),
      child: const _CameraVmsPageView(),
    );
  }
}

class _CameraVmsPageView extends StatelessWidget {
  const _CameraVmsPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CameraVmsViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, viewModel),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildContent(context, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CameraVmsViewModel viewModel) {
    final cameraName = viewModel.selectedRecording?.cameraInfo?.nomeCamera ??
        viewModel.selectedRecording?.name ??
        'Câmera VMS';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBrandBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: kBrandBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    cameraName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kBrandBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CameraVmsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.dataError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(viewModel.dataError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (viewModel.selectedRecording != null) {
                    viewModel.loadForRecording(viewModel.selectedRecording!);
                  }
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.selectedRecording == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nenhuma câmera selecionada'),
        ),
      );
    }

    final isVideoInitialized = viewModel.videoController != null &&
        viewModel.videoController!.value.isInitialized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra de Status (Câmera & Equipamento IoT)
        _buildStatusRow(context, viewModel),

        const SizedBox(height: 6),

        // 2. Video Player Container
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 232),
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: _buildVideoOrPlaceholder(viewModel),
            ),
          ),
        ),

        // 3. Video Controls Bar (Sempre visível abaixo do player)
        _buildVideoControlsBar(context, viewModel, isVideoInitialized),

        // 4. Botão Acionar Sirene (Abaixo das opções do player e acima do texto de gravações)
        _buildSireneSection(context, viewModel),

        // 5. Cabeçalho de Seleção de Data de Gravações
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gravações de ${DateFormat('dd/MM/yyyy').format(viewModel.selectedDate)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: kBrandBlue),
                tooltip: 'Selecionar data',
                onPressed: () async {
                  final picked = await DatePickerCalendarDialog.showSingle(
                    context: context,
                    title: 'Selecionar Data',
                    initialDate: viewModel.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    viewModel.selectDate(picked);
                  }
                },
              ),
            ],
          ),
        ),

        // 6. Lista de Segmentos Gravados
        _buildSegmentsList(context, viewModel),
      ],
    );
  }

  /// Barra de status com indicadores em tempo real para a Câmera e o Equipamento IoT vinculado
  Widget _buildStatusRow(BuildContext context, CameraVmsViewModel viewModel) {
    final camera = viewModel.selectedRecording?.cameraInfo;
    final idRasp = camera?.idRasp;
    final hasRasp = idRasp != null && idRasp > 0;

    final isVideoInitialized = viewModel.videoController != null &&
        viewModel.videoController!.value.isInitialized;
    final isLive = viewModel.currentSegmentIndex == -1;
    final isPlayingSegment = !isLive && isVideoInitialized;
    final isCameraOffline = viewModel.playerError != null;

    // Status da Câmera
    String cameraStatusText;
    Color cameraStatusBg;
    Color cameraStatusColor;
    IconData cameraStatusIcon;

    if (isPlayingSegment) {
      cameraStatusText = 'Câmera: Gravação';
      cameraStatusBg = const Color(0xFFE0F2FE);
      cameraStatusColor = const Color(0xFF0284C7);
      cameraStatusIcon = Icons.movie_outlined;
    } else if (isVideoInitialized) {
      cameraStatusText = 'Câmera: Ao Vivo';
      cameraStatusBg = const Color(0xFFDCFCE7);
      cameraStatusColor = const Color(0xFF16A34A);
      cameraStatusIcon = Icons.videocam;
    } else if (isCameraOffline) {
      cameraStatusText = 'Câmera: Offline';
      cameraStatusBg = const Color(0xFFFEE2E2);
      cameraStatusColor = const Color(0xFFDC2626);
      cameraStatusIcon = Icons.videocam_off;
    } else {
      cameraStatusText = 'Câmera: Conectando';
      cameraStatusBg = const Color(0xFFF3F4F6);
      cameraStatusColor = const Color(0xFF4B5563);
      cameraStatusIcon = Icons.sync;
    }

    final cameraBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cameraStatusBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cameraStatusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(cameraStatusIcon, size: 14, color: cameraStatusColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              cameraStatusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cameraStatusColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Se a câmera NÃO tem vínculo IoT (idRasp), exibe apenas o status da Câmera
    if (!hasRasp) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        child: cameraBadge,
      );
    }

    // Status do Equipamento IoT (quando a câmera possui idRasp)
    String iotStatusText;
    Color iotStatusBg;
    Color iotStatusColor;
    IconData iotStatusIcon;

    if (viewModel.isIotLoading) {
      iotStatusText = 'IoT (#$idRasp): Checando...';
      iotStatusBg = const Color(0xFFF3F4F6);
      iotStatusColor = const Color(0xFF4B5563);
      iotStatusIcon = Icons.sync;
    } else if (viewModel.linkedIotEquipamento != null) {
      final eq = viewModel.linkedIotEquipamento!;
      final isOnline = eq.isOnline; // statusMqtt == 1
      final isAtivo = eq.isAtivo;   // enabled == 1

      if (!isAtivo) {
        iotStatusText = 'IoT (#$idRasp): Inativo';
        iotStatusBg = const Color(0xFFFEE2E2);
        iotStatusColor = const Color(0xFFDC2626);
        iotStatusIcon = Icons.power_settings_new;
      } else if (isOnline) {
        iotStatusText = 'IoT (#$idRasp): Online';
        iotStatusBg = const Color(0xFFDCFCE7);
        iotStatusColor = const Color(0xFF16A34A);
        iotStatusIcon = Icons.wifi;
      } else {
        iotStatusText = 'IoT (#$idRasp): Offline';
        iotStatusBg = const Color(0xFFFEF3C7);
        iotStatusColor = const Color(0xFFD97706);
        iotStatusIcon = Icons.wifi_off;
      }
    } else {
      iotStatusText = 'IoT (#$idRasp): Não listado';
      iotStatusBg = const Color(0xFFF1F5F9);
      iotStatusColor = const Color(0xFF64748B);
      iotStatusIcon = Icons.memory;
    }

    final iotBadge = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => viewModel.refreshIotStatus(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: iotStatusBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: iotStatusColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iotStatusIcon, size: 14, color: iotStatusColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                iotStatusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iotStatusColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.refresh, size: 12, color: iotStatusColor),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        children: [
          Expanded(child: cameraBadge),
          const SizedBox(width: 8),
          Expanded(child: iotBadge),
        ],
      ),
    );
  }

  /// Barra de controle do player (Ao Vivo, Anterior, Play/Pause, Próximo, Velocidade, Fullscreen).
  /// Permanece sempre visível para uma experiência consistente.
  Widget _buildVideoControlsBar(
    BuildContext context,
    CameraVmsViewModel viewModel,
    bool isVideoInitialized,
  ) {
    final isLive = viewModel.currentSegmentIndex == -1;
    final hasPrev = viewModel.currentSegmentIndex > 0;
    final hasNext = viewModel.currentSegmentIndex >= 0 &&
        viewModel.currentSegmentIndex <
            viewModel.segmentsForSelectedDate.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      color: Colors.grey[200],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão Ao Vivo
              IconButton(
                icon: Icon(
                  Icons.fiber_manual_record,
                  color: isLive ? Colors.red : Colors.grey.shade600,
                  size: 22,
                ),
                onPressed: () {
                  if (viewModel.selectedRecording != null) {
                    viewModel.selectRecordingDirectly(
                        viewModel.selectedRecording!);
                  }
                },
                tooltip: isLive ? 'Ao Vivo' : 'Voltar ao vivo',
              ),

              // Botão Gravação Anterior
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: hasPrev ? viewModel.previousSegment : null,
                tooltip: 'Gravação anterior',
              ),

              // Botão Play / Pause
              IconButton(
                icon: Icon(
                  viewModel.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                iconSize: 36,
                color: isVideoInitialized ? kBrandBlue : Colors.grey.shade600,
                onPressed: isVideoInitialized ? viewModel.togglePlayPause : null,
                tooltip: viewModel.isPlaying ? 'Pausar' : 'Reproduzir',
              ),

              // Botão Próxima Gravação
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: hasNext ? viewModel.nextSegment : null,
                tooltip: 'Próxima gravação',
              ),

              // Dropdown de Velocidade (ativo em gravações)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: DropdownButton<double>(
                  value: viewModel.playbackSpeed,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                    DropdownMenuItem(value: 1.0, child: Text('1x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2.0, child: Text('2x')),
                  ],
                  underline: const SizedBox.shrink(),
                  onChanged: (isVideoInitialized && !isLive)
                      ? (value) {
                          if (value != null) {
                            viewModel.changePlaybackSpeed(value);
                          }
                        }
                      : null,
                ),
              ),

              // Botão Tela Cheia
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: isVideoInitialized
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenVideoPlayer(
                              controller: viewModel.videoController!,
                            ),
                          ),
                        );
                      }
                    : null,
                tooltip: 'Tela Cheia',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão de acionamento de sirene vinculado ao idRasp da câmera.
  /// Só aparece se a câmera tiver um idRasp válido (equipamento IoT vinculado).
  Widget _buildSireneSection(
    BuildContext context,
    CameraVmsViewModel viewModel,
  ) {
    final camera = viewModel.selectedRecording?.cameraInfo;
    final idRasp = camera?.idRasp;
    final hasRasp = idRasp != null && idRasp > 0;
    if (!hasRasp) {
      return const SizedBox.shrink();
    }

    final linkedIot = viewModel.linkedIotEquipamento;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showSireneCameraModal(context, camera!, linkedIot, viewModel),
          icon: const Icon(
            Icons.campaign,
            size: 20,
          ),
          label: const Text(
            'Acionar Sirene',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  void _showSireneCameraModal(
    BuildContext context,
    Camera camera,
    EquipamentoIot? linkedIot,
    CameraVmsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SireneCameraConfirmationDialog(
          camera: camera,
          linkedIot: linkedIot,
          onConfirm: () async {
            Navigator.of(dialogContext).pop();

            final idRasp = camera.idRasp;
            if (idRasp == null || idRasp <= 0) return;

            try {
              final iotUrl = AppConfig.iotApiUrl;
              debugPrint(
                '[Sirene Câmera VMS] Enviando requisição para o backend: '
                'POST $iotUrl/api/v1/equipamentosiot/timer '
                'Payload: {"id": $idRasp, "seconds": 5} | '
                'Câmera: "${camera.nomeCamera}" (camera_id: ${camera.displayId}, idRasp: $idRasp)',
              );

              await viewModel.acionarSirene(id: idRasp, seconds: 5);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comando de sirene enviado com sucesso! (idRasp: $idRasp)',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Erro ao acionar sirene: $e',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildVideoOrPlaceholder(CameraVmsViewModel viewModel) {
    if (viewModel.videoController != null &&
        viewModel.videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: viewModel.videoController!.value.aspectRatio,
        child: VideoPlayer(viewModel.videoController!),
      );
    }

    if (viewModel.currentSegmentIndex == -1 &&
        viewModel.selectedRecording != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (viewModel.playerError != null) ...[
            const Icon(Icons.signal_wifi_off, size: 54, color: Colors.redAccent),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                viewModel.playerError!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            if (viewModel.playerError!.contains('ao vivo'))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'A câmera pode estar offline ou com problemas de conexão. '
                  'Tente novamente ou selecione uma gravação abaixo.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ] else ...[
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'Carregando transmissão ao vivo...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.play_circle_outline, size: 54, color: Colors.white54),
        SizedBox(height: 8),
        Text(
          'Selecione uma gravação para reproduzir',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSegmentsList(
    BuildContext context,
    CameraVmsViewModel viewModel,
  ) {
    if (viewModel.segmentsForSelectedDate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Nenhuma gravação encontrada para ${DateFormat('dd/MM/yyyy').format(viewModel.selectedDate)}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Segmentos disponíveis (${viewModel.segmentsForSelectedDate.length}):',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: viewModel.segmentsForSelectedDate.length,
          itemBuilder: (context, index) {
            final segment = viewModel.segmentsForSelectedDate[index];
            final isActive = viewModel.currentSegmentIndex == index;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              elevation: isActive ? 1 : 0,
              color: isActive ? kBrandBlueLight : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: isActive ? kBrandBlue : Colors.grey.shade300,
                  width: isActive ? 2.0 : 1.0,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  isActive
                      ? Icons.play_circle_filled
                      : Icons.play_circle_outline,
                  color: isActive ? kBrandBlue : Colors.grey,
                  size: 32,
                ),
                title: Text(
                  segment.timeString,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? kPaletteDeepBlue : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(segment.start),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.graphic_eq, color: kBrandBlue)
                    : null,
                onTap: () => viewModel.playSegment(index),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Modal de confirmação para acionamento da sirene a partir da tela de Câmera VMS.
/// O botão de confirmar fica desabilitado por 3 segundos como medida de segurança.
class _SireneCameraConfirmationDialog extends StatefulWidget {
  final Camera camera;
  final EquipamentoIot? linkedIot;
  final VoidCallback onConfirm;

  const _SireneCameraConfirmationDialog({
    required this.camera,
    this.linkedIot,
    required this.onConfirm,
  });

  @override
  State<_SireneCameraConfirmationDialog> createState() =>
      _SireneCameraConfirmationDialogState();
}

class _SireneCameraConfirmationDialogState
    extends State<_SireneCameraConfirmationDialog> {
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
    final camera = widget.camera;
    final iot = widget.linkedIot;

    final isIotOnline = iot?.isOnline ?? false;
    final isIotAtivo = iot?.isAtivo ?? false;

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
              'Tem certeza que deseja acionar a sirene vinculada a esta câmera?',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam, size: 18, color: kPalettePrimaryDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          camera.nomeCamera.isNotEmpty ? camera.nomeCamera : 'Câmera #${camera.displayId}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.memory, size: 16, color: Color(0xFF455A64)),
                      const SizedBox(width: 8),
                      Text(
                        'Vínculo IoT (idRasp): ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        '#${camera.idRasp ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kPaletteDeepBlue,
                        ),
                      ),
                    ],
                  ),
                  if (iot != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isIotOnline ? Icons.wifi : Icons.wifi_off,
                          size: 16,
                          color: isIotOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status MQTT: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        Text(
                          isIotOnline ? 'Online (Conectado)' : 'Offline (Desconectado)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isIotOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isIotAtivo ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 16,
                          color: isIotAtivo ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Equipamento: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        Text(
                          isIotAtivo ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isIotAtivo ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                      'Esta ação enviará o comando de acionamento para o equipamento IoT associado.',
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
