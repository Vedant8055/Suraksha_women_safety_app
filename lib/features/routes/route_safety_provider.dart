import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';

final routeSafetyProvider =
    StateNotifierProvider<RouteSafetyNotifier, RouteSafetyState>(
      (ref) => RouteSafetyNotifier(ref),
    );

class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory RoutePoint.fromPosition(Position position) {
    return RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      timestamp:
          DateTime.tryParse(json['ts']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'ts': timestamp.toIso8601String(),
  };
}

class RouteSafetyAssessment {
  final int score;
  final String label;
  final String statusMessage;
  final bool hasLearnedRoute;
  final bool deviatedFromLearnedRoute;
  final double? deviationMeters;
  final List<String> riskFactors;

  const RouteSafetyAssessment({
    required this.score,
    required this.label,
    required this.statusMessage,
    required this.hasLearnedRoute,
    required this.deviatedFromLearnedRoute,
    required this.deviationMeters,
    required this.riskFactors,
  });
}

class RouteSafetyState {
  final bool monitoringActive;
  final bool permissionReady;
  final bool learningRoute;
  final bool hasLearnedRoute;
  final int routeLogCount;
  final int safetyScore;
  final String riskLabel;
  final String statusMessage;
  final bool pendingSafetyCheck;
  final int countdownSeconds;
  final DateTime? alertStartedAt;
  final double? deviationMeters;
  final List<String> riskFactors;
  final Position? lastPosition;
  final bool monitoringMapRoute;
  final String? activeMapRouteName;
  final int activeMapRoutePointCount;
  final int? activeMapRouteScore;
  final String? activeMapRouteReason;

  const RouteSafetyState({
    this.monitoringActive = false,
    this.permissionReady = false,
    this.learningRoute = true,
    this.hasLearnedRoute = false,
    this.routeLogCount = 0,
    this.safetyScore = 50,
    this.riskLabel = 'Learning',
    this.statusMessage = 'Learning daily route pattern from live GPS.',
    this.pendingSafetyCheck = false,
    this.countdownSeconds = RouteSafetyNotifier.defaultSafetyCheckSeconds,
    this.alertStartedAt,
    this.deviationMeters,
    this.riskFactors = const [],
    this.lastPosition,
    this.monitoringMapRoute = false,
    this.activeMapRouteName,
    this.activeMapRoutePointCount = 0,
    this.activeMapRouteScore,
    this.activeMapRouteReason,
  });

  RouteSafetyState copyWith({
    bool? monitoringActive,
    bool? permissionReady,
    bool? learningRoute,
    bool? hasLearnedRoute,
    int? routeLogCount,
    int? safetyScore,
    String? riskLabel,
    String? statusMessage,
    bool? pendingSafetyCheck,
    int? countdownSeconds,
    DateTime? alertStartedAt,
    bool clearAlertStartedAt = false,
    double? deviationMeters,
    bool clearDeviationMeters = false,
    List<String>? riskFactors,
    Position? lastPosition,
    bool? monitoringMapRoute,
    String? activeMapRouteName,
    bool clearActiveMapRouteName = false,
    int? activeMapRoutePointCount,
    int? activeMapRouteScore,
    bool clearActiveMapRouteScore = false,
    String? activeMapRouteReason,
    bool clearActiveMapRouteReason = false,
  }) {
    return RouteSafetyState(
      monitoringActive: monitoringActive ?? this.monitoringActive,
      permissionReady: permissionReady ?? this.permissionReady,
      learningRoute: learningRoute ?? this.learningRoute,
      hasLearnedRoute: hasLearnedRoute ?? this.hasLearnedRoute,
      routeLogCount: routeLogCount ?? this.routeLogCount,
      safetyScore: safetyScore ?? this.safetyScore,
      riskLabel: riskLabel ?? this.riskLabel,
      statusMessage: statusMessage ?? this.statusMessage,
      pendingSafetyCheck: pendingSafetyCheck ?? this.pendingSafetyCheck,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      alertStartedAt: clearAlertStartedAt
          ? null
          : (alertStartedAt ?? this.alertStartedAt),
      deviationMeters: clearDeviationMeters
          ? null
          : (deviationMeters ?? this.deviationMeters),
      riskFactors: riskFactors ?? this.riskFactors,
      lastPosition: lastPosition ?? this.lastPosition,
      monitoringMapRoute: monitoringMapRoute ?? this.monitoringMapRoute,
      activeMapRouteName: clearActiveMapRouteName
          ? null
          : (activeMapRouteName ?? this.activeMapRouteName),
      activeMapRoutePointCount:
          activeMapRoutePointCount ?? this.activeMapRoutePointCount,
      activeMapRouteScore: clearActiveMapRouteScore
          ? null
          : (activeMapRouteScore ?? this.activeMapRouteScore),
      activeMapRouteReason: clearActiveMapRouteReason
          ? null
          : (activeMapRouteReason ?? this.activeMapRouteReason),
    );
  }
}

class RouteSafetyAnalyzer {
  static const learnedRouteThreshold = 12;
  static const deviationThresholdMeters = 120.0;

  const RouteSafetyAnalyzer();

  RouteSafetyAssessment assess({
    required Position position,
    required List<RoutePoint> learnedRoute,
    required int areaSafetyScore,
    required int nearbyPoliceCount,
    required int nearbyHospitalCount,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final hasLearnedRoute = learnedRoute.length >= learnedRouteThreshold;
    final deviation = hasLearnedRoute
        ? nearestDistanceMeters(position, learnedRoute)
        : null;
    final deviated =
        deviation != null && deviation > deviationThresholdMeters;
    final riskFactors = <String>[];
    var score = areaSafetyScore.clamp(0, 100);

    if (_isNight(currentTime)) {
      score -= 15;
      riskFactors.add('Night travel');
    }

    if (nearbyPoliceCount == 0 && nearbyHospitalCount == 0) {
      score -= 10;
      riskFactors.add('No nearby mapped emergency service');
    }

    if (position.accuracy > 50) {
      score -= 8;
      riskFactors.add('Low GPS accuracy');
    }

    if (deviated) {
      score -= 22;
      riskFactors.add('Route changed from daily safe pattern');
    } else if (hasLearnedRoute) {
      score += 8;
      riskFactors.add('Known daily route');
    } else {
      riskFactors.add('Learning route history');
    }

    score = score.clamp(0, 100);
    final label = score >= 80
        ? 'Safest Route'
        : score >= 60
        ? 'Caution'
        : 'High Alert';
    final status = deviated
        ? 'Safe route changed. Please confirm you are safe.'
        : hasLearnedRoute
        ? 'Following your learned safer daily route.'
        : 'Learning your home-workplace route for future alerts.';

    return RouteSafetyAssessment(
      score: score,
      label: label,
      statusMessage: status,
      hasLearnedRoute: hasLearnedRoute,
      deviatedFromLearnedRoute: deviated,
      deviationMeters: deviation,
      riskFactors: riskFactors,
    );
  }

  double? nearestDistanceMeters(Position position, List<RoutePoint> route) {
    if (route.isEmpty) return null;

    var best = double.infinity;
    for (final point in route) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );
      best = min(best, distance);
    }
    return best;
  }

  bool shouldStoreSample({
    required RoutePoint sample,
    required List<RoutePoint> route,
  }) {
    if (route.isEmpty) return true;
    final last = route.last;
    final moved = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      sample.latitude,
      sample.longitude,
    );
    final elapsed = sample.timestamp.difference(last.timestamp).abs();
    return moved >= 20 || elapsed >= const Duration(seconds: 20);
  }

  bool _isNight(DateTime time) => time.hour >= 21 || time.hour < 6;
}

class RouteSafetyNotifier extends StateNotifier<RouteSafetyState> {
  RouteSafetyNotifier(this._ref) : super(const RouteSafetyState());

  static const defaultSafetyCheckSeconds = 300;
  static const _prefsKey = 'route_safety_learned_points_v1';
  static const _maxStoredPoints = 180;

  final Ref _ref;
  final RouteSafetyAnalyzer _analyzer = const RouteSafetyAnalyzer();
  final List<RoutePoint> _learnedRoute = [];
  final List<RoutePoint> _activeMapRoute = [];
  ProviderSubscription<SafetyMonitorState>? _monitorSubscription;
  Timer? _safetyCountdownTimer;
  bool _started = false;
  bool _loading = false;

  Future<void> start() async {
    if (_started || _loading) return;
    _loading = true;
    await _loadLearnedRoute();
    _loading = false;
    _started = true;

    _monitorSubscription = _ref.listen<SafetyMonitorState>(
      safetyMonitorProvider,
      (_, next) => _handleMonitorUpdate(next),
      fireImmediately: true,
    );
  }

  Future<void> refreshNow() async {
    await start();
    await _handleMonitorUpdate(_ref.read(safetyMonitorProvider));
  }

  Future<void> setActiveMapRoute({
    required List<RoutePoint> routePoints,
    required String destinationName,
    required int safetyScore,
    required String safetyReason,
  }) async {
    _activeMapRoute
      ..clear()
      ..addAll(routePoints);
    state = state.copyWith(
      monitoringMapRoute: _activeMapRoute.isNotEmpty,
      activeMapRouteName: destinationName,
      activeMapRoutePointCount: _activeMapRoute.length,
      activeMapRouteScore: safetyScore,
      activeMapRouteReason: safetyReason,
      statusMessage: _activeMapRoute.isEmpty
          ? state.statusMessage
          : 'Monitoring safest map route to $destinationName.',
    );
    await refreshNow();
  }

  Future<void> clearActiveMapRoute() async {
    _activeMapRoute.clear();
    state = state.copyWith(
      monitoringMapRoute: false,
      activeMapRoutePointCount: 0,
      clearActiveMapRouteName: true,
      clearActiveMapRouteScore: true,
      clearActiveMapRouteReason: true,
      statusMessage: 'Map route cleared. Daily route guard continues.',
    );
    await refreshNow();
  }

  Future<void> markUserSafe() async {
    _safetyCountdownTimer?.cancel();
    _safetyCountdownTimer = null;
    state = state.copyWith(
      pendingSafetyCheck: false,
      countdownSeconds: defaultSafetyCheckSeconds,
      clearAlertStartedAt: true,
      statusMessage: 'Safety confirmed. Route monitoring continues.',
    );
  }

  Future<void> resetLearnedRoute() async {
    _learnedRoute.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _safetyCountdownTimer?.cancel();
    state = const RouteSafetyState(
      statusMessage: 'Route history reset. Learning starts again now.',
    );
  }

  Future<void> _handleMonitorUpdate(SafetyMonitorState monitor) async {
    final position = monitor.position;
    final permissionReady = monitor.gpsEnabled && monitor.permissionGranted;
    if (!permissionReady || position == null) {
      state = state.copyWith(
        monitoringActive: false,
        permissionReady: permissionReady,
        statusMessage: monitor.statusMessage,
        lastPosition: position,
      );
      return;
    }

    final sample = RoutePoint.fromPosition(position);
    if (_analyzer.shouldStoreSample(sample: sample, route: _learnedRoute)) {
      _learnedRoute.add(sample);
      if (_learnedRoute.length > _maxStoredPoints) {
        _learnedRoute.removeRange(0, _learnedRoute.length - _maxStoredPoints);
      }
      unawaited(_saveLearnedRoute());
    }

    final monitoringMapRoute = _activeMapRoute.isNotEmpty;
    final assessment = _analyzer.assess(
      position: position,
      learnedRoute: monitoringMapRoute ? _activeMapRoute : _learnedRoute,
      areaSafetyScore: monitor.safetyScore,
      nearbyPoliceCount: monitor.nearbyPoliceCount,
      nearbyHospitalCount: monitor.nearbyHospitalCount,
    );
    final destinationName = state.activeMapRouteName;
    final statusMessage = monitoringMapRoute
        ? assessment.deviatedFromLearnedRoute
              ? 'You moved away from the selected safest map route. Are you safe?'
              : destinationName == null
              ? 'Following selected safest map route.'
              : 'Following selected safest map route to $destinationName.'
        : assessment.statusMessage;

    state = state.copyWith(
      monitoringActive: monitor.trackingActive,
      permissionReady: permissionReady,
      learningRoute: !assessment.hasLearnedRoute && !monitoringMapRoute,
      hasLearnedRoute: assessment.hasLearnedRoute || monitoringMapRoute,
      routeLogCount: _learnedRoute.length,
      safetyScore: assessment.score,
      riskLabel: assessment.label,
      statusMessage: statusMessage,
      deviationMeters: assessment.deviationMeters,
      riskFactors: assessment.riskFactors,
      lastPosition: position,
      monitoringMapRoute: monitoringMapRoute,
      activeMapRoutePointCount: _activeMapRoute.length,
    );

    if (assessment.deviatedFromLearnedRoute && !state.pendingSafetyCheck) {
      _beginSafetyCheck(position);
    }
  }

  void _beginSafetyCheck(Position position) {
    _safetyCountdownTimer?.cancel();
    state = state.copyWith(
      pendingSafetyCheck: true,
      countdownSeconds: defaultSafetyCheckSeconds,
      alertStartedAt: DateTime.now(),
      statusMessage: 'Safe route changed. Are you safe?',
      lastPosition: position,
    );

    _safetyCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nextSeconds = state.countdownSeconds - 1;
      if (nextSeconds <= 0) {
        timer.cancel();
        _safetyCountdownTimer = null;
        state = state.copyWith(
          pendingSafetyCheck: false,
          countdownSeconds: 0,
          clearAlertStartedAt: true,
          statusMessage: 'No safety confirmation received. SOS triggered.',
        );
        unawaited(
          _ref
              .read(sosProvider.notifier)
              .triggerSOS(fallbackPosition: state.lastPosition),
        );
        return;
      }

      state = state.copyWith(countdownSeconds: nextSeconds);
    });
  }

  Future<void> _loadLearnedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _learnedRoute
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(RoutePoint.fromJson)
              .take(_maxStoredPoints),
        );
      state = state.copyWith(
        hasLearnedRoute:
            _learnedRoute.length >= RouteSafetyAnalyzer.learnedRouteThreshold,
        learningRoute:
            _learnedRoute.length < RouteSafetyAnalyzer.learnedRouteThreshold,
        routeLogCount: _learnedRoute.length,
      );
    } catch (_) {
      _learnedRoute.clear();
    }
  }

  Future<void> _saveLearnedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_learnedRoute.map((point) => point.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _safetyCountdownTimer?.cancel();
    _monitorSubscription?.close();
    super.dispose();
  }
}
