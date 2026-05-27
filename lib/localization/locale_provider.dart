import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    state = Locale(code);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final locale = language.locale;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, language.code);
  }
}

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((
  ref,
) {
  return AppLocaleNotifier();
});
