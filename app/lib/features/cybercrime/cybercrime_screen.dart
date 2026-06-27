import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/services/cyber_protection_service.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/tabs/cyber_assistant_tab.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/tabs/cyber_deepfake_tab.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/tabs/cyber_learning_tab.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/tabs/cyber_report_tab.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/tabs/cyber_vault_tab.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/backend_connectivity.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class CyberCrimeScreen extends ConsumerStatefulWidget {
  const CyberCrimeScreen({super.key});

  @override
  ConsumerState<CyberCrimeScreen> createState() => _CyberCrimeScreenState();
}

class _CyberCrimeScreenState extends ConsumerState<CyberCrimeScreen> {
  final _service = CyberProtectionService();

  @override
  void initState() {
    super.initState();
    unawaited(ensureBackendReachable());
  }

  Future<bool> _handleApiError(DioException error) {
    return handleCyberAuthError(context, ref, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('cyberCrimeProtection')),
          bottom: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor:
                isLight ? const Color(0xFF6B7C95) : Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(icon: const Icon(Icons.psychology_rounded), text: l10n.t('aiAssist')),
              Tab(icon: const Icon(Icons.assignment_rounded), text: l10n.t('report')),
              Tab(icon: const Icon(Icons.lock_rounded), text: l10n.t('vault')),
              Tab(icon: const Icon(Icons.school_rounded), text: l10n.t('learn')),
              Tab(icon: const Icon(Icons.warning_rounded), text: l10n.t('deepfake')),
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
              CyberAssistantTab(service: _service, onApiError: _handleApiError),
              CyberReportTab(service: _service, onApiError: _handleApiError),
              CyberVaultTab(service: _service, onApiError: _handleApiError),
              CyberLearningTab(service: _service, onApiError: _handleApiError),
              CyberDeepfakeTab(service: _service),
            ],
          ),
        ),
      ),
    );
  }
}
