import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/widgets/save_feedback_dialog.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class CyberCrimeScreen extends StatefulWidget {
  const CyberCrimeScreen({super.key});

  @override
  State<CyberCrimeScreen> createState() => _CyberCrimeScreenState();
}

class _CyberCrimeScreenState extends State<CyberCrimeScreen> {
  final _service = _CyberProtectionService();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).t('cyberCrimeProtection')), 
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.psychology_rounded), text: AppLocalizations.of(context).t('aiAssist')),
              Tab(icon: Icon(Icons.assignment_rounded), text: AppLocalizations.of(context).t('report')),
              Tab(icon: Icon(Icons.lock_rounded), text: AppLocalizations.of(context).t('vault')),
              Tab(icon: Icon(Icons.school_rounded), text: AppLocalizations.of(context).t('learn')),
              Tab(icon: Icon(Icons.warning_rounded), text: AppLocalizations.of(context).t('deepfake')),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? const [
                      Color(0xFFF7FAFF),
                      Color(0xFFF1F6FF),
                      Color(0xFFEDF3FE),
                    ]
                  : const [
                      Color(0xFF071025),
                      Color(0xFF0A1A35),
                      Color(0xFF08162B),
                    ],
            ),
          ),
          child: TabBarView(
            children: [
              _CyberAssistantTab(service: _service),
              _CyberReportTab(service: _service),
              _EvidenceVaultTab(service: _service),
              _LearningHubTab(service: _service),
              _DeepfakeSupportTab(service: _service),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberProtectionService {
  final Dio _dio = DioClient().dio;

  Future<_ScamAnalysisResult> analyze({
    required String text,
    required String question,
    required List<String> links,
    String extractedText = '',
  }) async {
    final response = await _dio.post(
      ApiConstants.cyberAnalyze,
      data: {
        'text': text,
        'question': question,
        'links': links,
        'extractedText': extractedText,
      },
    );
    return _ScamAnalysisResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<_CyberReportResult> submitReport({
    required String category,
    required String description,
    required String suspectContact,
    required String transactionId,
    required DateTime incidentAt,
    required bool isDraft,
  }) async {
    final response = await _dio.post(
      ApiConstants.cyberReport,
      data: {
        'category': category,
        'description': description,
        'suspectContact': suspectContact,
        'transactionId': transactionId,
        'incidentAt': incidentAt.toUtc().toIso8601String(),
        'isDraft': isDraft,
      },
    );
    return _CyberReportResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<_EvidenceItem>> listEvidence({
    String? category,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiConstants.cyberEvidence,
      queryParameters: {
        if (category != null && category != 'All') 'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => _EvidenceItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> uploadEvidence({
    required XFile file,
    required String title,
    required String category,
    required List<String> tags,
    required bool privateMode,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'category': category,
      'tags': tags.join(','),
      'privateMode': privateMode.toString(),
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    await _dio.post(ApiConstants.cyberEvidenceUpload, data: form);
  }

  Future<List<_LearningTopic>> getLearningContent() async {
    final response = await _dio.get(ApiConstants.cyberLearningContent);
    final data = response.data;
    if (data is! List) return _fallbackLearningTopics;
    return data
        .whereType<Map>()
        .map((item) => _LearningTopic.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveProgress(String topicId, int score) async {
    await _dio.post(
      ApiConstants.cyberLearningProgress,
      data: {'topicId': topicId, 'score': score},
    );
  }

  Future<_DeepfakeResources> getDeepfakeResources() async {
    final response = await _dio.get(ApiConstants.cyberDeepfakeResources);
    return _DeepfakeResources.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class _CyberAssistantTab extends StatefulWidget {
  const _CyberAssistantTab({required this.service});

  final _CyberProtectionService service;

  @override
  State<_CyberAssistantTab> createState() => _CyberAssistantTabState();
}

class _CyberAssistantTabState extends State<_CyberAssistantTab> {
  final _messageController = TextEditingController();
  final _questionController = TextEditingController();
  final _linkController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _screenshot;
  _ScamAnalysisResult? _result;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    _questionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final ok = await _requestGalleryPermission();
    if (!ok || !mounted) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _screenshot = image);
  }

  Future<void> _analyze() async {
    final text = _messageController.text.trim();
    final question = _questionController.text.trim();
    final links = _linkController.text
        .split(RegExp(r'\s+|,'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (text.isEmpty && question.isEmpty && links.isEmpty && _screenshot == null) {
      _showSnack(context, 'Paste a message, link, question, or attach a screenshot.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final result = await widget.service.analyze(
        text: text,
        question: question,
        links: links,
        extractedText: _screenshot == null
            ? ''
            : 'Screenshot attached: ${_screenshot!.name}. OCR text extraction can be connected to a production OCR service.',
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _result = _localAnalyze(text, question, links);
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CyberScroll(
      children: [
        _SectionHeader(
          title: AppLocalizations.of(context).t('aiScamFraudAssistantTitle'),
          subtitle: AppLocalizations.of(context).t('pasteEvidenceContext'),
          icon: Icons.psychology_rounded,
          color: const Color(0xFF8E7CF4),
        ),
        _CyberCard(
          child: Column(
            children: [
              _MultilineInput(
                controller: _messageController,
                label: AppLocalizations.of(context).t('suspiciousMessageLabel'),
                hint: AppLocalizations.of(context).t('pasteFullMessageHereHint'),
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _linkController,
                label: AppLocalizations.of(context).t('suspiciousLinksLabel'),
                hint: AppLocalizations.of(context).t('urlHint'),
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _questionController,
                label: AppLocalizations.of(context).t('askQuestionLabel'),
                hint: AppLocalizations.of(context).t('scamQuestionHint'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickScreenshot,
                      icon: const Icon(Icons.image_rounded),
                      label: Text(
                        _screenshot == null
                            ? 'Attach screenshot'
                            : _screenshot!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyze,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.security_rounded),
                      label: Text(AppLocalizations.of(context).t('analyze')),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null) _WarningBanner(text: _error!),
        if (_result != null) _AnalysisResultCard(result: _result!),
      ],
    );
  }
}

class _CyberReportTab extends StatefulWidget {
  const _CyberReportTab({required this.service});

  final _CyberProtectionService service;

  @override
  State<_CyberReportTab> createState() => _CyberReportTabState();
}

class _CyberReportTabState extends State<_CyberReportTab> {
  static const _categories = [
    'Financial Fraud',
    'Harassment',
    'Blackmail',
    'Fake Profile',
    'Cyber Stalking',
    'Deepfake Threat',
    'Fake Job Scam',
    'UPI Fraud',
  ];

  final _descriptionController = TextEditingController();
  final _suspectController = TextEditingController();
  final _transactionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _evidence = [];
  String _category = _categories.first;
  DateTime _incidentAt = DateTime.now();
  int _step = 0;
  bool _isSubmitting = false;
  _CyberReportResult? _lastReport;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _suspectController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _category = prefs.getString('cyber_wizard_category') ?? _category;
      _descriptionController.text =
          prefs.getString('cyber_wizard_description') ?? '';
      _suspectController.text = prefs.getString('cyber_wizard_suspect') ?? '';
      _transactionController.text =
          prefs.getString('cyber_wizard_transaction') ?? '';
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cyber_wizard_category', _category);
    await prefs.setString(
      'cyber_wizard_description',
      _descriptionController.text.trim(),
    );
    await prefs.setString('cyber_wizard_suspect', _suspectController.text.trim());
    await prefs.setString(
      'cyber_wizard_transaction',
      _transactionController.text.trim(),
    );
    if (!mounted) return;
    await showSaveSuccessDialog(
      context,
      title: 'Draft saved',
      message: 'Your draft has been stored locally on this device.',
    );
  }

  Future<void> _pickEvidence() async {
    final ok = await _requestGalleryPermission();
    if (!ok || !mounted) return;
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) setState(() => _evidence.addAll(files.take(8)));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentAt),
    );
    if (time == null) return;
    setState(() {
      _incidentAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit({required bool draft}) async {
    final description = _descriptionController.text.trim();
    if (!draft && description.length < 10) {
      _showSnack(context, 'Add at least 10 characters of incident details.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final report = await widget.service.submitReport(
        category: _category,
        description: description.isEmpty ? 'Draft report pending details.' : description,
        suspectContact: _suspectController.text.trim(),
        transactionId: _transactionController.text.trim(),
        incidentAt: _incidentAt,
        isDraft: draft,
      );
      if (!mounted) return;
      setState(() {
        _lastReport = report;
        _step = 3;
      });
      _showSnack(context, draft ? AppLocalizations.of(context).t('draftSavedOnline') : AppLocalizations.of(context).t('reportGenerated'));
    } on DioException catch (error) {
      await _saveDraft();
      if (!mounted) return;
      _showSnack(context, 'Could not submit online. ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CyberScroll(
      children: [
        _SectionHeader(
          title: AppLocalizations.of(context).t('report'),
          subtitle: AppLocalizations.of(context).t('reportGenerated'),
          icon: Icons.assignment_rounded,
          color: const Color(0xFF3B82F6),
        ),
        StepProgress(current: _step, labels: [
          AppLocalizations.of(context).t('selectIncidentType'),
          AppLocalizations.of(context).t('incidentDescription'),
          AppLocalizations.of(context).t('attachScreenshotsOrProof'),
          AppLocalizations.of(context).t('summary'),
        ]),
        const SizedBox(height: 14),
        if (_step == 0) _buildTypeStep(),
        if (_step == 1) _buildDetailsStep(),
        if (_step == 2) _buildEvidenceStep(),
        if (_step == 3) _buildSummaryStep(),
      ],
    );
  }

  Widget _buildTypeStep() {
    return _CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Select incident type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _NextButton(onPressed: () => setState(() => _step = 1)),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return _CyberCard(
      child: Column(
        children: [
          _MultilineInput(
            controller: _descriptionController,
            label: 'Incident description',
            hint: 'Describe what happened, usernames, amounts, threats, and platforms.',
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _suspectController,
            label: AppLocalizations.of(context).t('suspectContactLabel'),
            hint: AppLocalizations.of(context).t('suspectContactHint'),
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _transactionController,
            label: AppLocalizations.of(context).t('transactionIdLabel'),
            hint: AppLocalizations.of(context).t('transactionIdHint'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDateTime,
            icon: const Icon(Icons.event_rounded),
            label: Text(AppLocalizations.of(context).t('incidentTime').replaceFirst('{time}', _incidentAt.toLocal().toString().split('.').first)),
          ),
          const SizedBox(height: 16),
          _WizardButtons(
            onBack: () => setState(() => _step = 0),
            onNext: () => setState(() => _step = 2),
            onDraft: _saveDraft,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceStep() {
    return _CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(AppLocalizations.of(context).t('attachScreenshotsOrProof')),
          OutlinedButton.icon(
            onPressed: _pickEvidence,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(AppLocalizations.of(context).t('attachScreenshot')),
          ),
          const SizedBox(height: 8),
          if (_evidence.isEmpty)
            Text(AppLocalizations.of(context).t('noFilesSelectedYet'), style: const TextStyle(color: Colors.white60))
          else
            ..._evidence.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.image_rounded, color: Colors.white70),
                    title: Text(
                      entry.value.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      onPressed: () => setState(() => _evidence.removeAt(entry.key)),
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
            _WizardButtons(
            onBack: () => setState(() => _step = 1),
            onNext: () => _submit(draft: false),
            onDraft: () => _submit(draft: true),
            nextLabel: _isSubmitting ? AppLocalizations.of(context).t('submitting') : AppLocalizations.of(context).t('generate'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    final report = _lastReport;
    return _CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(AppLocalizations.of(context).t('generatedComplaint')),
          Text(
            report?.firStyleReport ?? AppLocalizations.of(context).t('reportSummaryUnavailable'),
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: report == null
                      ? null
                      : () => _showSnack(
                            context,
                            AppLocalizations.of(context).t('pdfPayloadGenerated'),
                          ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(AppLocalizations.of(context).t('pdfReady')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.of(context).t('newReport')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceVaultTab extends StatefulWidget {
  const _EvidenceVaultTab({required this.service});

  final _CyberProtectionService service;

  @override
  State<_EvidenceVaultTab> createState() => _EvidenceVaultTabState();
}

class _EvidenceVaultTabState extends State<_EvidenceVaultTab> {
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _searchController = TextEditingController();
  List<_EvidenceItem> _items = const [];
  String _category = 'Screenshot';
  String _filter = 'All';
  bool _privateMode = false;
  bool _isLoading = true;
  bool _isUploading = false;

  static const _categories = [
    'All',
    'Screenshot',
    'Audio',
    'Threat Message',
    'Image',
    'Transaction Proof',
    'Document',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.service.listEvidence(
        category: _filter,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } on DioException catch (error) {
      if (mounted) _showSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _upload() async {
    final ok = await _requestGalleryPermission();
    if (!ok || !mounted) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final title = _titleController.text.trim().isEmpty
        ? image.name
        : _titleController.text.trim();
    setState(() => _isUploading = true);
    try {
      await widget.service.uploadEvidence(
        file: image,
        title: title,
        category: _category,
        tags: _tagController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        privateMode: _privateMode,
      );
      _titleController.clear();
      _tagController.clear();
      await _load();
      if (mounted) _showSnack(context, 'Evidence encrypted and saved.');
    } on DioException catch (error) {
      if (mounted) _showSnack(context, 'Upload failed. ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CyberScroll(
      children: [
        _SectionHeader(
          title: 'Secure Evidence Vault',
          subtitle: 'Upload, tag, search and package cyber evidence. Backend files are AES encrypted.',
          icon: Icons.lock_rounded,
          color: const Color(0xFF2FB79E),
        ),
        _CyberCard(
          child: Column(
            children: [
              _TextInput(
                controller: _titleController,
                label: AppLocalizations.of(context).t('evidenceTitleLabel'),
                hint: AppLocalizations.of(context).t('evidenceTitleHint'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration(AppLocalizations.of(context).t('category')),
                items: _categories
                    .where((item) => item != 'All')
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).t('private'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: _privateMode,
                      onChanged: (value) => setState(() => _privateMode = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _tagController,
                label: AppLocalizations.of(context).t('tags'),
                hint: AppLocalizations.of(context).t('tagsHint'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: _isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_rounded),
                label: Text(AppLocalizations.of(context).t('uploadEncryptedEvidence')),
              ),
            ],
          ),
        ),
        _CyberCard(
          child: Column(
            children: [
              _TextInput(
                controller: _searchController,
                label: 'Search vault',
                hint: 'Search by title',
                onSubmitted: (_) => _load(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _categories
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: _filter == category,
                        onSelected: (_) {
                          setState(() => _filter = category);
                          unawaited(_load());
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          const _EmptyState(text: 'No evidence found. Upload evidence to start your secure vault.')
        else
          ..._items.map((item) => _EvidenceCard(item: item)),
      ],
    );
  }
}

class _LearningHubTab extends StatefulWidget {
  const _LearningHubTab({required this.service});

  final _CyberProtectionService service;

  @override
  State<_LearningHubTab> createState() => _LearningHubTabState();
}

class _LearningHubTabState extends State<_LearningHubTab> {
  List<_LearningTopic> _topics = _fallbackLearningTopics;
  final Set<String> _completed = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final topics = await widget.service.getLearningContent();
      if (!mounted) return;
      setState(() => _topics = topics.isEmpty ? _fallbackLearningTopics : topics);
    } catch (_) {
      if (mounted) setState(() => _topics = _fallbackLearningTopics);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeQuiz(_LearningTopic topic) async {
    final score = await showDialog<int>(
      context: context,
      builder: (context) => _QuizDialog(topic: topic),
    );
    if (score == null) return;
    setState(() => _completed.add(topic.id));
    try {
      await widget.service.saveProgress(topic.id, score);
    } catch (_) {}
    if (mounted) _showSnack(context, 'Cyber Safety Score: $score');
  }

  @override
  Widget build(BuildContext context) {
    final progress = _topics.isEmpty ? 0.0 : _completed.length / _topics.length;
    return _CyberScroll(
      children: [
        _SectionHeader(
          title: 'Digital Safety Learning Hub',
          subtitle: 'Build skills for phishing, UPI, privacy, stalking prevention and deepfake response.',
          icon: Icons.school_rounded,
          color: const Color(0xFFF3B13E),
        ),
        _CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Cyber Safety Score'),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).t('progressBadge')
                    .replaceFirst('{percent}', '${(progress * 100).round()}')
                    .replaceFirst('{badge}', AppLocalizations.of(context).t(progress >= 1 ? 'cyberDefender' : 'cyberLearner')),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else
          ..._topics.map(
            (topic) => _CyberCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _CardTitle(topic.title)),
                      if (_completed.contains(topic.id))
                        const Icon(Icons.verified_rounded, color: Color(0xFF2FB79E)),
                    ],
                  ),
                  Text(topic.summary, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  ...topic.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('- $tip', style: const TextStyle(color: Colors.white60)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _completeQuiz(topic),
                    icon: const Icon(Icons.quiz_rounded),
                    label: Text(AppLocalizations.of(context).t('takeQuiz')),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DeepfakeSupportTab extends StatefulWidget {
  const _DeepfakeSupportTab({required this.service});

  final _CyberProtectionService service;

  @override
  State<_DeepfakeSupportTab> createState() => _DeepfakeSupportTabState();
}

class _DeepfakeSupportTabState extends State<_DeepfakeSupportTab> {
  _DeepfakeResources _resources = _fallbackDeepfakeResources;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final resources = await widget.service.getDeepfakeResources();
      if (mounted) setState(() => _resources = resources);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _CyberScroll(
      children: [
                _SectionHeader(
          title: _resources.title,
          subtitle: AppLocalizations.of(context).t('deepfakeSubtitle'),
          icon: Icons.warning_rounded,
          color: const Color(0xFFE53935),
        ),
        _WarningBanner(
          text: AppLocalizations.of(context).t('deepfakeWarning'),
        ),
        ..._resources.sections.map(
          (section) => _CyberCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(section.title),
                Text(section.body, style: const TextStyle(color: Colors.white70, height: 1.35)),
              ],
            ),
          ),
        ),
        _CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(AppLocalizations.of(context).t('emergencyActions')),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionButton(label: AppLocalizations.of(context).t('call1930'), icon: Icons.call, onTap: () => _dial('1930')),
                  _ActionButton(label: AppLocalizations.of(context).t('police100'), icon: Icons.local_police_rounded, onTap: () => _dial('100')),
                  _ActionButton(
                    label: AppLocalizations.of(context).t('cyberPortal'),
                    icon: Icons.open_in_new_rounded,
                    onTap: () => _openLink('https://cybercrime.gov.in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScamAnalysisResult {
  final String riskLevel;
  final String threatSummary;
  final List<String> recommendedActions;
  final List<String> safetyTips;

  const _ScamAnalysisResult({
    required this.riskLevel,
    required this.threatSummary,
    required this.recommendedActions,
    required this.safetyTips,
  });

  factory _ScamAnalysisResult.fromJson(Map<String, dynamic> json) {
    return _ScamAnalysisResult(
      riskLevel: json['riskLevel']?.toString() ?? 'LOW',
      threatSummary: json['threatSummary']?.toString() ?? 'No summary available.',
      recommendedActions: (json['recommendedActions'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      safetyTips: (json['safetyTips'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class _CyberReportResult {
  final String id;
  final String firStyleReport;
  final String? pdfBase64;

  const _CyberReportResult({
    required this.id,
    required this.firStyleReport,
    this.pdfBase64,
  });

  factory _CyberReportResult.fromJson(Map<String, dynamic> json) {
    return _CyberReportResult(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
        firStyleReport:
          json['firStyleReport']?.toString() ??
          json['complaintSummary']?.toString() ??
          'Report generated.',
      pdfBase64: json['pdfBase64']?.toString(),
    );
  }
}

class _EvidenceItem {
  final String title;
  final String category;
  final bool encrypted;
  final bool privateMode;
  final DateTime uploadedAt;
  final List<String> tags;

  const _EvidenceItem({
    required this.title,
    required this.category,
    required this.encrypted,
    required this.privateMode,
    required this.uploadedAt,
    required this.tags,
  });

  factory _EvidenceItem.fromJson(Map<String, dynamic> json) {
    return _EvidenceItem(
      title: json['title']?.toString() ?? 'Evidence',
      category: json['category']?.toString() ?? 'Other',
      encrypted: json['encrypted'] != false,
      privateMode: json['privateMode'] == true,
      uploadedAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      tags: (json['tags'] as List? ?? const []).map((item) => item.toString()).toList(),
    );
  }
}

class _LearningTopic {
  final String id;
  final String title;
  final String summary;
  final List<String> tips;
  final List<_QuizQuestion> quiz;

  const _LearningTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.tips,
    required this.quiz,
  });

  factory _LearningTopic.fromJson(Map<String, dynamic> json) {
    return _LearningTopic(
      id: json['id']?.toString() ?? json['title']?.toString() ?? 'topic',
      title: json['title']?.toString() ?? 'Learning Topic',
      summary: json['summary']?.toString() ?? '',
      tips: (json['tips'] as List? ?? const []).map((item) => item.toString()).toList(),
      quiz: (json['quiz'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory _QuizQuestion.fromJson(Map<String, dynamic> json) {
    return _QuizQuestion(
      question: json['question']?.toString() ?? 'Question',
      options: (json['options'] as List? ?? const ['Yes', 'No'])
          .map((item) => item.toString())
          .toList(),
      answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class _DeepfakeResources {
  final String title;
  final List<_InfoSection> sections;

  const _DeepfakeResources({required this.title, required this.sections});

  factory _DeepfakeResources.fromJson(Map<String, dynamic> json) {
    return _DeepfakeResources(
      title: json['title']?.toString() ?? 'Deepfake Awareness',
      sections: (json['sections'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _InfoSection.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class _InfoSection {
  final String title;
  final String body;

  const _InfoSection({required this.title, required this.body});

  factory _InfoSection.fromJson(Map<String, dynamic> json) {
    return _InfoSection(
      title: json['title']?.toString() ?? 'Information',
      body: json['body']?.toString() ?? '',
    );
  }
}

class _CyberScroll extends StatelessWidget {
  const _CyberScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isLight ? 0.14 : 0.24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF5F6F8A) : Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberCard extends StatelessWidget {
  const _CyberCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF8A9FBE).withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: isLight ? const Color(0xFF172235) : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }
}

class _MultilineInput extends StatelessWidget {
  const _MultilineInput({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    hintStyle: const TextStyle(color: Colors.white38),
    labelStyle: const TextStyle(color: Colors.white70),
    fillColor: AppTheme.surfaceSoft.withValues(alpha: 0.72),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.result});

  final _ScamAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel == 'HIGH'
        ? const Color(0xFFE53935)
        : result.riskLevel == 'MEDIUM'
        ? const Color(0xFFF3B13E)
        : const Color(0xFF2FB79E);
    return _CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                'Risk Level: ${result.riskLevel}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(result.threatSummary, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          const _CardTitle('Recommended actions'),
          ...result.recommendedActions.map(
            (action) => Text('- $action', style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 12),
          const _CardTitle('Safety tips'),
          ...result.safetyTips.map(
            (tip) => Text('- $tip', style: const TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.asMap().entries.map((entry) {
        final active = entry.key <= current;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryColor : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                entry.value,
                style: TextStyle(
                  color: active ? AppTheme.primaryColor : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _WizardButtons extends StatelessWidget {
  const _WizardButtons({
    required this.onBack,
    required this.onNext,
    required this.onDraft,
    this.nextLabel = 'Next',
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onDraft;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDraft,
            icon: const Icon(Icons.save_rounded),
            label: Text(AppLocalizations.of(context).t('saveDraft')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(AppLocalizations.of(context).t('continueLabel')),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.item});

  final _EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    return _CyberCard(
      child: Row(
        children: [
          Icon(
            item.privateMode ? Icons.visibility_off_rounded : Icons.insert_drive_file_rounded,
            color: item.encrypted ? const Color(0xFF2FB79E) : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Text(
                  '${item.category} | ${item.encrypted ? 'Encrypted' : 'Not encrypted'} | ${item.uploadedAt.toLocal()}'.split('.').first,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (item.tags.isNotEmpty)
                  Text(item.tags.join(', '), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizDialog extends StatefulWidget {
  const _QuizDialog({required this.topic});

  final _LearningTopic topic;

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topic.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.topic.quiz.asMap().entries.map((entry) {
            final question = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.question, style: const TextStyle(fontWeight: FontWeight.w800)),
                ...question.options.asMap().entries.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _answers[entry.key] == option.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(option.value),
                    onTap: () => setState(() => _answers[entry.key] = option.key),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).t('cancel'))),
        ElevatedButton(
          onPressed: () {
            var correct = 0;
            for (var i = 0; i < widget.topic.quiz.length; i++) {
              if (_answers[i] == widget.topic.quiz[i].answerIndex) correct++;
            }
            final total = widget.topic.quiz.isEmpty ? 1 : widget.topic.quiz.length;
            Navigator.pop(context, ((correct / total) * 100).round());
          },
          child: Text(AppLocalizations.of(context).t('finish')),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
  }
}

Future<bool> _requestGalleryPermission() async {
  var status = await Permission.photos.request();
  if (status.isGranted || status.isLimited) return true;
  status = await Permission.storage.request();
  return status.isGranted;
}

void _showSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _friendlyError(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;
  final message = data is Map ? data['message']?.toString() : null;
  if (message != null && message.isNotEmpty) return message;
  if (status == 401) return 'Please login again to use secure cyber features.';
  if (status == 413) return 'File is too large. Maximum upload size is 10 MB.';
  return 'Network or server issue. Please try again.';
}

_ScamAnalysisResult _localAnalyze(String text, String question, List<String> links) {
  final input = '$text $question ${links.join(' ')}'.toLowerCase();
  var score = 0;
  final reasons = <String>[];
  if (RegExp(r'otp|password|pin|cvv').hasMatch(input)) {
    score += 35;
    reasons.add('Sensitive credential request found.');
  }
  if (RegExp(r'upi|refund|kyc|account.*block').hasMatch(input)) {
    score += 25;
    reasons.add('Payment or account pressure indicators found.');
  }
  if (RegExp(r'blackmail|morphed|leak|viral').hasMatch(input)) {
    score += 35;
    reasons.add('Blackmail/extortion indicators found.');
  }
  final level = score >= 45 ? 'HIGH' : score >= 20 ? 'MEDIUM' : 'LOW';
  return _ScamAnalysisResult(
    riskLevel: level,
    threatSummary: reasons.isEmpty ? 'No strong local indicators found.' : reasons.join(' '),
    recommendedActions: const ['Do not share OTP/passwords', 'Save evidence', 'Verify from official source'],
    safetyTips: const ['Never pay blackmailers', 'Report financial fraud on 1930', 'Block suspicious senders'],
  );
}

Future<void> _dial(String number) async {
  await launchUrl(Uri(scheme: 'tel', path: number), mode: LaunchMode.externalApplication);
}

Future<void> _openLink(String link) async {
  await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
}

final _fallbackLearningTopics = [
  const _LearningTopic(
    id: 'password',
    title: 'Password Safety',
    summary: 'Create strong passwords and protect recovery channels.',
    tips: ['Use a password manager.', 'Enable two-factor authentication.', 'Do not reuse passwords.'],
    quiz: [
      _QuizQuestion(question: 'Is password reuse safe?', options: ['No', 'Yes'], answerIndex: 0),
    ],
  ),
  const _LearningTopic(
    id: 'dating',
    title: 'Online Dating Safety',
    summary: 'Recognize coercion, fake identities and image-based abuse risks.',
    tips: ['Video verify carefully.', 'Do not share intimate media.', 'Meet only in public places.'],
    quiz: [
      _QuizQuestion(question: 'Should you send money to a new online match?', options: ['No', 'Yes'], answerIndex: 0),
    ],
  ),
];

const _fallbackDeepfakeResources = _DeepfakeResources(
  title: 'Deepfake & Morphed Image Emergency Support',
  sections: [
    _InfoSection(
      title: 'What are deepfakes?',
      body: 'Manipulated media that can falsely show a person in fake photos, audio or videos.',
    ),
    _InfoSection(
      title: 'What to do immediately',
      body: 'Save screenshots, URLs and sender IDs. Do not pay or negotiate. Report to cybercrime.gov.in.',
    ),
    _InfoSection(
      title: 'Evidence preservation',
      body: 'Keep original files, timestamps, platform links and transaction details.',
    ),
  ],
);
