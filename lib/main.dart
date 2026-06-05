import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/theme/theme_mode_provider.dart';
import 'package:suraksha_women_safety_app/features/dashboard/dashboard_screen.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/routes/route_safety_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/sensor_service.dart';
import 'package:suraksha_women_safety_app/features/sos/scream_detection_service.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _lifecycleHandler = _AppLifecycleHandler(ref);
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
    if (widget.startBackgroundServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(safetyMonitorProvider.notifier).start().catchError((_) {}),
        );
        unawaited(
          ref.read(routeSafetyProvider.notifier).start().catchError((_) {}),
        );
        ref.read(impactDetectionProvider);
        ref.read(screamDetectionProvider);
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
          return AlertDialog(
            title: const Text('Impact detected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOS will be sent in ${state.countdownSeconds} seconds.'),
                const SizedBox(height: 8),
                Text(
                  state.lastImpactPosition == null
                      ? 'Saving last known location...'
                      : 'Last location saved for emergency help.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(impactDetectionProvider.notifier)
                      .cancelPendingImpact();
                },
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
                child: const Text('Send SOS now'),
              ),
            ],
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

  _AppLifecycleHandler(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(safetyMonitorProvider.notifier).start().catchError((_) {}),
      );
      unawaited(
        ref.read(routeSafetyProvider.notifier).start().catchError((_) {}),
      );
      unawaited(
        ref
            .read(impactDetectionProvider.notifier)
            .resumeIfEnabled()
            .catchError((_) {}),
      );
    }
  }
}
