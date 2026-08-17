import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';

/// Service for interacting with the /api/v1/equipamentosiot endpoint
class EquipamentoIotService {
  final Dio _dio;

  EquipamentoIotService(this._dio);

  /// Fetch all IoT equipment from the backend
  Future<List<EquipamentoIot>> list() async {
    try {
      final response = await _dio.get('/api/v1/equipamentosiot');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list;

        if (data is List) {
          list = data;
        } else if (data is Map && data['data'] != null) {
          list = data['data'] as List;
        } else {
          return [];
        }

        return list
            .map((json) =>
                EquipamentoIot.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EquipamentoIotService] Error fetching equipamentos IoT: $e');
      }
      rethrow;
    }
  }

  /// Aciona a sirene de um equipamento IoT por [seconds] segundos.
  ///
  /// Endpoint: POST /api/v1/equipamentosiot/timer
  /// Body: `{ "id": <idEquipamento>, "seconds": <seconds> }`
  Future<void> acionarSirene({required int id, int seconds = 5}) async {
    final body = {
      'id': id,
      'seconds': seconds,
    };

    try {
      await _dio.post(
        '/api/v1/equipamentosiot/timer',
        data: body,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EquipamentoIotService] Erro ao acionar sirene para id $id: $e');
      }
      rethrow;
    }
  }

  /// Fetch a single IoT equipment by ID
  Future<EquipamentoIot?> getById(int id) async {
    try {
      final response = await _dio.get('/api/v1/equipamentosiot/$id');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        return EquipamentoIot.fromJson(data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[EquipamentoIotService] Error fetching equipamento IoT by id $id: $e');
      }
      rethrow;
    }
  }
}
