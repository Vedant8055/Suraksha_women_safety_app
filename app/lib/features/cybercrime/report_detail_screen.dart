import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class CyberReportDetailScreen extends StatefulWidget {
  const CyberReportDetailScreen({
    super.key,
    required this.reportId,
    required this.service,
    required this.onApiError,
  });

  final String reportId;
  final CyberProtectionService service;
  final Future<bool> Function(DioException error) onApiError;

  @override
  State<CyberReportDetailScreen> createState() => _CyberReportDetailScreenState();
}

class _CyberReportDetailScreenState extends State<CyberReportDetailScreen> {
  CyberReportDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await widget.service.getReportDetail(widget.reportId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on DioException catch (error) {
      if (await widget.onApiError(error)) return;
      if (mounted) {
        showCyberSnack(context, friendlyCyberError(context, error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _previewEvidence(EvidenceItem item) async {
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
      if (mounted) showCyberSnack(context, friendlyCyberError(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('reportDetails')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(child: Text(l10n.t('reportSummaryUnavailable')))
          : CyberScroll(
              children: [
                CyberSectionHeader(
                  title: localizedReportCategory(context, detail.report.category),
                  subtitle: '${detail.report.isDraft ? l10n.t('draft') : detail.report.status} • ${detail.report.createdAt.toLocal()}'.split('.').first,
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                CyberCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CyberCardTitle(l10n.t('generatedComplaint')),
                      Text(
                        detail.report.firStyleReport ?? detail.report.description,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF516078)
                              : Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (detail.report.pdfBase64 != null &&
                          detail.report.pdfBase64!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => shareReportPdf(
                              context,
                              CyberReportResult(
                                id: detail.report.id,
                                firStyleReport: detail.report.firStyleReport ?? detail.report.description,
                                pdfBase64: detail.report.pdfBase64,
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(l10n.t('pdfReady')),
                          ),
                        ),
                    ],
                  ),
                ),
                CyberCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: CyberCardTitle(l10n.t('linkedEvidence'))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2FB79E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${detail.evidence.length}',
                              style: const TextStyle(
                                color: Color(0xFF2FB79E),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (detail.evidence.isEmpty)
                        CyberEmptyState(text: l10n.t('noLinkedEvidence'))
                      else
                        ...detail.evidence.map(
                          (item) => CyberEvidenceCard(
                            item: item,
                            onPreview: () => _previewEvidence(item),
                            onDownload: () => _previewEvidence(item),
                            onDelete: () {},
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
