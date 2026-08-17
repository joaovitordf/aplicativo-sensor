import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/core/auth_extensions.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/auth/login_page.dart';
import 'package:sensortech/features/home/homepage.dart';
import 'package:sensortech/features/alertas/alertas_page.dart';
import 'package:sensortech/features/vala/vala_page.dart';
import 'package:sensortech/features/camera_vms/camera_vms_grade_page.dart';
import 'package:sensortech/features/equipamentos_iot/equipamentos_iot_page.dart';
// import 'package:sensortech/features/notifications/notifications_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            final displayName = authController.displayName;
            final clientName = authController.clientName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do Drawer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Logo da empresa centralizada no topo
                      Center(
                        child: Image.asset(
                          logoSensor,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.shield,
                                  size: 36, color: kPaletteDeepBlue),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 2. Avatar fictício com Nome e Empresa ao lado
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: kPaletteDeepBlue.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.person,
                              size: 26,
                              color: kPaletteDeepBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isNotEmpty ? displayName : 'Usuário',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  clientName.isNotEmpty ? clientName : 'Empresa',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Lista de opções
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8.0),
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.home, color: kPaletteDeepBlue),
                        title: const Text('Início'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        },
                      ),
                      if (authController.hasVms)
                        ListTile(
                          leading: const Icon(Icons.videocam,
                              color: kPaletteDeepBlue),
                          title: const Text('Câmera VMS'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CameraVmsGradePage()),
                            );
                          },
                        ),
                      if (authController.hasCentralAlertas)
                        ListTile(
                          leading: const Icon(Icons.notifications_active,
                              color: kPaletteDeepBlue),
                          title: const Text('Central de Alertas'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AlertaPage()),
                            );
                          },
                        ),
                      if (authController.hasSaneamento)
                        ListTile(
                          leading: const Icon(Icons.landscape,
                              color: kPaletteDeepBlue),
                          title: const Text('Detecção de Valas'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ValaPage()),
                            );
                          },
                        ),
                      if (authController.hasEquipamentosIot)
                        ListTile(
                          leading: const Icon(Icons.memory,
                              color: kPaletteDeepBlue),
                          title: const Text('Equipamentos IoT'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EquipamentosIotPage()),
                            );
                          },
                        ),
                      // Comentado conforme solicitado:
                      // ListTile(
                      //   leading: const Icon(Icons.notifications,
                      //       color: kPaletteDeepBlue),
                      //   title: const Text('Notificações'),
                      //   onTap: () {
                      //     Navigator.pop(context);
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //           builder: (context) =>
                      //               const NotificationsScreen()),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Botão de Deslogar
                ListTile(
                  leading:
                      const Icon(Icons.exit_to_app, color: kPaletteDeepBlue),
                  title:
                      const Text('Deslogar', style: TextStyle(fontSize: 16)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          title: const Text('Confirmar logout'),
                          content: const Text('Deseja realmente deslogar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Não'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sim'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true && context.mounted) {
                      await authController.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
