import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';

final impactDetectionProvider =
    StateNotifierProvider<ImpactDetectionService, ImpactDetectionState>((ref) {
      final service = ImpactDetectionService(ref);
      unawaited(service.loadPreference());
      return service;
    });

class ImpactDetectionState {
  final bool enabled;
  final bool monitoring;
  final bool countdownActive;
  final int countdownSeconds;
  final double? lastImpactMagnitude;
  final DateTime? lastImpactAt;
  final Position? lastImpactPosition;
  final String? error;

  const ImpactDetectionState({
    this.enabled = false,
    this.monitoring = false,
    this.countdownActive = false,
    this.countdownSeconds = 10,
    this.lastImpactMagnitude,
    this.lastImpactAt,
    this.lastImpactPosition,
    this.error,
  });

  ImpactDetectionState copyWith({
    bool? enabled,
    bool? monitoring,
    bool? countdownActive,
    int? countdownSeconds,
    double? lastImpactMagnitude,
    DateTime? lastImpactAt,
    Position? lastImpactPosition,
    bool clearLastImpactPosition = false,
    String? error,
  }) {
    return ImpactDetectionState(
      enabled: enabled ?? this.enabled,
      monitoring: monitoring ?? this.monitoring,
      countdownActive: countdownActive ?? this.countdownActive,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      lastImpactMagnitude: lastImpactMagnitude ?? this.lastImpactMagnitude,
      lastImpactAt: lastImpactAt ?? this.lastImpactAt,
      lastImpactPosition: clearLastImpactPosition
          ? null
          : lastImpactPosition ?? this.lastImpactPosition,
      error: error,
    );
  }
}

class ImpactDetectionService extends StateNotifier<ImpactDetectionState> {
  final Ref _ref;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  Timer? _countdownTimer;
  bool _starting = false;
  DateTime? _lastSosTriggeredAt;

  static const String _preferenceKey = 'impact_detection_enabled_v1';
  static const String _lastLatitudeKey = 'impact_detection_last_latitude_v1';
  static const String _lastLongitudeKey = 'impact_detection_last_longitude_v1';
  static const String _lastAccuracyKey = 'impact_detection_last_accuracy_v1';
  static const String _lastTimestampKey = 'impact_detection_last_timestamp_v1';
  static const double impactThreshold = 30.0;
  static const Duration _sosCooldown = Duration(minutes: 2);
  static const int _countdownStartSeconds = 10;

  ImpactDetectionService(this._ref) : super(const ImpactDetectionState());

  Future<void> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_preferenceKey) ?? false;
      state = state.copyWith(enabled: enabled, error: null);
      if (enabled) {
        await startMonitoring();
      }
    } catch (_) {
      state = state.copyWith(
        enabled: false,
        monitoring: false,
        error: 'Impact detection could not start automatically.',
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

  Future<void> resumeIfEnabled() async {
    if (state.enabled && !state.monitoring) {
      await startMonitoring();
    }
  }

  Future<bool> startMonitoring() async {
    if (state.monitoring) return true;
    if (_starting) return false;
    _starting = true;

    _accelerometerSubscription = userAccelerometerEventStream().listen(
      (UserAccelerometerEvent event) {
        final acceleration = event.x.abs() + event.y.abs() + event.z.abs();

        if (acceleration > impactThreshold) {
          debugPrint('IMPACT DETECTED: $acceleration');
          final now = DateTime.now();
          state = state.copyWith(
            lastImpactMagnitude: acceleration,
            lastImpactAt: now,
            error: null,
          );
          if (_lastSosTriggeredAt != null &&
              now.difference(_lastSosTriggeredAt!) < _sosCooldown) {
            return;
          }

          unawaited(_startImpactCountdown(acceleration, now));
        }
      },
      onError: (Object error) {
        state = state.copyWith(
          monitoring: false,
          error: 'Could not monitor impact sensor: $error',
        );
      },
    );

    _starting = false;
    state = state.copyWith(monitoring: true, error: null);
    return true;
  }

  Future<void> _startImpactCountdown(double acceleration, DateTime now) async {
    if (state.countdownActive) return;

    state = state.copyWith(
      countdownActive: true,
      countdownSeconds: _countdownStartSeconds,
      lastImpactMagnitude: acceleration,
      lastImpactAt: now,
      clearLastImpactPosition: true,
      error: null,
    );
    unawaited(_captureAndAttachImpactLocation());

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.countdownSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        unawaited(confirmPendingImpact());
        return;
      }

      state = state.copyWith(countdownSeconds: remaining, error: null);
    });
  }

  Future<void> _captureAndAttachImpactLocation() async {
    final impactPosition = await _captureAndSaveImpactLocation();
    if (!mounted || !state.countdownActive || impactPosition == null) return;

    state = state.copyWith(lastImpactPosition: impactPosition, error: null);
  }

  Future<Position?> _captureAndSaveImpactLocation() async {
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatitudeKey, position.latitude);
      await prefs.setDouble(_lastLongitudeKey, position.longitude);
      await prefs.setDouble(_lastAccuracyKey, position.accuracy);
      await prefs.setString(
        _lastTimestampKey,
        position.timestamp.toIso8601String(),
      );
    } catch (_) {
      // The live fallback position still helps even if local persistence fails.
    }
    return position;
  }

  Future<void> confirmPendingImpact() async {
    if (!state.countdownActive) return;

    final impactPosition = state.lastImpactPosition;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _lastSosTriggeredAt = DateTime.now();
    state = state.copyWith(
      countdownActive: false,
      countdownSeconds: _countdownStartSeconds,
      error: null,
    );
    await _ref
        .read(sosProvider.notifier)
        .triggerSOS(fallbackPosition: impactPosition);
  }

  void cancelPendingImpact() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(
      countdownActive: false,
      countdownSeconds: _countdownStartSeconds,
      error: null,
    );
  }

  Future<void> stopMonitoring() async {
    try {
      await _accelerometerSubscription?.cancel();
    } catch (_) {
      // Keep disabling reliable even if the sensor stream is already closed.
    }
    cancelPendingImpact();
    _accelerometerSubscription = null;
    _starting = false;
    state = state.copyWith(monitoring: false, error: null);
  }

  @override
  void dispose() {
    unawaited(stopMonitoring());
    super.dispose();
  }
}
