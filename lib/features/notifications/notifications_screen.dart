import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/notifications/notification_controller.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleText: 'Notificações'),
      drawer: const AppDrawer(),
      body: Consumer2<NotificationController, AuthController>(
        builder: (context, notificationController, authController, child) {
          final notifications = notificationController.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum alerta recente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Novos eventos de EPI aparecerão aqui.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationItemCard(
                event: item,
                authController: authController,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItemCard extends StatelessWidget {
  final PpeEvent event;
  final AuthController authController;

  const _NotificationItemCard({
    required this.event,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    final ppeService = Provider.of<PpeService>(context, listen: false);
    final clientId = authController.clientId ?? 0;
    final token = authController.token ?? '';
    final imageUrl = ppeService.buildImageUrl(event.id, clientId);

    return InkWell(
      onTap: () {
        _showImageModal(context, event, imageUrl, token);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Image.network(
                  imageUrl,
                  headers: token.isNotEmpty
                      ? {'Authorization': 'Bearer $token'}
                      : null,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        size: 24, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.isNonCompliant
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.isNonCompliant ? 'ALERTA' : 'CONFORME',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (event.cameraId != null)
                        Text(
                          'Câmera ${event.cameraId}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.translatedMissingPpe,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.displayDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showImageModal(
    BuildContext context,
    PpeEvent event,
    String imageUrl,
    String token,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.black,
                title: Text(
                  event.translatedMissingPpe,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: Image.network(
                  imageUrl,
                  headers: token.isNotEmpty
                      ? {'Authorization': 'Bearer $token'}
                      : null,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Erro ao carregar imagem',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  event.displayDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
