import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class SafetyRiskReasonsExpansion extends StatefulWidget {
  final List<String> reasons;
  final Color accentColor;
  final bool isLight;

  const SafetyRiskReasonsExpansion({
    super.key,
    required this.reasons,
    required this.accentColor,
    required this.isLight,
  });

  @override
  State<SafetyRiskReasonsExpansion> createState() =>
      _SafetyRiskReasonsExpansionState();
}

class _SafetyRiskReasonsExpansionState extends State<SafetyRiskReasonsExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reasons.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final titleColor = widget.isLight
        ? const Color(0xFF334155)
        : Colors.white.withValues(alpha: 0.92);
    final bodyColor = widget.isLight
        ? const Color(0xFF475569)
        : Colors.white.withValues(alpha: 0.78);

    return Material(
      color: widget.accentColor.withValues(alpha: widget.isLight ? 0.06 : 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.t('safetyWhyNotSafeTitle'),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.accentColor,
                    size: 22,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                ...widget.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SafetyVerdictBadge extends StatelessWidget {
  final String headline;
  final Color tone;
  final bool compact;

  const SafetyVerdictBadge({
    super.key,
    required this.headline,
    required this.tone,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(
          alpha: Theme.of(context).brightness == Brightness.light ? 0.12 : 0.22,
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(
        headline,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tone,
          fontSize: compact ? 11.5 : 12.5,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}
