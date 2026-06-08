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
  lighting,
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
      _nearbySearch(position, apiKey, keyword: 'bus stop'),
      _nearbySearch(position, apiKey, type: 'transit_station'),
      _nearbySearch(position, apiKey, type: 'train_station'),
      _nearbySearch(position, apiKey, type: 'subway_station'),
      _nearbySearch(position, apiKey, type: 'taxi_stand'),
      _nearbySearch(position, apiKey, keyword: 'auto rickshaw stand'),
      _nearbySearch(position, apiKey, keyword: 'rickshaw stand'),
      _nearbySearch(position, apiKey, keyword: 'cab stand'),
      _nearbySearch(
        position,
        apiKey,
        keyword: 'restaurant OR cafe OR store OR mall',
      ),
      _nearbySearch(position, apiKey, type: 'restaurant'),
      _nearbySearch(position, apiKey, type: 'cafe'),
      _nearbySearch(position, apiKey, type: 'shopping_mall'),
      _nearbySearch(position, apiKey, type: 'convenience_store'),
      _nearbySearch(position, apiKey, type: 'gas_station'),
      _nearbySearch(position, apiKey, type: 'parking'),
      _nearbySearch(position, apiKey, type: 'hospital'),
      _nearbySearch(position, apiKey, type: 'school'),
      _nearbySearch(position, apiKey, type: 'courthouse'),
      _nearbySearch(position, apiKey, type: 'police'),
    ]);

    return _NearbySignals(
      busStops: responses[0],
      busStopKeywords: responses[1],
      transitStations: responses[2],
      trainStations: responses[3],
      metroStations: responses[4],
      taxiStands: responses[5],
      autoRickshawStands: responses[6],
      rickshawStandKeywords: responses[7],
      cabStands: responses[8],
      activePlaces: responses[9],
      restaurants: responses[10],
      cafes: responses[11],
      malls: responses[12],
      convenienceStores: responses[13],
      gasStations: responses[14],
      parkingAreas: responses[15],
      hospitals: responses[16],
      schools: responses[17],
      courts: responses[18],
      policeStations: responses[19],
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
    final transitCount = nearby.transitPointCount;
    final silentZoneCount = nearby.hospitals + nearby.schools + nearby.courts;
    final transportSummary = _buildTransportSummary(nearby);
    final lightingSummary = _buildLightingSummary(nearby, isLateNight);

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
              '${transportSummary.summary}. Fewer transport options look active within about 1.2 km.',
          updatedAt: now,
        ),
      );
    } else if (transportSummary.hasStrongAvailability) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.transport,
          title: 'Public transport active nearby',
          detail:
              '${transportSummary.summary}. Area access looks good for quick movement.',
          updatedAt: now,
        ),
      );
    } else {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.transport,
          title: 'Public transport availability',
          detail:
              '${transportSummary.summary}. Availability looks moderate around your location.',
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
        kind: CommunityAlertKind.lighting,
        title: lightingSummary.title,
        detail: lightingSummary.detail,
        updatedAt: now,
      ),
    );

    return alerts.take(5).toList();
  }

  _TransportSummary _buildTransportSummary(_NearbySignals nearby) {
    final busAccess = nearby.busStops + nearby.busStopKeywords;
    final railAccess =
        nearby.transitStations + nearby.trainStations + nearby.metroStations;
    final taxiAccess =
        nearby.taxiStands +
        nearby.autoRickshawStands +
        nearby.rickshawStandKeywords +
        nearby.cabStands;

    final parts = <String>[];
    if (busAccess > 0) {
      parts.add('$busAccess bus access points');
    }
    if (railAccess > 0) {
      parts.add('$railAccess rail or metro points');
    }
    if (taxiAccess > 0) {
      parts.add('$taxiAccess taxi or auto stands');
    }
    if (parts.isEmpty) {
      parts.add('No bus, rail, taxi, or auto stands were found nearby');
    }

    return _TransportSummary(
      summary: parts.join(', '),
      hasStrongAvailability:
          busAccess >= 2 || railAccess >= 1 || taxiAccess >= 2,
    );
  }

  _LightingSummary _buildLightingSummary(
    _NearbySignals nearby,
    bool isLateNight,
  ) {
    final lightingSupportScore =
        nearby.restaurants +
        nearby.cafes +
        nearby.malls +
        nearby.convenienceStores +
        nearby.gasStations * 2 +
        nearby.parkingAreas +
        nearby.transitPointCount;

    if (lightingSupportScore >= 14) {
      return _LightingSummary(
        title: 'Lighting looks strong nearby',
        detail:
            '${nearby.nightActivityCount} active public places and ${nearby.transitPointCount} transport points suggest well-used, better-lit roads around you.',
      );
    }

    if (lightingSupportScore >= 7) {
      return _LightingSummary(
        title: 'Lighting looks moderate nearby',
        detail:
            '${nearby.nightActivityCount} public venues and ${nearby.transitPointCount} transport points were found nearby, so main roads may stay reasonably lit.',
      );
    }

    return _LightingSummary(
      title: isLateNight
          ? 'Lighting may be limited nearby'
          : 'Lighting coverage looks limited',
      detail:
          'Few public venues, fuel stops, parking areas, or transit points were found nearby. Prefer brighter main roads if you move out.',
    );
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
  final int busStopKeywords;
  final int transitStations;
  final int trainStations;
  final int metroStations;
  final int taxiStands;
  final int autoRickshawStands;
  final int rickshawStandKeywords;
  final int cabStands;
  final int activePlaces;
  final int restaurants;
  final int cafes;
  final int malls;
  final int convenienceStores;
  final int gasStations;
  final int parkingAreas;
  final int hospitals;
  final int schools;
  final int courts;
  final int policeStations;

  const _NearbySignals({
    required this.busStops,
    required this.busStopKeywords,
    required this.transitStations,
    required this.trainStations,
    required this.metroStations,
    required this.taxiStands,
    required this.autoRickshawStands,
    required this.rickshawStandKeywords,
    required this.cabStands,
    required this.activePlaces,
    required this.restaurants,
    required this.cafes,
    required this.malls,
    required this.convenienceStores,
    required this.gasStations,
    required this.parkingAreas,
    required this.hospitals,
    required this.schools,
    required this.courts,
    required this.policeStations,
  });

  int get transitPointCount =>
      busStops +
      busStopKeywords +
      transitStations +
      trainStations +
      metroStations +
      taxiStands +
      autoRickshawStands +
      rickshawStandKeywords +
      cabStands;

  int get nightActivityCount =>
      activePlaces +
      restaurants +
      cafes +
      malls +
      convenienceStores +
      gasStations +
      parkingAreas;
}

class _TransportSummary {
  final String summary;
  final bool hasStrongAvailability;

  const _TransportSummary({
    required this.summary,
    required this.hasStrongAvailability,
  });
}

class _LightingSummary {
  final String title;
  final String detail;

  const _LightingSummary({required this.title, required this.detail});
}
