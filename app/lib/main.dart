import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/config/environment_loader.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contact_guard.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/theme/theme_mode_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/dashboard_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/sensor_service.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentLoader.load();
  if (!dotenv.isInitialized) {
    throw StateError('App environment failed to load.');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  final bool startBackgroundServices;

  const MyApp({super.key, this.startBackgroundServices = true});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final _AppLifecycleHandler _lifecycleHandler;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _impactDialogVisible = false;
  bool _missingContactsDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _lifecycleHandler = _AppLifecycleHandler(
      ref,
      onResumed: _checkMissingEmergencyContactsReminder,
    );
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_checkMissingEmergencyContactsReminder());
    });
    if (widget.startBackgroundServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(safetyMonitorProvider.notifier).start().catchError((_) {}),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<EmergencyContact>>(emergencyContactsProvider, (
      previous,
      next,
    ) {
      if (previous == null) return;
      if (previous.isNotEmpty && next.isEmpty) {
        unawaited(_checkMissingEmergencyContactsReminder());
      }
    });

    if (widget.startBackgroundServices) {
      ref.listen<ImpactDetectionState>(impactDetectionProvider, (
        previous,
        next,
      ) {
        final wasActive = previous?.countdownActive ?? false;
        if (next.countdownActive && !_impactDialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showImpactCountdownDialog();
          });
        } else if (wasActive && !next.countdownActive && _impactDialogVisible) {
          _dismissImpactCountdownDialog();
        }
      });
    }

    final appThemeMode = ref.watch(appThemeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Suraksha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appThemeMode,
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DashboardScreen(),
    );
  }

  Future<void> _checkMissingEmergencyContactsReminder() async {
    if (!mounted) return;

    final hasContacts = await hasSavedEmergencyContacts(ref);
    if (!mounted || hasContacts) return;

    _presentMissingEmergencyContactsReminder();
  }

  void _presentMissingEmergencyContactsReminder() {
    if (!mounted || _missingContactsDialogVisible) return;

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;

    _missingContactsDialogVisible = true;
    unawaited(
      showMissingEmergencyContactsDialog(dialogContext).whenComplete(() {
        _missingContactsDialogVisible = false;
      }),
    );
  }

  Future<void> _showImpactCountdownDialog() async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || _impactDialogVisible) return;

    _impactDialogVisible = true;
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(impactDetectionProvider);
          return PremiumDialogSurface(
            title: 'Impact detected',
            message:
                'Your SOS countdown is active. Act now if this was accidental.',
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFE53935),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(impactDetectionProvider.notifier)
                      .cancelPendingImpact();
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF172235)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: const Text('Cancel SOS'),
              ),
              ElevatedButton(
                onPressed: () {
                  unawaited(
                    ref
                        .read(impactDetectionProvider.notifier)
                        .confirmPendingImpact(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Send SOS now'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS will be sent in ${state.countdownSeconds} seconds.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF23324A)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.lastImpactPosition == null
                      ? 'Saving last known location...'
                      : 'Last location saved for emergency help.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF516078)
                        : Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    _impactDialogVisible = false;
  }

  void _dismissImpactCountdownDialog() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      _impactDialogVisible = false;
      return;
    }

    navigator.pop();
    _impactDialogVisible = false;
  }
}

class _AppLifecycleHandler extends WidgetsBindingObserver {
  final WidgetRef ref;
  final Future<void> Function() onResumed;

  _AppLifecycleHandler(this.ref, {required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(safetyMonitorProvider.notifier).start().catchError((_) {}),
      );
      unawaited(
        ref
            .read(impactDetectionProvider.notifier)
            .resumeIfEnabled()
            .catchError((_) {}),
      );
      unawaited(onResumed());
    }
  }
}
