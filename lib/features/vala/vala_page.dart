import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/vala/vala_viewmodel.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';
import 'package:sensortech/shared/widgets/date_picker_dialog.dart';
import 'package:sensortech/data/services/camera_service.dart';
import 'package:sensortech/shared/widgets/searchable_dropdown.dart';
import 'package:sensortech/features/home/homepage.dart';

class ValaPage extends StatelessWidget {
  const ValaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ValaViewModel(
        ppeService: Provider.of<PpeService>(context, listen: false),
        cameraService: Provider.of<CameraService>(context, listen: false),
        auth: Provider.of<AuthController>(context, listen: false),
      ),
      child: const _ValaView(),
    );
  }
}

class _ValaView extends StatelessWidget {
  const _ValaView();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ValaViewModel>(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                _buildHeader(context),

                // Scrollable content (filters, top pagination, events, bottom pagination)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        viewModel.loadEvents(page: viewModel.currentPage),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Filter controls
                        SliverToBoxAdapter(
                          child: _buildFilterBar(context, viewModel),
                        ),

                        // Error state (if error and no events)
                        if (viewModel.errorMessage != null &&
                            viewModel.events.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildErrorState(viewModel),
                          ),

                        // Loading state
                        if (viewModel.isLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 60.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),

                        // Empty state (if not loading and no events)
                        if (!viewModel.isLoading &&
                            viewModel.errorMessage == null &&
                            viewModel.events.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyState(viewModel),
                          ),

                        // Top Pagination
                        if (!viewModel.isLoading &&
                            (viewModel.events.isNotEmpty ||
                                viewModel.currentPage > 1))
                          SliverToBoxAdapter(
                            child: _buildPagination(viewModel),
                          ),

                        // Lazy-loaded Events List
                        if (!viewModel.isLoading && viewModel.events.isNotEmpty)
                          SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            sliver: SliverList.separated(
                              itemCount: viewModel.events.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final event = viewModel.events[index];
                                return _buildEventCard(
                                    context, viewModel, event, index);
                              },
                            ),
                          ),

                        // Bottom Pagination
                        if (!viewModel.isLoading &&
                            (viewModel.events.isNotEmpty ||
                                viewModel.currentPage > 1))
                          SliverToBoxAdapter(
                            child: _buildPagination(viewModel),
                          ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Toast feedback overlay for general messages
            if (viewModel.successMessage != null && viewModel.selectedEvent == null)
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kPaletteDeepBlue.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    viewModel.successMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Fullscreen Modal for selected event
            if (viewModel.selectedEvent != null)
              _buildFullScreenModal(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          const SizedBox(width: 4),
          const Icon(
            Icons.landscape,
            color: kPalettePrimaryDark,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Detecção de Valas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPalettePrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ValaViewModel viewModel) {
    final fmt = DateFormat('dd/MM/yyyy');
    final startDateStr = viewModel.selectedStartDate != null
        ? fmt.format(viewModel.selectedStartDate!)
        : 'Início';
    final endDateStr = viewModel.selectedEndDate != null
        ? fmt.format(viewModel.selectedEndDate!)
        : 'Fim';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Row 1: Date Range
          Row(
            children: [
              const Icon(Icons.calendar_month,
                  size: 22, color: kPalettePrimaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final range = await DatePickerCalendarDialog.showRange(
                      context: context,
                      title: 'Selecione o Período',
                      initialStart: viewModel.selectedStartDate,
                      initialEnd: viewModel.selectedEndDate,
                    );
                    if (range != null) {
                      viewModel.setDateRange(range.start, range.end);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPaletteLightGray),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$startDateStr - $endDateStr',
                            style: const TextStyle(
                                fontSize: 13.5, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: kPalettePrimaryDark,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Camera Filter
          Row(
            children: [
              const Icon(Icons.videocam,
                  size: 22, color: kPalettePrimaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: SearchableDropdown<int?>(
                  hint: viewModel.getCameraHintText(),
                  value: viewModel.selectedCameraId,
                  items: [
                    const SearchableDropdownItem(
                      value: null,
                      label: 'Todas as Câmeras',
                    ),
                    ...viewModel.cameras.map((c) => SearchableDropdownItem(
                          value: c.displayId,
                          label: '${c.displayId} - ${c.nomeCamera}',
                        )),
                  ],
                  onChanged: viewModel.isLoadingCameras
                      ? null
                      : viewModel.setSelectedCamera,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Vala / Escora Filter
          Row(
            children: [
              const Icon(Icons.landscape,
                  size: 22, color: kPalettePrimaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: SearchableDropdown<String?>(
                  hint: 'Tipo de Detecção',
                  value: viewModel.selectedEpi,
                  items: const [
                    SearchableDropdownItem(
                        value: 'presenca_vala', label: 'Presença de Vala'),
                    SearchableDropdownItem(
                        value: 'presenca_escora', label: 'Presença de Escora'),
                    SearchableDropdownItem(
                        value: 'todas', label: 'Todas (Vala e Escora)'),
                  ],
                  onChanged: (val) => viewModel.setEpiFilter(val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: viewModel.isLoading
                  ? null
                  : () => viewModel.loadEvents(page: 1),
              icon: Icon(
                viewModel.isLoading ? Icons.hourglass_empty : Icons.search,
                size: 18,
              ),
              label: Text(
                viewModel.isLoading ? 'Buscando...' : 'Buscar',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: kBrandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ValaViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  viewModel.loadEvents(page: viewModel.currentPage),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ValaViewModel viewModel) {
    if (viewModel.currentPage > 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64,
                  color: kPalettePrimaryDark.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              const Text(
                'Fim dos resultados',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Não há detecções adicionais na página ${viewModel.currentPage}.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    viewModel.loadEvents(page: viewModel.currentPage - 1),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar para página anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPaletteDeepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhuma detecção de vala encontrada',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste o período ou os filtros de busca.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ValaViewModel viewModel) {
    final visiblePages = viewModel.getVisiblePages();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page chevron
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, color: kPalettePrimaryDark),
              onPressed: viewModel.currentPage > 1 && !viewModel.isLoading
                  ? () => viewModel.goToPage(viewModel.currentPage - 1)
                  : null,
            ),
          ),
          const SizedBox(width: 4),

          // Number buttons
          ...visiblePages.map((page) {
            final isSelected = viewModel.currentPage == page;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: isSelected || viewModel.isLoading
                    ? null
                    : () => viewModel.goToPage(page),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 34),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF089bfe)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$page',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 4),
          // Next page chevron
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_right, color: kPalettePrimaryDark),
              onPressed: viewModel.hasNextPage && !viewModel.isLoading
                  ? () => viewModel.goToPage(viewModel.currentPage + 1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getValaLabel(PpeEvent event) {
    if (event.missingPpe.any((e) => e.contains('escora'))) {
      return 'Presença de Escora';
    }
    if (event.missingPpe.any((e) => e.contains('vala'))) {
      return 'Presença de Vala';
    }
    return event.translatedMissingPpe.isNotEmpty
        ? event.translatedMissingPpe
        : 'Presença de Vala';
  }

  Widget _buildEventCard(
    BuildContext context,
    ValaViewModel viewModel,
    PpeEvent event,
    int index,
  ) {
    final imageUrl = viewModel.getEventImageUrl(event);
    final token = viewModel.token ?? '';
    final valaLabel = _getValaLabel(event);

    return Card(
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => viewModel.selectEvent(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with camera and status badge overlay
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
                    cacheWidth: 600,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        ),
                      );
                    },
                  ),
                  // Status Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPaletteDeepBlue,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        valaLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Camera ID Badge
                  if (event.cameraId != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Câm. ${event.cameraId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Information Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.landscape, size: 18, color: kPalettePrimaryDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          valaLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.displayDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenModal(BuildContext context, ValaViewModel viewModel) {
    final event = viewModel.selectedEvent!;
    final imageUrl = viewModel.getSelectedImageUrl();
    final token = viewModel.token ?? '';

    return Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: Stack(
        children: [
          // PhotoView zoomable image
          Center(
            child: PhotoView(
              imageProvider: NetworkImage(
                imageUrl,
                headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white70, size: 64),
                    SizedBox(height: 8),
                    Text('Erro ao carregar imagem', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: viewModel.closeModal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.translatedMissingPpe.isNotEmpty
                              ? event.translatedMissingPpe
                              : 'Detecção de Vala',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event.displayDate,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Download button
                  IconButton(
                    icon: viewModel.isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, color: Colors.white),
                    tooltip: 'Baixar imagem',
                    onPressed: viewModel.isDownloading
                        ? null
                        : () => viewModel.downloadCurrentImage(),
                  ),
                ],
              ),
            ),
          ),

          // Navigation buttons (prev/next)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                onPressed: viewModel.selectedIndex! > 0 ? viewModel.previousImage : null,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                onPressed: viewModel.selectedIndex! < viewModel.events.length - 1
                    ? viewModel.nextImage
                    : null,
              ),
            ),
          ),

          // Toast feedback overlay
          if (viewModel.successMessage != null || viewModel.errorMessage != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: viewModel.successMessage != null
                      ? Colors.green.shade800.withValues(alpha: 0.9)
                      : Colors.red.shade800.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  viewModel.successMessage ?? viewModel.errorMessage ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
