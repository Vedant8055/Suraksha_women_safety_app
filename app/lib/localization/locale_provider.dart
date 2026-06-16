import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

enum AppLanguage { english, hindi, marathi }

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.hindi:
        return const Locale('hi');
      case AppLanguage.marathi:
        return const Locale('mr');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  static AppLanguage fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return AppLanguage.hindi;
      case 'mr':
        return AppLanguage.marathi;
      default:
        return AppLanguage.english;
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.marathi:
        return 'mr';
      case AppLanguage.english:
        return 'en';
    }
  }
}

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const String _localeKey = 'app_locale_v1';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return;
    final normalizedCode = _normalizeLanguageCode(code);
    state = Locale(normalizedCode);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, language.code);
  }

  String _normalizeLanguageCode(String code) {
    final languageCode = code.trim().toLowerCase().split(RegExp(r'[_-]')).first;
    return AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    )
        ? languageCode
        : 'en';
  }
}

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((
  ref,
) {
  return AppLocaleNotifier();
});
