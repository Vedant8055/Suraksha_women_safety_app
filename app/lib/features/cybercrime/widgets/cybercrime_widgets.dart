import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_constants.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class CyberScroll extends StatelessWidget {
  const CyberScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class CyberSectionHeader extends StatelessWidget {
  const CyberSectionHeader({
    super.key,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
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
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF5F6F8A) : Colors.white70,
                    height: 1.35,
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

class CyberCard extends StatelessWidget {
  const CyberCard({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = accent ?? (isLight ? const Color(0xFFDCE5F6) : Colors.white24);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: isLight ? 1 : 0.35)),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF8A9FBE).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class CyberCardTitle extends StatelessWidget {
  const CyberCardTitle(this.text, {super.key});

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

InputDecoration cyberInputDecoration(BuildContext context, String label) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: isLight ? const Color(0xFF516078) : Colors.white70),
    hintStyle: TextStyle(color: isLight ? const Color(0xFF8A9BB5) : Colors.white38),
    fillColor: isLight
        ? const Color(0xFFF3F7FD)
        : AppTheme.surfaceSoft.withValues(alpha: 0.72),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: isLight ? const Color(0xFFE2EAF7) : Colors.transparent),
    ),
  );
}

class CyberTextInput extends StatelessWidget {
  const CyberTextInput({
    super.key,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: TextStyle(color: isLight ? const Color(0xFF172235) : Colors.white),
      decoration: cyberInputDecoration(context, label).copyWith(hintText: hint),
    );
  }
}

class CyberMultilineInput extends StatelessWidget {
  const CyberMultilineInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return TextField(
      controller: controller,
      maxLines: 5,
      style: TextStyle(color: isLight ? const Color(0xFF172235) : Colors.white),
      decoration: cyberInputDecoration(context, label).copyWith(hintText: hint),
    );
  }
}

class CyberAnalysisResultCard extends StatelessWidget {
  const CyberAnalysisResultCard({super.key, required this.result});

  final ScamAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = result.riskLevel == 'HIGH'
        ? const Color(0xFFE53935)
        : result.riskLevel == 'MEDIUM'
        ? const Color(0xFFF3B13E)
        : const Color(0xFF2FB79E);
    return CyberCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.t('riskLevel')}: ${result.riskLevel}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (result.analysisSource != null) ...[
                const Spacer(),
                Text(
                  result.analysisSource!,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF8A9BB5)
                        : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.threatSummary,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF516078)
                  : Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          CyberCardTitle(l10n.t('recommendedActions')),
          ...result.recommendedActions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $action',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF516078)
                      : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CyberCardTitle(l10n.t('safetyTips')),
          ...result.safetyTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
        ],
      ),
    );
  }
}

class CyberStepProgress extends StatelessWidget {
  const CyberStepProgress({super.key, required this.current, required this.labels});

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
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? AppTheme.primaryColor : Colors.white54,
                  fontSize: 10,
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

class CyberWizardButtons extends StatelessWidget {
  const CyberWizardButtons({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.onDraft,
    this.nextLabel,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onDraft;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDraft,
            icon: const Icon(Icons.save_rounded),
            label: Text(l10n.t('saveDraft')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(nextLabel ?? l10n.t('continueLabel')),
          ),
        ),
      ],
    );
  }
}

class CyberNextButton extends StatelessWidget {
  const CyberNextButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

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

class CyberEvidenceCard extends StatelessWidget {
  const CyberEvidenceCard({
    super.key,
    required this.item,
    required this.onPreview,
    required this.onDownload,
    required this.onDelete,
  });

  final EvidenceItem item;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  IconData _iconForType() {
    final type = item.fileType ?? '';
    if (type.startsWith('image/')) return Icons.image_rounded;
    if (type.startsWith('audio/')) return Icons.audiotrack_rounded;
    if (type.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return item.privateMode ? Icons.visibility_off_rounded : Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final metaColor = isLight ? const Color(0xFF6B7C95) : Colors.white60;
    return CyberCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2FB79E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForType(),
              color: item.encrypted ? const Color(0xFF2FB79E) : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${localizedEvidenceCategory(context, item.category)} • ${item.encrypted ? l10n.t('encrypted') : l10n.t('notEncrypted')} • ${item.uploadedAt.toLocal()}'.split('.').first,
                  style: TextStyle(color: metaColor, fontSize: 12),
                ),
                if (item.reportId != null && item.reportId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.t('linkedToReport'),
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (item.tags.isNotEmpty)
                  Text(item.tags.join(', '), style: TextStyle(color: metaColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.t('preview'),
            onPressed: onPreview,
            icon: Icon(Icons.visibility_rounded, color: metaColor),
          ),
          IconButton(
            tooltip: l10n.t('download'),
            onPressed: onDownload,
            icon: Icon(Icons.download_rounded, color: metaColor),
          ),
          IconButton(
            tooltip: l10n.t('delete'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class CyberWarningBanner extends StatelessWidget {
  const CyberWarningBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF8B1E1E)
                    : const Color(0xFFFFCDD2),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CyberEmptyState extends StatelessWidget {
  const CyberEmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isLight ? const Color(0xFF6B7C95) : Colors.white60),
        ),
      ),
    );
  }
}

class CyberActionButton extends StatelessWidget {
  const CyberActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class CyberQuizDialog extends StatefulWidget {
  const CyberQuizDialog({super.key, required this.topic});

  final LearningTopic topic;

  @override
  State<CyberQuizDialog> createState() => _CyberQuizDialogState();
}

class _CyberQuizDialogState extends State<CyberQuizDialog> {
  int _index = 0;
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.topic.quiz;
    if (quiz.isEmpty) return const SizedBox.shrink();
    final question = quiz[_index.clamp(0, quiz.length - 1)];
    return AlertDialog(
      title: Text(widget.topic.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question),
          const SizedBox(height: 12),
          ...question.options.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  if (entry.key == question.answerIndex) _score += 100;
                  if (_index >= quiz.length - 1) {
                    Navigator.of(context).pop(_score);
                    return;
                  }
                  setState(() => _index += 1);
                },
                child: Text(entry.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String localizedCategoryChip(BuildContext context, String category, {bool isReport = true}) {
  if (isReport) return localizedReportCategory(context, category);
  return localizedEvidenceCategory(context, category);
}

List<String> get reportCategoryValues => CybercrimeConstants.reportCategories;

List<String> get evidenceFilterValues => CybercrimeConstants.evidenceCategories;

List<String> get evidenceUploadValues => CybercrimeConstants.evidenceUploadCategories;
