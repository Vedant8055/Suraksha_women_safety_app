import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const supportedLocales = [Locale('en'), Locale('hi'), Locale('mr')];

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appTitle': 'Suraksha',
      'myProfile': 'My Profile',
      'darkMode': 'Dark Mode',
      'darkModeSubtitleOn': 'Dark Bluish Theme',
      'darkModeSubtitleOff': 'Soft Calm Light Theme',
      'language': 'Language',
      'contentLanguage': 'Content language for the app',
      'english': 'English',
      'hindi': 'Hindi',
      'marathi': 'Marathi',
      'editProfileDetails': 'EDIT PROFILE DETAILS',
      'phoneNumber': 'Phone Number',
      'notProvided': 'Not provided',
      'emergencyContacts': 'Emergency Contacts',
      'contactsSaved': 'Contacts Saved',
      'emergencyContactList': 'Emergency Contact List',
      'addEmergencyContact': 'ADD EMERGENCY CONTACT',
      'logoutSession': 'LOGOUT SESSION',
      'emergencyServices': 'Emergency Services',
      'communityAlerts': 'Community Alerts',
      'womenHelpline': 'Women Helpline',
      'nearbyServices': 'Nearby Services',
      'nearbyHospitals': 'Nearby Hospitals',
      'policeStations': 'Police Stations',
      'tapToLoadNearby': 'Tap a button to load nearby real-time services.',
      'noNearbyPlaces': 'No nearby places found in 5 km radius.',
      'safeZoneActive': 'Prioritizing your Safety',
      'helloKaveri': 'Hello, Kaveri',
      'openSafetyMap': 'Open Safety Map',
      'openSafetyMapConfirm': 'Willing to see this location on the safety map?',
      'yes': 'Yes',
      'no': 'No',
      'couldNotOpenDialer': 'Could not open dialer',
      'safeZoneUpdatedNearby': 'Safe zone updated nearby',
      'crowdedAreaWarning': 'Crowded area warning',
      'minsAgo2': '2 mins ago',
      'minsAgo15': '15 mins ago',
      'map': 'Map',
      'medical': 'Medical',
      'cyber': 'Cyber',
      'poshPortal': 'POSH Portal',
    },
    'hi': {
      'appTitle': 'सुरक्षा',
      'myProfile': 'मेरा प्रोफाइल',
      'darkMode': 'डार्क मोड',
      'darkModeSubtitleOn': 'डार्क ब्लू थीम',
      'darkModeSubtitleOff': 'हल्की शांत थीम',
      'language': 'भाषा',
      'contentLanguage': 'ऐप की सामग्री की भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'editProfileDetails': 'प्रोफाइल विवरण संपादित करें',
      'phoneNumber': 'फोन नंबर',
      'notProvided': 'उपलब्ध नहीं',
      'emergencyContacts': 'आपातकालीन संपर्क',
      'contactsSaved': 'संपर्क सहेजे गए',
      'emergencyContactList': 'आपातकालीन संपर्क सूची',
      'addEmergencyContact': 'आपातकालीन संपर्क जोड़ें',
      'logoutSession': 'लॉगआउट',
      'emergencyServices': 'आपातकालीन सेवाएं',
      'communityAlerts': 'सामुदायिक अलर्ट',
      'womenHelpline': 'महिला हेल्पलाइन',
      'nearbyServices': 'नजदीकी सेवाएं',
      'nearbyHospitals': 'नजदीकी अस्पताल',
      'policeStations': 'पुलिस स्टेशन',
      'tapToLoadNearby': 'नजदीकी सेवाएं लोड करने के लिए बटन दबाएं।',
      'noNearbyPlaces': '5 किमी में कोई स्थान नहीं मिला।',
      'safeZoneActive': 'सेफ ज़ोन सक्रिय',
      'helloKaveri': 'नमस्ते, कावेरी',
      'openSafetyMap': 'सुरक्षा मानचित्र खोलें',
      'openSafetyMapConfirm':
          'क्या आप यह स्थान सुरक्षा मानचित्र पर देखना चाहते हैं?',
      'yes': 'हाँ',
      'no': 'नहीं',
      'couldNotOpenDialer': 'डायलर नहीं खुल सका',
      'safeZoneUpdatedNearby': 'नजदीक सुरक्षित क्षेत्र अपडेट हुआ',
      'crowdedAreaWarning': 'भीड़भाड़ क्षेत्र चेतावनी',
      'minsAgo2': '2 मिनट पहले',
      'minsAgo15': '15 मिनट पहले',
      'map': 'मैप',
      'medical': 'मेडिकल',
      'cyber': 'साइबर',
      'poshPortal': 'पोश पोर्टल',
    },
    'mr': {
      'appTitle': 'सुरक्षा',
      'myProfile': 'माझे प्रोफाइल',
      'darkMode': 'डार्क मोड',
      'darkModeSubtitleOn': 'गडद निळी थीम',
      'darkModeSubtitleOff': 'हलकी शांत थीम',
      'language': 'भाषा',
      'contentLanguage': 'अॅपमधील मजकुराची भाषा',
      'english': 'इंग्रजी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'editProfileDetails': 'प्रोफाइल तपशील संपादित करा',
      'phoneNumber': 'फोन नंबर',
      'notProvided': 'उपलब्ध नाही',
      'emergencyContacts': 'आपत्कालीन संपर्क',
      'contactsSaved': 'संपर्क जतन केले',
      'emergencyContactList': 'आपत्कालीन संपर्क यादी',
      'addEmergencyContact': 'आपत्कालीन संपर्क जोडा',
      'logoutSession': 'लॉगआउट',
      'emergencyServices': 'आपत्कालीन सेवा',
      'communityAlerts': 'समुदाय सूचना',
      'womenHelpline': 'महिला हेल्पलाइन',
      'nearbyServices': 'जवळच्या सेवा',
      'nearbyHospitals': 'जवळची रुग्णालये',
      'policeStations': 'पोलीस ठाणे',
      'tapToLoadNearby': 'जवळच्या सेवा लोड करण्यासाठी बटण दाबा.',
      'noNearbyPlaces': '5 किमी परिसरात कोणतीही जागा सापडली नाही.',
      'safeZoneActive': 'सुरक्षित क्षेत्र सक्रिय',
      'helloKaveri': 'नमस्कार, कावेरी',
      'openSafetyMap': 'सुरक्षा नकाशा उघडा',
      'openSafetyMapConfirm': 'हा ठिकाण सुरक्षा नकाशावर पाहायचा आहे का?',
      'yes': 'हो',
      'no': 'नाही',
      'couldNotOpenDialer': 'डायलर उघडता आला नाही',
      'safeZoneUpdatedNearby': 'जवळ सुरक्षित क्षेत्र अपडेट झाले',
      'crowdedAreaWarning': 'गर्दीच्या भागाची चेतावणी',
      'minsAgo2': '2 मिनिटांपूर्वी',
      'minsAgo15': '15 मिनिटांपूर्वी',
      'map': 'नकाशा',
      'medical': 'मेडिकल',
      'cyber': 'सायबर',
      'poshPortal': 'POSH पोर्टल',
    },
  };

  String t(String key) {
    final langCode =
        supportedLocales.any((e) => e.languageCode == locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _values[langCode]?[key] ?? _values['en']![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
