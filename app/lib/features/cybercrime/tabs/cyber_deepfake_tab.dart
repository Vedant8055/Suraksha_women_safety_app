import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/models/cybercrime_models.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/widgets/cybercrime_widgets.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class CyberDeepfakeTab extends StatefulWidget {
  const CyberDeepfakeTab({super.key, required this.service});

  final CyberProtectionService service;

  @override
  State<CyberDeepfakeTab> createState() => _CyberDeepfakeTabState();
}

class _CyberDeepfakeTabState extends State<CyberDeepfakeTab> {
  DeepfakeResources _resources = fallbackDeepfakeResources;

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
    final l10n = AppLocalizations.of(context);
    return CyberScroll(
      children: [
        CyberSectionHeader(
          title: _resources.title.isNotEmpty
              ? _resources.title
              : l10n.t('deepfakeEmergencySupportTitle'),
          subtitle: l10n.t('deepfakeSubtitle'),
          icon: Icons.warning_rounded,
          color: const Color(0xFFE53935),
        ),
        CyberWarningBanner(text: l10n.t('deepfakeWarning')),
        ..._resources.sections.map(
          (section) => CyberCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CyberCardTitle(section.title),
                Text(
                  section.body,
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
        ),
        CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CyberCardTitle(l10n.t('emergencyActions')),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...(_resources.helplines.isEmpty
                      ? [
                          CyberActionButton(
                            label: l10n.t('call1930'),
                            icon: Icons.call,
                            onTap: () => dialPhoneNumber('1930'),
                          ),
                          CyberActionButton(
                            label: l10n.t('police100'),
                            icon: Icons.local_police_rounded,
                            onTap: () => dialPhoneNumber('100'),
                          ),
                        ]
                      : _resources.helplines.map(
                          (helpline) => CyberActionButton(
                            label: helpline.label,
                            icon: Icons.call,
                            onTap: () => dialPhoneNumber(helpline.value),
                          ),
                        )),
                  CyberActionButton(
                    label: l10n.t('cyberPortal'),
                    icon: Icons.open_in_new_rounded,
                    onTap: () => openExternalLink('https://cybercrime.gov.in'),
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
