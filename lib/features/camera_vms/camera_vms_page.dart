import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/shared/widgets/full_screen_player.dart';
import 'package:sensortech/shared/widgets/date_picker_dialog.dart';
import 'package:sensortech/features/camera_vms/camera_vms_viewmodel.dart';
import 'package:sensortech/data/services/vms_service.dart';

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
      )..loadForRecording(recording),
      child: const _CameraVmsPageView(),
    );
  }
}

class _CameraVmsPageView extends StatelessWidget {
  const _CameraVmsPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            final viewModel = context.watch<CameraVmsViewModel>();

            if (isLandscape) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, viewModel),
                    const SizedBox(height: 8),
                    _buildContent(context, viewModel, isScrollable: true),
                  ],
                ),
              );
            } else {
              return Column(
                children: [
                  _buildHeader(context, viewModel),
                  const SizedBox(height: 8),
                  Expanded(
                      child: _buildContent(context, viewModel,
                          isScrollable: false)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CameraVmsViewModel viewModel) {
    final cameraName = viewModel.selectedRecording?.cameraInfo?.nomeCamera ??
        viewModel.selectedRecording?.name ??
        'Câmera VMS';

    return Padding(
      padding: const EdgeInsets.all(8.0),
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

  Widget _buildContent(BuildContext context, CameraVmsViewModel viewModel,
      {required bool isScrollable}) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.dataError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(viewModel.dataError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
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
      );
    }

    if (viewModel.selectedRecording == null) {
      return const Center(child: Text('Nenhuma câmera selecionada'));
    }

    return Column(
      children: [
        const SizedBox(height: 8),

        // Video player / Placeholder
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

        // Video controls
        if (viewModel.videoController != null &&
            viewModel.videoController!.value.isInitialized)
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Live button
                    IconButton(
                      icon: Icon(Icons.fiber_manual_record,
                          color: viewModel.currentSegmentIndex == -1
                              ? Colors.red
                              : Colors.grey),
                      onPressed: viewModel.currentSegmentIndex == -1
                          ? null
                          : () {
                              if (viewModel.selectedRecording != null) {
                                viewModel.selectRecordingDirectly(
                                    viewModel.selectedRecording!);
                              }
                            },
                      tooltip: viewModel.currentSegmentIndex == -1
                          ? 'Ao Vivo'
                          : 'Voltar ao vivo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: viewModel.currentSegmentIndex > 0
                          ? viewModel.previousSegment
                          : null,
                      tooltip: 'Segmento anterior',
                    ),
                    IconButton(
                      icon: Icon(viewModel.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                      iconSize: 36,
                      onPressed: viewModel.togglePlayPause,
                      tooltip:
                          viewModel.isPlaying ? 'Pausar' : 'Reproduzir',
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: viewModel.currentSegmentIndex <
                              viewModel.segmentsForSelectedDate.length - 1
                          ? viewModel.nextSegment
                          : null,
                      tooltip: 'Próximo segmento',
                    ),
                    if (viewModel.currentSegmentIndex != -1)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 72),
                        child: DropdownButton<double>(
                          value: viewModel.playbackSpeed,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 0.5, child: Text('0.5x')),
                            DropdownMenuItem(
                                value: 1.0, child: Text('1x')),
                            DropdownMenuItem(
                                value: 1.5, child: Text('1.5x')),
                            DropdownMenuItem(
                                value: 2.0, child: Text('2x')),
                          ],
                          underline: Container(),
                          onChanged: (value) {
                            if (value != null) {
                              viewModel.changePlaybackSpeed(value);
                            }
                          },
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () {
                        if (viewModel.videoController != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenVideoPlayer(
                                  controller: viewModel.videoController!),
                            ),
                          );
                        }
                      },
                      tooltip: 'Tela Cheia',
                    ),
                  ],
                ),
              ],
            ),
          ),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gravações de ${DateFormat('dd/MM/yyyy').format(viewModel.selectedDate)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: kBrandBlue),
                tooltip: 'Calendário',
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

        // Segments list
        isScrollable
            ? _buildSegmentsList(context, viewModel, isScrollable: true)
            : Expanded(
                child: _buildSegmentsList(context, viewModel,
                    isScrollable: false)),
      ],
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
            const Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                viewModel.playerError!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
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
        Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
        SizedBox(height: 8),
        Text(
          'Selecione um segmento para reproduzir',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSegmentsList(
      BuildContext context, CameraVmsViewModel viewModel,
      {required bool isScrollable}) {
    if (viewModel.segmentsForSelectedDate.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Nenhuma gravação disponível para esta data',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final list = ListView.builder(
      itemCount: viewModel.segmentsForSelectedDate.length,
      shrinkWrap: isScrollable,
      physics: isScrollable
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final segment = viewModel.segmentsForSelectedDate[index];
        final isActive = index == viewModel.currentSegmentIndex;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isActive ? Colors.blue[50] : null,
          child: ListTile(
            leading: Icon(
              isActive
                  ? Icons.play_circle_filled
                  : Icons.play_circle_outline,
              color: isActive ? Colors.blue : Colors.grey,
              size: 32,
            ),
            title: Text(
              DateFormat('HH:mm:ss').format(segment.start),
              style: TextStyle(
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(segment.start),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isActive
                ? const Icon(Icons.graphic_eq, color: Colors.blue)
                : null,
            selected: isActive,
            onTap: () => viewModel.playSegment(index),
          ),
        );
      },
    );

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
        isScrollable ? list : Expanded(child: list),
      ],
    );
  }
}
