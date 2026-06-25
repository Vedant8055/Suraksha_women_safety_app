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

class _POSHLegalPortalScreenState extends State<POSHLegalPortalScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  static const _progressKey = 'posh_quiz_progress_v1';
  static const _certificateKey = 'posh_certificate_issued_at_v1';
  static const int _passScore = 16;
  static const int _quizLevelCount = 3;

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

  bool _submitting = false;
  bool _loadingProgress = true;
  bool _certificateReady = false;
  DateTime? _certificateIssuedAt;
  int _activeLevelIndex = 0;
  int _activeQuestionIndex = 0;

  List<_PoshQuizLevel> get _levels => _buildPoshQuizLevels(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    unawaited(_loadProgress());
  }

  @override
  void dispose() {
    _tabController.dispose();
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

          if (!mounted) return;
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
      _certificateIssuedAt = DateTime.fromMillisecondsSinceEpoch(
        certificateMillis,
      );
      _certificateReady = _passedLevels.length == _quizLevelCount;
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
        'bestScores': _bestScores.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'attemptCounts': _attemptCounts.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      }),
    );
    if (_certificateIssuedAt != null) {
      await prefs.setInt(
        _certificateKey,
        _certificateIssuedAt!.millisecondsSinceEpoch,
      );
    }
  }

  String _extractComplaintErrorMessage(
    DioException error,
    AppLocalizations l10n,
  ) {
    final response = error.response;
    final data = response?.data;
    final statusCode = response?.statusCode;

    String? message;
    if (data is Map) {
      final rawMessage = data['message']?.toString();
      if (rawMessage != null && rawMessage.trim().isNotEmpty) {
        message = rawMessage.trim();
      }

      if (message == 'Validation failed') {
        final details = data['details'];
        if (details is Map) {
          final fieldErrors = details['fieldErrors'];
          if (fieldErrors is Map && fieldErrors.isNotEmpty) {
            final firstEntry = fieldErrors.entries.first;
            final firstError = firstEntry.value;
            if (firstError is List && firstError.isNotEmpty) {
              final firstMessage = firstError.first?.toString().trim();
              if (firstMessage != null && firstMessage.isNotEmpty) {
                return firstMessage;
              }
            }
            final firstMessage = firstError?.toString().trim();
            if (firstMessage != null && firstMessage.isNotEmpty) {
              return firstMessage;
            }
          }

          final formErrors = details['formErrors'];
          if (formErrors is List && formErrors.isNotEmpty) {
            final firstMessage = formErrors.first?.toString().trim();
            if (firstMessage != null && firstMessage.isNotEmpty) {
              return firstMessage;
            }
          }
        }
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The complaint request timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Network connection unavailable. Please check your internet and try again.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Your session expired. Please sign in again to submit a complaint.';
    }

    if (message != null && message.isNotEmpty) {
      return message;
    }

    final errorText = error.error?.toString().trim();
    if (errorText != null && errorText.isNotEmpty) {
      return errorText;
    }

    return l10n.t('submissionFailedTryAgain');
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

    final complaintLines = <String>[
      'POSH Workplace Complaint',
      'Complainant: $complainantName',
      'Phone: $complainantPhone',
      'Email: ${complainantEmail.isEmpty ? l10n.t('notProvided') : complainantEmail}',
      'Accused: $accusedName',
      'Workplace: ${workplace.isEmpty ? l10n.t('notProvided') : workplace}',
      'Incident Date: ${incidentDate.isEmpty ? l10n.t('notProvided') : incidentDate}',
      'Incident Location: ${incidentLocation.isEmpty ? l10n.t('notProvided') : incidentLocation}',
      'Witnesses: ${witnesses.isEmpty ? l10n.t('noneProvided') : witnesses}',
      'Complaint Details: $details',
    ];
    final compiledDescription = complaintLines.join('\n');

    setState(() => _submitting = true);
    try {
      final response = await _dio.post(
        ApiConstants.incidentReport,
        data: {
          'category': 'POSH Workplace Complaint',
          'description': compiledDescription,
        },
      );
      if (mounted &&
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('complaintSubmittedSuccessfully'))),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('submissionFailedTryAgain'))),
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractComplaintErrorMessage(error, l10n))),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('poshPortal')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.menu_book_rounded), text: l10n.t('study')),
            Tab(icon: Icon(Icons.school_rounded), text: l10n.t('quizzes')),
            Tab(
              icon: Icon(Icons.assignment_rounded),
              text: l10n.t('complaint'),
            ),
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
                controller: _tabController,
                children: [
                  _buildStudyTab(context),
                  _buildQuizTab(context),
                  _buildComplaintTab(context),
                ],
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
            label: Text(
              AppLocalizations.of(context).t('openDetailedPoshActGuide'),
            ),
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
        _buildQuestionCard(
          context,
          currentLevel,
          _activeLevelIndex,
          _activeQuestionIndex,
        ),
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
              label: Text(
                _submitting ? l10n.t('submitting') : l10n.t('submitComplaint'),
              ),
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
        final available =
            index == 0 || _passedLevels.contains(index - 1) || passed;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _levels.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: available
                  ? () => setState(() {
                      _activeLevelIndex = index;
                      _activeQuestionIndex = 0;
                    })
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          ).t('clearPreviousQuizToUnlockThisLevel'),
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
              _SmallPill(
                label: '${level.questions.length} questions',
                icon: Icons.quiz_rounded,
              ),
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
    final answeredCount = answerMap.values
        .where((set) => set.isNotEmpty)
        .length;
    final allAnswered =
        answerMap.length == level.questions.length &&
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
                    : [const Color(0xFFFDFEFF), const Color(0xFFF2F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border.withValues(alpha: 0.72)),
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
                                  : () => setState(
                                      () => _activeQuestionIndex += 1,
                                    ))
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).t('pleaseAnswerEveryQuestionFirst'),
          ),
        ),
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
          accentColor: const Color.fromRGBO(229, 57, 53, 1), // Corrected from Color.from
          actions: [
            PremiumDialogAction(
              label: AppLocalizations.of(context).t('reviewStudy'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                // _tabController is owned by this State — no context lookup needed.
                _tabController.animateTo(0); // Navigate to Study tab (index 0)
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
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 34,
          ),
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
                      .replaceFirst(
                        '{date}',
                        issuedAt.toLocal().toString().split('.').first,
                      ),
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
              style: TextStyle(color: colors.mutedText, fontSize: 12),
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
          _GuideSection(
            title: l10n.t('guide1Title'),
            body: l10n.t('guide1Body'),
          ),
          _GuideSection(
            title: l10n.t('guide2Title'),
            body: l10n.t('guide2Body'),
          ),
          _GuideSection(
            title: l10n.t('guide3Title'),
            body: l10n.t('guide3Body'),
          ),
          _GuideSection(
            title: l10n.t('guide4Title'),
            body: l10n.t('guide4Body'),
          ),
          _GuideSection(
            title: l10n.t('guide5Title'),
            body: l10n.t('guide5Body'),
          ),
          _GuideSection(
            title: l10n.t('guide6Title'),
            body: l10n.t('guide6Body'),
          ),
          _GuideSection(
            title: l10n.t('guide7Title'),
            body: l10n.t('guide7Body'),
          ),
          _GuideSection(
            title: l10n.t('guide8Title'),
            body: l10n.t('guide8Body'),
          ),
          _GuideSection(
            title: l10n.t('guide9Title'),
            body: l10n.t('guide9Body'),
          ),
          _GuideSection(
            title: l10n.t('guide10Title'),
            body: l10n.t('guide10Body'),
          ),
          _GuideSection(
            title: l10n.t('guide11Title'),
            body: l10n.t('guide11Body'),
          ),
          _GuideSection(
            title: l10n.t('guide12Title'),
            body: l10n.t('guide12Body'),
          ),
          _GuideSection(
            title: l10n.t('guide13Title'),
            body: l10n.t('guide13Body'),
          ),
          _GuideSection(
            title: l10n.t('guide14Title'),
            body: l10n.t('guide14Body'),
          ),
          _GuideSection(
            title: l10n.t('guide15Title'),
            body: l10n.t('guide15Body'),
          ),
          _GuideSection(
            title: l10n.t('guide16Title'),
            body: l10n.t('guide16Body'),
          ),
          _GuideSection(
            title: l10n.t('guide17Title'),
            body: l10n.t('guide17Body'),
          ),
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
      child: Text(
        text,
        style: TextStyle(color: colors.mutedText, height: 1.35),
      ),
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
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11.5,
              height: 1.25,
            ),
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
                    ? (selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded)
                    : (selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded),
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

List<_PoshQuizLevel> _buildPoshQuizLevels(BuildContext context) {
  String t({required String en, required String hi, required String mr}) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'hi':
        return hi;
      case 'mr':
        return mr;
      default:
        return en;
    }
  }

  return [
    _PoshQuizLevel(
      title: t(en: 'Level 1', hi: 'स्तर 1', mr: 'स्तर 1'),
      summary: t(
        en: 'Core POSH Act basics, scope, definitions, committee structure, and what legally counts as harassment.',
        hi: 'POSH अधिनियम की बुनियादी बातें, दायरा, परिभाषाएँ, समिति की संरचना और कानूनी रूप से क्या उत्पीड़न माना जाता है।',
        mr: 'POSH कायद्याची मूलभूत माहिती, कार्यकक्षा, व्याख्या, समितीची रचना आणि कायदेशीरदृष्ट्या छळ काय मानला जातो.',
      ),
      questions: [
        _PoshQuizQuestion(
          question: t(
            en: 'What is the main objective of the POSH Act?',
            hi: 'POSH अधिनियम का मुख्य उद्देश्य क्या है?',
            mr: 'POSH कायद्याचा मुख्य उद्देश काय आहे?',
          ),
          options: [
            t(
              en: 'Prevent, prohibit, and redress sexual harassment at the workplace',
              hi: 'कार्यस्थल पर यौन उत्पीड़न को रोकना, निषिद्ध करना और उसका निवारण करना',
              mr: 'कामाच्या ठिकाणी लैंगिक छळ रोखणे, प्रतिबंधित करणे आणि त्यावर उपाय करणे',
            ),
            t(
              en: 'Regulate salaries and promotions',
              hi: 'वेतन और पदोन्नति को नियंत्रित करना',
              mr: 'पगार आणि बढती नियंत्रित करणे',
            ),
            t(
              en: 'Manage attendance records',
              hi: 'उपस्थिति रिकॉर्ड प्रबंधित करना',
              mr: 'उपस्थिती नोंदी सांभाळणे',
            ),
            t(
              en: 'Control office budgets',
              hi: 'कार्यालय के बजट को नियंत्रित करना',
              mr: 'कार्यालयाचे बजेट नियंत्रित करणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'The POSH Act was enacted in which year?',
            hi: 'POSH अधिनियम किस वर्ष लागू किया गया था?',
            mr: 'POSH कायदा कोणत्या वर्षी लागू झाला?',
          ),
          options: ['2013', '2008', '2016', '2020'],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'POSH protection applies to which kind of workplace?',
            hi: 'POSH सुरक्षा किस प्रकार के कार्यस्थल पर लागू होती है?',
            mr: 'POSH संरक्षण कोणत्या प्रकारच्या कार्यस्थळी लागू होते?',
          ),
          options: [
            t(
              en: 'Only government offices',
              hi: 'केवल सरकारी कार्यालय',
              mr: 'फक्त सरकारी कार्यालये',
            ),
            t(
              en: 'Only private companies',
              hi: 'केवल निजी कंपनियाँ',
              mr: 'फक्त खासगी कंपन्या',
            ),
            t(
              en: 'Public and private workplaces, including many work-related settings',
              hi: 'सार्वजनिक और निजी कार्यस्थल, जिनमें कई कार्य-संबंधी स्थान शामिल हैं',
              mr: 'सार्वजनिक आणि खासगी कार्यस्थळे, तसेच अनेक कामाशी संबंधित ठिकाणे',
            ),
            t(en: 'Only factories', hi: 'केवल कारखाने', mr: 'फक्त कारखाने'),
          ],
          correctIndexes: {2},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Who is protected under the statutory POSH framework?',
            hi: 'वैधानिक POSH ढांचे के तहत किसे सुरक्षा मिलती है?',
            mr: 'कायदेशीर POSH चौकटीअंतर्गत कोणाचे संरक्षण केले जाते?',
          ),
          options: [
            t(
              en: 'Women at the workplace',
              hi: 'कार्यस्थल पर महिलाएँ',
              mr: 'कार्यस्थळी महिला',
            ),
            t(en: 'Only managers', hi: 'केवल प्रबंधक', mr: 'फक्त व्यवस्थापक'),
            t(
              en: 'Only permanent employees',
              hi: 'केवल स्थायी कर्मचारी',
              mr: 'फक्त कायम कर्मचारी',
            ),
            t(en: 'Only customers', hi: 'केवल ग्राहक', mr: 'फक्त ग्राहक'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of the following can be workplace context under POSH?',
            hi: 'POSH के तहत निम्न में से कौन-सी कार्यस्थल की स्थिति मानी जा सकती है?',
            mr: 'POSH अंतर्गत खालीलपैकी कोणता कार्यस्थळ संदर्भ असू शकतो?',
          ),
          options: [
            t(
              en: 'Transport provided by the employer',
              hi: 'नियोक्ता द्वारा दी गई परिवहन सेवा',
              mr: 'नियोक्त्याने दिलेले परिवहन',
            ),
            t(
              en: 'A work-related client visit',
              hi: 'काम से जुड़ा ग्राहक/क्लाइंट दौरा',
              mr: 'कामाशी संबंधित क्लायंट भेट',
            ),
            t(
              en: 'A conference or training linked to employment',
              hi: 'नौकरी से जुड़ा सम्मेलन या प्रशिक्षण',
              mr: 'नोकरीशी संबंधित परिषद किंवा प्रशिक्षण',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these are forms of sexual harassment?',
            hi: 'निम्न में से कौन-सी यौन उत्पीड़न की श्रेणियाँ हैं?',
            mr: 'खालीलपैकी कोणत्या लैंगिक छळाच्या स्वरूपात येतात?',
          ),
          options: [
            t(
              en: 'Unwanted sexual remarks',
              hi: 'अनचाही यौन टिप्पणियाँ',
              mr: 'अनिच्छित लैंगिक टिप्पणी',
            ),
            t(en: 'Sexual messages', hi: 'यौन संदेश', mr: 'लैंगिक संदेश'),
            t(
              en: 'Role assignment meeting',
              hi: 'भूमिका निर्धारण बैठक',
              mr: 'भूमिका वाटप बैठक',
            ),
            t(
              en: 'Showing pornography without consent',
              hi: 'बिना सहमति अश्लील सामग्री दिखाना',
              mr: 'संमतीशिवाय अश्लील साहित्य दाखवणे',
            ),
          ],
          correctIndexes: {0, 1, 3},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which item is a valid example of evidence in a POSH inquiry?',
            hi: 'POSH जाँच में साक्ष्य का वैध उदाहरण कौन-सा है?',
            mr: 'POSH चौकशीत पुराव्याचे वैध उदाहरण कोणते?',
          ),
          options: [
            t(
              en: 'Witness statements and communication records',
              hi: 'गवाहों के बयान और संचार रिकॉर्ड',
              mr: 'साक्षींची विधाने आणि संवाद नोंदी',
            ),
            t(
              en: 'Only attendance logs',
              hi: 'केवल उपस्थिति लॉग',
              mr: 'फक्त उपस्थिती नोंदी',
            ),
            t(
              en: 'Only social media likes',
              hi: 'केवल सोशल मीडिया लाइक',
              mr: 'फक्त सोशल मीडिया लाईक',
            ),
            t(
              en: 'Only lunch menu receipts',
              hi: 'केवल लंच मेनू रसीदें',
              mr: 'फक्त जेवणाच्या बिलाच्या पावत्या',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Repeated unwelcome sexual messages can be treated as:',
            hi: 'बार-बार भेजे गए अनचाहे यौन संदेशों को क्या माना जा सकता है?',
            mr: 'वारंवार पाठवलेले अनिच्छित लैंगिक संदेश कसे मानले जाऊ शकतात?',
          ),
          options: [
            t(
              en: 'Harassment behavior',
              hi: 'उत्पीड़न व्यवहार',
              mr: 'छळ वर्तन',
            ),
            t(
              en: 'Normal office communication',
              hi: 'सामान्य कार्यालयी संवाद',
              mr: 'सामान्य कार्यालयीन संवाद',
            ),
            t(
              en: 'Attendance issue only',
              hi: 'केवल उपस्थिति समस्या',
              mr: 'फक्त उपस्थितीची समस्या',
            ),
            t(
              en: 'A payroll issue',
              hi: 'वेतन संबंधी समस्या',
              mr: 'पगाराशी संबंधित समस्या',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A workplace complaint under POSH should usually be filed in writing within:',
            hi: 'POSH के तहत कार्यस्थल शिकायत आमतौर पर कितने समय के भीतर लिखित रूप में दाखिल की जानी चाहिए?',
            mr: 'POSH अंतर्गत कार्यस्थळ तक्रार साधारणपणे किती वेळेत लेखी स्वरूपात द्यावी?',
          ),
          options: [
            t(en: '3 months', hi: '3 महीने', mr: '3 महिने'),
            t(en: '1 year', hi: '1 वर्ष', mr: '1 वर्ष'),
            t(en: '7 days', hi: '7 दिन', mr: '7 दिवस'),
            t(en: '6 months', hi: '6 महीने', mr: '6 महिने'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which committee is required in workplaces with 10 or more employees?',
            hi: '10 या अधिक कर्मचारियों वाले कार्यस्थलों में कौन-सी समिति आवश्यक है?',
            mr: '10 किंवा अधिक कर्मचारी असलेल्या कार्यस्थळांमध्ये कोणती समिती आवश्यक आहे?',
          ),
          options: [
            t(
              en: 'Internal Committee',
              hi: 'आंतरिक समिति',
              mr: 'अंतर्गत समिती',
            ),
            t(en: 'Finance Committee', hi: 'वित्त समिति', mr: 'वित्त समिती'),
            t(en: 'Sports Committee', hi: 'खेल समिति', mr: 'क्रीडा समिती'),
            t(en: 'Hiring Committee', hi: 'भर्ती समिति', mr: 'भरती समिती'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which member is usually part of the Internal Committee?',
            hi: 'आंतरिक समिति का सामान्य सदस्य कौन होता है?',
            mr: 'अंतर्गत समितीचा सहसा कोणता सदस्य असतो?',
          ),
          options: [
            t(
              en: 'Presiding Officer',
              hi: 'अध्यक्ष अधिकारी',
              mr: 'अध्यक्ष अधिकारी',
            ),
            t(en: 'Chief Accountant', hi: 'मुख्य लेखाकार', mr: 'मुख्य लेखापाल'),
            t(
              en: 'Receptionist only',
              hi: 'केवल रिसेप्शनिस्ट',
              mr: 'फक्त रिसेप्शनिस्ट',
            ),
            t(
              en: 'Security guard only',
              hi: 'केवल सुरक्षा गार्ड',
              mr: 'फक्त सुरक्षा रक्षक',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'The POSH framework stresses which workplace value most?',
            hi: 'POSH ढाँचा कार्यस्थल पर किस मूल्य पर सबसे अधिक जोर देता है?',
            mr: 'POSH चौकट कार्यस्थळी कोणत्या मूल्यावर सर्वाधिक भर देते?',
          ),
          options: [
            t(
              en: 'Equality and dignity',
              hi: 'समानता और गरिमा',
              mr: 'समता आणि प्रतिष्ठा',
            ),
            t(en: 'Speed only', hi: 'केवल गति', mr: 'फक्त वेग'),
            t(en: 'Profit only', hi: 'केवल लाभ', mr: 'फक्त नफा'),
            t(en: 'Ranking only', hi: 'केवल रैंकिंग', mr: 'फक्त क्रमवारी'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which act can be harassment even without physical contact?',
            hi: 'बिना शारीरिक संपर्क के भी कौन-सा कृत्य उत्पीड़न हो सकता है?',
            mr: 'शारीरिक संपर्क नसतानाही कोणते कृत्य छळ ठरू शकते?',
          ),
          options: [
            t(
              en: 'Sexually colored remarks',
              hi: 'यौन-रंग वाली टिप्पणियाँ',
              mr: 'लैंगिक छटा असलेल्या टिप्पणी',
            ),
            t(
              en: 'Project planning',
              hi: 'प्रोजेक्ट योजना',
              mr: 'प्रकल्प नियोजन',
            ),
            t(en: 'Code review', hi: 'कोड समीक्षा', mr: 'कोड पुनरावलोकन'),
            t(en: 'Payroll approval', hi: 'वेतन स्वीकृति', mr: 'पगार मंजुरी'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'What should the complaint ideally contain?',
            hi: 'शिकायत में आदर्श रूप से क्या होना चाहिए?',
            mr: 'तक्रारीत आदर्शपणे काय असावे?',
          ),
          options: [
            t(
              en: 'Dates, facts, witnesses, and evidence',
              hi: 'तारीखें, तथ्य, गवाह और साक्ष्य',
              mr: 'तारखा, तथ्य, साक्षी आणि पुरावे',
            ),
            t(
              en: 'Only the accused name',
              hi: 'केवल आरोपी का नाम',
              mr: 'फक्त आरोपीचे नाव',
            ),
            t(
              en: 'Only the company name',
              hi: 'केवल कंपनी का नाम',
              mr: 'फक्त कंपनीचे नाव',
            ),
            t(
              en: 'Only a short slogan',
              hi: 'केवल एक छोटा नारा',
              mr: 'फक्त एक छोटा नारा',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these is covered by the POSH concept of conduct?',
            hi: 'POSH में आचरण की अवधारणा के अंतर्गत क्या आता है?',
            mr: 'POSH मधील वर्तन संकल्पनेत काय समाविष्ट आहे?',
          ),
          options: [
            t(
              en: 'Verbal, non-verbal, digital, and physical actions',
              hi: 'मौखिक, अमौखिक, डिजिटल और शारीरिक आचरण',
              mr: 'तोंडी, अदृश्य, डिजिटल आणि शारीरिक कृती',
            ),
            t(
              en: 'Only written letters',
              hi: 'केवल लिखित पत्र',
              mr: 'फक्त लिखित पत्रे',
            ),
            t(
              en: 'Only in-person touch',
              hi: 'केवल प्रत्यक्ष स्पर्श',
              mr: 'फक्त प्रत्यक्ष स्पर्श',
            ),
            t(
              en: 'Only email spam',
              hi: 'केवल ईमेल स्पैम',
              mr: 'फक्त ईमेल स्पॅम',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these should a workplace do?',
            hi: 'कार्यस्थल को इनमें से क्या करना चाहिए?',
            mr: 'कार्यस्थळाने खालीलपैकी काय करावे?',
          ),
          options: [
            t(
              en: 'Display its POSH policy',
              hi: 'अपनी POSH नीति प्रदर्शित करे',
              mr: 'आपले POSH धोरण दर्शवावे',
            ),
            t(
              en: 'Hide complaint details from everyone including the IC',
              hi: 'आईसी सहित सभी से शिकायत विवरण छिपाए',
              mr: 'अंतर्गत समितीसह सर्वांपासून तक्रारीचे तपशील लपवावे',
            ),
            t(
              en: 'Avoid awareness training',
              hi: 'जागरूकता प्रशिक्षण से बचे',
              mr: 'जागरूकता प्रशिक्षण टाळावे',
            ),
            t(
              en: 'Ignore committee composition',
              hi: 'समिति की संरचना को अनदेखा करे',
              mr: 'समितीची रचना दुर्लक्षित करावी',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Confidentiality under POSH generally includes:',
            hi: 'POSH के तहत गोपनीयता में सामान्यतः क्या शामिल होता है?',
            mr: 'POSH अंतर्गत गोपनीयतेत सामान्यतः काय समाविष्ट असते?',
          ),
          options: [
            t(
              en: 'Identity of parties and inquiry content',
              hi: 'पक्षकारों की पहचान और जाँच की सामग्री',
              mr: 'पक्षकारांची ओळख आणि चौकशीची सामग्री',
            ),
            t(
              en: 'Only the company logo',
              hi: 'केवल कंपनी का लोगो',
              mr: 'फक्त कंपनीचा लोगो',
            ),
            t(
              en: 'Only attendance records',
              hi: 'केवल उपस्थिति रिकॉर्ड',
              mr: 'फक्त उपस्थिती नोंदी',
            ),
            t(
              en: 'Only payroll summaries',
              hi: 'केवल वेतन सारांश',
              mr: 'फक्त पगाराचे सारांश',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of the following are examples of unwelcome sexual conduct?',
            hi: 'निम्न में से कौन-से अनचाहे यौन आचरण के उदाहरण हैं?',
            mr: 'खालीलपैकी कोणती अनिच्छित लैंगिक वर्तनाची उदाहरणे आहेत?',
          ),
          options: [
            t(
              en: 'Unwanted touching',
              hi: 'अनचाहा स्पर्श',
              mr: 'अनिच्छित स्पर्श',
            ),
            t(en: 'Sexual jokes', hi: 'यौन चुटकुले', mr: 'लैंगिक विनोद'),
            t(
              en: 'Repeated sexual messages',
              hi: 'बार-बार यौन संदेश',
              mr: 'वारंवार लैंगिक संदेश',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'What is the purpose of the Internal Committee?',
            hi: 'आंतरिक समिति का उद्देश्य क्या है?',
            mr: 'अंतर्गत समितीचा उद्देश काय आहे?',
          ),
          options: [
            t(
              en: 'Investigate and recommend redressal',
              hi: 'जाँच करना और निवारण की सिफारिश करना',
              mr: 'चौकशी करून उपाय सुचवणे',
            ),
            t(
              en: 'Approve appraisals',
              hi: 'मूल्यांकन स्वीकृत करना',
              mr: 'मूल्यमापन मंजूर करणे',
            ),
            t(en: 'Manage payroll', hi: 'वेतन प्रबंधन', mr: 'पगार व्यवस्थापन'),
            t(
              en: 'Track attendance',
              hi: 'उपस्थिति ट्रैक करना',
              mr: 'उपस्थितीची नोंद ठेवणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'If someone is in immediate danger, the best first step is to:',
            hi: 'यदि कोई व्यक्ति तुरंत खतरे में है, तो सबसे पहला कदम क्या होना चाहिए?',
            mr: 'जर कुणी तातडीच्या धोक्यात असेल, तर पहिला उत्तम टप्पा काय आहे?',
          ),
          options: [
            t(
              en: 'Call emergency services',
              hi: 'आपातकालीन सेवाओं को कॉल करें',
              mr: 'आपत्कालीन सेवांना कॉल करा',
            ),
            t(
              en: 'Wait for the next day',
              hi: 'अगले दिन तक प्रतीक्षा करें',
              mr: 'पुढच्या दिवसाची वाट पाहा',
            ),
            t(
              en: 'Ignore the incident',
              hi: 'घटना को अनदेखा करें',
              mr: 'घटनेकडे दुर्लक्ष करा',
            ),
            t(en: 'Delete evidence', hi: 'साक्ष्य मिटाएँ', mr: 'पुरावे हटवा'),
          ],
          correctIndexes: {0},
        ),
      ],
    ),
    _PoshQuizLevel(
      title: t(en: 'Level 2', hi: 'स्तर 2', mr: 'स्तर 2'),
      summary: t(
        en: 'Complaint filing, conciliation, inquiry steps, interim relief, evidence handling, and fair process.',
        hi: 'शिकायत दाखिल करना, सुलह, जाँच की प्रक्रिया, अंतरिम राहत, साक्ष्य संभालना और निष्पक्ष प्रक्रिया।',
        mr: 'तक्रार दाखल करणे, समेट, चौकशीची पावले, तात्पुरता दिलासा, पुरावे हाताळणे आणि न्याय्य प्रक्रिया.',
      ),
      questions: [
        _PoshQuizQuestion(
          question: t(
            en: 'A POSH complaint is usually filed within how much time?',
            hi: 'POSH शिकायत आमतौर पर कितने समय के भीतर दाखिल की जाती है?',
            mr: 'POSH तक्रार साधारणपणे किती वेळेत दाखल केली जाते?',
          ),
          options: [
            t(en: '3 months', hi: '3 महीने', mr: '3 महिने'),
            t(en: '24 hours', hi: '24 घंटे', mr: '24 तास'),
            t(en: '2 years', hi: '2 वर्ष', mr: '2 वर्षे'),
            t(en: '15 days', hi: '15 दिन', mr: '15 दिवस'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Can the IC allow an extension of the filing timeline for valid reasons?',
            hi: 'क्या IC वैध कारणों से शिकायत दाखिल करने की समय-सीमा बढ़ा सकता है?',
            mr: 'वैध कारणांसाठी IC तक्रार दाखल करण्याच्या मुदतीत वाढ देऊ शकते का?',
          ),
          options: [
            t(en: 'Yes', hi: 'हाँ', mr: 'हो'),
            t(en: 'No', hi: 'नहीं', mr: 'नाही'),
            t(
              en: 'Only for managers',
              hi: 'केवल प्रबंधकों के लिए',
              mr: 'फक्त व्यवस्थापकांसाठी',
            ),
            t(
              en: 'Only if the company is large',
              hi: 'केवल अगर कंपनी बड़ी हो',
              mr: 'फक्त कंपनी मोठी असेल तर',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Conciliation under POSH should be:',
            hi: 'POSH के तहत सुलह कैसी होनी चाहिए?',
            mr: 'POSH अंतर्गत समेट कसा असावा?',
          ),
          options: [
            t(
              en: 'Requested voluntarily by the complainant',
              hi: 'शिकायतकर्ता द्वारा स्वेच्छा से अनुरोधित',
              mr: 'तक्रारदाराने स्वेच्छेने मागितलेले',
            ),
            t(
              en: 'Forced by the employer',
              hi: 'नियोक्ता द्वारा थोपी गई',
              mr: 'नियोक्त्याने लादलेली',
            ),
            t(
              en: 'Mandatory in every case',
              hi: 'हर मामले में अनिवार्य',
              mr: 'प्रत्येक प्रकरणात अनिवार्य',
            ),
            t(
              en: 'Used only after punishment',
              hi: 'सिर्फ दंड के बाद उपयोग',
              mr: 'फक्त शिक्षेनंतर वापरणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A monetary settlement should:',
            hi: 'मौद्रिक समझौता कैसा होना चाहिए?',
            mr: 'आर्थिक सेटलमेंट कसा असावा?',
          ),
          options: [
            t(
              en: 'Not be the sole basis of conciliation',
              hi: 'सुलह का एकमात्र आधार न हो',
              mr: 'समेटीचा एकमेव आधार नसावा',
            ),
            t(
              en: 'Replace the whole inquiry automatically',
              hi: 'पूरी जाँच को स्वतः बदल दे',
              mr: 'संपूर्ण चौकशी आपोआप बदलावी',
            ),
            t(
              en: 'Be mandatory in every case',
              hi: 'हर मामले में अनिवार्य हो',
              mr: 'प्रत्येक प्रकरणात अनिवार्य असावे',
            ),
            t(
              en: 'End the process before complaint',
              hi: 'शिकायत से पहले प्रक्रिया समाप्त कर दे',
              mr: 'तक्रारीपूर्वी प्रक्रिया संपवावी',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A fair inquiry should follow:',
            hi: 'निष्पक्ष जाँच किस सिद्धांत का पालन करे?',
            mr: 'न्याय्य चौकशीने कशाचे पालन करावे?',
          ),
          options: [
            t(
              en: 'Natural justice',
              hi: 'प्राकृतिक न्याय',
              mr: 'नैसर्गिक न्याय',
            ),
            t(
              en: 'Secret decisions only',
              hi: 'केवल गुप्त निर्णय',
              mr: 'फक्त गुप्त निर्णय',
            ),
            t(
              en: 'No hearing at all',
              hi: 'कोई सुनवाई नहीं',
              mr: 'कोणतीही सुनावणी नाही',
            ),
            t(
              en: 'Only the accused version',
              hi: 'केवल आरोपी का पक्ष',
              mr: 'फक्त आरोपीची बाजू',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'During inquiry, both sides should:',
            hi: 'जाँच के दौरान दोनों पक्षों को क्या मिलना चाहिए?',
            mr: 'चौकशीदरम्यान दोन्ही बाजूंना काय मिळाले पाहिजे?',
          ),
          options: [
            t(
              en: 'Be heard and allowed to present material',
              hi: 'सुनवाई और सामग्री प्रस्तुत करने का अवसर मिले',
              mr: 'ऐकून घेणे आणि पुरावे सादर करण्याची संधी मिळावी',
            ),
            t(
              en: 'Only sign one paper each',
              hi: 'केवल एक कागज़ पर हस्ताक्षर करें',
              mr: 'फक्त एक कागद स्वाक्षरी करा',
            ),
            t(
              en: 'Avoid all evidence',
              hi: 'सभी साक्ष्यों से बचें',
              mr: 'सर्व पुरावे टाळा',
            ),
            t(
              en: 'Skip the documentation',
              hi: 'दस्तावेजीकरण छोड़ दें',
              mr: 'दस्तऐवजीकरण टाळा',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these can be interim relief?',
            hi: 'निम्न में से क्या अंतरिम राहत हो सकती है?',
            mr: 'खालीलपैकी कोणता तात्पुरता दिलासा असू शकतो?',
          ),
          options: [
            t(en: 'Transfer', hi: 'स्थानांतरण', mr: 'बदली'),
            t(
              en: 'No-contact instructions',
              hi: 'संपर्क निषेध निर्देश',
              mr: 'संपर्क न करण्याच्या सूचना',
            ),
            t(
              en: 'Reporting-line change',
              hi: 'रिपोर्टिंग लाइन में बदलाव',
              mr: 'रिपोर्टिंग लाइन बदलणे',
            ),
            t(
              en: 'Temporary leave or WFH adjustment',
              hi: 'अस्थायी छुट्टी या घर से काम समायोजन',
              mr: 'तात्पुरती रजा किंवा घरून कामाची सोय',
            ),
          ],
          correctIndexes: {0, 1, 2, 3},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which items should evidence preserve?',
            hi: 'साक्ष्य में क्या सुरक्षित रखा जाना चाहिए?',
            mr: 'पुराव्यांमध्ये काय जपले पाहिजे?',
          ),
          options: [
            t(
              en: 'Original chats and emails',
              hi: 'मूल चैट और ईमेल',
              mr: 'मूळ चॅट आणि ईमेल',
            ),
            t(
              en: 'Timestamped screenshots',
              hi: 'समय-चिह्नित स्क्रीनशॉट',
              mr: 'वेळेसह स्क्रीनशॉट',
            ),
            t(
              en: 'Witness names and context notes',
              hi: 'गवाहों के नाम और संदर्भ नोट',
              mr: 'साक्षींची नावे आणि संदर्भ नोंदी',
            ),
            t(
              en: 'Only personal opinions',
              hi: 'केवल व्यक्तिगत राय',
              mr: 'फक्त वैयक्तिक मते',
            ),
          ],
          correctIndexes: {0, 1, 2},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A formal POSH complaint can be made:',
            hi: 'औपचारिक POSH शिकायत किस रूप में की जा सकती है?',
            mr: 'औपचारिक POSH तक्रार कशी करता येते?',
          ),
          options: [
            t(
              en: 'In writing or electronic form, depending on platform and practice',
              hi: 'लिखित या इलेक्ट्रॉनिक रूप में, प्लेटफ़ॉर्म और प्रक्रिया के अनुसार',
              mr: 'लेखी किंवा इलेक्ट्रॉनिक स्वरूपात, मंच आणि पद्धतीनुसार',
            ),
            t(
              en: 'Only by word of mouth',
              hi: 'केवल मौखिक रूप से',
              mr: 'फक्त तोंडी',
            ),
            t(
              en: 'Only by email to friends',
              hi: 'केवल दोस्तों को ईमेल करके',
              mr: 'फक्त मित्रांना ईमेल करून',
            ),
            t(
              en: 'Only after the inquiry ends',
              hi: 'केवल जाँच समाप्त होने के बाद',
              mr: 'फक्त चौकशी संपल्यावर',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which statement about confidentiality is correct?',
            hi: 'गोपनीयता के बारे में कौन-सा कथन सही है?',
            mr: 'गोपनीयतेबद्दल कोणते विधान बरोबर आहे?',
          ),
          options: [
            t(
              en: 'It applies to parties, witnesses, and proceedings',
              hi: 'यह पक्षकारों, गवाहों और प्रक्रिया पर लागू होती है',
              mr: 'ती पक्षकार, साक्षी आणि कार्यवाहीवर लागू होते',
            ),
            t(
              en: 'It applies only to the respondent',
              hi: 'यह केवल प्रतिवादी पर लागू होती है',
              mr: 'ती फक्त प्रतिवादीवर लागू होते',
            ),
            t(
              en: 'It does not matter in POSH',
              hi: 'POSH में इसका कोई महत्व नहीं',
              mr: 'POSH मध्ये त्याचा काही फरक पडत नाही',
            ),
            t(
              en: 'It ends as soon as a complaint is drafted',
              hi: 'शिकायत तैयार होते ही यह खत्म हो जाती है',
              mr: 'तक्रार तयार होताच ती संपते',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'If the facts also show a criminal offense, the complainant can:',
            hi: 'यदि तथ्यों से आपराधिक अपराध भी दिखता है, तो शिकायतकर्ता क्या कर सकता है?',
            mr: 'तथ्यांवरून गुन्हाही दिसत असेल तर तक्रारदार काय करू शकतो?',
          ),
          options: [
            t(
              en: 'File a police complaint or FIR',
              hi: 'पुलिस शिकायत या FIR दर्ज करे',
              mr: 'पोलीस तक्रार किंवा FIR दाखल करावी',
            ),
            t(en: 'Do nothing else', hi: 'कुछ और न करे', mr: 'काहीही करू नये'),
            t(
              en: 'Wait forever for IC only',
              hi: 'सिर्फ IC के लिए अनंत प्रतीक्षा करे',
              mr: 'फक्त IC साठी अनंत वाट पाहावी',
            ),
            t(
              en: 'Delete the report',
              hi: 'रिपोर्ट मिटा दे',
              mr: 'अहवाल हटवावा',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these is not a proper POSH inquiry principle?',
            hi: 'निम्न में से कौन-सा उचित POSH जाँच सिद्धांत नहीं है?',
            mr: 'खालीलपैकी कोणता योग्य POSH चौकशी तत्त्व नाही?',
          ),
          options: [
            t(
              en: 'Secret judgment without hearing',
              hi: 'बिना सुनवाई के गुप्त निर्णय',
              mr: 'सुनावणीशिवाय गुप्त निर्णय',
            ),
            t(
              en: 'Reasoned findings',
              hi: 'तर्कसंगत निष्कर्ष',
              mr: 'कारणयुक्त निष्कर्ष',
            ),
            t(
              en: 'Written proceedings',
              hi: 'लिखित कार्यवाही',
              mr: 'लेखी कार्यवाही',
            ),
            t(
              en: 'Opportunity to present evidence',
              hi: 'साक्ष्य प्रस्तुत करने का अवसर',
              mr: 'पुरावे सादर करण्याची संधी',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'The complainant can ask for safety measures like:',
            hi: 'शिकायतकर्ता निम्न जैसी सुरक्षा माँग सकता है:',
            mr: 'तक्रारदार खालीलप्रमाणे सुरक्षा उपाय मागू शकतो:',
          ),
          options: [
            t(
              en: 'Leave or transfer',
              hi: 'छुट्टी या स्थानांतरण',
              mr: 'रजा किंवा बदली',
            ),
            t(
              en: 'No-contact orders',
              hi: 'संपर्क निषेध आदेश',
              mr: 'संपर्क न करण्याचे आदेश',
            ),
            t(
              en: 'Temporary WFH adjustments',
              hi: 'अस्थायी घर से काम समायोजन',
              mr: 'तात्पुरते घरून कामाचे बदल',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which statement is correct about the IC?',
            hi: 'IC के बारे में कौन-सा कथन सही है?',
            mr: 'IC बद्दल कोणते विधान बरोबर आहे?',
          ),
          options: [
            t(
              en: 'It should be properly formed and documented',
              hi: 'इसे उचित रूप से गठित और दस्तावेजीकृत होना चाहिए',
              mr: 'ते योग्यरित्या गठीत व दस्तऐवजीकृत असावे',
            ),
            t(
              en: 'It can be informal only',
              hi: 'यह केवल अनौपचारिक हो सकता है',
              mr: 'ते फक्त अनौपचारिक असू शकते',
            ),
            t(
              en: 'It may be skipped if the case is sensitive',
              hi: 'यदि मामला संवेदनशील हो तो इसे छोड़ा जा सकता है',
              mr: 'प्रकरण संवेदनशील असेल तर ते वगळता येते',
            ),
            t(
              en: 'It is optional in large workplaces',
              hi: 'बड़े कार्यस्थलों में यह वैकल्पिक है',
              mr: 'मोठ्या कार्यस्थळांमध्ये ते ऐच्छिक आहे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A respondent and complainant should ideally receive:',
            hi: 'प्रतिवादी और शिकायतकर्ता को आदर्श रूप से क्या मिलना चाहिए?',
            mr: 'प्रतिवादी आणि तक्रारदाराला आदर्शपणे काय मिळाले पाहिजे?',
          ),
          options: [
            t(
              en: 'A chance to be heard',
              hi: 'सुने जाने का अवसर',
              mr: 'ऐकून घेण्याची संधी',
            ),
            t(
              en: 'No opportunity to explain',
              hi: 'समझाने का कोई अवसर नहीं',
              mr: 'स्पष्टीकरणाची संधी नाही',
            ),
            t(
              en: 'Only verbal rumors',
              hi: 'केवल मौखिक अफवाहें',
              mr: 'फक्त तोंडी अफवा',
            ),
            t(
              en: 'Only payroll data',
              hi: 'केवल वेतन डेटा',
              mr: 'फक्त पगाराची माहिती',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'If a complaint is not proven, that alone means it was:',
            hi: 'यदि शिकायत सिद्ध नहीं होती, तो क्या वह स्वयं ही क्या साबित करती है?',
            mr: 'तक्रार सिद्ध झाली नाही तर केवळ त्याचा अर्थ काय?',
          ),
          options: [
            t(
              en: 'Not automatically false or malicious',
              hi: 'यह अपने आप झूठी या दुर्भावनापूर्ण नहीं होती',
              mr: 'ती आपोआप खोटी किंवा दुष्ट हेतूची नसते',
            ),
            t(
              en: 'Definitely fake',
              hi: 'निश्चित रूप से झूठी',
              mr: 'नक्कीच बनावट',
            ),
            t(en: 'Always punishable', hi: 'हमेशा दंडनीय', mr: 'नेहमी दंडनीय'),
            t(
              en: 'Always criminal',
              hi: 'हमेशा आपराधिक',
              mr: 'नेहमी गुन्हेगारी',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which is a good complaint practice?',
            hi: 'शिकायत की अच्छी प्रक्रिया कौन-सी है?',
            mr: 'चांगली तक्रार पद्धत कोणती?',
          ),
          options: [
            t(
              en: 'Write a factual, date-wise narrative',
              hi: 'तथ्यात्मक और तारीख़वार विवरण लिखें',
              mr: 'तथ्याधारित, तारखेनुसार निवेदन लिहा',
            ),
            t(
              en: 'Use only insults',
              hi: 'केवल अपशब्दों का प्रयोग करें',
              mr: 'फक्त शिवीगाळ करा',
            ),
            t(
              en: 'Delete all proof',
              hi: 'सारे प्रमाण मिटा दें',
              mr: 'सर्व पुरावे हटवा',
            ),
            t(
              en: 'Keep the details vague',
              hi: 'विवरण अस्पष्ट रखें',
              mr: 'तपशील धूसर ठेवा',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Can witnesses be relevant in a POSH case?',
            hi: 'POSH मामले में गवाह प्रासंगिक हो सकते हैं?',
            mr: 'POSH प्रकरणात साक्षी महत्त्वाचे ठरू शकतात का?',
          ),
          options: [
            t(en: 'Yes', hi: 'हाँ', mr: 'हो'),
            t(en: 'No', hi: 'नहीं', mr: 'नाही'),
            t(
              en: 'Only if the accused agrees',
              hi: 'केवल यदि आरोपी सहमत हो',
              mr: 'फक्त आरोपी मान्य असेल तर',
            ),
            t(
              en: 'Only after appeal',
              hi: 'केवल अपील के बाद',
              mr: 'फक्त अपीलनंतर',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'The employer should implement IC recommendations:',
            hi: 'नियोक्ता को IC की सिफारिशें कब लागू करनी चाहिए?',
            mr: 'नियोक्त्याने IC च्या शिफारसी कधी अंमलात आणाव्यात?',
          ),
          options: [
            t(
              en: 'Within the required timelines',
              hi: 'निर्धारित समय-सीमा के भीतर',
              mr: 'ठरलेल्या कालमर्यादेत',
            ),
            t(
              en: 'Whenever convenient',
              hi: 'जब सुविधाजनक हो',
              mr: 'सोयीचे वाटेल तेव्हा',
            ),
            t(en: 'Never', hi: 'कभी नहीं', mr: 'कधीच नाही'),
            t(
              en: 'Only if the complaint becomes public',
              hi: 'केवल यदि शिकायत सार्वजनिक हो जाए',
              mr: 'फक्त तक्रार सार्वजनिक झाल्यास',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'POSH inquiry records should generally be:',
            hi: 'POSH जाँच रिकॉर्ड सामान्यतः कैसे होने चाहिए?',
            mr: 'POSH चौकशी नोंदी सामान्यतः कशा असाव्यात?',
          ),
          options: [
            t(
              en: 'Documented and kept confidential',
              hi: 'दस्तावेजीकृत और गोपनीय रखे जाएँ',
              mr: 'नोंदवलेल्या आणि गोपनीय ठेवलेल्या',
            ),
            t(
              en: 'Shared on social media',
              hi: 'सोशल मीडिया पर साझा किए जाएँ',
              mr: 'सोशल मीडियावर शेअर कराव्यात',
            ),
            t(
              en: 'Destroyed immediately',
              hi: 'तुरंत नष्ट कर दिए जाएँ',
              mr: 'ताबडतोब नष्ट कराव्यात',
            ),
            t(
              en: 'Kept only in memory',
              hi: 'केवल याद में रखे जाएँ',
              mr: 'फक्त स्मरणात ठेवाव्यात',
            ),
          ],
          correctIndexes: {0},
        ),
      ],
    ),
    _PoshQuizLevel(
      title: t(en: 'Level 3', hi: 'स्तर 3', mr: 'स्तर 3'),
      summary: t(
        en: 'Compliance, penalties, evidence preservation, appeals, misuse boundaries, and practical workplace readiness.',
        hi: 'अनुपालन, दंड, साक्ष्य संरक्षण, अपील, दुरुपयोग की सीमाएँ और कार्यस्थल की व्यावहारिक तैयारी।',
        mr: 'अनुपालन, शिक्षा, पुरावे जपणे, अपील, गैरवापराच्या मर्यादा आणि कार्यस्थळाची व्यावहारिक तयारी.',
      ),
      questions: [
        _PoshQuizQuestion(
          question: t(
            en: 'Which workplace action is part of POSH compliance?',
            hi: 'कौन-सी कार्यस्थल गतिविधि POSH अनुपालन का हिस्सा है?',
            mr: 'कोणती कार्यस्थळ कृती POSH अनुपालनाचा भाग आहे?',
          ),
          options: [
            t(
              en: 'Conduct regular awareness training',
              hi: 'नियमित जागरूकता प्रशिक्षण आयोजित करना',
              mr: 'नियमित जागरूकता प्रशिक्षण घेणे',
            ),
            t(
              en: 'Hide complaint channels',
              hi: 'शिकायत चैनल छिपाना',
              mr: 'तक्रार चॅनेल लपवणे',
            ),
            t(
              en: 'Ignore policy display',
              hi: 'नीति प्रदर्शन को अनदेखा करना',
              mr: 'धोरण दाखवणे दुर्लक्षित करणे',
            ),
            t(
              en: 'Avoid committee formation',
              hi: 'समिति गठन से बचना',
              mr: 'समिती तयार करणे टाळणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A workplace with 10 or more employees must:',
            hi: '10 या अधिक कर्मचारियों वाले कार्यस्थल को क्या करना होगा?',
            mr: '10 किंवा अधिक कर्मचारी असलेल्या कार्यस्थळाने काय करणे आवश्यक आहे?',
          ),
          options: [
            t(
              en: 'Constitute an Internal Committee',
              hi: 'आंतरिक समिति गठित करना',
              mr: 'अंतर्गत समिती स्थापन करणे',
            ),
            t(
              en: 'Close the complaint channel',
              hi: 'शिकायत चैनल बंद करना',
              mr: 'तक्रार चॅनेल बंद करणे',
            ),
            t(
              en: 'Skip training',
              hi: 'प्रशिक्षण छोड़ना',
              mr: 'प्रशिक्षण टाळणे',
            ),
            t(
              en: 'Ignore POSH obligations',
              hi: 'POSH दायित्वों को अनदेखा करना',
              mr: 'POSH जबाबदाऱ्या दुर्लक्षित करणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which member helps bring independence to the IC?',
            hi: 'IC में स्वतंत्रता लाने में कौन-सा सदस्य मदद करता है?',
            mr: 'IC ला स्वायत्तता देण्यासाठी कोणता सदस्य मदत करतो?',
          ),
          options: [
            t(en: 'External member', hi: 'बाहरी सदस्य', mr: 'बाह्य सदस्य'),
            t(en: 'Payroll clerk', hi: 'वेतन लिपिक', mr: 'पगार लिपिक'),
            t(en: 'Intern only', hi: 'केवल इंटर्न', mr: 'फक्त इंटर्न'),
            t(en: 'Visitor only', hi: 'केवल आगंतुक', mr: 'फक्त भेट देणारा'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which can be an employer response after a proved complaint?',
            hi: 'सिद्ध शिकायत के बाद नियोक्ता की प्रतिक्रिया क्या हो सकती है?',
            mr: 'सिद्ध तक्रारीनंतर नियोक्त्याचा प्रतिसाद काय असू शकतो?',
          ),
          options: [
            t(
              en: 'Warning or counseling',
              hi: 'चेतावनी या परामर्श',
              mr: 'इशारा किंवा समुपदेशन',
            ),
            t(
              en: 'Withholding increment',
              hi: 'वेतनवृद्धि रोकना',
              mr: 'वाढ रोखणे',
            ),
            t(
              en: 'Termination in appropriate cases',
              hi: 'उचित मामलों में बर्खास्तगी',
              mr: 'योग्य प्रकरणात सेवासमाप्ती',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these should be preserved as evidence?',
            hi: 'निम्न में से क्या साक्ष्य के रूप में सुरक्षित रखा जाना चाहिए?',
            mr: 'खालीलपैकी काय पुरावा म्हणून जपले पाहिजे?',
          ),
          options: [
            t(
              en: 'Original chats and emails',
              hi: 'मूल चैट और ईमेल',
              mr: 'मूळ चॅट आणि ईमेल',
            ),
            t(
              en: 'Screenshots with timestamps',
              hi: 'समय-चिह्नित स्क्रीनशॉट',
              mr: 'वेळेसह स्क्रीनशॉट',
            ),
            t(
              en: 'Call logs or notes of calls',
              hi: 'कॉल लॉग या कॉल नोट्स',
              mr: 'कॉल लॉग किंवा कॉल नोंदी',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Should complaint confidentiality cover witnesses too?',
            hi: 'क्या शिकायत की गोपनीयता में गवाह भी शामिल होने चाहिए?',
            mr: 'तक्रारीची गोपनीयता साक्षीदारांपर्यंतही असावी का?',
          ),
          options: [
            t(en: 'Yes', hi: 'हाँ', mr: 'हो'),
            t(en: 'No', hi: 'नहीं', mr: 'नाही'),
            t(
              en: 'Only supervisors',
              hi: 'केवल पर्यवेक्षक',
              mr: 'फक्त पर्यवेक्षक',
            ),
            t(en: 'Only HR', hi: 'केवल HR', mr: 'फक्त HR'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A good POSH complaint should avoid:',
            hi: 'एक अच्छी POSH शिकायत में क्या नहीं होना चाहिए?',
            mr: 'चांगल्या POSH तक्रारीत काय टाळले पाहिजे?',
          ),
          options: [
            t(
              en: 'Knowingly fabricated allegations',
              hi: 'जानबूझकर गढ़े गए आरोप',
              mr: 'जाणीवपूर्वक बनावट आरोप',
            ),
            t(
              en: 'Factual dates',
              hi: 'तथ्यात्मक तारीखें',
              mr: 'तथ्याधारित तारखा',
            ),
            t(en: 'Real evidence', hi: 'वास्तविक साक्ष्य', mr: 'खरे पुरावे'),
            t(
              en: 'Witness details',
              hi: 'गवाहों का विवरण',
              mr: 'साक्षींचे तपशील',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'If the complaint is not proven, the right legal approach is:',
            hi: 'यदि शिकायत सिद्ध नहीं होती, तो सही कानूनी दृष्टिकोण क्या है?',
            mr: 'तक्रार सिद्ध झाली नाही तर योग्य कायदेशीर पद्धत कोणती?',
          ),
          options: [
            t(
              en: 'Check for deliberate falsehood before calling it malicious',
              hi: 'दुर्भावनापूर्ण कहने से पहले जानबूझकर झूठ की जाँच करें',
              mr: 'दुष्ट हेतू म्हणण्यापूर्वी जाणूनबुजून खोटेपणाची तपासणी करा',
            ),
            t(
              en: 'Punish automatically',
              hi: 'स्वतः ही दंडित करें',
              mr: 'आपोआप शिक्षा द्या',
            ),
            t(
              en: 'Ignore all reports',
              hi: 'सभी रिपोर्टों को अनदेखा करें',
              mr: 'सर्व अहवाल दुर्लक्षित करा',
            ),
            t(
              en: 'Stop all future complaints',
              hi: 'भविष्य की सभी शिकायतें रोक दें',
              mr: 'पुढील सर्व तक्रारी थांबवा',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'A workplace should usually display:',
            hi: 'कार्यस्थल को सामान्यतः क्या प्रदर्शित करना चाहिए?',
            mr: 'कार्यस्थळाने सामान्यतः काय दर्शवावे?',
          ),
          options: [
            t(
              en: 'Its POSH policy and complaint channel',
              hi: 'अपनी POSH नीति और शिकायत चैनल',
              mr: 'आपले POSH धोरण आणि तक्रार चॅनेल',
            ),
            t(
              en: 'Only the canteen menu',
              hi: 'केवल कैंटीन मेनू',
              mr: 'फक्त कॅन्टीन मेनू',
            ),
            t(
              en: 'Only the payroll schedule',
              hi: 'केवल वेतन समय-सारणी',
              mr: 'फक्त पगार वेळापत्रक',
            ),
            t(
              en: 'Only casual notices',
              hi: 'केवल सामान्य नोटिस',
              mr: 'फक्त सामान्य सूचना',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which of these can be a misuse of POSH?',
            hi: 'निम्न में से POSH का दुरुपयोग क्या हो सकता है?',
            mr: 'खालीलपैकी POSH चा गैरवापर कोणता ठरू शकतो?',
          ),
          options: [
            t(
              en: 'Knowingly fabricated allegations',
              hi: 'जानबूझकर गढ़े गए आरोप',
              mr: 'जाणीवपूर्वक बनावट आरोप',
            ),
            t(
              en: 'Factual reporting',
              hi: 'तथ्यात्मक रिपोर्टिंग',
              mr: 'तथ्याधारित अहवाल',
            ),
            t(
              en: 'Authentic evidence submission',
              hi: 'प्रामाणिक साक्ष्य जमा करना',
              mr: 'खरे पुरावे सादर करणे',
            ),
            t(
              en: 'Good-faith complaint filing',
              hi: 'सद्भावना से शिकायत दाखिल करना',
              mr: 'सद्भावनेने तक्रार दाखल करणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which are good evidence habits?',
            hi: 'साक्ष्य रखने की अच्छी आदतें कौन-सी हैं?',
            mr: 'पुरावे जपण्याच्या चांगल्या सवयी कोणत्या?',
          ),
          options: [
            t(
              en: 'Keep a chronological diary',
              hi: 'क्रमानुसार डायरी रखें',
              mr: 'कालानुक्रमिक नोंद ठेवा',
            ),
            t(
              en: 'Save screenshots and originals',
              hi: 'स्क्रीनशॉट और मूल प्रति सुरक्षित रखें',
              mr: 'स्क्रीनशॉट आणि मूळ जपा',
            ),
            t(
              en: 'Note witnesses and context',
              hi: 'गवाहों और संदर्भ को नोट करें',
              mr: 'साक्षी आणि संदर्भ नोंदवा',
            ),
            t(
              en: 'Delete chat history',
              hi: 'चैट इतिहास मिटा दें',
              mr: 'चॅट इतिहास हटवा',
            ),
          ],
          correctIndexes: {0, 1, 2},
          multiSelect: true,
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Can the complainant seek external legal remedies where allowed?',
            hi: 'जहाँ अनुमति हो, क्या शिकायतकर्ता बाहरी कानूनी उपाय ले सकता है?',
            mr: 'जिथे परवानगी असेल तिथे तक्रारदार बाह्य कायदेशीर उपाय शोधू शकतो का?',
          ),
          options: [
            t(en: 'Yes', hi: 'हाँ', mr: 'हो'),
            t(en: 'No', hi: 'नहीं', mr: 'नाही'),
            t(
              en: 'Only before complaint',
              hi: 'केवल शिकायत से पहले',
              mr: 'फक्त तक्रारीपूर्वी',
            ),
            t(
              en: 'Only after 5 years',
              hi: 'केवल 5 साल बाद',
              mr: 'फक्त 5 वर्षांनंतर',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Interim relief during inquiry may include:',
            hi: 'जाँच के दौरान अंतरिम राहत में क्या शामिल हो सकता है?',
            mr: 'चौकशीदरम्यान तात्पुरत्या दिलशात काय असू शकते?',
          ),
          options: [
            t(en: 'Transfer', hi: 'स्थानांतरण', mr: 'बदली'),
            t(
              en: 'No-contact directions',
              hi: 'संपर्क न करने के निर्देश',
              mr: 'संपर्क न करण्याच्या सूचना',
            ),
            t(
              en: 'Leave or WFH adjustment',
              hi: 'छुट्टी या घर से काम समायोजन',
              mr: 'रजा किंवा घरून कामाची सोय',
            ),
            t(en: 'All of the above', hi: 'उपरोक्त सभी', mr: 'वरील सर्व'),
          ],
          correctIndexes: {3},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Employer training under POSH should be:',
            hi: 'POSH के तहत नियोक्ता प्रशिक्षण कैसा होना चाहिए?',
            mr: 'POSH अंतर्गत नियोक्ता प्रशिक्षण कसे असावे?',
          ),
          options: [
            t(
              en: 'Regular and visible',
              hi: 'नियमित और स्पष्ट',
              mr: 'नियमित आणि दृश्यमान',
            ),
            t(
              en: 'Optional and hidden',
              hi: 'वैकल्पिक और छिपा हुआ',
              mr: 'ऐच्छिक आणि लपवलेले',
            ),
            t(
              en: 'Done once forever',
              hi: 'एक बार करके हमेशा के लिए',
              mr: 'एकदाच करून कायमचे',
            ),
            t(
              en: 'Avoided for privacy',
              hi: 'गोपनीयता के नाम पर टाला जाए',
              mr: 'गोपनीयतेसाठी टाळले जावे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Appeals or further remedies may exist depending on:',
            hi: 'अपील या आगे के उपाय किस पर निर्भर हो सकते हैं?',
            mr: 'अपील किंवा पुढील उपाय कशावर अवलंबून असू शकतात?',
          ),
          options: [
            t(
              en: 'Service rules and law',
              hi: 'सेवा नियम और कानून',
              mr: 'सेवा नियम आणि कायदा',
            ),
            t(
              en: 'Only office gossip',
              hi: 'केवल कार्यालयी अफवाह',
              mr: 'फक्त कार्यालयीन चर्चा',
            ),
            t(en: 'The weather', hi: 'मौसम', mr: 'हवामान'),
            t(
              en: 'The complaint color',
              hi: 'शिकायत का रंग',
              mr: 'तक्रारीचा रंग',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which is an example of criminal conduct that may coexist with POSH?',
            hi: 'निम्न में से कौन-सा आपराधिक आचरण POSH के साथ भी हो सकता है?',
            mr: 'POSH सोबत सहअस्तित्वात असू शकणारे गुन्हेगारी वर्तन कोणते?',
          ),
          options: [
            t(
              en: 'Stalking or assault',
              hi: 'पीछा करना या हमला',
              mr: 'पीछा करणे किंवा हल्ला',
            ),
            t(en: 'Office meeting', hi: 'कार्यालय बैठक', mr: 'कार्यालयीन बैठक'),
            t(en: 'Shift planning', hi: 'शिफ्ट योजना', mr: 'शिफ्ट नियोजन'),
            t(en: 'Salary approval', hi: 'वेतन स्वीकृति', mr: 'पगार मंजुरी'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'The POSH portal is best used to:',
            hi: 'POSH पोर्टल का सर्वोत्तम उपयोग क्या है?',
            mr: 'POSH पोर्टलचा सर्वोत्तम वापर काय आहे?',
          ),
          options: [
            t(
              en: 'Learn, document, and prepare a structured complaint',
              hi: 'सीखना, दस्तावेज़ करना और संरचित शिकायत तैयार करना',
              mr: 'शिकणे, दस्तऐवजीकरण करणे आणि संरचित तक्रार तयार करणे',
            ),
            t(
              en: 'Replace all legal advice',
              hi: 'सारी कानूनी सलाह को बदलना',
              mr: 'सर्व कायदेशीर सल्ल्याची जागा घेणे',
            ),
            t(
              en: 'Avoid evidence collection',
              hi: 'साक्ष्य इकट्ठा करने से बचना',
              mr: 'पुरावे गोळा करणे टाळणे',
            ),
            t(
              en: 'Bypass the IC',
              hi: 'IC को दरकिनार करना',
              mr: 'IC ला बगल देणे',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'If there is immediate danger, the best action is to:',
            hi: 'यदि तुरंत खतरा है, तो सबसे अच्छा कदम क्या है?',
            mr: 'तातडीचा धोका असल्यास सर्वोत्तम कृती काय आहे?',
          ),
          options: [
            t(
              en: 'Call emergency services immediately',
              hi: 'तुरंत आपातकालीन सेवाओं को कॉल करें',
              mr: 'ताबडतोब आपत्कालीन सेवांना कॉल करा',
            ),
            t(
              en: 'Wait for the next appraisal',
              hi: 'अगले मूल्यांकन तक प्रतीक्षा करें',
              mr: 'पुढील मूल्यमापनाची वाट पाहा',
            ),
            t(
              en: 'Hope it stops',
              hi: 'उम्मीद करें कि यह रुक जाए',
              mr: 'ते थांबेल अशी आशा ठेवा',
            ),
            t(en: 'Hide the incident', hi: 'घटना छिपा दें', mr: 'घटना लपवा'),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'Which statement is correct about workplace safety and POSH?',
            hi: 'कार्यस्थल सुरक्षा और POSH के बारे में कौन-सा कथन सही है?',
            mr: 'कार्यस्थळ सुरक्षा आणि POSH बद्दल कोणते विधान बरोबर आहे?',
          ),
          options: [
            t(
              en: 'Safe work culture requires policy, awareness, and fair inquiry',
              hi: 'सुरक्षित कार्य संस्कृति के लिए नीति, जागरूकता और निष्पक्ष जाँच आवश्यक है',
              mr: 'सुरक्षित कार्यसंस्कृतीसाठी धोरण, जागरूकता आणि न्याय्य चौकशी आवश्यक आहे',
            ),
            t(
              en: 'Policy alone is enough without action',
              hi: 'सिर्फ नीति काफी है, कार्रवाई नहीं',
              mr: 'फक्त धोरण पुरेसे आहे, कृतीची गरज नाही',
            ),
            t(
              en: 'Inquiry is not needed if the case is difficult',
              hi: 'यदि मामला कठिन हो तो जाँच की जरूरत नहीं',
              mr: 'प्रकरण कठीण असेल तर चौकशीची गरज नाही',
            ),
            t(
              en: 'Confidentiality means never documenting anything',
              hi: 'गोपनीयता का मतलब कुछ भी दस्तावेज़ न करना',
              mr: 'गोपनीयतेचा अर्थ काहीही नोंदवू नये',
            ),
          ],
          correctIndexes: {0},
        ),
        _PoshQuizQuestion(
          question: t(
            en: 'To unlock the certificate, the learner must:',
            hi: 'प्रमाणपत्र अनलॉक करने के लिए सीखने वाले को क्या करना होगा?',
            mr: 'प्रमाणपत्र उघडण्यासाठी शिकणाऱ्याने काय करावे?',
          ),
          options: [
            t(
              en: 'Pass all three quiz levels',
              hi: 'तीनों क्विज़ स्तर पास करें',
              mr: 'तिन्ही क्विझ स्तर पास करा',
            ),
            t(
              en: 'Only open the guide',
              hi: 'सिर्फ गाइड खोलें',
              mr: 'फक्त मार्गदर्शक उघडा',
            ),
            t(
              en: 'Only file a complaint',
              hi: 'सिर्फ शिकायत दर्ज करें',
              mr: 'फक्त तक्रार दाखल करा',
            ),
            t(
              en: 'Only read the app title',
              hi: 'सिर्फ ऐप का शीर्षक पढ़ें',
              mr: 'फक्त अॅपचे शीर्षक वाचा',
            ),
          ],
          correctIndexes: {0},
        ),
      ],
    ),
  ];
}
