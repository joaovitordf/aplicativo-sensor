import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/features/auth/auth_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;

  const CustomAppBar({super.key, this.titleText});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPaletteDeepBlue,
      elevation: 0,
      leadingWidth: 60,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, size: 32, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: titleText != null
          ? Text(
              titleText!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : Consumer<AuthController>(
              builder: (context, auth, child) {
                final clientName = auth.clientName;
                return Row(
                  children: [
                    Image.asset(
                      logoMini,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, color: Colors.white, size: 28),
                    ),
                    if (clientName.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
      actions: const [
        // Comentado conforme solicitado:
        // Consumer<NotificationController>(
        //   builder: (context, notificationController, child) {
        //     final unreadCount = notificationController.unreadCount;
        //     return IconButton(
        //       icon: Badge(
        //         isLabelVisible: unreadCount > 0,
        //         label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
        //         child: const Icon(Icons.notifications_none,
        //             size: 30, color: Colors.white),
        //       ),
        //       onPressed: () {
        //         notificationController.markAsRead();
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //               builder: (context) => const NotificationsScreen()),
        //         );
        //       },
        //     );
        //   },
        // ),
        SizedBox(width: 8),
      ],
    );
  }
}
