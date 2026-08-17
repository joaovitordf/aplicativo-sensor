import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensortech/data/models/camera_model.dart';

/// Service for fetching camera data from the backend API.
class CameraService {
  final Dio _dio;

  CameraService(this._dio);

  /// Get cameras for a specific client.
  /// Endpoint: GET /api/v1/cameras?idCliente={clienteId}
  Future<List<Camera>> getCamerasByClient(int clienteId) async {
    try {
      final response = await _dio.get(
        '/api/v1/cameras',
        queryParameters: {'idCliente': clienteId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> cameraList;

        // Handle different response formats
        if (data is Map && data['data'] != null) {
          cameraList = data['data'] as List;
        } else if (data is List) {
          cameraList = data;
        } else {
          return [];
        }

        final cameras = cameraList
            .map((json) => Camera.fromJson(json as Map<String, dynamic>))
            .toList();
        cameras.sort((a, b) => a.displayId.compareTo(b.displayId));
        return cameras;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CameraService] Error fetching cameras for client $clienteId: $e');
      }
      rethrow;
    }
  }
}
