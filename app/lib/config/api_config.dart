import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _envValue(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  static String get environment =>
      _envValue('APP_ENV') ??
      const String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static String get baseUrlFromEnv {
    final value =
        _envValue('BASE_URL') ??
        const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return value.replaceAll(RegExp(r'/$'), '');
  }

  /// PC LAN IP for physical phones, e.g. http://192.168.1.5:5000/api
  static String get lanBaseUrl {
    final value =
        _envValue('LAN_BASE_URL') ??
        _envValue('PHYSICAL_BASE_URL') ??
        const String.fromEnvironment('LAN_BASE_URL', defaultValue: '');
    return value.replaceAll(RegExp(r'/$'), '');
  }

  /// Useful when running on iOS simulator / desktop.
  static String get localhostBaseUrl {
    const port = String.fromEnvironment('API_PORT', defaultValue: '5000');
    return 'http://127.0.0.1:$port/api';
  }

  static String get baseUrl => baseUrlFromEnv;

  static String get socketUrl {
    final value =
        _envValue('SOCKET_URL') ??
        const String.fromEnvironment('SOCKET_BASE_URL', defaultValue: '');
    return value.replaceAll(RegExp(r'/$'), '');
  }
}
