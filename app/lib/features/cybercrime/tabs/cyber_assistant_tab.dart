import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class CyberAssistantTab extends StatefulWidget {
  const CyberAssistantTab({
    super.key,
    required this.service,
    required this.onApiError,
  });

  final CyberProtectionService service;
  final Future<bool> Function(DioException error) onApiError;

  @override
  State<CyberAssistantTab> createState() => _CyberAssistantTabState();
}

class _CyberAssistantTabState extends State<CyberAssistantTab> {
  final _messageController = TextEditingController();
  final _questionController = TextEditingController();
  final _linkController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _screenshot;
  ScamAnalysisResult? _result;
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
    final ok = await requestGalleryPermission();
    if (!ok || !mounted) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _screenshot = image);
  }

  void _clearScreenshot() => setState(() => _screenshot = null);

  Future<void> _analyze() async {
    final l10n = AppLocalizations.of(context);
    final text = _messageController.text.trim();
    final question = _questionController.text.trim();
    final links = _linkController.text
        .split(RegExp(r'\s+|,'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (text.isEmpty && question.isEmpty && links.isEmpty && _screenshot == null) {
      showCyberSnack(context, l10n.t('analyzeInputRequired'));
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final result = _screenshot == null
          ? await widget.service.analyze(
              text: text,
              question: question,
              links: links,
            )
          : await widget.service.analyzeWithScreenshot(
              text: text,
              question: question,
              links: links,
              screenshot: _screenshot!,
            );
      if (!mounted) return;
      setState(() => _result = result);
    } on DioException catch (error) {
      if (!mounted) return;
      if (await widget.onApiError(error)) return;
      setState(() {
        _error = friendlyCyberError(context, error);
        _result = localAnalyze(text, question, links);
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CyberScroll(
      children: [
        CyberSectionHeader(
          title: l10n.t('aiScamFraudAssistantTitle'),
          subtitle: l10n.t('pasteEvidenceContext'),
          icon: Icons.psychology_rounded,
          color: const Color(0xFF8E7CF4),
        ),
        CyberCard(
          child: Column(
            children: [
              CyberMultilineInput(
                controller: _messageController,
                label: l10n.t('suspiciousMessageLabel'),
                hint: l10n.t('pasteFullMessageHereHint'),
              ),
              const SizedBox(height: 12),
              CyberTextInput(
                controller: _linkController,
                label: l10n.t('suspiciousLinksLabel'),
                hint: l10n.t('urlHint'),
              ),
              const SizedBox(height: 12),
              CyberTextInput(
                controller: _questionController,
                label: l10n.t('askQuestionLabel'),
                hint: l10n.t('scamQuestionHint'),
              ),
              const SizedBox(height: 12),
              if (_screenshot != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_screenshot!.path),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _isAnalyzing ? null : _clearScreenshot,
                      tooltip: l10n.t('clearScreenshot'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickScreenshot,
                      icon: const Icon(Icons.image_rounded),
                      label: Text(
                        _screenshot == null
                            ? l10n.t('attachScreenshot')
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
                    label: Text(l10n.t('analyze')),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null) CyberWarningBanner(text: _error!),
        if (_result != null) CyberAnalysisResultCard(result: _result!),
        if (_result?.extractedText != null && _result!.extractedText!.isNotEmpty)
          CyberCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CyberCardTitle(l10n.t('screenshotTextExtracted')),
                Text(
                  _result!.extractedText!,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF516078)
                        : Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
