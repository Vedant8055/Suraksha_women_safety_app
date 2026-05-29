import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';

enum CommunityAlertKind {
  traffic,
  transport,
  lonelyRoad,
  silentZone,
  roadBlock,
  safetyContext,
}

class CommunityAlertItem {
  final CommunityAlertKind kind;
  final String title;
  final String detail;
  final DateTime updatedAt;

  const CommunityAlertItem({
    required this.kind,
    required this.title,
    required this.detail,
    required this.updatedAt,
  });

  String get timeText {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    return '${diff.inHours} hrs ago';
  }
}

class CommunityAlertsState {
  final bool isLoading;
  final String? error;
  final List<CommunityAlertItem> alerts;
  final DateTime? lastUpdatedAt;

  const CommunityAlertsState({
    this.isLoading = false,
    this.error,
    this.alerts = const [],
    this.lastUpdatedAt,
  });

  CommunityAlertsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<CommunityAlertItem>? alerts,
    DateTime? lastUpdatedAt,
  }) {
    return CommunityAlertsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      alerts: alerts ?? this.alerts,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final communityAlertsProvider =
    StateNotifierProvider<CommunityAlertsNotifier, CommunityAlertsState>(
      (ref) => CommunityAlertsNotifier(ref),
    );

class CommunityAlertsNotifier extends StateNotifier<CommunityAlertsState> {
  CommunityAlertsNotifier(this._ref) : super(const CommunityAlertsState());

  final Ref _ref;
  final Dio _dio = Dio();

  Future<void> refresh() async {
    if (state.isLoading) return;

    final apiKey = AppEnvironment.googleMapsApiKey;
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google Maps API key is missing.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final position = await _resolvePosition();
      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Live GPS not available. Please keep location ON.',
        );
        return;
      }

      final results = await Future.wait([
        _trafficSignals(position, apiKey),
        _nearbyCounts(position, apiKey),
      ]);
      final traffic = results[0] as _TrafficSignals;
      final nearby = results[1] as _NearbySignals;
      final now = DateTime.now();
      final alerts = _buildAlerts(traffic, nearby, now);

      state = state.copyWith(
        isLoading: false,
        alerts: alerts,
        lastUpdatedAt: now,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load live community alerts right now.',
      );
    }
  }

  Future<Position?> _resolvePosition() async {
    final monitor = _ref.read(safetyMonitorProvider);
    if (monitor.gpsEnabled &&
        monitor.permissionGranted &&
        monitor.position != null) {
      return monitor.position;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  Future<_TrafficSignals> _trafficSignals(
    Position position,
    String apiKey,
  ) async {
    final destinations = _destinationSamples(position);
    final ratios = <double>[];
    var failedRoutes = 0;

    for (final destination in destinations) {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${position.latitude},${position.longitude}',
          'destination': '${destination.$1},${destination.$2}',
          'mode': 'driving',
          'departure_time': 'now',
          'key': apiKey,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) continue;

      final status = data['status']?.toString() ?? 'UNKNOWN';
      if (status == 'ZERO_RESULTS') {
        failedRoutes++;
        continue;
      }
      if (status != 'OK') continue;

      final routes = data['routes'];
      final firstRoute = routes is List && routes.isNotEmpty
          ? routes.first
          : null;
      final legs = firstRoute is Map<String, dynamic>
          ? firstRoute['legs']
          : null;
      final firstLeg = legs is List && legs.isNotEmpty ? legs.first : null;
      if (firstLeg is! Map<String, dynamic>) continue;

      final duration = _durationValue(firstLeg['duration']);
      final trafficDuration =
          _durationValue(firstLeg['duration_in_traffic']) ?? duration;
      if (duration == null || duration <= 0 || trafficDuration == null) {
        continue;
      }

      ratios.add(trafficDuration / duration);
    }

    if (ratios.isEmpty) {
      return _TrafficSignals(
        averageDelayRatio: 1,
        maxDelayRatio: 1,
        sampledRoutes: 0,
        failedRoutes: failedRoutes,
      );
    }

    final total = ratios.fold<double>(0, (sum, value) => sum + value);
    ratios.sort();

    return _TrafficSignals(
      averageDelayRatio: total / ratios.length,
      maxDelayRatio: ratios.last,
      sampledRoutes: ratios.length,
      failedRoutes: failedRoutes,
    );
  }

  Future<_NearbySignals> _nearbyCounts(Position position, String apiKey) async {
    final responses = await Future.wait([
      _nearbySearch(position, apiKey, type: 'bus_station'),
      _nearbySearch(position, apiKey, type: 'train_station'),
      _nearbySearch(position, apiKey, type: 'subway_station'),
      _nearbySearch(position, apiKey, type: 'taxi_stand'),
      _nearbySearch(
        position,
        apiKey,
        keyword: 'restaurant OR cafe OR store OR mall',
      ),
      _nearbySearch(position, apiKey, type: 'hospital'),
      _nearbySearch(position, apiKey, type: 'school'),
      _nearbySearch(position, apiKey, type: 'courthouse'),
      _nearbySearch(position, apiKey, type: 'police'),
    ]);

    return _NearbySignals(
      busStops: responses[0],
      trainStations: responses[1],
      metroStations: responses[2],
      taxiStands: responses[3],
      activePlaces: responses[4],
      hospitals: responses[5],
      schools: responses[6],
      courts: responses[7],
      policeStations: responses[8],
    );
  }

  Future<int> _nearbySearch(
    Position position,
    String apiKey, {
    String? type,
    String? keyword,
  }) async {
    final params = <String, Object>{
      'location': '${position.latitude},${position.longitude}',
      'radius': 1200,
      'key': apiKey,
    };
    if (type != null) {
      params['type'] = type;
    }
    if (keyword != null) {
      params['keyword'] = keyword;
    }

    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      queryParameters: params,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return 0;
    final status = data['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK' && status != 'ZERO_RESULTS') return 0;
    final results = data['results'];
    return results is List ? results.length : 0;
  }

  List<CommunityAlertItem> _buildAlerts(
    _TrafficSignals traffic,
    _NearbySignals nearby,
    DateTime now,
  ) {
    final alerts = <CommunityAlertItem>[];
    final isLateNight = now.hour >= 22 || now.hour < 5;
    final transitCount =
        nearby.busStops + nearby.trainStations + nearby.metroStations;
    final silentZoneCount = nearby.hospitals + nearby.schools + nearby.courts;

    if (traffic.sampledRoutes == 0) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: 'Traffic data limited nearby',
          detail: 'Could not sample nearby driving routes from Google Maps.',
          updatedAt: now,
        ),
      );
    } else if (traffic.maxDelayRatio >= 1.45 ||
        traffic.averageDelayRatio >= 1.3) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: 'Heavy traffic near you',
          detail:
              'Live routes are taking about ${(traffic.maxDelayRatio * 100).round()}% of normal time on the slowest sampled road.',
          updatedAt: now,
        ),
      );
    } else {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: 'Traffic looks normal nearby',
          detail:
              '${traffic.sampledRoutes} nearby road directions checked with live Google traffic.',
          updatedAt: now,
        ),
      );
    }

    if (traffic.failedRoutes > 0 || traffic.maxDelayRatio >= 1.8) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.roadBlock,
          title: 'Possible route blockage or detour',
          detail:
              'Google routing shows failed or unusually delayed nearby route samples. Check map before moving.',
          updatedAt: now,
        ),
      );
    }

    if (isLateNight && transitCount < 3 && nearby.taxiStands == 0) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.transport,
          title: 'Late-night transport scarcity',
          detail:
              'Few transit points and no taxi stands found within about 1.2 km.',
          updatedAt: now,
        ),
      );
    } else {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.transport,
          title: 'Public transport availability',
          detail:
              '$transitCount transit points and ${nearby.taxiStands} taxi stands found nearby.',
          updatedAt: now,
        ),
      );
    }

    if (nearby.activePlaces < 4 && transitCount < 2) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.lonelyRoad,
          title: 'Low activity area detected',
          detail:
              'Few open public places and transit points were found nearby. Stay alert and prefer main roads.',
          updatedAt: now,
        ),
      );
    }

    if (silentZoneCount >= 2) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.silentZone,
          title: 'Silent-zone context nearby',
          detail:
              '$silentZoneCount hospitals, schools, or court locations found around you.',
          updatedAt: now,
        ),
      );
    }

    alerts.add(
      CommunityAlertItem(
        kind: CommunityAlertKind.safetyContext,
        title: 'Crime activity feed not connected',
        detail:
            'Google Maps does not provide verified crime-frequency alerts. Connect police/community reports for this signal.',
        updatedAt: now,
      ),
    );

    return alerts.take(5).toList();
  }

  List<(double, double)> _destinationSamples(Position position) {
    const delta = 0.018;
    return [
      (position.latitude + delta, position.longitude),
      (position.latitude - delta, position.longitude),
      (position.latitude, position.longitude + delta),
      (position.latitude, position.longitude - delta),
    ];
  }

  int? _durationValue(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return (value['value'] as num?)?.toInt();
  }
}

class _TrafficSignals {
  final double averageDelayRatio;
  final double maxDelayRatio;
  final int sampledRoutes;
  final int failedRoutes;

  const _TrafficSignals({
    required this.averageDelayRatio,
    required this.maxDelayRatio,
    required this.sampledRoutes,
    required this.failedRoutes,
  });
}

class _NearbySignals {
  final int busStops;
  final int trainStations;
  final int metroStations;
  final int taxiStands;
  final int activePlaces;
  final int hospitals;
  final int schools;
  final int courts;
  final int policeStations;

  const _NearbySignals({
    required this.busStops,
    required this.trainStations,
    required this.metroStations,
    required this.taxiStands,
    required this.activePlaces,
    required this.hospitals,
    required this.schools,
    required this.courts,
    required this.policeStations,
  });
}
