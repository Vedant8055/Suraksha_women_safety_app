import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

class POSHLegalPortalScreen extends StatefulWidget {
  const POSHLegalPortalScreen({super.key});

  @override
  State<POSHLegalPortalScreen> createState() => _POSHLegalPortalScreenState();
}

class _POSHLegalPortalScreenState extends State<POSHLegalPortalScreen> {
  static const _progressKey = 'posh_quiz_progress_v1';
  static const _certificateKey = 'posh_certificate_issued_at_v1';
  static const int _passScore = 16;

  final Dio _dio = DioClient().dio;
  final _complainantNameController = TextEditingController();
  final _complainantPhoneController = TextEditingController();
  final _complainantEmailController = TextEditingController();
  final _accusedNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _incidentDateController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _witnessesController = TextEditingController();
  final _detailsController = TextEditingController();

  final Map<int, Map<int, Set<int>>> _answers = {};
  final Set<int> _passedLevels = {};
  final Map<int, int> _bestScores = {};
  final Map<int, int> _attemptCounts = {};

  late final List<_PoshQuizLevel> _levels = _buildPoshQuizLevels();
  bool _submitting = false;
  bool _loadingProgress = true;
  bool _certificateReady = false;
  DateTime? _certificateIssuedAt;
  int _activeLevelIndex = 0;
  int _activeQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProgress());
  }

  @override
  void dispose() {
    _complainantNameController.dispose();
    _complainantPhoneController.dispose();
    _complainantEmailController.dispose();
    _accusedNameController.dispose();
    _companyController.dispose();
    _incidentDateController.dispose();
    _incidentLocationController.dispose();
    _witnessesController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProgress = prefs.getString(_progressKey);
    final certificateMillis = prefs.getInt(_certificateKey);

    if (rawProgress != null && rawProgress.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawProgress);
        if (decoded is Map<String, dynamic>) {
          final passed = (decoded['passedLevels'] as List? ?? const [])
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toSet();
          final bestScores = <int, int>{};
          final attempts = <int, int>{};

          final scoresMap = decoded['bestScores'];
          if (scoresMap is Map) {
            for (final entry in scoresMap.entries) {
              final key = int.tryParse(entry.key.toString());
              final value = int.tryParse(entry.value.toString());
              if (key != null && value != null) {
                bestScores[key] = value;
              }
            }
          }

          final attemptsMap = decoded['attemptCounts'];
          if (attemptsMap is Map) {
            for (final entry in attemptsMap.entries) {
              final key = int.tryParse(entry.key.toString());
              final value = int.tryParse(entry.value.toString());
              if (key != null && value != null) {
                attempts[key] = value;
              }
            }
          }

          setState(() {
            _passedLevels
              ..clear()
              ..addAll(passed);
            _bestScores
              ..clear()
              ..addAll(bestScores);
            _attemptCounts
              ..clear()
              ..addAll(attempts);
          });
        }
      } catch (_) {
        // Ignore corrupted progress and start fresh.
      }
    }

    if (certificateMillis != null) {
      _certificateIssuedAt = DateTime.fromMillisecondsSinceEpoch(certificateMillis);
      _certificateReady = _passedLevels.length == _levels.length;
    }

    if (mounted) {
      setState(() => _loadingProgress = false);
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _progressKey,
      jsonEncode({
        'passedLevels': _passedLevels.toList(),
        'bestScores': _bestScores.map((key, value) => MapEntry(key.toString(), value)),
        'attemptCounts': _attemptCounts.map((key, value) => MapEntry(key.toString(), value)),
      }),
    );
    if (_certificateIssuedAt != null) {
      await prefs.setInt(
        _certificateKey,
        _certificateIssuedAt!.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _submitComplaint() async {
    final l10n = AppLocalizations.of(context);
    final complainantName = _complainantNameController.text.trim();
    final complainantPhone = _complainantPhoneController.text.trim();
    final complainantEmail = _complainantEmailController.text.trim();
    final accusedName = _accusedNameController.text.trim();
    final workplace = _companyController.text.trim();
    final incidentDate = _incidentDateController.text.trim();
    final incidentLocation = _incidentLocationController.text.trim();
    final witnesses = _witnessesController.text.trim();
    final details = _detailsController.text.trim();

    if (complainantName.isEmpty ||
        complainantPhone.isEmpty ||
        accusedName.isEmpty ||
        details.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('pleaseFillAllRequiredDetails'))),
      );
      return;
    }

    final compiledDescription = '''
  POSH Workplace Complaint (Police Filing Intent)
  Complainant: $complainantName
  Phone: $complainantPhone
  Email: ${complainantEmail.isEmpty ? l10n.t('notProvided') : complainantEmail}
  Accused: $accusedName
  Workplace: ${workplace.isEmpty ? l10n.t('notProvided') : workplace}
  Incident Date: ${incidentDate.isEmpty ? l10n.t('notProvided') : incidentDate}
  Incident Location: ${incidentLocation.isEmpty ? l10n.t('notProvided') : incidentLocation}
  Witnesses: ${witnesses.isEmpty ? l10n.t('noneProvided') : witnesses}
  Complaint Details: $details
  ''';

    setState(() => _submitting = true);
    try {
      await _dio.post(
        ApiConstants.incidentReport,
        data: {
          'category': 'POSH Workplace Complaint',
          'description': compiledDescription,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('complaintSubmittedSuccessfully'))),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('submissionFailedTryAgain'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _PoshColors(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('poshPortal')),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.menu_book_rounded), text: l10n.t('study')),
              Tab(icon: Icon(Icons.school_rounded), text: l10n.t('quizzes')),
              Tab(icon: Icon(Icons.assignment_rounded), text: l10n.t('complaint')),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.backgroundGradient,
            ),
          ),
          child: _loadingProgress
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildStudyTab(context),
                    _buildQuizTab(context),
                    _buildComplaintTab(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStudyTab(BuildContext context) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        FadeInDown(
          child: _HeroCard(
            title: l10n.t('poshActLearningHub'),
            subtitle:
                'Study the full framework first, then clear three quiz levels to unlock your certificate.',
            icon: Icons.workspace_premium_rounded,
            accentColor: const Color(0xFF3B82F6),
            child: Column(
              children: [
                _buildProgressRow(context),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: l10n.t('studyFirst'),
                        value: l10n.t('readAllSectionsBeforeQuiz1'),
                        icon: Icons.auto_stories_rounded,
                        color: const Color(0xFF2ED6C5),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        title: l10n.t('threeLevels'),
                        value: l10n.t('twentyMcqsEachQuiz'),
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFFFF9A3D),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildStudySection(
          context,
          number: '1',
          title: l10n.t('poshStudy1Title'),
          icon: Icons.balance_rounded,
          bullets: [
            l10n.t('poshStudy1Bullet1'),
            l10n.t('poshStudy1Bullet2'),
            l10n.t('poshStudy1Bullet3'),
            l10n.t('poshStudy1Bullet4'),
            l10n.t('poshStudy1Bullet5'),
            l10n.t('poshStudy1Bullet6'),
          ],
        ),
        const SizedBox(height: 14),
        _buildStudySection(
          context,
          number: '2',
          title: l10n.t('poshStudy2Title'),
          icon: Icons.rule_folder_rounded,
          bullets: [
            l10n.t('poshStudy2Bullet1'),
            l10n.t('poshStudy2Bullet2'),
            l10n.t('poshStudy2Bullet3'),
            l10n.t('poshStudy2Bullet4'),
            l10n.t('poshStudy2Bullet5'),
            l10n.t('poshStudy2Bullet6'),
          ],
        ),
        const SizedBox(height: 14),
        _buildStudySection(
          context,
          number: '3',
          title: l10n.t('poshStudy3Title'),
          icon: Icons.shield_rounded,
          bullets: [
            l10n.t('poshStudy3Bullet1'),
            l10n.t('poshStudy3Bullet2'),
            l10n.t('poshStudy3Bullet3'),
            l10n.t('poshStudy3Bullet4'),
            l10n.t('poshStudy3Bullet5'),
            l10n.t('poshStudy3Bullet6'),
          ],
        ),
        const SizedBox(height: 14),
        _buildStudySection(
          context,
          number: '4',
          title: l10n.t('poshStudy4Title'),
          icon: Icons.info_outline_rounded,
          bullets: [
            l10n.t('poshStudy4Bullet1'),
            l10n.t('poshStudy4Bullet2'),
            l10n.t('poshStudy4Bullet3'),
            l10n.t('poshStudy4Bullet4'),
            l10n.t('poshStudy4Bullet5'),
            l10n.t('poshStudy4Bullet6'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const POSHActGuideScreen()),
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(AppLocalizations.of(context).t('openDetailedPoshActGuide')),
          ),
        ),
      ],
    );
  }

  Widget _buildStudySection(
    BuildContext context, {
    required String number,
    required String title,
    required IconData icon,
    required List<String> bullets,
  }) {
    return _StudySectionCard(
      number: number,
      title: title,
      icon: icon,
      bullets: bullets,
    );
  }

  Widget _buildQuizTab(BuildContext context) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);
    final totalPassed = _passedLevels.length;
    final allComplete = _certificateReady || totalPassed == _levels.length;
    final currentLevel = _levels[_activeLevelIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _HeroCard(
          title: l10n.t('quizCertificationTrack'),
          subtitle: l10n.t('studyFirstThenClearQuizzesInOrder'),
          icon: Icons.workspace_premium_rounded,
          accentColor: const Color(0xFF8E7CF4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressRow(context),
              const SizedBox(height: 14),
              Text(
                allComplete
                    ? 'All levels cleared. Your certificate is ready.'
                    : l10n.t('studyFirstThenClearQuizzesInOrder'),
                style: TextStyle(color: colors.mutedText, height: 1.3),
              ),
            ],
          ),
        ),
        if (allComplete) ...[
          const SizedBox(height: 14),
          _buildCertificateCard(context),
        ],
        const SizedBox(height: 8),
        _buildLevelSelector(context),
        const SizedBox(height: 8),
        _buildLevelIntroCard(context, currentLevel),
        const SizedBox(height: 14),
        _buildQuestionCard(context, currentLevel, _activeLevelIndex, _activeQuestionIndex),
      ],
    );
  }

  Widget _buildComplaintTab(BuildContext context) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);

    InputDecoration fieldDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.mutedText),
      floatingLabelStyle: const TextStyle(color: AppTheme.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.4),
      ),
      filled: true,
      fillColor: colors.fieldFill,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _HeroCard(
          title: l10n.t('fileWorkplaceComplaint'),
          subtitle: l10n.t('fileWorkplaceComplaintSubtitle'),
          icon: Icons.report_gmailerrorred_rounded,
          accentColor: const Color(0xFFE53935),
          child: Text(
            l10n.t('keepRecordsFactual'),
            style: TextStyle(color: colors.mutedText),
          ),
        ),
        const SizedBox(height: 14),
        _buildComplaintCard(context, fieldDecoration),
      ],
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    InputDecoration Function(String label) fieldDecoration,
  ) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _complainantNameController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('yourFullName')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _complainantPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('yourPhoneNumber')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _complainantEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('yourEmailAddress')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _accusedNameController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('accusedPersonName')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _companyController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('companyWorkplaceName')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _incidentDateController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('incidentDateDdMmYyyy')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _incidentLocationController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('incidentLocation')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _witnessesController,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('witnessesIfAny')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailsController,
            maxLines: 5,
            style: TextStyle(color: colors.text),
            decoration: fieldDecoration(l10n.t('detailedIncidentDescription')),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitComplaint,
              icon: const Icon(Icons.report_gmailerrorred),
              label: Text(_submitting ? l10n.t('submitting') : l10n.t('submitComplaint')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    final colors = _PoshColors(context);
    return Row(
      children: List.generate(_levels.length, (index) {
        final passed = _passedLevels.contains(index);
        final selected = index == _activeLevelIndex;
        final available = index == 0 || _passedLevels.contains(index - 1) || passed;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _levels.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: available
                  ? () => setState(() {
                      _activeLevelIndex = index;
                      _activeQuestionIndex = 0;
                    })
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).t(
                            'clearPreviousQuizToUnlockThisLevel',
                          ),
                        ),
                      ),
                    ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF1D8CF8), Color(0xFF2ED6C5)],
                        )
                      : null,
                  color: selected ? null : colors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: passed
                        ? const Color(0xFF2ED6C5)
                        : selected
                        ? Colors.transparent
                        : colors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      passed
                          ? Icons.check_circle_rounded
                          : available
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      color: selected ? Colors.white : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLocalizations.of(context).t('level')} ${index + 1}',
                      style: TextStyle(
                        color: selected ? Colors.white : colors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passed
                          ? AppLocalizations.of(context).t('passed')
                          : available
                          ? AppLocalizations.of(context).t('available')
                          : AppLocalizations.of(context).t('locked'),
                      style: TextStyle(
                        color: selected ? Colors.white70 : colors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLevelIntroCard(BuildContext context, _PoshQuizLevel level) {
    final colors = _PoshColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.title,
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.summary,
            style: TextStyle(color: colors.mutedText, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SmallPill(label: '${level.questions.length} questions', icon: Icons.quiz_rounded),
              const SizedBox(width: 8),
              _SmallPill(
                label: level.questions.any((q) => q.multiSelect)
                    ? 'Mixed MCQ'
                    : 'Single choice',
                icon: Icons.checklist_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    _PoshQuizLevel level,
    int levelIndex,
    int questionIndex,
  ) {
    final colors = _PoshColors(context);
    final question = level.questions[questionIndex];
    final answerMap = _answers.putIfAbsent(levelIndex, () => {});
    final selected = answerMap.putIfAbsent(questionIndex, () => <int>{});
    final answeredCount = answerMap.values.where((set) => set.isNotEmpty).length;
    final allAnswered = answerMap.length == level.questions.length &&
        answerMap.values.every((set) => set.isNotEmpty);
    final isLast = questionIndex == level.questions.length - 1;
    final isFirst = questionIndex == 0;
    final locked = levelIndex > 0 && !_passedLevels.contains(levelIndex - 1);
    final canProceed = !locked && selected.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${questionIndex + 1} of ${level.questions.length}',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$answeredCount answered',
                style: TextStyle(color: colors.mutedText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...question.options.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnswerOptionTile(
                    label: entry.value,
                    selected: selected.contains(entry.key),
                    multiSelect: question.multiSelect,
                    onTap: () {
                      setState(() {
                        if (question.multiSelect) {
                          if (selected.contains(entry.key)) {
                            selected.remove(entry.key);
                          } else {
                            selected.add(entry.key);
                          }
                        } else {
                          selected
                            ..clear()
                            ..add(entry.key);
                        }
                      });
                    },
                  ),
                ),
              ),
          const SizedBox(height: 4),
          if (locked)
            Text(
              'Unlock the previous level to continue.',
              style: TextStyle(color: colors.mutedText, fontSize: 12),
            ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        const Color(0xFFFDFEFF),
                        const Color(0xFFF2F7FF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.14
                        : 0.05,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isFirst
                            ? null
                            : () => setState(() => _activeQuestionIndex -= 1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context).t('previous')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canProceed
                            ? (isLast
                                ? () => _submitLevel(levelIndex)
                                : () => setState(() => _activeQuestionIndex += 1))
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLast
                              ? AppLocalizations.of(context).t('submitQuiz')
                              : AppLocalizations.of(context).t('next'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _resetLevel(levelIndex),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.24),
                        width: 1.2,
                      ),
                      foregroundColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    label: Text(
                      AppLocalizations.of(context).t('retryQuiz'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                if (!allAnswered) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Answer all questions in this level before submitting.',
                      style: TextStyle(color: colors.mutedText, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (locked) ...[
            const SizedBox(height: 10),
            Text(
              'Unlock the previous level to continue.',
              style: TextStyle(color: colors.mutedText, fontSize: 12),
            ),
          ],
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _submitLevel(int levelIndex) async {
    final level = _levels[levelIndex];
    final answers = _answers[levelIndex] ?? const {};

      if (answers.length != level.questions.length ||
        answers.values.any((set) => set.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('pleaseAnswerEveryQuestionFirst'))),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      var score = 0;
      for (var index = 0; index < level.questions.length; index++) {
        final question = level.questions[index];
        final selected = answers[index] ?? const <int>{};
        if (setEquals(selected, question.correctIndexes)) {
          score += 1;
        }
      }

      _attemptCounts[levelIndex] = (_attemptCounts[levelIndex] ?? 0) + 1;
      _bestScores[levelIndex] = score > (_bestScores[levelIndex] ?? 0)
          ? score
          : _bestScores[levelIndex] ?? score;

      if (score >= _passScore) {
        _passedLevels.add(levelIndex);
        if (levelIndex == _levels.length - 1) {
          _certificateReady = true;
          _certificateIssuedAt ??= DateTime.now();
        }
        await _saveProgress();
        if (!mounted) return;
        await showPremiumDialog<void>(
          context: context,
          title: levelIndex == _levels.length - 1
              ? AppLocalizations.of(context).t('poshCertified')
              : AppLocalizations.of(context).t('levelPassed'),
          message: levelIndex == _levels.length - 1
              ? 'You cleared all three quiz levels and earned your certificate.'
              : 'Great work. The next level is now unlocked.',
          icon: Icons.verified_rounded,
          accentColor: const Color(0xFF2ED6C5),
          actions: [
            PremiumDialogAction(
              label: levelIndex == _levels.length - 1
                  ? AppLocalizations.of(context).t('viewCertificate')
                  : AppLocalizations.of(context).t('continueLabel'),
              isPrimary: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ],
        );
        if (mounted) {
          setState(() {
            _activeLevelIndex = min(levelIndex + 1, _levels.length - 1);
            _activeQuestionIndex = 0;
          });
        }
      } else {
        await _saveProgress();
        if (!mounted) return;
        await showPremiumDialog<void>(
          context: context,
          title: AppLocalizations.of(context).t('quizNotClearedYet'),
          message:
              'You scored $score/${level.questions.length}. Review the study section and retry this level.',
          icon: Icons.refresh_rounded,
          accentColor: const Color(0xFFE53935),
          actions: [
            PremiumDialogAction(
              label: AppLocalizations.of(context).t('reviewStudy'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                DefaultTabController.of(context).animateTo(0);
              },
            ),
            PremiumDialogAction(
              label: AppLocalizations.of(context).t('retry'),
              isPrimary: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ],
        );
        if (mounted) {
          _resetLevel(levelIndex);
          setState(() => _activeQuestionIndex = 0);
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetLevel(int levelIndex) {
    setState(() {
      _answers.remove(levelIndex);
      _activeQuestionIndex = 0;
    });
  }

  Widget _buildCertificateCard(BuildContext context) {
    final colors = _PoshColors(context);
    final issuedAt = _certificateIssuedAt ?? DateTime.now();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D8CF8), Color(0xFF2ED6C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D8CF8).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).t('poshCertified'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).t('poshCertifiedMessage'),
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('certificateDetails'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)
                      .t('issuedOn')
                      .replaceFirst('{date}', issuedAt.toLocal().toString().split('.').first),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).t('validForPoshCertificate'),
                  style: TextStyle(color: colors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector(BuildContext context) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);
    final levelTitle = '${l10n.t('level')} ${_activeLevelIndex + 1}';

    return GestureDetector(
      onTap: () => setState(() => _activeQuestionIndex = 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              levelTitle,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              l10n.t('currentLevel'),
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class POSHActGuideScreen extends StatelessWidget {
  const POSHActGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('detailedPoshActGuide'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GuideIntro(colors: colors, text: l10n.t('guideIntro')),
          const SizedBox(height: 12),
          _GuideSection(title: l10n.t('guide1Title'), body: l10n.t('guide1Body')),
          _GuideSection(title: l10n.t('guide2Title'), body: l10n.t('guide2Body')),
          _GuideSection(title: l10n.t('guide3Title'), body: l10n.t('guide3Body')),
          _GuideSection(title: l10n.t('guide4Title'), body: l10n.t('guide4Body')),
          _GuideSection(title: l10n.t('guide5Title'), body: l10n.t('guide5Body')),
          _GuideSection(title: l10n.t('guide6Title'), body: l10n.t('guide6Body')),
          _GuideSection(title: l10n.t('guide7Title'), body: l10n.t('guide7Body')),
          _GuideSection(title: l10n.t('guide8Title'), body: l10n.t('guide8Body')),
          _GuideSection(title: l10n.t('guide9Title'), body: l10n.t('guide9Body')),
          _GuideSection(title: l10n.t('guide10Title'), body: l10n.t('guide10Body')),
          _GuideSection(title: l10n.t('guide11Title'), body: l10n.t('guide11Body')),
          _GuideSection(title: l10n.t('guide12Title'), body: l10n.t('guide12Body')),
          _GuideSection(title: l10n.t('guide13Title'), body: l10n.t('guide13Body')),
          _GuideSection(title: l10n.t('guide14Title'), body: l10n.t('guide14Body')),
          _GuideSection(title: l10n.t('guide15Title'), body: l10n.t('guide15Body')),
          _GuideSection(title: l10n.t('guide16Title'), body: l10n.t('guide16Body')),
          _GuideSection(title: l10n.t('guide17Title'), body: l10n.t('guide17Body')),
          const SizedBox(height: 12),
          _GuideDisclaimer(text: l10n.t('legalDisclaimer')),
        ],
      ),
    );
  }
}

class _GuideIntro extends StatelessWidget {
  const _GuideIntro({required this.colors, required this.text});

  final _PoshColors colors;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Text(text, style: TextStyle(color: colors.mutedText, height: 1.35)),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      collapsedBackgroundColor: colors.card,
      backgroundColor: colors.card,
      iconColor: AppTheme.primaryColor,
      collapsedIconColor: colors.mutedText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      title: Text(
        title,
        style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Text(body, style: TextStyle(color: colors.mutedText, height: 1.35)),
      ],
    );
  }
}

class _GuideDisclaimer extends StatelessWidget {
  const _GuideDisclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4E2B18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFFE6D5), height: 1.35),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colors.card,
            Color.lerp(colors.card, accentColor, 0.08)!,
            Color.lerp(colors.card, accentColor, 0.14)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: accentColor.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.mutedText,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.colors,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final _PoshColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fieldFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: colors.mutedText, fontSize: 11.5, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _StudySectionCard extends StatelessWidget {
  const _StudySectionCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.bullets,
  });

  final String number;
  final String title;
  final IconData icon;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(icon, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $bullet',
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.fieldFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _PoshColors(context);
    return Material(
      color: colors.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                multiSelect
                    ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                    : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                color: selected ? AppTheme.primaryColor : colors.mutedText,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoshColors {
  final List<Color> backgroundGradient;
  final Color card;
  final Color fieldFill;
  final Color text;
  final Color mutedText;
  final Color border;

  _PoshColors(BuildContext context)
      : backgroundGradient = Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF06111F), Color(0xFF081628), Color(0xFF050B14)]
            : const [Color(0xFFF8FBFF), Color(0xFFF2F7FF), Color(0xFFEAF2FF)],
        card = Theme.of(context).colorScheme.surface,
        fieldFill = Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF1F5FB),
        text = Theme.of(context).colorScheme.onSurface,
        mutedText = Theme.of(context).brightness == Brightness.dark
            ? AppTheme.textSecondary
            : const Color(0xFF4E5F79),
        border = Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFD8E0EC);
}

class _PoshQuizLevel {
  final String title;
  final String summary;
  final List<_PoshQuizQuestion> questions;

  const _PoshQuizLevel({
    required this.title,
    required this.summary,
    required this.questions,
  });
}

class _PoshQuizQuestion {
  final String question;
  final List<String> options;
  final Set<int> correctIndexes;
  final bool multiSelect;

  const _PoshQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndexes,
    this.multiSelect = false,
  });
}

List<_PoshQuizLevel> _buildPoshQuizLevels() {
  return [
    _PoshQuizLevel(
      title: 'Level 1',
      summary:
          'Core POSH Act basics, scope, definitions, committee structure, and what legally counts as harassment.',
      questions: const [
        _PoshQuizQuestion(
          question: 'What is the main objective of the POSH Act?',
          options: [
            'Prevent, prohibit, and redress sexual harassment at the workplace',
            'Regulate salaries and promotions',
            'Manage attendance records',
            'Control office budgets',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'The POSH Act was enacted in which year?',
          options: ['2013', '2008', '2016', '2020'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'POSH protection applies to which kind of workplace?',
          options: [
            'Only government offices',
            'Only private companies',
            'Public and private workplaces, including many work-related settings',
            'Only factories',
          ],
          correctIndexes: {2},
        ),
        _PoshQuizQuestion(
          question: 'Who is protected under the statutory POSH framework?',
          options: [
            'Women at the workplace',
            'Only managers',
            'Only permanent employees',
            'Only customers',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of the following can be workplace context under POSH?',
          options: [
            'Transport provided by the employer',
            'A work-related client visit',
            'A conference or training linked to employment',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'Which of these are forms of sexual harassment?',
          options: [
            'Unwanted sexual remarks',
            'Sexual messages',
            'Role assignment meeting',
            'Showing pornography without consent',
          ],
          correctIndexes: {0, 1, 3},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: 'Which item is a valid example of evidence in a POSH inquiry?',
          options: [
            'Witness statements and communication records',
            'Only attendance logs',
            'Only social media likes',
            'Only lunch menu receipts',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Repeated unwelcome sexual messages can be treated as:',
          options: [
            'Harassment behavior',
            'Normal office communication',
            'Attendance issue only',
            'A payroll issue',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A workplace complaint under POSH should usually be filed in writing within:',
          options: ['3 months', '1 year', '7 days', '6 months'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which committee is required in workplaces with 10 or more employees?',
          options: [
            'Internal Committee',
            'Finance Committee',
            'Sports Committee',
            'Hiring Committee',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which member is usually part of the Internal Committee?',
          options: [
            'Presiding Officer',
            'Chief Accountant',
            'Receptionist only',
            'Security guard only',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'The POSH framework stresses which workplace value most?',
          options: [
            'Equality and dignity',
            'Speed only',
            'Profit only',
            'Ranking only',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which act can be harassment even without physical contact?',
          options: [
            'Sexually colored remarks',
            'Project planning',
            'Code review',
            'Payroll approval',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'What should the complaint ideally contain?',
          options: [
            'Dates, facts, witnesses, and evidence',
            'Only the accused name',
            'Only the company name',
            'Only a short slogan',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of these is covered by the POSH concept of conduct?',
          options: [
            'Verbal, non-verbal, digital, and physical actions',
            'Only written letters',
            'Only in-person touch',
            'Only email spam',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of these should a workplace do?',
          options: [
            'Display its POSH policy',
            'Hide complaint details from everyone including the IC',
            'Avoid awareness training',
            'Ignore committee composition',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Confidentiality under POSH generally includes:',
          options: [
            'Identity of parties and inquiry content',
            'Only the company logo',
            'Only attendance records',
            'Only payroll summaries',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of the following are examples of unwelcome sexual conduct?',
          options: [
            'Unwanted touching',
            'Sexual jokes',
            'Repeated sexual messages',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'What is the purpose of the Internal Committee?',
          options: [
            'Investigate and recommend redressal',
            'Approve appraisals',
            'Manage payroll',
            'Track attendance',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'If someone is in immediate danger, the best first step is to:',
          options: [
            'Call emergency services',
            'Wait for the next day',
            'Ignore the incident',
            'Delete evidence',
          ],
          correctIndexes: {0},
        ),
      ],
    ),
    _PoshQuizLevel(
      title: 'Level 2',
      summary:
          'Complaint filing, conciliation, inquiry steps, interim relief, evidence handling, and fair process.',
      questions: const [
        _PoshQuizQuestion(
          question: 'A POSH complaint is usually filed within how much time?',
          options: ['3 months', '24 hours', '2 years', '15 days'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Can the IC allow an extension of the filing timeline for valid reasons?',
          options: ['Yes', 'No', 'Only for managers', 'Only if the company is large'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Conciliation under POSH should be:',
          options: [
            'Requested voluntarily by the complainant',
            'Forced by the employer',
            'Mandatory in every case',
            'Used only after punishment',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A monetary settlement should:',
          options: [
            'Not be the sole basis of conciliation',
            'Replace the whole inquiry automatically',
            'Be mandatory in every case',
            'End the process before complaint',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A fair inquiry should follow:',
          options: [
            'Natural justice',
            'Secret decisions only',
            'No hearing at all',
            'Only the accused version',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'During inquiry, both sides should:',
          options: [
            'Be heard and allowed to present material',
            'Only sign one paper each',
            'Avoid all evidence',
            'Skip the documentation',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of these can be interim relief?',
          options: [
            'Transfer',
            'No-contact instructions',
            'Reporting-line change',
            'Temporary leave or WFH adjustment',
          ],
          correctIndexes: {0, 1, 2, 3},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: 'Which items should evidence preserve?',
          options: [
            'Original chats and emails',
            'Timestamped screenshots',
            'Witness names and context notes',
            'Only personal opinions',
          ],
          correctIndexes: {0, 1, 2},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: 'A formal POSH complaint can be made:',
          options: [
            'In writing or electronic form, depending on platform and practice',
            'Only by word of mouth',
            'Only by email to friends',
            'Only after the inquiry ends',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which statement about confidentiality is correct?',
          options: [
            'It applies to parties, witnesses, and proceedings',
            'It applies only to the respondent',
            'It does not matter in POSH',
            'It ends as soon as a complaint is drafted',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'If the facts also show a criminal offense, the complainant can:',
          options: [
            'File a police complaint or FIR',
            'Do nothing else',
            'Wait forever for IC only',
            'Delete the report',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of these is not a proper POSH inquiry principle?',
          options: [
            'Secret judgment without hearing',
            'Reasoned findings',
            'Written proceedings',
            'Opportunity to present evidence',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'The complainant can ask for safety measures like:',
          options: [
            'Leave or transfer',
            'No-contact orders',
            'Temporary WFH adjustments',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'Which statement is correct about the IC?',
          options: [
            'It should be properly formed and documented',
            'It can be informal only',
            'It may be skipped if the case is sensitive',
            'It is optional in large workplaces',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A respondent and complainant should ideally receive:',
          options: [
            'A chance to be heard',
            'No opportunity to explain',
            'Only verbal rumors',
            'Only payroll data',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'If a complaint is not proven, that alone means it was:',
          options: [
            'Not automatically false or malicious',
            'Definitely fake',
            'Always punishable',
            'Always criminal',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which is a good complaint practice?',
          options: [
            'Write a factual, date-wise narrative',
            'Use only insults',
            'Delete all proof',
            'Keep the details vague',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Can witnesses be relevant in a POSH case?',
          options: ['Yes', 'No', 'Only if the accused agrees', 'Only after appeal'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'The employer should implement IC recommendations:',
          options: [
            'Within the required timelines',
            'Whenever convenient',
            'Never',
            'Only if the complaint becomes public',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'POSH inquiry records should generally be:',
          options: [
            'Documented and kept confidential',
            'Shared on social media',
            'Destroyed immediately',
            'Kept only in memory',
          ],
          correctIndexes: {0},
        ),
      ],
    ),
    _PoshQuizLevel(
      title: 'Level 3',
      summary:
          'Compliance, penalties, evidence preservation, appeals, misuse boundaries, and practical workplace readiness.',
      questions: const [
        _PoshQuizQuestion(
          question: 'Which workplace action is part of POSH compliance?',
          options: [
            'Conduct regular awareness training',
            'Hide complaint channels',
            'Ignore policy display',
            'Avoid committee formation',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A workplace with 10 or more employees must:',
          options: [
            'Constitute an Internal Committee',
            'Close the complaint channel',
            'Skip training',
            'Ignore POSH obligations',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which member helps bring independence to the IC?',
          options: [
            'External member',
            'Payroll clerk',
            'Intern only',
            'Visitor only',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which can be an employer response after a proved complaint?',
          options: [
            'Warning or counseling',
            'Withholding increment',
            'Termination in appropriate cases',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'Which of these should be preserved as evidence?',
          options: [
            'Original chats and emails',
            'Screenshots with timestamps',
            'Call logs or notes of calls',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'Should complaint confidentiality cover witnesses too?',
          options: ['Yes', 'No', 'Only supervisors', 'Only HR'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A good POSH complaint should avoid:',
          options: [
            'Knowingly fabricated allegations',
            'Factual dates',
            'Real evidence',
            'Witness details',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'If the complaint is not proven, the right legal approach is:',
          options: [
            'Check for deliberate falsehood before calling it malicious',
            'Punish automatically',
            'Ignore all reports',
            'Stop all future complaints',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'A workplace should usually display:',
          options: [
            'Its POSH policy and complaint channel',
            'Only the canteen menu',
            'Only the payroll schedule',
            'Only casual notices',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which of these can be a misuse of POSH?',
          options: [
            'Knowingly fabricated allegations',
            'Factual reporting',
            'Authentic evidence submission',
            'Good-faith complaint filing',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which are good evidence habits?',
          options: [
            'Keep a chronological diary',
            'Save screenshots and originals',
            'Note witnesses and context',
            'Delete chat history',
          ],
          correctIndexes: {0, 1, 2},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: 'Can the complainant seek external legal remedies where allowed?',
          options: ['Yes', 'No', 'Only before complaint', 'Only after 5 years'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Interim relief during inquiry may include:',
          options: [
            'Transfer',
            'No-contact directions',
            'Leave or WFH adjustment',
            'All of the above',
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: 'Employer training under POSH should be:',
          options: [
            'Regular and visible',
            'Optional and hidden',
            'Done once forever',
            'Avoided for privacy',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Appeals or further remedies may exist depending on:',
          options: [
            'Service rules and law',
            'Only office gossip',
            'The weather',
            'The complaint color',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which is an example of criminal conduct that may coexist with POSH?',
          options: [
            'Stalking or assault',
            'Office meeting',
            'Shift planning',
            'Salary approval',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'The POSH portal is best used to:',
          options: [
            'Learn, document, and prepare a structured complaint',
            'Replace all legal advice',
            'Avoid evidence collection',
            'Bypass the IC',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'If there is immediate danger, the best action is to:',
          options: [
            'Call emergency services immediately',
            'Wait for the next appraisal',
            'Hope it stops',
            'Hide the incident',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'Which statement is correct about workplace safety and POSH?',
          options: [
            'Safe work culture requires policy, awareness, and fair inquiry',
            'Policy alone is enough without action',
            'Inquiry is not needed if the case is difficult',
            'Confidentiality means never documenting anything',
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: 'To unlock the certificate, the learner must:',
          options: [
            'Pass all three quiz levels',
            'Only open the guide',
            'Only file a complaint',
            'Only read the app title',
          ],
          correctIndexes: {0},
        ),
      ],
    ),
  ];
}
