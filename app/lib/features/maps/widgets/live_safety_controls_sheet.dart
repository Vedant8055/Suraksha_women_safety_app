import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class LiveSafetyControlsSheet extends StatelessWidget {
  final Position? position;
  final int safetyScore;
  final String riskLevel;
  final int? aiConfidence;
  final List<String> contributingFactors;
  final List<String> recommendations;
  final UpcomingRiskAlert? upcomingRisk;
  final String? statusText;
  final VoidCallback onMyLocation;
  final VoidCallback onRefreshNearby;
  final VoidCallback onRetryLiveLocation;

  const LiveSafetyControlsSheet({
    super.key,
    required this.position,
    required this.safetyScore,
    required this.riskLevel,
    required this.aiConfidence,
    required this.contributingFactors,
    required this.recommendations,
    required this.upcomingRisk,
    required this.statusText,
    required this.onMyLocation,
    required this.onRefreshNearby,
    required this.onRetryLiveLocation,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.28,
      maxChildSize: 0.84,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).t('liveSafetyMapTitle'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        position == null
                            ? AppLocalizations.of(context).t('locating')
                            : '${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                  if (statusText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      statusText!,
                      style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        icon: Icons.shield_rounded,
                        label: 'Safety Score $safetyScore',
                      ),
                      _pill(
                        icon: Icons.flag_rounded,
                        label: riskLevel,
                      ),
                      _pill(
                        icon: Icons.verified_rounded,
                        label: aiConfidence == null
                            ? 'Assessment limited'
                            : 'AI Confidence $aiConfidence%',
                      ),
                    ],
                  ),
                  if (upcomingRisk != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.42),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming elevated risk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            upcomingRisk!.summary,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (contributingFactors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Contributing factors',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...contributingFactors.take(4).map(
                      (factor) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $factor',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Recommended actions',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.take(4).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $item',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMyLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: Text(AppLocalizations.of(context).t('myLocation')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRefreshNearby,
                          icon: const Icon(Icons.local_police, size: 16),
                          label: Text(AppLocalizations.of(context).t('refreshNearby')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRetryLiveLocation,
                      icon: const Icon(Icons.gps_fixed, size: 16),
                      label: Text(AppLocalizations.of(context).t('retryLiveLocation')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
