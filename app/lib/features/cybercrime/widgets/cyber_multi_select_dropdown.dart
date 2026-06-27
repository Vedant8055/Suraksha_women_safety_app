import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

/// Collapsible multiselect panel — tap header to expand, tap again to collapse.
class CyberMultiSelectDropdown extends StatefulWidget {
  const CyberMultiSelectDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.optionLabel,
    required this.onChanged,
    this.allOptionValue,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final String Function(String value) optionLabel;
  final ValueChanged<Set<String>> onChanged;

  /// When set, selecting this value clears other selections (e.g. "All").
  final String? allOptionValue;

  @override
  State<CyberMultiSelectDropdown> createState() => _CyberMultiSelectDropdownState();
}

class _CyberMultiSelectDropdownState extends State<CyberMultiSelectDropdown> {
  bool _expanded = false;

  String _summary(AppLocalizations l10n) {
    if (widget.selected.isEmpty) return l10n.t('multiSelectNone');
    if (widget.allOptionValue != null &&
        widget.selected.length == 1 &&
        widget.selected.contains(widget.allOptionValue)) {
      return optionLabel(widget.allOptionValue!);
    }
    if (widget.selected.length == 1) {
      return widget.optionLabel(widget.selected.first);
    }
    return l10n
        .t('multiSelectCount')
        .replaceFirst('{count}', '${widget.selected.length}');
  }

  String optionLabel(String value) => widget.optionLabel(value);

  void _toggleOption(String value) {
    final next = Set<String>.from(widget.selected);
    if (widget.allOptionValue != null && value == widget.allOptionValue) {
      widget.onChanged({widget.allOptionValue!});
      return;
    }
    if (widget.allOptionValue != null) {
      next.remove(widget.allOptionValue);
    }
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    if (next.isEmpty && widget.allOptionValue != null) {
      next.add(widget.allOptionValue!);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isLight ? const Color(0xFFF3F7FD) : AppTheme.surfaceSoft.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: isLight ? const Color(0xFF516078) : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _summary(l10n),
                          style: TextStyle(
                            color: isLight ? const Color(0xFF172235) : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isLight ? const Color(0xFF516078) : Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          CyberCard(
            child: Column(
              children: widget.options.map((option) {
                final checked = widget.selected.contains(option);
                return InkWell(
                  onTap: () => _toggleOption(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: checked,
                          onChanged: (_) => _toggleOption(option),
                          activeColor: AppTheme.primaryColor,
                        ),
                        Expanded(
                          child: Text(
                            optionLabel(option),
                            style: TextStyle(
                              color: isLight ? const Color(0xFF172235) : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
