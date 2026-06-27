import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';

class CyberProtectionService {
  final Dio _dio = DioClient().dio;

  Future<ScamAnalysisResult> analyze({
    required String text,
    required String question,
    required List<String> links,
    String extractedText = '',
  }) async {
    final response = await _dio.post(
      ApiConstants.cyberAnalyze,
      data: {
        'text': text,
        'question': question,
        'links': links,
        'extractedText': extractedText,
      },
    );
    return ScamAnalysisResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<ScamAnalysisResult> analyzeWithScreenshot({
    required String text,
    required String question,
    required List<String> links,
    required XFile screenshot,
  }) async {
    final form = FormData.fromMap({
      'text': text,
      'question': question,
      'links': links.join(','),
      'screenshot': await MultipartFile.fromFile(
        screenshot.path,
        filename: screenshot.name,
      ),
    });
    final response = await _dio.post(
      ApiConstants.cyberAnalyzeImage,
      data: form,
    );
    return ScamAnalysisResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CyberReportResult> submitReport({
    required String category,
    required String description,
    required String suspectContact,
    required String transactionId,
    required DateTime incidentAt,
    required bool isDraft,
    List<String> evidenceUrls = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.cyberReport,
      data: {
        'category': category,
        'description': description,
        'suspectContact': suspectContact,
        'transactionId': transactionId,
        'incidentAt': incidentAt.toUtc().toIso8601String(),
        'isDraft': isDraft,
        if (evidenceUrls.isNotEmpty) 'evidenceUrls': evidenceUrls,
      },
    );
    return CyberReportResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<CyberReportListItem>> listMyReports() async {
    final response = await _dio.get(ApiConstants.cyberReports);
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => CyberReportListItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CyberReportDetail> getReportDetail(String id) async {
    final response = await _dio.get(ApiConstants.cyberReportDetail(id));
    return CyberReportDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<EvidenceItem>> listEvidence({
    String? category,
    String? search,
    String? reportId,
    String? linked,
  }) async {
    final response = await _dio.get(
      ApiConstants.cyberEvidence,
      queryParameters: {
        if (category != null && category != 'All') 'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
        if (linked != null && linked.isNotEmpty) 'linked': linked,
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => EvidenceItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> uploadEvidence({
    required XFile file,
    required String title,
    required String category,
    required List<String> tags,
    required bool privateMode,
    String? reportId,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'category': category,
      'tags': tags.join(','),
      'privateMode': privateMode.toString(),
      if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    await _dio.post(ApiConstants.cyberEvidenceUpload, data: form);
  }

  Future<void> linkEvidenceToReport({
    required String evidenceId,
    required String reportId,
  }) async {
    await _dio.patch(
      ApiConstants.cyberEvidenceLink(evidenceId),
      data: {'reportId': reportId},
    );
  }

  Future<List<LearningTopic>> getLearningContent() async {
    final response = await _dio.get(ApiConstants.cyberLearningContent);
    final data = response.data;
    if (data is! List) return fallbackLearningTopics;
    return data
        .whereType<Map>()
        .map((item) => LearningTopic.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveProgress(String topicId, int score) async {
    await _dio.post(
      ApiConstants.cyberLearningProgress,
      data: {'topicId': topicId, 'score': score},
    );
  }

  Future<LearningProgressSnapshot> getLearningProgress() async {
    final response = await _dio.get(ApiConstants.cyberLearningProgress);
    return LearningProgressSnapshot.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> exportVaultPackage() async {
    final response = await _dio.get(ApiConstants.cyberEvidenceExport);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<DownloadedEvidence> downloadEvidence(String id) async {
    final response = await _dio.get<List<int>>(
      '${ApiConstants.cyberEvidence}/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty evidence download response',
      );
    }
    final disposition = response.headers.value('content-disposition') ?? '';
    final type = response.headers.value('content-type') ?? 'application/octet-stream';
    final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
    return DownloadedEvidence(
      bytes: Uint8List.fromList(bytes),
      fileName: match?.group(1) ?? 'evidence_$id',
      mimeType: type,
    );
  }

  Future<void> deleteEvidence(String id) async {
    await _dio.delete('${ApiConstants.cyberEvidence}/$id');
  }

  Future<DeepfakeResources> getDeepfakeResources() async {
    final response = await _dio.get(ApiConstants.cyberDeepfakeResources);
    return DeepfakeResources.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
