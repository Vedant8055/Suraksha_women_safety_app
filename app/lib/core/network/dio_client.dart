import 'package:dio/dio.dart';
import 'package:suraksha_women_safety_app/core/network/network_manager.dart';

class DioClient {
  DioClient() : _dio = NetworkManager.instance.dio;

  final Dio _dio;

  Dio get dio => _dio;
}
