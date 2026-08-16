import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';
import 'package:sensortech/features/home/homepage.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/data/services/camera_service.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/features/camera_vms/camera_vms_grade_viewmodel.dart';
import 'package:sensortech/features/camera_vms/camera_vms_page.dart';

/// Grade (grid listing) screen for Câmera VMS.
/// Shows all available cameras as cards, with search filter.
/// Tapping a card navigates to the player screen for that specific camera.
class CameraVmsGradePage extends StatelessWidget {
  const CameraVmsGradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraVmsGradeViewModel(
        auth: Provider.of<AuthController>(context, listen: false),
        cameraService: Provider.of<CameraService>(context, listen: false),
      )..loadData(),
      child: const _CameraVmsGradeView(),
    );
  }
}

class _CameraVmsGradeView extends StatelessWidget {
  const _CameraVmsGradeView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CameraVmsGradeViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildSearchBar(context, viewModel),
                          _buildCameraCount(viewModel),
                        ],
                      ),
                    ),
                  ];
                },
                body: _buildContent(context, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
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
                const Flexible(
                  child: Text(
                    'Câmera VMS',
                    style: TextStyle(
                      fontSize: 22,
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

  // ─── Search bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(
      BuildContext context, CameraVmsGradeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar câmera...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: viewModel.onSearchChange,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Camera count ─────────────────────────────────────────────────────────
  Widget _buildCameraCount(CameraVmsGradeViewModel viewModel) {
    if (viewModel.isLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${viewModel.filteredRecordings.length} Câmera(s)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────
  Widget _buildContent(
      BuildContext context, CameraVmsGradeViewModel viewModel) {
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
              onPressed: viewModel.loadData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (viewModel.filteredRecordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma câmera encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: viewModel.filteredRecordings.length,
      itemBuilder: (context, index) {
        final recording = viewModel.filteredRecordings[index];
        return _CameraCard(
          recording: recording,
          viewModel: viewModel,
          onTap: () => _openPlayer(context, recording),
        );
      },
    );
  }

  Future<void> _openPlayer(BuildContext context, Recording recording) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraVmsPage(recording: recording),
      ),
    );
    // Refresh thumbnails when returning from the player
    if (context.mounted) {
      context.read<CameraVmsGradeViewModel>().refreshThumbnails();
    }
  }
}

// ─── Camera card widget ─────────────────────────────────────────────────────
class _CameraCard extends StatelessWidget {
  final Recording recording;
  final CameraVmsGradeViewModel viewModel;
  final VoidCallback onTap;

  const _CameraCard({
    required this.recording,
    required this.viewModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final camera = recording.cameraInfo;
    final cameraName = camera?.nomeCamera ?? recording.name;
    final cameraId =
        camera?.id.toString() ?? recording.name.split('/').last;

    final thumbPath = viewModel.thumbnails[cameraId];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Thumbnail placeholder / Camera icon
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: thumbPath != null
                      ? DecorationImage(
                          image: FileImage(File(thumbPath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (thumbPath == null)
                      const Center(
                        child: Icon(Icons.videocam,
                            size: 28, color: Colors.grey),
                      ),
                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Camera info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Camera name
                    Text(
                      cameraName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 4),

                    // Badges row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Connection type badge
                        if (camera != null &&
                            viewModel
                                .formatarTipoConexao(camera)
                                .isNotEmpty)
                          _Badge(
                            text: viewModel.formatarTipoConexao(camera),
                            color: Colors.white,
                            bgColor: const Color(0xFF198754),
                          ),

                        // REC badge
                        if (camera?.gravar == 1)
                          const _Badge(
                            text: 'REC',
                            color: Colors.white,
                            bgColor: Color(0xFFDC3545),
                            icon: Icons.fiber_manual_record,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badge widget ───────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;
  final IconData? icon;

  const _Badge({
    required this.text,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
