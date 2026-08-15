import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/features/home/homepage.dart';
import 'package:sensortech/features/auth/login_page.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/features/notifications/notification_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ProxyProvider<AuthController, PpeService>(
          update: (_, auth, prev) =>
              auth.dio != null ? PpeService(auth.dio!) : prev ?? PpeService(Dio()),
        ),
        ChangeNotifierProxyProvider2<AuthController, PpeService,
            NotificationController>(
          create: (context) => NotificationController(
            Provider.of<AuthController>(context, listen: false),
            Provider.of<PpeService>(context, listen: false),
          ),
          update: (_, auth, ppeService, prev) =>
              prev ?? NotificationController(auth, ppeService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SensorEPI Remoto',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kPaletteDeepBlue),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to check authentication status and route to HomePage or LoginPage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        if (authController.isLoading && !authController.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authController.isAuthenticated) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
