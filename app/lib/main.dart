import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/config/environment_loader.dart';
import 'package:suraksha_women_safety_app/core/notifications/push_notification_service.dart';
import 'package:suraksha_women_safety_app/features/auth/auth_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contact_guard.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/theme/theme_mode_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/dashboard_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:suraksha_women_safety_app/features/sos/scream_detection_service.dart';
import 'package:suraksha_women_safety_app/features/sos/sensor_service.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';
import 'package:suraksha_women_safety_app/widgets/premium_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await EnvironmentLoader.load();
  if (!dotenv.isInitialized) {
    throw StateError('App environment failed to load.');
  }
  await PushNotificationService.instance.initialize();
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
  bool _distressDialogVisible = false;
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
      _syncSafetySummaryLanguage(ref.read(appLocaleProvider));
      final auth = ref.read(authProvider);
      if (auth.token != null && auth.token!.isNotEmpty) {
        unawaited(PushNotificationService.instance.registerTokenIfAuthenticated());
      }
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
    ref.listen<Locale>(appLocaleProvider, (previous, next) {
      _syncSafetySummaryLanguage(next);
    });

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token != null && next.token!.isNotEmpty) {
        unawaited(PushNotificationService.instance.registerTokenIfAuthenticated());
      }
    });

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

      ref.listen<ScreamDetectionState>(screamDetectionProvider, (
        previous,
        next,
      ) {
        final wasActive = previous?.countdownActive ?? false;
        if (next.countdownActive && !_distressDialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showDistressCountdownDialog();
          });
        } else if (wasActive && !next.countdownActive && _distressDialogVisible) {
          _dismissDistressCountdownDialog();
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

  void _syncSafetySummaryLanguage(Locale locale) {
    ref
        .read(safetyMonitorProvider.notifier)
        .setSummaryLanguage(locale.languageCode);
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
    showMissingEmergencyContactsDialog(dialogContext).whenComplete(() {
      _missingContactsDialogVisible = false;
    });
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
                  backgroundColor: const Color.fromARGB(255, 239, 179, 178),
                  foregroundColor: const Color.fromARGB(255, 232, 49, 49),
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

  Future<void> _showDistressCountdownDialog() async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || _distressDialogVisible) return;

    _distressDialogVisible = true;
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(screamDetectionProvider);
          final triggerLabel = state.lastTriggerType == DistressTriggerType.phrase
              ? 'Distress phrase detected'
              : 'Scream or loud distress sound detected';
          return PremiumDialogSurface(
            title: triggerLabel,
            message:
                'SOS countdown is active. Cancel now if this was accidental.',
            icon: Icons.record_voice_over_rounded,
            accentColor: const Color(0xFFE53935),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(screamDetectionProvider.notifier)
                      .cancelPendingDistress();
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
                        .read(screamDetectionProvider.notifier)
                        .confirmPendingDistress(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 239, 179, 178),
                  foregroundColor: const Color.fromARGB(255, 232, 49, 49),
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
                if (state.lastDetectedPhrase != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Matched: ${state.lastDetectedPhrase}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF516078)
                          : Colors.white.withValues(alpha: 0.78),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (state.lastScreamScore != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Scream confidence: ${(state.lastScreamScore! * 100).round()}%',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF516078)
                          : Colors.white.withValues(alpha: 0.78),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
    _distressDialogVisible = false;
  }

  void _dismissDistressCountdownDialog() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      _distressDialogVisible = false;
      return;
    }

    navigator.pop();
    _distressDialogVisible = false;
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
      unawaited(
        ref.read(screamDetectionProvider.notifier).resumeIfEnabled().catchError((_) {}),
      );
    }
  }
}
