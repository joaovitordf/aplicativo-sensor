import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration helper for handling Environment URLs and Staging/Production switching.
class AppConfig {
  static Map<String, String>? _mockEnv;

  /// Visible for testing to mock environment variables in unit tests.
  static void setMockEnvForTesting(Map<String, String>? env) {
    _mockEnv = env;
  }

  static String? _get(String key) {
    return _mockEnv != null ? _mockEnv![key] : dotenv.env[key];
  }

  /// Check whether the app is configured to use the Staging / Test environment.
  static bool get isStaging {
    final val = _get('USE_STAGING')?.trim().toLowerCase();
    return val == 'true' || val == '1';
  }

  /// Base API URL for backend calls (e.g. login, PPE, cameras, clients).
  /// Automatically selects Staging or Production based on [isStaging].
  static String get apiUrl {
    if (isStaging) {
      final stagingUrl = _get('API_URL_STAGING')?.trim();
      if (stagingUrl != null && stagingUrl.isNotEmpty) {
        return _normalizeUrl(stagingUrl);
      }
    }

    final prodUrl = _get('API_URL_PROD')?.trim() ??
        _get('API_URL')?.trim() ??
        '';
    return _normalizeUrl(prodUrl);
  }

  /// IoT API URL for IoT equipment and timers.
  static String get iotApiUrl {
    final iot = _get('API_IOT_URL')?.trim();
    if (iot != null && iot.isNotEmpty) {
      return _normalizeUrl(iot);
    }
    return apiUrl;
  }

  /// Normalize URL to ensure it does not end with a trailing slash.
  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
