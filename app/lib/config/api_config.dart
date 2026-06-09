import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _envValue(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  static String get environment =>
      _envValue('APP_ENV') ??
      const String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static String get baseUrl {
    final value =
        _envValue('BASE_URL') ??
        const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return value.replaceAll(RegExp(r'/$'), '');
  }

  static String get socketUrl {
    final value =
        _envValue('SOCKET_URL') ??
        const String.fromEnvironment('SOCKET_BASE_URL', defaultValue: '');
    return value.replaceAll(RegExp(r'/$'), '');
  }
}
