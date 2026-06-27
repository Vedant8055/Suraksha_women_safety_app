import 'package:dio/dio.dart';
import 'package:suraksha_women_safety_app/config/api_config.dart';
import 'package:suraksha_women_safety_app/core/network/auth_interceptor.dart';
import 'package:suraksha_women_safety_app/core/network/backend_url_resolver.dart';

class NetworkManager {
  NetworkManager._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    _dio.interceptors.addAll([
      AuthInterceptor(),
      InterceptorsWrapper(
        onError: (error, handler) => handler.next(_normalizeError(error)),
      ),
    ]);
  }

  static final NetworkManager instance = NetworkManager._internal();

  late final Dio _dio;
  bool? _lastReachable;

  Future<bool> ensureReachable({bool force = false}) async {
    if (!force && _lastReachable != null) return _lastReachable!;
    final ok = await BackendUrlResolver.applyToDio(_dio);
    _lastReachable = ok;
    return ok;
  }

  Future<bool> recoverConnection() async {
    _lastReachable = null;
    final ok = await BackendUrlResolver.recoverConnection(_dio);
    _lastReachable = ok;
    return ok;
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  Dio get dio => _dio;

  DioException _normalizeError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        error: 'Request timed out. Please try again.',
        type: error.type,
      );
    }
    return error;
  }
}
