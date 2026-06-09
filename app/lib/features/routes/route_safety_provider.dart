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

class LearnedTrip {
  final String id;
  final List<RoutePoint> points;
  final DateTime startedAt;
  final DateTime endedAt;

  const LearnedTrip({
    required this.id,
    required this.points,
    required this.startedAt,
    required this.endedAt,
  });

  RoutePoint get startPoint => points.first;
  RoutePoint get endPoint => points.last;
  Duration get duration => endedAt.difference(startedAt).abs();

  factory LearnedTrip.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoutePoint.fromJson)
        .toList(growable: false);
    final startedAt =
        DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
        (points.isNotEmpty ? points.first.timestamp : DateTime.now());
    final endedAt =
        DateTime.tryParse(json['endedAt']?.toString() ?? '') ??
        (points.isNotEmpty ? points.last.timestamp : startedAt);
    return LearnedTrip(
      id: json['id']?.toString() ?? startedAt.microsecondsSinceEpoch.toString(),
      points: points,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'points': points.map((point) => point.toJson()).toList(growable: false),
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
  static const defaultRouteCorridorMeters = 85.0;

  const RouteSafetyAnalyzer();

  RouteSafetyAssessment assess({
    required Position position,
    required List<RoutePoint> learnedRoute,
    required int areaSafetyScore,
    required int nearbyPoliceCount,
    required int nearbyHospitalCount,
    DateTime? now,
    bool? hasLearnedRouteOverride,
    double deviationThresholdMeters =
        RouteSafetyAnalyzer.deviationThresholdMeters,
  }) {
    final currentTime = now ?? DateTime.now();
    final hasLearnedRoute =
        hasLearnedRouteOverride ?? learnedRoute.length >= learnedRouteThreshold;
    final deviation = hasLearnedRoute && learnedRoute.isNotEmpty
        ? nearestDistanceMeters(position, learnedRoute)
        : null;
    final deviated = deviation != null && deviation > deviationThresholdMeters;
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
    return routeDistanceMeters(
      latitude: position.latitude,
      longitude: position.longitude,
      route: route,
    );
  }

  double? routeDistanceMeters({
    required double latitude,
    required double longitude,
    required List<RoutePoint> route,
  }) {
    if (route.isEmpty) return null;
    if (route.length == 1) {
      return Geolocator.distanceBetween(
        latitude,
        longitude,
        route.first.latitude,
        route.first.longitude,
      );
    }

    var best = double.infinity;
    for (var index = 0; index < route.length - 1; index++) {
      final distance = _distanceToSegmentMeters(
        latitude: latitude,
        longitude: longitude,
        start: route[index],
        end: route[index + 1],
      );
      best = min(best, distance);
    }

    if (!best.isFinite) {
      return Geolocator.distanceBetween(
        latitude,
        longitude,
        route.first.latitude,
        route.first.longitude,
      );
    }
    return best;
  }

  bool shouldStoreSample({
    required RoutePoint sample,
    required List<RoutePoint> route,
    double minimumMovementMeters = 20,
    Duration minimumElapsed = const Duration(seconds: 20),
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
    return moved >= minimumMovementMeters || elapsed >= minimumElapsed;
  }

  double averageRouteDistanceMeters(
    List<RoutePoint> points,
    List<RoutePoint> route,
  ) {
    if (points.isEmpty || route.isEmpty) return double.infinity;
    var total = 0.0;
    for (final point in points) {
      total +=
          routeDistanceMeters(
            latitude: point.latitude,
            longitude: point.longitude,
            route: route,
          ) ??
          double.infinity;
    }
    return total / points.length;
  }

  bool _isNight(DateTime time) => time.hour >= 21 || time.hour < 6;

  double _distanceToSegmentMeters({
    required double latitude,
    required double longitude,
    required RoutePoint start,
    required RoutePoint end,
  }) {
    final meanLatRadians =
        ((latitude + start.latitude + end.latitude) / 3) * pi / 180;
    final metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * cos(meanLatRadians);

    final px = longitude * metersPerDegreeLng;
    final py = latitude * metersPerDegreeLat;
    final ax = start.longitude * metersPerDegreeLng;
    final ay = start.latitude * metersPerDegreeLat;
    final bx = end.longitude * metersPerDegreeLng;
    final by = end.latitude * metersPerDegreeLat;

    final abx = bx - ax;
    final aby = by - ay;
    final abLengthSquared = (abx * abx) + (aby * aby);
    if (abLengthSquared <= 0.0001) {
      return sqrt(pow(px - ax, 2) + pow(py - ay, 2));
    }

    final apx = px - ax;
    final apy = py - ay;
    final t = ((apx * abx) + (apy * aby)) / abLengthSquared;
    final clamped = t.clamp(0.0, 1.0);
    final closestX = ax + (abx * clamped);
    final closestY = ay + (aby * clamped);
    return sqrt(pow(px - closestX, 2) + pow(py - closestY, 2));
  }
}

class _RoutineProfile {
  final String id;
  final List<RoutePoint> route;
  final RoutePoint startPoint;
  final RoutePoint endPoint;
  final int tripCount;
  final int averageStartHour;
  final bool weekdayProfile;
  final double corridorMeters;

  const _RoutineProfile({
    required this.id,
    required this.route,
    required this.startPoint,
    required this.endPoint,
    required this.tripCount,
    required this.averageStartHour,
    required this.weekdayProfile,
    required this.corridorMeters,
  });
}

class _RoutineMatch {
  final _RoutineProfile profile;
  final double deviationMeters;

  const _RoutineMatch({required this.profile, required this.deviationMeters});
}

class RouteSafetyNotifier extends StateNotifier<RouteSafetyState> {
  RouteSafetyNotifier(this._ref) : super(const RouteSafetyState());

  static const defaultSafetyCheckSeconds = 300;
  static const _prefsKey = 'route_safety_learned_points_v2';
  static const _legacyPrefsKey = 'route_safety_learned_points_v1';
  static const _maxStoredTrips = 24;
  static const _maxPointsPerTrip = 180;
  static const _minTripPoints = 8;
  static const _minTripsForRoutine = 2;
  static const _maxTripGap = Duration(minutes: 12);
  static const _minTripDuration = Duration(minutes: 4);
  static const _tripBreakDistanceMeters = 1500.0;
  static const _tripMatchStartRadiusMeters = 350.0;
  static const _profileGridMeters = 250.0;
  static const _requiredDeviationSamples = 3;

  final Ref _ref;
  final RouteSafetyAnalyzer _analyzer = const RouteSafetyAnalyzer();
  final List<LearnedTrip> _learnedTrips = [];
  final List<RoutePoint> _activeMapRoute = [];
  final List<RoutePoint> _currentTripPoints = [];
  final Map<String, _RoutineProfile> _routineProfiles = {};
  ProviderSubscription<SafetyMonitorState>? _monitorSubscription;
  Timer? _safetyCountdownTimer;
  bool _started = false;
  bool _loading = false;
  bool _profilesDirty = true;
  int _deviationStreak = 0;

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
    _deviationStreak = 0;
    state = state.copyWith(
      pendingSafetyCheck: false,
      countdownSeconds: defaultSafetyCheckSeconds,
      clearAlertStartedAt: true,
      statusMessage: 'Safety confirmed. Route monitoring continues.',
    );
  }

  Future<void> resetLearnedRoute() async {
    _learnedTrips.clear();
    _routineProfiles.clear();
    _currentTripPoints.clear();
    _activeMapRoute.clear();
    _profilesDirty = true;
    _deviationStreak = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_legacyPrefsKey);
    _safetyCountdownTimer?.cancel();
    state = const RouteSafetyState(
      statusMessage: 'Route history reset. Learning starts again now.',
    );
  }

  Future<void> _handleMonitorUpdate(SafetyMonitorState monitor) async {
    final position = monitor.position;
    final permissionReady = monitor.gpsEnabled && monitor.permissionGranted;
    if (!permissionReady || position == null) {
      _completeCurrentTripIfPossible(force: true);
      state = state.copyWith(
        monitoringActive: false,
        permissionReady: permissionReady,
        statusMessage: monitor.statusMessage,
        lastPosition: position,
      );
      return;
    }

    final sample = RoutePoint.fromPosition(position);
    _appendLiveSample(sample);
    _rebuildProfilesIfNeeded();

    final monitoringMapRoute = _activeMapRoute.isNotEmpty;
    final matchedRoutine = monitoringMapRoute
        ? null
        : _matchRoutine(position: position, now: sample.timestamp);
    final comparisonRoute = monitoringMapRoute
        ? _activeMapRoute
        : matchedRoutine?.profile.route ?? const <RoutePoint>[];
    final hasLearnedRoute = monitoringMapRoute || matchedRoutine != null;
    final deviationThreshold = monitoringMapRoute
        ? RouteSafetyAnalyzer.defaultRouteCorridorMeters
        : matchedRoutine?.profile.corridorMeters ??
              RouteSafetyAnalyzer.deviationThresholdMeters;

    final assessment = _analyzer.assess(
      position: position,
      learnedRoute: comparisonRoute,
      areaSafetyScore: monitor.safetyScore,
      nearbyPoliceCount: monitor.nearbyPoliceCount,
      nearbyHospitalCount: monitor.nearbyHospitalCount,
      hasLearnedRouteOverride: hasLearnedRoute,
      deviationThresholdMeters: deviationThreshold,
    );

    final baseRiskFactors = List<String>.from(assessment.riskFactors);
    if (monitoringMapRoute) {
      baseRiskFactors.add('Selected safest map route');
    } else if (matchedRoutine != null) {
      baseRiskFactors.add(
        matchedRoutine.profile.tripCount >= 4
            ? 'Strong commute pattern'
            : 'Repeated daily pattern',
      );
    } else if (_routineProfiles.isNotEmpty) {
      baseRiskFactors.add('No matching routine for this trip yet');
    }

    final destinationName = state.activeMapRouteName;
    final statusMessage = monitoringMapRoute
        ? assessment.deviatedFromLearnedRoute
              ? 'You moved away from the selected safest map route. Are you safe?'
              : destinationName == null
              ? 'Following selected safest map route.'
              : 'Following selected safest map route to $destinationName.'
        : matchedRoutine == null
        ? _routineProfiles.isEmpty
              ? 'Learning your daily travel routines.'
              : 'Watching for a known commute pattern.'
        : assessment.deviatedFromLearnedRoute
        ? 'You moved away from your usual route. Are you safe?'
        : 'Following your learned safer daily route.';

    if (assessment.deviatedFromLearnedRoute) {
      _deviationStreak += 1;
    } else {
      _deviationStreak = 0;
    }

    state = state.copyWith(
      monitoringActive: monitor.trackingActive,
      permissionReady: permissionReady,
      learningRoute: !hasLearnedRoute,
      hasLearnedRoute: hasLearnedRoute || _routineProfiles.isNotEmpty,
      routeLogCount: _storedPointCount,
      safetyScore: assessment.score,
      riskLabel: assessment.label,
      statusMessage: statusMessage,
      deviationMeters: assessment.deviationMeters,
      riskFactors: baseRiskFactors,
      lastPosition: position,
      monitoringMapRoute: monitoringMapRoute,
      activeMapRoutePointCount: _activeMapRoute.length,
    );

    if (assessment.deviatedFromLearnedRoute &&
        _deviationStreak >= _requiredDeviationSamples &&
        !state.pendingSafetyCheck) {
      _beginSafetyCheck(position);
    }
  }

  void _appendLiveSample(RoutePoint sample) {
    if (_currentTripPoints.isEmpty) {
      _currentTripPoints.add(sample);
      return;
    }

    final last = _currentTripPoints.last;
    final gap = sample.timestamp.difference(last.timestamp).abs();
    final moved = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      sample.latitude,
      sample.longitude,
    );

    if (gap > _maxTripGap || moved > _tripBreakDistanceMeters) {
      _completeCurrentTripIfPossible(force: true);
      _currentTripPoints
        ..clear()
        ..add(sample);
      return;
    }

    if (_analyzer.shouldStoreSample(
      sample: sample,
      route: _currentTripPoints,
      minimumMovementMeters: 18,
      minimumElapsed: const Duration(seconds: 15),
    )) {
      _currentTripPoints.add(sample);
      if (_currentTripPoints.length > _maxPointsPerTrip) {
        _currentTripPoints.removeAt(0);
      }
    }
  }

  void _completeCurrentTripIfPossible({bool force = false}) {
    if (_currentTripPoints.length < _minTripPoints) {
      if (force) {
        _currentTripPoints.clear();
      }
      return;
    }

    final startedAt = _currentTripPoints.first.timestamp;
    final endedAt = _currentTripPoints.last.timestamp;
    if (!force && endedAt.difference(startedAt) < _minTripDuration) {
      return;
    }

    final trip = LearnedTrip(
      id: startedAt.microsecondsSinceEpoch.toString(),
      points: List<RoutePoint>.from(_currentTripPoints, growable: false),
      startedAt: startedAt,
      endedAt: endedAt,
    );

    if (_learnedTrips.isEmpty || _learnedTrips.last.id != trip.id) {
      _learnedTrips.add(trip);
      if (_learnedTrips.length > _maxStoredTrips) {
        _learnedTrips.removeRange(0, _learnedTrips.length - _maxStoredTrips);
      }
      _profilesDirty = true;
      unawaited(_saveLearnedRoute());
    }
    _currentTripPoints.clear();
  }

  _RoutineMatch? _matchRoutine({
    required Position position,
    required DateTime now,
  }) {
    if (_routineProfiles.isEmpty) return null;

    final contextPoints = _currentTripPoints.isEmpty
        ? [
            RoutePoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: now,
            ),
          ]
        : _currentTripPoints.takeLast(5);
    final startPoint = _currentTripPoints.isEmpty
        ? contextPoints.first
        : _currentTripPoints.first;
    final weekday = _isWeekday(now);

    _RoutineProfile? bestProfile;
    double bestScore = double.infinity;
    double bestDeviation = double.infinity;

    for (final profile in _routineProfiles.values) {
      final startDistance = Geolocator.distanceBetween(
        startPoint.latitude,
        startPoint.longitude,
        profile.startPoint.latitude,
        profile.startPoint.longitude,
      );
      final currentDistance =
          _analyzer.nearestDistanceMeters(position, profile.route) ??
          double.infinity;
      final contextDistance = _analyzer.averageRouteDistanceMeters(
        contextPoints,
        profile.route,
      );
      final hourDelta = _hourDistance(now.hour, profile.averageStartHour);
      final weekdayPenalty = weekday == profile.weekdayProfile ? 0.0 : 18.0;
      final repeatBonus = min(profile.tripCount * 4.0, 18.0);
      final score =
          (currentDistance * 0.70) +
          (contextDistance * 0.35) +
          (min(startDistance, 500) * 0.20) +
          (hourDelta * 16) +
          weekdayPenalty -
          repeatBonus;

      final nearExpectedStart = startDistance <= _tripMatchStartRadiusMeters;
      final nearRoute = currentDistance <= (profile.corridorMeters * 2.2);
      if (!(nearExpectedStart || nearRoute)) {
        continue;
      }
      if (score < bestScore) {
        bestProfile = profile;
        bestScore = score;
        bestDeviation = currentDistance;
      }
    }

    if (bestProfile == null) return null;
    return _RoutineMatch(profile: bestProfile, deviationMeters: bestDeviation);
  }

  void _rebuildProfilesIfNeeded() {
    if (!_profilesDirty) return;
    _routineProfiles
      ..clear()
      ..addAll(_buildRoutineProfiles(_learnedTrips));
    _profilesDirty = false;
  }

  Map<String, _RoutineProfile> _buildRoutineProfiles(List<LearnedTrip> trips) {
    if (trips.isEmpty) return const {};

    final grouped = <String, List<LearnedTrip>>{};
    for (final trip in trips) {
      if (trip.points.length < _minTripPoints) continue;
      final key = _routineKey(trip);
      grouped.putIfAbsent(key, () => <LearnedTrip>[]).add(trip);
    }

    final profiles = <String, _RoutineProfile>{};
    for (final entry in grouped.entries) {
      final groupTrips = entry.value;
      if (groupTrips.length < _minTripsForRoutine) continue;
      final representative = _pickRepresentativeTrip(groupTrips);
      final avgStartHour =
          groupTrips
              .map((trip) => trip.startedAt.hour)
              .reduce((a, b) => a + b) ~/
          groupTrips.length;
      final avgRouteDistance =
          groupTrips
              .map(
                (trip) => _analyzer.averageRouteDistanceMeters(
                  trip.points.takeLast(12),
                  representative.points,
                ),
              )
              .reduce((a, b) => a + b) /
          groupTrips.length;
      final corridorMeters = (avgRouteDistance + 30).clamp(60.0, 140.0);
      profiles[entry.key] = _RoutineProfile(
        id: entry.key,
        route: representative.points,
        startPoint: representative.startPoint,
        endPoint: representative.endPoint,
        tripCount: groupTrips.length,
        averageStartHour: avgStartHour,
        weekdayProfile: _isWeekday(representative.startedAt),
        corridorMeters: corridorMeters,
      );
    }

    return profiles;
  }

  LearnedTrip _pickRepresentativeTrip(List<LearnedTrip> trips) {
    final sorted = [...trips]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    LearnedTrip best = sorted.first;
    double bestScore = double.infinity;

    for (final candidate in sorted.take(5)) {
      var total = 0.0;
      for (final other in trips) {
        total += _tripDistanceScore(candidate, other);
      }
      if (total < bestScore) {
        best = candidate;
        bestScore = total;
      }
    }
    return best;
  }

  double _tripDistanceScore(LearnedTrip candidate, LearnedTrip other) {
    final tailAverage = _analyzer.averageRouteDistanceMeters(
      other.points.takeLast(12),
      candidate.points,
    );
    final headAverage = _analyzer.averageRouteDistanceMeters(
      other.points.take(12).toList(growable: false),
      candidate.points,
    );
    return (tailAverage * 0.55) + (headAverage * 0.45);
  }

  String _routineKey(LearnedTrip trip) {
    final startKey = _gridKey(trip.startPoint);
    final endKey = _gridKey(trip.endPoint);
    final dayKey = _isWeekday(trip.startedAt) ? 'weekday' : 'weekend';
    final bucket = _timeBucket(trip.startedAt.hour);
    return '$startKey>$endKey|$bucket|$dayKey';
  }

  String _gridKey(RoutePoint point) {
    final latMeters = point.latitude * 111132.92;
    final lngMeters =
        point.longitude * (111412.84 * cos(point.latitude * pi / 180));
    final latGrid = (latMeters / _profileGridMeters).round();
    final lngGrid = (lngMeters / _profileGridMeters).round();
    return '$latGrid:$lngGrid';
  }

  String _timeBucket(int hour) {
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 16) return 'midday';
    if (hour >= 16 && hour < 22) return 'evening';
    return 'night';
  }

  int _hourDistance(int left, int right) {
    final delta = (left - right).abs();
    return min(delta, 24 - delta);
  }

  bool _isWeekday(DateTime time) =>
      time.weekday >= DateTime.monday && time.weekday <= DateTime.friday;

  int get _storedPointCount {
    var count = _currentTripPoints.length;
    for (final trip in _learnedTrips) {
      count += trip.points.length;
    }
    return count;
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
        _deviationStreak = 0;
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
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final trips = (decoded['trips'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(LearnedTrip.fromJson)
              .where((trip) => trip.points.length >= _minTripPoints)
              .take(_maxStoredTrips)
              .toList(growable: false);
          _learnedTrips
            ..clear()
            ..addAll(trips);
        }
      } else {
        await _loadLegacyRoute(prefs);
      }

      _profilesDirty = true;
      _rebuildProfilesIfNeeded();
      state = state.copyWith(
        hasLearnedRoute: _routineProfiles.isNotEmpty,
        learningRoute: _routineProfiles.isEmpty,
        routeLogCount: _storedPointCount,
      );
    } catch (_) {
      _learnedTrips.clear();
      _routineProfiles.clear();
      _currentTripPoints.clear();
    }
  }

  Future<void> _loadLegacyRoute(SharedPreferences prefs) async {
    final raw = prefs.getString(_legacyPrefsKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final points = decoded
        .whereType<Map<String, dynamic>>()
        .map(RoutePoint.fromJson)
        .toList(growable: false);
    if (points.length < _minTripPoints) return;

    final segmented = _segmentLegacyPoints(points);
    _learnedTrips
      ..clear()
      ..addAll(segmented.take(_maxStoredTrips));
    unawaited(_saveLearnedRoute());
  }

  List<LearnedTrip> _segmentLegacyPoints(List<RoutePoint> points) {
    final trips = <LearnedTrip>[];
    var buffer = <RoutePoint>[];

    for (final point in points) {
      if (buffer.isEmpty) {
        buffer = [point];
        continue;
      }

      final last = buffer.last;
      final gap = point.timestamp.difference(last.timestamp).abs();
      final moved = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        point.latitude,
        point.longitude,
      );

      if (gap > _maxTripGap || moved > _tripBreakDistanceMeters) {
        if (buffer.length >= _minTripPoints) {
          trips.add(
            LearnedTrip(
              id: buffer.first.timestamp.microsecondsSinceEpoch.toString(),
              points: List<RoutePoint>.from(buffer, growable: false),
              startedAt: buffer.first.timestamp,
              endedAt: buffer.last.timestamp,
            ),
          );
        }
        buffer = [point];
        continue;
      }

      buffer.add(point);
    }

    if (buffer.length >= _minTripPoints) {
      trips.add(
        LearnedTrip(
          id: buffer.first.timestamp.microsecondsSinceEpoch.toString(),
          points: List<RoutePoint>.from(buffer, growable: false),
          startedAt: buffer.first.timestamp,
          endedAt: buffer.last.timestamp,
        ),
      );
    }
    return trips;
  }

  Future<void> _saveLearnedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'version': 2,
          'trips': _learnedTrips.map((trip) => trip.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _completeCurrentTripIfPossible(force: true);
    _safetyCountdownTimer?.cancel();
    _monitorSubscription?.close();
    super.dispose();
  }
}

extension on List<RoutePoint> {
  List<RoutePoint> takeLast(int count) {
    if (length <= count) return List<RoutePoint>.from(this, growable: false);
    return sublist(length - count, length);
  }
}
