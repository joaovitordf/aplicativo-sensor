import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensortech/core/app_config.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';

/// Service responsible for querying PPE detection events and downloading images.
class PpeService {
  final Dio _dio;

  PpeService(this._dio);

  String get baseUrl =>
      _dio.options.baseUrl.isNotEmpty ? _dio.options.baseUrl : AppConfig.apiUrl;

  /// Fetch list of PPE events with filters and pagination.
  ///
  /// Endpoint: GET /api/ppe/events
  Future<List<PpeEvent>> getEvents({
    required int clientId,
    int page = 1,
    String? start,
    String? end,
    String? startTime,
    String? endTime,
    String? epi,
    int? cameraId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'client_id': clientId,
      };

      if (start != null && start.isNotEmpty) queryParams['start'] = start;
      if (end != null && end.isNotEmpty) queryParams['end'] = end;
      if (startTime != null && startTime.isNotEmpty) {
        queryParams['start_time'] = startTime;
      }
      if (endTime != null && endTime.isNotEmpty) {
        queryParams['end_time'] = endTime;
      }
      if (epi != null && epi.isNotEmpty) queryParams['epi'] = epi;
      if (cameraId != null) queryParams['camera_id'] = cameraId;

      if (kDebugMode) {
        debugPrint('[PpeService] GET /api/ppe/events params: $queryParams');
      }

      final response = await _dio.get(
        '/api/ppe/events',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = PpeEventsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return parsed.events;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PpeService] Error fetching events: $e');
      }
      rethrow;
    }
  }

  /// Construct the full URL for an event image
  String buildImageUrl(int eventId, int clientId, {bool anon = false}) {
    final anonParam = anon ? 1 : 0;
    return '$baseUrl/api/ppe/events/$eventId/image?anon=$anonParam&client_id=$clientId';
  }

  /// Fetch image bytes directly with authenticated Dio client
  Future<Uint8List?> getImageBytes(
    int eventId,
    int clientId, {
    bool anon = false,
  }) async {
    try {
      final anonParam = anon ? 1 : 0;
      final response = await _dio.get(
        '/api/ppe/events/$eventId/image',
        queryParameters: {
          'anon': anonParam,
          'client_id': clientId,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data as List<int>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PpeService] Error fetching image bytes for event $eventId: $e');
      }
      return null;
    }
  }

  /// Download and save image to device
  Future<void> downloadImageFile({
    required int eventId,
    required int clientId,
    required String savePath,
    bool anon = false,
  }) async {
    try {
      final anonParam = anon ? 1 : 0;
      await _dio.download(
        '/api/ppe/events/$eventId/image',
        savePath,
        queryParameters: {
          'anon': anonParam,
          'client_id': clientId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PpeService] Error downloading image to $savePath: $e');
      }
      rethrow;
    }
  }
}
