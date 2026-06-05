class AppEnvironment {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const String socketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String _viteGoogleMapsApiKey = String.fromEnvironment(
    'VITE_GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static String get googleMapsApiKey {
    if (_googleMapsApiKey.isNotEmpty) return _googleMapsApiKey;
    if (_viteGoogleMapsApiKey.isNotEmpty) return _viteGoogleMapsApiKey;
    return 'AIzaSyAHuQ735KTsOI98USg1auNELNf4tY8AwK4';
  }
}
