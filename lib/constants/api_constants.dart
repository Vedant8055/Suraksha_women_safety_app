import 'package:suraksha_women_safety_app/config/app_environment.dart';

class ApiConstants {
  static const String baseUrl = AppEnvironment.apiBaseUrl;
  static const String socketUrl = AppEnvironment.socketBaseUrl;

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/profile';

  static const String createSOS = '/sos/create';
  static const String activeSOS = '/sos/active';
  static const String updateLocation = '/location/update';

  static const String incidentReport = '/incident/report';
  static const String nearbyPolice = '/nearby/police';
  static const String nearbyHospitals = '/nearby/hospitals';
  static const String aiChat = '/ai/chat';
  static const String uploadMedia = '/media/upload';
  static const String notifications = '/notifications';
  static const String contacts = '/profile/contacts';
}
