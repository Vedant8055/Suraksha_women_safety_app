import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final screamDetectionProvider =
    StateNotifierProvider<ScreamDetectionService, ScreamDetectionState>(
      (ref) => ScreamDetectionService(ref)..loadPreference(),
    );

class ScreamDetectionState {
  final bool enabled;
  final bool monitoring;
  final bool permissionGranted;
  final String? error;

  const ScreamDetectionState({
    this.enabled = false,
    this.monitoring = false,
    this.permissionGranted = false,
    this.error,
  });

  ScreamDetectionState copyWith({
    bool? enabled,
    bool? monitoring,
    bool? permissionGranted,
    String? error,
  }) {
    return ScreamDetectionState(
      enabled: enabled ?? this.enabled,
      monitoring: monitoring ?? this.monitoring,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      error: error,
    );
  }
}

class ScreamDetectionService extends StateNotifier<ScreamDetectionState> {
  final Ref _ref;
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderSubscription;
  DateTime? _lastSosTriggeredAt;
  bool _starting = false;
  static const String _preferenceKey = 'scream_detection_enabled_v1';
  static const double screamThreshold = -12.0;
  static const Duration _sosCooldown = Duration(minutes: 2);

  ScreamDetectionService(this._ref) : super(const ScreamDetectionState());

  Future<void> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_preferenceKey) ?? false;
      state = state.copyWith(enabled: enabled);
      if (enabled) {
        await startMonitoring();
      }
    } catch (_) {
      state = state.copyWith(
        enabled: false,
        monitoring: false,
        error: 'Scream detection could not start automatically.',
      );
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (!enabled) {
      await stopMonitoring();
      await prefs.setBool(_preferenceKey, false);
      state = state.copyWith(enabled: false, error: null);
      return true;
    }

    final started = await startMonitoring();
    if (started) {
      await prefs.setBool(_preferenceKey, true);
      state = state.copyWith(enabled: true, error: null);
      return true;
    }

    await prefs.setBool(_preferenceKey, false);
    state = state.copyWith(enabled: false);
    return false;
  }

  Future<bool> startMonitoring() async {
    if (state.monitoring) return true;
    if (_starting) return false;
    _starting = true;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = state.copyWith(
        monitoring: false,
        permissionGranted: false,
        error: 'Microphone permission is needed for scream detection.',
      );
      _starting = false;
      return false;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final monitorPath = '${tempDir.path}/scream_monitor.aac';
      final recorder = FlutterSoundRecorder();
      _recorder = recorder;

      await recorder.openRecorder();
      await recorder.setSubscriptionDuration(const Duration(milliseconds: 250));

      _recorderSubscription = recorder.onProgress?.listen((event) {
        final decibels = event.decibels;
        if (decibels == null || decibels < screamThreshold) return;

        final now = DateTime.now();
        if (_lastSosTriggeredAt != null &&
            now.difference(_lastSosTriggeredAt!) < _sosCooldown) {
          return;
        }

        _lastSosTriggeredAt = now;
        _ref.read(sosProvider.notifier).triggerSOS();
      });

      await recorder.startRecorder(toFile: monitorPath);
      state = state.copyWith(
        monitoring: true,
        permissionGranted: true,
        error: null,
      );
      return true;
    } catch (error) {
      await stopMonitoring();
      state = state.copyWith(
        monitoring: false,
        permissionGranted: true,
        error: 'Could not start scream detection: $error',
      );
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _recorderSubscription?.cancel();
      await _recorder?.stopRecorder();
      await _recorder?.closeRecorder();
    } catch (_) {
      // Ignore recorder cleanup failures so turning the feature off stays safe.
    }
    _recorderSubscription = null;
    _recorder = null;
    _starting = false;
    state = state.copyWith(monitoring: false, error: null);
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
