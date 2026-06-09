import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentLoader {
  static Future<void> load() async {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final fileName = switch (appEnv) {
      'production' => '.env.production',
      'development' => '.env.development',
      _ => '.env',
    };

    try {
      await dotenv.load(fileName: fileName);
    } catch (_) {
      await dotenv.load(fileName: '.env');
    }
  }
}
