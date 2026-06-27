import 'package:suraksha_women_safety_app/config/app_environment.dart';

class ApiConstants {
  static String get baseUrl => AppEnvironment.apiBaseUrl;
  static String get socketUrl => AppEnvironment.socketBaseUrl;

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/profile';

  static const String createSOS = '/sos/create';
  static const String cancelSOS = '/sos/cancel';
  static const String activeSOS = '/sos/active';
  static const String updateLocation = '/location/update';

  static const String incidentReport = '/incident/report';
  static const String nearbyPolice = '/nearby/police';
  static const String nearbyHospitals = '/nearby/hospitals';
  static const String aiChat = '/ai/chat';
  static const String uploadMedia = '/media/upload';
  static const String notifications = '/notifications';
  static const String contacts = '/profile/contacts';
  static const String cyberAnalyze = '/cybercrime/assistant/analyze';
  static const String cyberAnalyzeImage = '/cybercrime/assistant/analyze-image';
  static const String cyberReport = '/cybercrime/report';
  static const String cyberReports = '/cybercrime/my-reports';
  static String cyberReportDetail(String id) => '/cybercrime/my-reports/$id';
  static String cyberEvidenceLink(String id) => '/cybercrime/evidence/$id/link';
  static const String cyberEvidence = '/cybercrime/evidence';
  static const String cyberEvidenceUpload = '/cybercrime/evidence/upload';
  static const String cyberEvidenceExport = '/cybercrime/evidence/export';
  static const String cyberLearningContent = '/cybercrime/learning/content';
  static const String cyberLearningProgress = '/cybercrime/learning/progress';
  static const String cyberDeepfakeResources = '/cybercrime/deepfake/resources';
  static const String safetyIntelligenceLive = '/safety-intelligence/live';
  static const String safetyIntelligenceRoutes = '/safety-intelligence/routes';
  static const String safetyIntelligenceHealth = '/safety-intelligence/health';
  static const String safetyIntelligencePings = '/safety-intelligence/pings';
  static const String safetyIntelligenceSummary = '/safety-intelligence/summary';
  static const String safetyIntelligenceJourneyUpdate =
      '/safety-intelligence/journey/update';
  static const String safetyIntelligencePreferences =
      '/safety-intelligence/preferences';
  static const String profileFcmToken = '/profile/fcm-token';
}
