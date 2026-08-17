import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensortech/core/constants.dart';
import 'package:sensortech/features/home/homepage.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/shared/widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    authController.clearError();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha usuário e senha'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await authController.login(username, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<AuthController>(
          builder: (context, authController, child) {
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Image.asset(
                            logoSensor,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shield_outlined,
                                    size: 80, color: kPaletteDeepBlue),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (authController.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authController.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 5),
                            CustomTextField(
                              controller: _usernameController,
                              enabled: !authController.isLoading,
                              onChanged: (value) {
                                if (authController.errorMessage != null) {
                                  authController.clearError();
                                }
                              },
                              hint: "Usuário ou E-mail",
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(height: 15),
                            CustomTextField(
                              controller: _passwordController,
                              obscureText: true,
                              enabled: !authController.isLoading,
                              onChanged: (value) {
                                if (authController.errorMessage != null) {
                                  authController.clearError();
                                }
                              },
                              onSubmitted: (_) => _handleLogin(),
                              hint: "Senha",
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: authController.isLoading
                                    ? null
                                    : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPaletteDeepBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: authController.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Entrar",
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
