import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

enum SafetyVerdictLevel { safe, caution, highRisk }

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
    String? summary,
  }) {
    final level = _levelFromInputs(score: score, riskLabel: riskLabel);
    final headline = switch (level) {
      SafetyVerdictLevel.safe => l10n.t('safetyVerdictSafe'),
      SafetyVerdictLevel.caution => l10n.t('safetyVerdictCaution'),
      SafetyVerdictLevel.highRisk => l10n.t('safetyVerdictHighRisk'),
    };
    final defaultSummary = switch (level) {
      SafetyVerdictLevel.safe => l10n.t('safetyVerdictSafeSummary'),
      SafetyVerdictLevel.caution => l10n.t('safetyVerdictCautionSummary'),
      SafetyVerdictLevel.highRisk => l10n.t('safetyVerdictHighRiskSummary'),
    };
    final tone = switch (level) {
      SafetyVerdictLevel.safe => const Color(0xFF15803D),
      SafetyVerdictLevel.caution => const Color(0xFFEAB308),
      SafetyVerdictLevel.highRisk => const Color(0xFFB91C1C),
    };

    return SafetyVerdict(
      level: level,
      headline: headline,
      summary: _cleanSummary(summary) ?? defaultSummary,
      tone: tone,
    );
  }

  static SafetyVerdictLevel _levelFromInputs({
    required int score,
    String? riskLabel,
  }) {
    final label = riskLabel?.trim().toLowerCase() ?? '';
    if (label.contains('critical') ||
        label.contains('high risk') ||
        label.contains('high alert')) {
      return SafetyVerdictLevel.highRisk;
    }
    if (label.contains('moderate') ||
        label.contains('caution') ||
        label.contains('mixed')) {
      return SafetyVerdictLevel.caution;
    }
    if (label.contains('very safe') ||
        (label.contains('safe') && !label.contains('unsafe'))) {
      return SafetyVerdictLevel.safe;
    }

    if (score >= 75) return SafetyVerdictLevel.safe;
    if (score >= 55) return SafetyVerdictLevel.caution;
    return SafetyVerdictLevel.highRisk;
  }

  static String? _cleanSummary(String? summary) {
    final text = summary?.trim();
    if (text == null || text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower.contains('still building') ||
        lower.contains('still learning') ||
        lower.contains('initializing safety monitor')) {
      return null;
    }
    return text;
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
        level: SafetyVerdictLevel.caution,
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
    List<String> recommendations = const [],
    List<SafetyCommunityAlert> relatedAlerts = const [],
    int nearbyPoliceCount = 0,
    int nearbyHospitalCount = 0,
    String? limitedAssessmentNote,
    bool ensureForRiskyArea = false,
    SafetyVerdictLevel? verdictLevel,
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
    }

    for (final factor in contributingFactors) {
      if (_isPositiveFactor(factor)) continue;
      addReason(_humanizeFactor(l10n, factor));
    }

    for (final dimension in dimensions) {
      if (dimension.score >= 55) continue;
      addReason(_reasonForWeakDimension(l10n, dimension.key));
    }

    for (final recommendation in recommendations.take(3)) {
      if (_isActionRecommendation(recommendation)) {
        addReason(_humanizeFactor(l10n, recommendation));
      }
    }

    for (final alert in relatedAlerts) {
      if (isAreaSafetyAlert(alert.category)) continue;
      if (alert.priority != 'critical' && alert.priority != 'caution') continue;
      addReason(_humanizeFactor(l10n, alert.summary));
    }

    final hour = DateTime.now().hour;
    final isNight = hour >= 20 || hour < 6;
    final isLateNight = hour >= 23 || hour < 5;

    if (isLateNight) {
      addReason(l10n.t('safetyReasonLowFootfall'));
    } else if (isNight) {
      addReason(l10n.t('safetyReasonNightRisk'));
    }

    if (nearbyPoliceCount == 0 && nearbyHospitalCount == 0) {
      addReason(l10n.t('safetyReasonLimitedSupport'));
    }

    if (limitedAssessmentNote != null && limitedAssessmentNote.trim().isNotEmpty) {
      addReason(l10n.t('safetyReasonLimitedData'));
    }

    final needsFallback = ensureForRiskyArea ||
        verdictLevel == SafetyVerdictLevel.caution ||
        verdictLevel == SafetyVerdictLevel.highRisk;

    if (needsFallback && reasons.isEmpty) {
      addReason(l10n.t('safetyReasonGeneralCaution'));
      if (isNight) addReason(l10n.t('safetyReasonNightRisk'));
      if (nearbyPoliceCount == 0 && nearbyHospitalCount == 0) {
        addReason(l10n.t('safetyReasonLimitedSupport'));
      }
    }

    return reasons.take(6).toList(growable: false);
  }

  static bool _isActionRecommendation(String text) {
    final lower = text.toLowerCase();
    return lower.contains('light') ||
        lower.contains('alert') ||
        lower.contains('isolated') ||
        lower.contains('night') ||
        lower.contains('sos') ||
        lower.contains('location') ||
        lower.contains('police') ||
        lower.contains('hospital') ||
        lower.contains('crowd') ||
        lower.contains('shortcut');
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
    if (_containsAny(text, ['light', 'lighting', 'lit', 'visibility after sunset', 'dark'])) {
      return l10n.t('safetyReasonPoorLighting');
    }
    if (_containsAny(text, ['pedestrian', 'footfall', 'crowd', 'poi visibility', 'activity'])) {
      return l10n.t('safetyReasonLowFootfall');
    }
    if (_containsAny(text, ['incident', 'crime', 'grid model', 'elevated risk'])) {
      return l10n.t('safetyReasonCrimeActivity');
    }
    if (_containsAny(text, ['emergency support', 'police', 'hospital', 'support points'])) {
      return l10n.t('safetyReasonLimitedSupport');
    }
    if (_containsAny(text, ['late-night', 'night', 'after sunset', 'midnight'])) {
      return l10n.t('safetyReasonNightRisk');
    }
    if (_containsAny(text, ['gps', 'precision', 'accuracy', 'limited verified'])) {
      return l10n.t('safetyReasonLimitedData');
    }
    if (_containsAny(text, ['red light', 'unsafe nightlife', 'nightlife'])) {
      return l10n.t('safetyReasonUnsafeNightlife');
    }
    if (_containsAny(text, ['well-lit', 'isolated shortcut', 'poorly lit'])) {
      return l10n.t('safetyReasonPoorLighting');
    }
    if (_containsAny(text, ['share your live location', 'keep sos'])) {
      return l10n.t('safetyReasonGeneralCaution');
    }
    return factor;
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
      'conditions look manageable',
      'comparatively stable',
      'comparatively steadier',
    ]);
  }
}
