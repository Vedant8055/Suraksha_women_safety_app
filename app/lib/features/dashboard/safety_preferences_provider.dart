import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';

class SafetyPreferencesState {
  final bool journeyAlertsEnabled;
  final bool loading;
  final String? error;

  const SafetyPreferencesState({
    this.journeyAlertsEnabled = true,
    this.loading = false,
    this.error,
  });

  SafetyPreferencesState copyWith({
    bool? journeyAlertsEnabled,
    bool? loading,
    String? error,
  }) {
    return SafetyPreferencesState(
      journeyAlertsEnabled: journeyAlertsEnabled ?? this.journeyAlertsEnabled,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

final safetyPreferencesProvider =
    StateNotifierProvider<SafetyPreferencesNotifier, SafetyPreferencesState>(
      (ref) => SafetyPreferencesNotifier(),
    );

class SafetyPreferencesNotifier extends StateNotifier<SafetyPreferencesState> {
  SafetyPreferencesNotifier() : super(const SafetyPreferencesState()) {
    _loadLocal();
  }

  static const _localKey = 'safety_journey_alerts_enabled_v1';
  final _dio = DioClient().dio;

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_localKey) ?? true;
    state = state.copyWith(journeyAlertsEnabled: enabled);
    await _syncFromServer();
  }

  Future<void> _syncFromServer() async {
    try {
      final response = await _dio.get(ApiConstants.safetyIntelligencePreferences);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final enabled = data['journeyAlertsEnabled'] == true;
        state = state.copyWith(journeyAlertsEnabled: enabled, error: null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_localKey, enabled);
      }
    } catch (_) {}
  }

  Future<void> setJourneyAlertsEnabled(bool enabled) async {
    state = state.copyWith(journeyAlertsEnabled: enabled, loading: true, error: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localKey, enabled);
    try {
      await _dio.patch(
        ApiConstants.safetyIntelligencePreferences,
        data: {'journeyAlertsEnabled': enabled},
      );
      state = state.copyWith(loading: false, journeyAlertsEnabled: enabled);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        journeyAlertsEnabled: enabled,
        error: 'Saved locally. Sign in to sync across devices.',
      );
    }
  }
}
