import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentLoader {
  static Future<void> load() async {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final fileName = switch (appEnv) {
      'production' => '.env.production',
      'development' => '.env.development',
      _ => '.env',
    };

    await dotenv.load(fileName: '.env');

    if (fileName == '.env') return;

    try {
      await dotenv.load(
        fileName: fileName,
        mergeWith: Map<String, String>.from(dotenv.env),
      );
    } catch (_) {
      // Keep the base .env values when an environment-specific file is absent.
    }
  }
}
