import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/core/auth_extensions.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/alertas/alertas_page.dart';
import 'package:sensortech/features/vala/vala_page.dart';
// import 'package:sensortech/features/notifications/notifications_screen.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<AuthController>(
                builder: (context, auth, child) {
                  return Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Módulos Disponíveis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kPalettePrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (auth.hasCentralAlertas) ...[
                            _buildMenuCard(
                              context,
                              'Central de Alertas',
                              'Monitoramento e galeria de detecções de EPI',
                              const AlertaPage(),
                              Icons.notifications_active,
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (auth.hasSaneamento) ...[
                            _buildMenuCard(
                              context,
                              'Detecção de Valas',
                              'Monitoramento e detecção de valas e escoras',
                              const ValaPage(),
                              Icons.landscape,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Comentado conforme solicitado:
                          // _buildMenuCard(
                          //   context,
                          //   'Notificações Recentes',
                          //   'Histórico de avisos e infrações detectadas',
                          //   const NotificationsScreen(),
                          //   Icons.notifications_none,
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: Image.asset(
                    logoSensor,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget page,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBrandBlueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 28, color: kPaletteDeepBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
