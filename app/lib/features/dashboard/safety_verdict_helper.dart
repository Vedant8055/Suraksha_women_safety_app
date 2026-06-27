import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

enum SafetyVerdictLevel { safe, caution, highRisk, monitoring }

class SafetyVerdict {
  final SafetyVerdictLevel level;
  final String headline;
  final String summary;
  final Color tone;

  const SafetyVerdict({
    required this.level,
    required this.headline,
    required this.summary,
    required this.tone,
  });

  bool get showRiskReasons =>
      level == SafetyVerdictLevel.caution ||
      level == SafetyVerdictLevel.highRisk;
}

class SafetyVerdictHelper {
  const SafetyVerdictHelper._();

  static SafetyVerdict fromScore(
    AppLocalizations l10n, {
    required int score,
    String? riskLabel,
    bool intelligenceLimited = false,
  }) {
    if (intelligenceLimited ||
        riskLabel?.toLowerCase() == 'monitoring' ||
        score <= 52) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.monitoring,
        headline: l10n.t('safetyVerdictMonitoring'),
        summary: l10n.t('safetyVerdictMonitoringSummary'),
        tone: const Color(0xFF64748B),
      );
    }
    if (score >= 75) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.safe,
        headline: l10n.t('safetyVerdictSafe'),
        summary: l10n.t('safetyVerdictSafeSummary'),
        tone: const Color(0xFF15803D),
      );
    }
    if (score >= 55) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.caution,
        headline: l10n.t('safetyVerdictCaution'),
        summary: l10n.t('safetyVerdictCautionSummary'),
        tone: const Color(0xFFEAB308),
      );
    }
    return SafetyVerdict(
      level: SafetyVerdictLevel.highRisk,
      headline: l10n.t('safetyVerdictHighRisk'),
      summary: l10n.t('safetyVerdictHighRiskSummary'),
      tone: const Color(0xFFB91C1C),
    );
  }

  static SafetyVerdict fromRouteState(
    AppLocalizations l10n, {
    required bool pendingSafetyCheck,
    required String riskLabel,
    required bool hasLearnedRoute,
    required bool learningRoute,
  }) {
    if (pendingSafetyCheck) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.highRisk,
        headline: l10n.t('routeVerdictChanged'),
        summary: l10n.t('routeVerdictChangedSummary'),
        tone: const Color(0xFFE53935),
      );
    }
    if (learningRoute || !hasLearnedRoute) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.monitoring,
        headline: l10n.t('routeVerdictLearning'),
        summary: l10n.t('routeVerdictLearningSummary'),
        tone: const Color(0xFF3B82F6),
      );
    }
    final label = riskLabel.toLowerCase();
    if (label.contains('safest') || label.contains('safe')) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.safe,
        headline: l10n.t('routeVerdictOnTrack'),
        summary: l10n.t('routeVerdictOnTrackSummary'),
        tone: const Color(0xFF2FB79E),
      );
    }
    if (label.contains('caution')) {
      return SafetyVerdict(
        level: SafetyVerdictLevel.caution,
        headline: l10n.t('routeVerdictCaution'),
        summary: l10n.t('routeVerdictCautionSummary'),
        tone: const Color(0xFFF3B13E),
      );
    }
    return SafetyVerdict(
      level: SafetyVerdictLevel.highRisk,
      headline: l10n.t('routeVerdictAlert'),
      summary: l10n.t('routeVerdictAlertSummary'),
      tone: const Color(0xFFE66E41),
    );
  }

  static bool isAreaSafetyAlert(String category) {
    final normalized = category.toLowerCase();
    return normalized.contains('area safety') ||
        normalized.contains('safety score');
  }

  static List<String> buildRiskReasons(
    AppLocalizations l10n, {
    required List<String> contributingFactors,
    required List<SafetyDimensionScore> dimensions,
    List<String> riskReasonsFromAlert = const [],
  }) {
    final reasons = <String>[];
    final seen = <String>{};

    void addReason(String reason) {
      final trimmed = reason.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) return;
      seen.add(trimmed);
      reasons.add(trimmed);
    }

    if (riskReasonsFromAlert.isNotEmpty) {
      for (final reason in riskReasonsFromAlert) {
        addReason(_humanizeFactor(l10n, reason));
      }
      return reasons.take(6).toList(growable: false);
    }

    for (final factor in contributingFactors) {
      if (_isPositiveFactor(factor)) continue;
      addReason(_humanizeFactor(l10n, factor));
    }

    for (final dimension in dimensions) {
      if (dimension.score >= 55) continue;
      addReason(_reasonForWeakDimension(l10n, dimension.key));
    }

    return reasons.take(6).toList(growable: false);
  }

  static String _humanizeFactor(AppLocalizations l10n, String factor) {
    final text = factor.toLowerCase();
    if (_containsAny(text, ['drug', 'narcotic'])) {
      return l10n.t('safetyReasonDrugActivity');
    }
    if (_containsAny(text, ['snatch', 'chain'])) {
      return l10n.t('safetyReasonChainSnatching');
    }
    if (_containsAny(text, ['theft', 'robbery', 'steal'])) {
      return l10n.t('safetyReasonTheftProne');
    }
    if (_containsAny(text, ['harass', 'molest', 'assault'])) {
      return l10n.t('safetyReasonHarassmentReports');
    }
    if (_containsAny(text, ['lighting', 'lit', 'visibility after sunset', 'dark'])) {
      return l10n.t('safetyReasonPoorLighting');
    }
    if (_containsAny(text, ['pedestrian', 'footfall', 'crowd', 'poi visibility'])) {
      return l10n.t('safetyReasonLowFootfall');
    }
    if (_containsAny(text, ['incident', 'crime', 'grid model', 'elevated risk'])) {
      return l10n.t('safetyReasonCrimeActivity');
    }
    if (_containsAny(text, ['emergency support', 'police', 'hospital'])) {
      return l10n.t('safetyReasonLimitedSupport');
    }
    if (_containsAny(text, ['late-night', 'night', 'after sunset'])) {
      return l10n.t('safetyReasonNightRisk');
    }
    if (_containsAny(text, ['gps', 'precision', 'accuracy'])) {
      return l10n.t('safetyReasonGpsLimited');
    }
    if (_containsAny(text, ['red light', 'unsafe nightlife', 'nightlife'])) {
      return l10n.t('safetyReasonUnsafeNightlife');
    }
    return factor;
  }

  static String _reasonForWeakDimension(AppLocalizations l10n, String key) {
    return switch (key) {
      'crime' => l10n.t('safetyReasonCrimeActivity'),
      'infrastructure' => l10n.t('safetyReasonPoorLighting'),
      'support' => l10n.t('safetyReasonLimitedSupport'),
      'visibility' => l10n.t('safetyReasonLowFootfall'),
      'temporal' => l10n.t('safetyReasonNightRisk'),
      _ => l10n.t('safetyReasonGeneralCaution'),
    };
  }

  static bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }

  static bool _isPositiveFactor(String factor) {
    final text = factor.toLowerCase();
    return _containsAny(text, [
      'favorable',
      'emergency support infrastructure is mapped',
      'community-identified safer',
      'daytime visibility and activity signals are favorable',
    ]);
  }
}
