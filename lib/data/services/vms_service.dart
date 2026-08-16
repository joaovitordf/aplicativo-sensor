import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sensortech/data/models/recording_model.dart';

/// Service for interacting with StreamServer VMS API (recordings & live streams).
class VmsService {
  final Dio _dio;
  final String apiUrl;
  final String streamUrl;
  final String hlsUrl;

  VmsService(this._dio)
      : apiUrl = dotenv.env['STREAMSERVER_API_URL'] ?? '',
        streamUrl = dotenv.env['STREAMSERVER_STREAM_URL'] ?? '',
        hlsUrl = dotenv.env['STREAMSERVER_HLS_URL'] ?? '';

  /// Lazy-load segments for a single camera from the StreamServer.
  /// Fetches from GET {apiUrl}/v3/recordings/get/{pathName}
  Future<List<RecordingSegment>> loadSegmentsForCamera(String pathName) async {
    try {
      final urlPath =
          pathName.split('/').map(Uri.encodeComponent).join('/');
      final response = await _dio.get('$apiUrl/v3/recordings/get/$urlPath');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> segmentsList = [];

        if (data is Map<String, dynamic>) {
          if (data['segments'] is List) {
            segmentsList = data['segments'] as List;
          } else if (data['items'] is List &&
              (data['items'] as List).isNotEmpty) {
            segmentsList =
                (data['items'] as List).first['segments'] as List? ?? [];
          } else if (data['data'] is Map &&
              data['data']['segments'] is List) {
            segmentsList = data['data']['segments'] as List;
          } else if (data['recordings'] is List) {
            segmentsList = data['recordings'] as List;
          }
        } else if (data is List) {
          segmentsList = data;
        }

        return segmentsList
            .map((item) =>
                RecordingSegment.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[VmsService] Error loading segments for camera $pathName: $e');
      }
      return [];
    }
  }

  /// Build URL for recorded segment playback.
  /// Format: {streamUrl}/get?path={cameraPath}&start={timestamp}&duration={seconds}&format=fmp4
  String buildRecordingUrl({
    required String cameraPath,
    required DateTime startTime,
    String? originalStartString,
    int durationSeconds = 3600,
  }) {
    final pathEncoded = Uri.encodeComponent(cameraPath);
    final startString = originalStartString ?? startTime.toIso8601String();
    final startEncoded = Uri.encodeComponent(startString);

    return '$streamUrl/get?path=$pathEncoded&start=$startEncoded&duration=$durationSeconds&format=fmp4';
  }

  /// Calculate duration between two consecutive segments.
  int calculateSegmentDuration(
      RecordingSegment current, RecordingSegment? next) {
    if (next == null) return 3600; // Default 1 hour
    final durationMs = next.start.difference(current.start).inMilliseconds;
    return (durationMs / 1000).floor();
  }

  /// Get playback URL for a specific segment.
  String getSegmentUrl({
    required String cameraPath,
    required RecordingSegment segment,
    RecordingSegment? nextSegment,
    int? overrideDuration,
  }) {
    final duration =
        overrideDuration ?? calculateSegmentDuration(segment, nextSegment);
    return buildRecordingUrl(
      cameraPath: cameraPath,
      startTime: segment.start,
      originalStartString: segment.originalStartString,
      durationSeconds: duration,
    );
  }

  /// Format connection type integer to a human-readable label.
  /// If tipoConexao is not set (0), infers type from linkcamera, idP2p or linkHLS.
  static String formatarTipoConexao(
    int? tipoConexao, {
    String linkcamera = '',
    String linkHLS = '',
    int? idP2p,
  }) {
    switch (tipoConexao) {
      case 1:
        return 'RTSP';
      case 2:
        return 'RTMP';
      case 3:
        return 'P2P';
    }

    final link = linkcamera.trim().toLowerCase();
    if (link.startsWith('rtsp://')) return 'RTSP';
    if (link.startsWith('rtmp://')) return 'RTMP';
    if (idP2p != null && idP2p > 0) return 'P2P';
    if (linkHLS.trim().isNotEmpty) return 'HLS';

    return '';
  }
}
