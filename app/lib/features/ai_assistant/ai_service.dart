import 'package:dio/dio.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';

class AIService {
  final Dio _dio = DioClient().dio;

  Future<String> getSafetyAdvice(String query) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiChat,
        data: {'message': query},
      );
      final text = response.data['reply']?.toString();
      return (text == null || text.trim().isEmpty)
          ? 'I could not generate a reliable answer right now.'
          : text.trim();
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'I am unable to connect right now. Please check internet and try again.';
    } catch (_) {
      return 'I am unable to answer right now. Please try again in a moment.';
    }
  }
}
