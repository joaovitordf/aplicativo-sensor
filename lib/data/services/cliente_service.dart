import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensortech/data/models/cliente_detailed_model.dart';

/// Service for managing client data from the backend API
class ClienteService {
  final Dio _dio;

  ClienteService(this._dio);

  /// Get all clients (admin only)
  Future<List<ClienteDetailed>> getClientes() async {
    try {
      final response = await _dio.get('/api/v1/clientes');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> clienteList;

        // Handle different response formats
        if (data is Map && data['data'] != null) {
          clienteList = data['data'] as List;
        } else if (data is List) {
          clienteList = data;
        } else {
          return [];
        }

        return clienteList
            .map((json) =>
                ClienteDetailed.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ClienteService] Error fetching clientes: $e');
      }
      rethrow;
    }
  }

  /// Get clients filtered by solution ID
  Future<List<ClienteDetailed>> getClientesBySolution(int solutionId) async {
    try {
      final allClientes = await getClientes();

      // Filter clients that have the specified solution
      return allClientes
          .where((cliente) => cliente.solucoes.contains(solutionId))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[ClienteService] Error fetching clientes by solution $solutionId: $e');
      }
      rethrow;
    }
  }
}
