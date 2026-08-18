import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sensortech/core/app_config.dart';
import 'package:sensortech/data/models/auth_model.dart';
import 'package:sensortech/data/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  static const String _storageKey = 'auth_data_v2';
  final _secureStorage = const FlutterSecureStorage();

  LoginResponse? _loginResponse;
  Dio? _dio;
  Dio? _iotDio;
  AuthService? _authService;
  bool _isLoading = false;
  String? _errorMessage;

  LoginResponse? get loginResponse => _loginResponse;
  AuthUser? get user => _loginResponse?.user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Key getters used across the app
  bool get isAuthenticated =>
      _loginResponse != null && _loginResponse!.token.isNotEmpty;
  String? get token => _loginResponse?.token;
  int? get clientId => _loginResponse?.user.clientId;
  String get clientName => _loginResponse?.clientName ?? '';
  String get userName => _loginResponse?.user.name.trim() ?? '';
  String get userLogin => _loginResponse?.user.username.trim() ?? '';
  String get role => _loginResponse?.user.role ?? 'cliente';
  List<String> get allowedTabs => _loginResponse?.allowedTabs ?? [];

  String get displayName {
    if (userName.isNotEmpty) return userName;
    if (userLogin.isNotEmpty) return userLogin;
    return 'Usuário';
  }

  Dio? get dio => _dio;
  Dio? get iotDio => _iotDio;
  AuthService? get authService => _authService;

  AuthController() {
    _init();
  }

  Future<void> _init() async {
    _initializeDio();
    await loadAuth();
  }

  void _initializeDio() {
    final apiUrl = AppConfig.apiUrl;
    final iotApiUrl = AppConfig.iotApiUrl;
    debugPrint('[AuthController] Initializing Main Dio with base URL: $apiUrl (Staging: ${AppConfig.isStaging})');
    debugPrint('[AuthController] Initializing IoT Dio with base URL: $iotApiUrl');

    _dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _iotDio = Dio(BaseOptions(
      baseUrl: iotApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Shared interceptor to attach Bearer token to all outgoing requests
    final authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_loginResponse?.token != null &&
            _loginResponse!.token.isNotEmpty) {
          options.headers['Authorization'] =
              'Bearer ${_loginResponse!.token}';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Do NOT trigger logout if the 401 occurred during login request
          final path = e.requestOptions.path;
          if (path.contains('/api/auth/login')) {
            return handler.next(e);
          }

          debugPrint('[AuthController] 401 Unauthorized detected - logging out');
          logout();
        }
        return handler.next(e);
      },
    );

    _dio!.interceptors.add(authInterceptor);
    _iotDio!.interceptors.add(authInterceptor);

    // Logging interceptor in debug mode
    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ));
      _iotDio!.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[IOT-DIO] $obj'),
      ));
    }

    _authService = AuthService(_dio!);
  }

  /// Load persisted authentication data from secure storage
  Future<void> loadAuth() async {
    try {
      final raw = await _secureStorage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _loginResponse = LoginResponse.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Error loading auth: $e');
      }
      _loginResponse = null;
    }
  }

  /// Save authentication data to secure storage
  Future<void> _saveAuth(LoginResponse response) async {
    try {
      final json = jsonEncode(response.toJson());
      await _secureStorage.write(key: _storageKey, value: json);
      _loginResponse = response;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Error saving auth: $e');
      }
    }
  }

  /// Perform login against POST /api/auth/login
  Future<bool> login(String username, String password, {String email = ''}) async {
    if (_dio == null || _authService == null) {
      _initializeDio();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService!.login(
        username: username,
        password: password,
        email: email,
      );

      await _saveAuth(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      debugPrint('[AuthController] Login DioException: ${e.response?.statusCode}');
      debugPrint('[AuthController] Response data: ${e.response?.data}');

      if (e.response != null) {
        final data = e.response!.data;
        String? serverError;

        if (data is Map) {
          if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
            serverError = data['error'].toString().trim();
          } else if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
            serverError = data['message'].toString().trim();
          }
        } else if (data is String && data.trim().isNotEmpty) {
          serverError = data.trim();
        }

        if (serverError != null &&
            serverError.isNotEmpty &&
            !serverError.trim().startsWith('<')) {
          final lower = serverError.toLowerCase();
          if (lower.contains('credenciais invalidas') ||
              lower.contains('credenciais inválidas') ||
              lower.contains('invalid credentials')) {
            _errorMessage = 'Credenciais inválidas. Verifique seu usuário e senha.';
          } else {
            _errorMessage = serverError;
          }
        } else {
          switch (e.response!.statusCode) {
            case 301:
            case 302:
            case 307:
            case 308:
              _errorMessage =
                  'Erro de redirecionamento (${e.response!.statusCode}). Verifique se a URL no .env usa HTTPS.';
              break;
            case 400:
            case 401:
              _errorMessage = 'Credenciais inválidas. Verifique seu usuário e senha.';
              break;
            case 403:
              _errorMessage = 'Acesso negado para esta conta.';
              break;
            case 404:
              _errorMessage = 'Serviço de autenticação não encontrado.';
              break;
            case 500:
              _errorMessage = 'Erro no servidor. Tente novamente mais tarde.';
              break;
            default:
              _errorMessage = 'Erro ao fazer login (${e.response!.statusCode})';
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Tempo de conexão excedido. Verifique sua internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        _errorMessage = 'Erro de conexão com o servidor. Verifique sua rede.';
      } else {
        _errorMessage = 'Erro ao conectar ao servidor.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro inesperado: $e';
      notifyListeners();
      return false;
    }
  }

  /// Perform logout and clear credentials
  Future<void> logout() async {
    try {
      if (_authService != null && isAuthenticated) {
        await _authService!.logout();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Logout remote call error: $e');
      }
    } finally {
      await _secureStorage.delete(key: _storageKey);
      _loginResponse = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
