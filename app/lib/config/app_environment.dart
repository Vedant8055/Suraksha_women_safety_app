import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suraksha_women_safety_app/config/api_config.dart';

class AppEnvironment {
  static String? _envValue(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  static String get environment => ApiConfig.environment;

  static String get apiBaseUrl => ApiConfig.baseUrl;

  static String get socketBaseUrl => ApiConfig.socketUrl;

  static String get geminiApiKey =>
      _envValue('GEMINI_API_KEY') ??
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get geminiModel =>
      _envValue('GEMINI_MODEL') ??
      const String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: 'gemini-1.5-flash',
      );

  static String get googleMapsApiKey =>
      _envValue('GOOGLE_MAPS_API_KEY') ??
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}
