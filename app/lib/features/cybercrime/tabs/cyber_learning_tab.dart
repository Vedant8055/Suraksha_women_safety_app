import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class CyberLearningTab extends StatefulWidget {
  const CyberLearningTab({
    super.key,
    required this.service,
    required this.onApiError,
  });

  final CyberProtectionService service;
  final Future<bool> Function(DioException error) onApiError;

  @override
  State<CyberLearningTab> createState() => _CyberLearningTabState();
}

class _CyberLearningTabState extends State<CyberLearningTab> {
  List<LearningTopic> _topics = fallbackLearningTopics;
  final Set<String> _completed = {};
  int _safetyScore = 0;
  List<String> _badges = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final topics = await widget.service.getLearningContent();
      LearningProgressSnapshot progress = const LearningProgressSnapshot();
      try {
        progress = await widget.service.getLearningProgress();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _topics = topics.isEmpty ? fallbackLearningTopics : topics;
        _completed
          ..clear()
          ..addAll(progress.completedTopicIds);
        _safetyScore = progress.safetyScore;
        _badges = progress.badges;
      });
    } catch (_) {
      if (mounted) setState(() => _topics = fallbackLearningTopics);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeQuiz(LearningTopic topic) async {
    final l10n = AppLocalizations.of(context);
    final score = await showDialog<int>(
      context: context,
      builder: (context) => CyberQuizDialog(topic: topic),
    );
    if (score == null) return;
    setState(() {
      _completed.add(topic.id);
      _safetyScore = score;
    });
    try {
      await widget.service.saveProgress(topic.id, score);
      final progress = await widget.service.getLearningProgress();
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(progress.completedTopicIds);
        _safetyScore = progress.safetyScore;
        _badges = progress.badges;
      });
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) showCyberSnack(context, friendlyCyberError(context, error));
    }
    if (mounted) {
      showCyberSnack(
        context,
        l10n.t('cyberSafetyScoreUpdated').replaceFirst('{score}', '$_safetyScore'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = _topics.isEmpty ? 0.0 : _completed.length / _topics.length;
    final badgeKey = _badges.contains('Cyber Defender') || progress >= 1
        ? 'cyberDefender'
        : 'cyberLearner';
    final displayPercent =
        _safetyScore > 0 ? _safetyScore : (progress * 100).round();

    return CyberScroll(
      children: [
        CyberSectionHeader(
          title: l10n.t('digitalSafetyLearningHub'),
          subtitle: l10n.t('learningHubSubtitle'),
          icon: Icons.school_rounded,
          color: const Color(0xFFF3B13E),
        ),
        CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CyberCardTitle(l10n.t('cyberSafetyScore')),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                l10n
                    .t('progressBadge')
                    .replaceFirst('{percent}', '$displayPercent')
                    .replaceFirst('{badge}', l10n.t(badgeKey)),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF516078)
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ..._topics.map(
            (topic) => CyberCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: CyberCardTitle(topic.title)),
                      if (_completed.contains(topic.id))
                        const Icon(Icons.verified_rounded, color: Color(0xFF2FB79E)),
                    ],
                  ),
                  Text(
                    topic.summary,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF516078)
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...topic.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $tip',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF6B7C95)
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _completeQuiz(topic),
                    icon: const Icon(Icons.quiz_rounded),
                    label: Text(l10n.t('takeQuiz')),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
