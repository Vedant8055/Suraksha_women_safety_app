import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_constants.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/backend_connectivity.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cyber_multi_select_dropdown.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class CyberVaultTab extends StatefulWidget {
  const CyberVaultTab({
    super.key,
    required this.service,
    required this.onApiError,
  });

  final CyberProtectionService service;
  final Future<bool> Function(DioException error) onApiError;

  @override
  State<CyberVaultTab> createState() => _CyberVaultTabState();
}

class _CyberVaultTabState extends State<CyberVaultTab> {
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _searchController = TextEditingController();
  List<EvidenceItem> _items = const [];
  String _category = CybercrimeConstants.evidenceUploadCategories.first;
  Set<String> _selectedCategoryFilters = {'All'};
  Set<String> _selectedLinkFilters = {'all'};
  bool _privateMode = false;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isExporting = false;

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

  String? _resolveLinkedFilter() {
    if (_selectedLinkFilters.contains('all') || _selectedLinkFilters.isEmpty) {
      return null;
    }
    final linked = _selectedLinkFilters.contains('linked');
    final unlinked = _selectedLinkFilters.contains('unlinked');
    if (linked && unlinked) return null;
    if (linked) return 'true';
    if (unlinked) return 'false';
    return null;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      await ensureBackendReachable();
      final categoryFilters = _selectedCategoryFilters.where((c) => c != 'All').toSet();
      final showAll =
          _selectedCategoryFilters.contains('All') || categoryFilters.isEmpty;

      var items = await widget.service.listEvidence(
        category: (!showAll && categoryFilters.length == 1)
            ? categoryFilters.first
            : null,
        search: _searchController.text,
        linked: _resolveLinkedFilter(),
      );

      if (!showAll && categoryFilters.isNotEmpty) {
        items = items
            .where((item) => categoryFilters.contains(item.category))
            .toList();
      }

      if (!mounted) return;
      setState(() => _items = items);
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) showCyberSnack(context, friendlyCyberError(context, error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile(XFile file) async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim().isEmpty
        ? file.name
        : _titleController.text.trim();
    setState(() => _isUploading = true);
    try {
      await widget.service.uploadEvidence(
        file: file,
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
      if (mounted) showCyberSnack(context, l10n.t('evidenceEncryptedSaved'));
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(
          context,
          '${l10n.t('uploadFailed')} ${friendlyCyberError(context, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final ok = await requestGalleryPermission();
    if (!ok || !mounted) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _uploadFile(image);
  }

  Future<void> _pickFromFiles() async {
    final ok = await requestStoragePermission();
    if (!ok || !mounted) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'mp3', 'wav', 'm4a'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    await _uploadFile(XFile(file.path!, name: file.name));
  }

  Future<void> _previewEvidence(EvidenceItem item) async {
    final l10n = AppLocalizations.of(context);
    try {
      final downloaded = await widget.service.downloadEvidence(item.id);
      if (!mounted) return;
      if (downloaded.mimeType.startsWith('image/')) {
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: InteractiveViewer(
              child: Image.memory(
                Uint8List.fromList(downloaded.bytes),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
        return;
      }
      await shareDownloadedEvidence(context, downloaded);
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(
          context,
          '${l10n.t('previewFailed')} ${friendlyCyberError(context, error)}',
        );
      }
    }
  }

  Future<void> _downloadEvidence(EvidenceItem item) async {
    final l10n = AppLocalizations.of(context);
    try {
      final downloaded = await widget.service.downloadEvidence(item.id);
      if (!mounted) return;
      await shareDownloadedEvidence(context, downloaded);
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(
          context,
          '${l10n.t('downloadFailed')} ${friendlyCyberError(context, error)}',
        );
      }
    }
  }

  Future<void> _deleteEvidence(EvidenceItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('deleteEvidenceTitle')),
        content: Text(
          l10n.t('deleteEvidenceConfirm').replaceFirst('{title}', item.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteEvidence(item.id);
      await _load();
      if (mounted) showCyberSnack(context, l10n.t('evidenceDeleted'));
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(
          context,
          '${l10n.t('deleteFailed')} ${friendlyCyberError(context, error)}',
        );
      }
    }
  }

  Future<void> _exportPackage() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);
    try {
      final payload = await widget.service.exportVaultPackage();
      if (!mounted) return;
      await shareVaultExport(context, payload);
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(
          context,
          '${l10n.t('exportFailed')} ${friendlyCyberError(context, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CyberScroll(
      children: [
        CyberSectionHeader(
          title: l10n.t('secureEvidenceVault'),
          subtitle: l10n.t('uploadTagSearchPackageEvidence'),
          icon: Icons.lock_rounded,
          color: const Color(0xFF2FB79E),
        ),
        CyberCard(
          child: Column(
            children: [
              CyberTextInput(
                controller: _titleController,
                label: l10n.t('evidenceTitleLabel'),
                hint: l10n.t('evidenceTitleHint'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: cyberInputDecoration(context, l10n.t('category')),
                items: CybercrimeConstants.evidenceUploadCategories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(localizedEvidenceCategory(context, item)),
                      ),
                    )
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
                        l10n.t('private'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF516078)
                              : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
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
              CyberTextInput(
                controller: _tagController,
                label: l10n.t('tags'),
                hint: l10n.t('tagsHint'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickFromGallery,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_rounded),
                      label: Text(l10n.t('pickFromGallery')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFromFiles,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l10n.t('pickFile')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isExporting ? null : _exportPackage,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory_2_rounded),
                label: Text(l10n.t('exportEvidencePackage')),
              ),
            ],
          ),
        ),
        CyberCard(
          child: Column(
            children: [
              CyberTextInput(
                controller: _searchController,
                label: l10n.t('searchVault'),
                hint: l10n.t('searchByTitle'),
                onSubmitted: (_) => _load(),
              ),
              const SizedBox(height: 10),
              CyberMultiSelectDropdown(
                label: l10n.t('filterCategories'),
                options: CybercrimeConstants.evidenceCategories,
                selected: _selectedCategoryFilters,
                allOptionValue: 'All',
                optionLabel: (value) => localizedEvidenceCategory(context, value),
                onChanged: (next) {
                  setState(() => _selectedCategoryFilters = next);
                  unawaited(_load());
                },
              ),
              const SizedBox(height: 10),
              CyberMultiSelectDropdown(
                label: l10n.t('filterLinkStatus'),
                options: const ['all', 'linked', 'unlinked'],
                selected: _selectedLinkFilters,
                allOptionValue: 'all',
                optionLabel: (value) {
                  switch (value) {
                    case 'linked':
                      return l10n.t('filterLinked');
                    case 'unlinked':
                      return l10n.t('filterUnlinked');
                    default:
                      return l10n.t('filterAll');
                  }
                },
                onChanged: (next) {
                  setState(() => _selectedLinkFilters = next);
                  unawaited(_load());
                },
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
        else if (_items.isEmpty)
          CyberEmptyState(text: l10n.t('noEvidenceFound'))
        else
          ..._items.map(
            (item) => CyberEvidenceCard(
              item: item,
              onPreview: () => _previewEvidence(item),
              onDownload: () => _downloadEvidence(item),
              onDelete: () => _deleteEvidence(item),
            ),
          ),
      ],
    );
  }
}
