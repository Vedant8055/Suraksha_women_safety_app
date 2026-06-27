import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_constants.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/report_detail_screen.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/backend_connectivity.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cyber_multi_select_dropdown.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/core/network/backend_url_resolver.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/widgets/save_feedback_dialog.dart';

class CyberReportTab extends StatefulWidget {
  const CyberReportTab({
    super.key,
    required this.service,
    required this.onApiError,
  });

  final CyberProtectionService service;
  final Future<bool> Function(DioException error) onApiError;

  @override
  State<CyberReportTab> createState() => _CyberReportTabState();
}

class _CyberReportTabState extends State<CyberReportTab> {
  final _descriptionController = TextEditingController();
  final _suspectController = TextEditingController();
  final _transactionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _evidence = [];
  final Set<String> _vaultEvidenceIds = {};
  Set<String> _selectedCategories = {
    CybercrimeConstants.reportCategories.first,
  };
  String get _category => _selectedCategories.isEmpty
      ? CybercrimeConstants.reportCategories.first
      : _selectedCategories.first;
  DateTime _incidentAt = DateTime.now();
  int _step = 0;
  bool _isSubmitting = false;
  bool _backendUnreachable = false;
  double? _uploadProgress;
  int _uploadCurrent = 0;
  int _uploadTotal = 0;
  CyberReportResult? _lastReport;
  List<CyberReportListItem> _myReports = const [];
  bool _loadingMyReports = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDraft());
    unawaited(_loadMyReports());
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
    final savedCategories = prefs.getString('cyber_wizard_categories');
    setState(() {
      if (savedCategories != null && savedCategories.isNotEmpty) {
        _selectedCategories = savedCategories
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet();
        if (_selectedCategories.isEmpty) {
          _selectedCategories = {CybercrimeConstants.reportCategories.first};
        }
      } else {
        final legacy = prefs.getString('cyber_wizard_category');
        if (legacy != null && legacy.isNotEmpty) {
          _selectedCategories = {legacy};
        }
      }
      _descriptionController.text =
          prefs.getString('cyber_wizard_description') ?? '';
      _suspectController.text = prefs.getString('cyber_wizard_suspect') ?? '';
      _transactionController.text =
          prefs.getString('cyber_wizard_transaction') ?? '';
    });
  }

  Future<void> _loadMyReports() async {
    setState(() => _loadingMyReports = true);
    try {
      final reachable = await ensureBackendReachable();
      if (!mounted) return;
      setState(() => _backendUnreachable = !reachable);
      if (!reachable) return;

      final reports = await widget.service.listMyReports();
      if (!mounted) return;
      setState(() {
        _myReports = reports;
        _backendUnreachable = false;
      });
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (!mounted) return;
      setState(
        () => _backendUnreachable = BackendUrlResolver.isConnectionError(error),
      );
      showCyberSnack(context, friendlyCyberError(context, error));
    } finally {
      if (mounted) setState(() => _loadingMyReports = false);
    }
  }

  Future<void> _persistDraftLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cyber_wizard_categories', _selectedCategories.join(','));
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
  }

  Future<void> _saveDraft() async {
    await _persistDraftLocally();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showSaveSuccessDialog(
      context,
      title: l10n.t('draftSavedTitle'),
      message: l10n.t('draftSavedMessage'),
    );
  }

  Future<int> _uploadReportEvidence(String reportId) async {
    var uploaded = 0;
    final total = _evidence.length;
    setState(() {
      _uploadTotal = total;
      _uploadCurrent = 0;
      _uploadProgress = total == 0 ? null : 0;
    });
    for (var i = 0; i < _evidence.length; i++) {
      final file = _evidence[i];
      await widget.service.uploadEvidence(
        file: file,
        title: '$_category evidence ${i + 1}',
        category: 'Screenshot',
        tags: ['report', _category],
        privateMode: true,
        reportId: reportId,
      );
      uploaded += 1;
      if (mounted) {
        setState(() {
          _uploadCurrent = uploaded;
          _uploadProgress = uploaded / total;
        });
      }
    }
    if (mounted) {
      setState(() {
        _uploadProgress = null;
        _uploadCurrent = 0;
        _uploadTotal = 0;
      });
    }
    return uploaded;
  }

  Future<void> _linkVaultEvidence(String reportId) async {
    for (final id in _vaultEvidenceIds) {
      await widget.service.linkEvidenceToReport(evidenceId: id, reportId: reportId);
    }
  }

  void _openReportDetails(CyberReportListItem report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CyberReportDetailScreen(
          reportId: report.id,
          service: widget.service,
          onApiError: widget.onApiError,
        ),
      ),
    );
  }

  Future<void> _pickEvidenceFromGallery() async {
    final ok = await requestGalleryPermission();
    if (!ok || !mounted) return;
    final files = await _imagePicker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => _evidence.addAll(files.take(8 - _evidence.length)));
    }
  }

  Future<void> _pickEvidenceFiles() async {
    final ok = await requestStoragePermission();
    if (!ok || !mounted) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'mp3', 'wav', 'm4a'],
    );
    if (result == null) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => XFile(file.path!, name: file.name))
        .take(8 - _evidence.length)
        .toList();
    if (files.isNotEmpty) setState(() => _evidence.addAll(files));
  }

  Future<void> _pickFromVault() async {
    final l10n = AppLocalizations.of(context);
    try {
      final items = await widget.service.listEvidence(linked: 'unlinked');
      if (!mounted) return;
      if (items.isEmpty) {
        showCyberSnack(context, l10n.t('noUnlinkedEvidence'));
        return;
      }
      final selected = await showDialog<Set<String>>(
        context: context,
        builder: (context) => _VaultEvidencePickerDialog(
          items: items,
          initialSelection: Set<String>.from(_vaultEvidenceIds),
        ),
      );
      if (selected != null) {
        setState(() {
          _vaultEvidenceIds
            ..clear()
            ..addAll(selected);
        });
      }
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) showCyberSnack(context, friendlyCyberError(context, error));
    }
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
    final l10n = AppLocalizations.of(context);
    final description = _descriptionController.text.trim();
    if (!draft && description.length < 10) {
      showCyberSnack(context, l10n.t('minDescriptionChars'));
      return;
    }
    if (_selectedCategories.isEmpty) {
      showCyberSnack(context, l10n.t('multiSelectNone'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ensureBackendReachable(force: true);
      final categories = _selectedCategories.toList();
      final primary = categories.first;
      var finalDescription = description.isEmpty
          ? l10n.t('draftPendingDetails')
          : description;
      if (categories.length > 1) {
        final extras = categories
            .skip(1)
            .map((item) => localizedReportCategory(context, item))
            .join(', ');
        finalDescription =
            '${l10n.t('additionalCategoriesNote')}: $extras\n\n$finalDescription';
      }

      final report = await widget.service.submitReport(
        category: primary,
        description: finalDescription,
        suspectContact: _suspectController.text.trim(),
        transactionId: _transactionController.text.trim(),
        incidentAt: _incidentAt,
        isDraft: draft,
      );
      var uploadedEvidence = 0;
      if (_evidence.isNotEmpty && report.id.isNotEmpty) {
        uploadedEvidence = await _uploadReportEvidence(report.id);
      }
      if (_vaultEvidenceIds.isNotEmpty && report.id.isNotEmpty) {
        await _linkVaultEvidence(report.id);
      }
      if (!mounted) return;
      final linkedCount = _vaultEvidenceIds.length;
      setState(() {
        _lastReport = report;
        _evidence.clear();
        _vaultEvidenceIds.clear();
        _step = 3;
      });
      await _loadMyReports();
      if (!mounted) return;
      final baseMessage =
          draft ? l10n.t('draftSavedOnline') : l10n.t('reportGenerated');
      var evidenceMessage = '';
      if (uploadedEvidence > 0) {
        evidenceMessage = l10n
            .t('evidenceFilesSecured')
            .replaceFirst('{count}', '$uploadedEvidence');
      }
      if (linkedCount > 0) {
        evidenceMessage += l10n
            .t('vaultEvidenceLinked')
            .replaceFirst('{count}', '$linkedCount');
      }
      showCyberSnack(context, '$baseMessage$evidenceMessage');
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      await _persistDraftLocally();
      if (!mounted) return;
      setState(
        () => _backendUnreachable = BackendUrlResolver.isConnectionError(error),
      );
      showCyberSnack(
        context,
        '${l10n.t('couldNotSubmitOnline')} ${friendlyCyberError(context, error)}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CyberScroll(
      children: [
        CyberSectionHeader(
          title: l10n.t('report'),
          subtitle: l10n.t('reportGenerated'),
          icon: Icons.assignment_rounded,
          color: const Color(0xFF3B82F6),
        ),
        CyberStepProgress(
          current: _step,
          labels: [
            l10n.t('selectIncidentType'),
            l10n.t('incidentDescription'),
            l10n.t('attachScreenshotsOrProof'),
            l10n.t('summaryStep'),
          ],
        ),
        const SizedBox(height: 14),
        if (_backendUnreachable) _buildConnectionBanner(l10n),
        _buildMyReportsSection(l10n),
        const SizedBox(height: 6),
        if (_step == 0) _buildTypeStep(l10n),
        if (_step == 1) _buildDetailsStep(l10n),
        if (_step == 2) _buildEvidenceStep(l10n),
        if (_step == 3) _buildSummaryStep(l10n),
      ],
    );
  }

  Widget _buildMyReportsSection(AppLocalizations l10n) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CyberCardTitle(l10n.t('myReports'))),
              IconButton(
                onPressed: _loadingMyReports ? null : _loadMyReports,
                icon: _loadingMyReports
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (_loadingMyReports && _myReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (_myReports.isEmpty)
            CyberEmptyState(text: l10n.t('noSubmittedReportsYet'))
          else
            ..._myReports.take(6).map(
              (report) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  report.isDraft ? Icons.drafts_rounded : Icons.assignment_turned_in_rounded,
                  color: report.isDraft
                      ? const Color(0xFFF3B13E)
                      : const Color(0xFF2FB79E),
                ),
                title: Text(
                  localizedReportCategory(context, report.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${report.isDraft ? l10n.t('draft') : report.status} • ${report.createdAt.toLocal().toString().split('.').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openReportDetails(report),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CyberWarningBanner(text: l10n.t('cannotReachServer')),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showBackendConfigDialog(context);
                  await _loadMyReports();
                },
                icon: const Icon(Icons.settings_ethernet_rounded),
                label: Text(l10n.t('fixConnection')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStep(AppLocalizations l10n) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CyberMultiSelectDropdown(
            label: l10n.t('selectIncidentType'),
            options: CybercrimeConstants.reportCategories,
            selected: _selectedCategories,
            optionLabel: (value) => localizedReportCategory(context, value),
            onChanged: (next) => setState(() => _selectedCategories = next),
          ),
          const SizedBox(height: 16),
          CyberNextButton(
            onPressed: _selectedCategories.isEmpty
                ? null
                : () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(AppLocalizations l10n) {
    return CyberCard(
      child: Column(
        children: [
          CyberMultilineInput(
            controller: _descriptionController,
            label: l10n.t('incidentDescription'),
            hint: l10n.t('incidentDetailsHint'),
          ),
          const SizedBox(height: 12),
          CyberTextInput(
            controller: _suspectController,
            label: l10n.t('suspectContactLabel'),
            hint: l10n.t('suspectContactHint'),
          ),
          const SizedBox(height: 12),
          CyberTextInput(
            controller: _transactionController,
            label: l10n.t('transactionIdLabel'),
            hint: l10n.t('transactionIdHint'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDateTime,
            icon: const Icon(Icons.event_rounded),
            label: Text(
              l10n.t('incidentTime').replaceFirst(
                '{time}',
                _incidentAt.toLocal().toString().split('.').first,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CyberWizardButtons(
            onBack: () => setState(() => _step = 0),
            onNext: () => setState(() => _step = 2),
            onDraft: _saveDraft,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceStep(AppLocalizations l10n) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CyberCardTitle(l10n.t('attachScreenshotsOrProof')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickEvidenceFromGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(l10n.t('pickFromGallery')),
              ),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickEvidenceFiles,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l10n.t('pickFile')),
              ),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickFromVault,
                icon: const Icon(Icons.lock_rounded),
                label: Text(l10n.t('attachFromVault')),
              ),
            ],
          ),
          if (_vaultEvidenceIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n
                    .t('vaultItemsSelected')
                    .replaceFirst('{count}', '${_vaultEvidenceIds.length}'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF93C5FD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_uploadProgress != null) ...[
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 6),
            Text(
              l10n
                  .t('uploadingEvidence')
                  .replaceFirst('{current}', '$_uploadCurrent')
                  .replaceFirst('{total}', '$_uploadTotal'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF516078)
                    : Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_evidence.isEmpty && _vaultEvidenceIds.isEmpty)
            Text(
              l10n.t('noFilesSelectedYet'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF6B7C95)
                    : Colors.white60,
              ),
            )
          else
            ..._evidence.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.image_rounded,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF516078)
                      : Colors.white70,
                ),
                title: Text(
                  entry.value.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _evidence.removeAt(entry.key)),
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                ),
              ),
            ),
          const SizedBox(height: 16),
          CyberWizardButtons(
            onBack: () => setState(() => _step = 1),
            onNext: () => _submit(draft: false),
            onDraft: () => _submit(draft: true),
            nextLabel: _isSubmitting ? l10n.t('submitting') : l10n.t('generate'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(AppLocalizations l10n) {
    final report = _lastReport;
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CyberCardTitle(l10n.t('generatedComplaint')),
          Text(
            report?.firStyleReport ?? l10n.t('reportSummaryUnavailable'),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF516078)
                  : Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: report == null
                      ? null
                      : () => shareReportPdf(context, report),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(l10n.t('pdfReady')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.t('newReport')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultEvidencePickerDialog extends StatefulWidget {
  const _VaultEvidencePickerDialog({
    required this.items,
    required this.initialSelection,
  });

  final List<EvidenceItem> items;
  final Set<String> initialSelection;

  @override
  State<_VaultEvidencePickerDialog> createState() =>
      _VaultEvidencePickerDialogState();
}

class _VaultEvidencePickerDialogState extends State<_VaultEvidencePickerDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.t('selectVaultEvidence')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.items
              .map(
                (item) => CheckboxListTile(
                  value: _selected.contains(item.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(item.id);
                      } else {
                        _selected.remove(item.id);
                      }
                    });
                  },
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(localizedEvidenceCategory(context, item.category)),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.t('finish')),
        ),
      ],
    );
  }
}
