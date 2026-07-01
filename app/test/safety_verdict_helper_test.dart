import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_verdict_helper.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  test('buildRiskReasons keeps crime and lighting reasons', () {
    final reasons = SafetyVerdictHelper.buildRiskReasons(
      l10n,
      contributingFactors: const [
        'Recent drug-related activity reported in this area.',
        'Chain-snatching cases have been reported nearby.',
        'This stretch is known for theft-related incidents.',
        'Poor street lighting may reduce visibility here.',
        'Low pedestrian activity makes this area feel isolated.',
      ],
      dimensions: const [
        SafetyDimensionScore(
          key: 'crime',
          score: 40,
          label: 'High Risk',
          confidence: 70,
        ),
      ],
      nearbySupportCount: 0,
      nearbyPoliceCount: 0,
      nearbyHospitalCount: 0,
      verdictLevel: SafetyVerdictLevel.highRisk,
      ensureForRiskyArea: true,
    );

    expect(
      reasons,
      containsAllInOrder([
        'Recent drug-related activity reported in this area.',
        'Chain-snatching cases have been reported nearby.',
        'This stretch is known for theft-related incidents.',
        'Poor street lighting may reduce visibility here.',
        'Low pedestrian activity makes this area feel isolated.',
      ]),
    );
  });

  test('buildRiskReasons suppresses support warning when help is nearby', () {
    final reasons = SafetyVerdictHelper.buildRiskReasons(
      l10n,
      contributingFactors: const [
        'Emergency support infrastructure is mapped nearby.',
        'At least one emergency support point is mapped nearby.',
      ],
      dimensions: const [
        SafetyDimensionScore(
          key: 'support',
          score: 42,
          label: 'High Risk',
          confidence: 70,
        ),
      ],
      nearbySupportCount: 1,
      nearbyPoliceCount: 0,
      nearbyHospitalCount: 0,
      verdictLevel: SafetyVerdictLevel.caution,
      ensureForRiskyArea: true,
    );

    expect(
      reasons,
      isNot(contains('Limited nearby emergency support points may slow rapid assistance.')),
    );
  });

  test('buildRiskReasons never shows limited support as the only risk reason', () {
    final reasons = SafetyVerdictHelper.buildRiskReasons(
      l10n,
      contributingFactors: const [],
      dimensions: const [
        SafetyDimensionScore(
          key: 'support',
          score: 20,
          label: 'Critical',
          confidence: 70,
        ),
      ],
      riskReasonsFromAlert: const [
        'Limited nearby emergency support points may slow rapid assistance.',
      ],
      nearbySupportCount: 0,
      nearbyPoliceCount: 0,
      nearbyHospitalCount: 0,
      verdictLevel: SafetyVerdictLevel.highRisk,
      ensureForRiskyArea: true,
    );

    expect(
      reasons,
      isNot(contains('Limited nearby emergency support points may slow rapid assistance.')),
    );
  });
}
