import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/config/api_config.dart';

class BackendUrlResolver {
  BackendUrlResolver._();

  static const _prefKey = 'backend_base_url_override';
  static const _probePaths = [
    '/safety-intelligence/health',
    '/cybercrime/learning/content',
  ];

  static Future<String?> savedOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'/$'), '');
  }

  static Future<void> saveOverride(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, normalized);
  }

  static Future<void> clearOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  static List<String> candidateUrls() {
    final urls = <String>[];
    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final normalized = raw.trim().replaceAll(RegExp(r'/$'), '');
      if (!urls.contains(normalized)) urls.add(normalized);
    }

    add(ApiConfig.baseUrlFromEnv);
    add(ApiConfig.lanBaseUrl);
    add(ApiConfig.localhostBaseUrl);
    return urls;
  }

  static Future<List<String>> _orderedCandidates() async {
    final urls = <String>[];
    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final normalized = raw.trim().replaceAll(RegExp(r'/$'), '');
      if (!urls.contains(normalized)) urls.add(normalized);
    }

    add(await savedOverride());
    add(ApiConfig.baseUrlFromEnv);
    add(ApiConfig.lanBaseUrl);
    add(ApiConfig.localhostBaseUrl);
    return urls;
  }

  static Future<bool> _probe(String baseUrl) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    try {
      for (final path in _probePaths) {
        try {
          final response = await dio.get(path);
          if (response.statusCode == 200) return true;
        } catch (_) {
          continue;
        }
      }
      return false;
    } finally {
      dio.close(force: true);
    }
  }

  static Future<bool> recoverConnection(Dio dio) async {
    final candidates = await _orderedCandidates();
    for (final candidate in candidates) {
      if (!await _probe(candidate)) continue;
      dio.options.baseUrl = candidate;
      await saveOverride(candidate);
      return true;
    }
    return false;
  }

  static Future<String> resolveWorkingBaseUrl() async {
    final candidates = await _orderedCandidates();
    if (candidates.isEmpty) return ApiConfig.baseUrlFromEnv;

    for (final candidate in candidates) {
      if (await _probe(candidate)) {
        return candidate;
      }
    }
    return candidates.first;
  }

  static Future<bool> applyToDio(Dio dio) async {
    final url = await resolveWorkingBaseUrl();
    dio.options.baseUrl = url;
    return await _probe(url);
  }

  static bool isConnectionError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response == null && error.error != null);
  }
}
