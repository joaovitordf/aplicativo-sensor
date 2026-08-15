import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensortech/data/models/auth_model.dart';

/// Service responsible for authentication against the SensorEPI Remoto backend.
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Authenticate user via POST /api/auth/login
  Future<LoginResponse> login({
    required String username,
    required String password,
    String email = '',
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Falha no login: código ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Login error: $e');
      }
      rethrow;
    }
  }

  /// Logout via POST /api/auth/logout
  Future<bool> logout() async {
    try {
      final response = await _dio.post('/api/auth/logout');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Logout error: $e');
      }
      return false;
    }
  }
}
