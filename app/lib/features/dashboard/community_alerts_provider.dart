import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';

enum CommunityAlertKind {
  traffic,
  transport,
  lonelyRoad,
  silentZone,
  roadBlock,
  lighting,
}

String _normalizeLanguageCode(String code) {
  final normalized = code.trim().toLowerCase().split(RegExp(r'[_-]')).first;
  return normalized == 'hi' || normalized == 'mr' ? normalized : 'en';
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

  String timeText(String languageCode) {
    final diff = DateTime.now().difference(updatedAt);
    final lang = _normalizeLanguageCode(languageCode);
    if (diff.inMinutes < 1) {
      return switch (lang) {
        'hi' => 'अभी अभी',
        'mr' => 'आत्ताच',
        _ => 'Just now',
      };
    }
    if (diff.inMinutes < 60) {
      return switch (lang) {
        'hi' => '${diff.inMinutes} मिनट पहले',
        'mr' => '${diff.inMinutes} मिनिटांपूर्वी',
        _ => '${diff.inMinutes} mins ago',
      };
    }
    return switch (lang) {
      'hi' => '${diff.inHours} घंटे पहले',
      'mr' => '${diff.inHours} तासांपूर्वी',
      _ => '${diff.inHours} hrs ago',
    };
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
        error: _text(
          en: 'Google Maps API key is missing.',
          hi: 'Google Maps API key उपलब्ध नहीं है।',
          mr: 'Google Maps API key उपलब्ध नाही.',
        ),
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final position = await _resolvePosition();
      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: _text(
            en: 'Live GPS not available. Please keep location ON.',
            hi: 'Live GPS उपलब्ध नहीं है। कृपया location ON रखें।',
            mr: 'Live GPS उपलब्ध नाही. कृपया location ON ठेवा.',
          ),
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
        error: _text(
          en: 'Unable to load live community alerts right now.',
          hi: 'फिलहाल live community alerts लोड नहीं हो सके।',
          mr: 'सध्या live community alerts लोड करता आले नाहीत.',
        ),
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
    final showRoadLighting = now.hour >= 19 || now.hour < 6;

    if (traffic.sampledRoutes == 0) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: _text(
            en: 'Traffic data limited nearby',
            hi: 'पास में ट्रैफ़िक डेटा सीमित है',
            mr: 'जवळ traffic data मर्यादित आहे',
          ),
          detail: _text(
            en: 'Could not sample nearby driving routes from Google Maps.',
            hi: 'Google Maps से नज़दीकी ड्राइविंग रूट sample नहीं हो पाए।',
            mr: 'Google Maps मधून जवळचे driving routes sample करता आले नाहीत.',
          ),
          updatedAt: now,
        ),
      );
    } else if (traffic.maxDelayRatio >= 1.45 ||
        traffic.averageDelayRatio >= 1.3) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: _text(
            en: 'Heavy traffic near you',
            hi: 'आपके पास भारी ट्रैफ़िक',
            mr: 'तुमच्याजवळ जास्त वाहतूक',
          ),
          detail: _text(
            en:
                'Live routes are taking about ${(traffic.maxDelayRatio * 100).round()}% of normal time on the slowest sampled road.',
            hi:
                'सबसे धीमी sample की गई सड़क पर live route लगभग ${(traffic.maxDelayRatio * 100).round()}% सामान्य समय ले रहा है।',
            mr:
                'सर्वात मंद sample घेतलेल्या रस्त्यावर live route सुमारे ${(traffic.maxDelayRatio * 100).round()}% सामान्य वेळ घेत आहे.',
          ),
          updatedAt: now,
        ),
      );
    } else {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.traffic,
          title: _text(
            en: 'Traffic looks normal nearby',
            hi: 'पास में ट्रैफ़िक सामान्य लग रहा है',
            mr: 'जवळची वाहतूक सामान्य दिसते',
          ),
          detail: _text(
            en:
                '${traffic.sampledRoutes} nearby road directions checked with live Google traffic.',
            hi:
                'नज़दीक की ${traffic.sampledRoutes} सड़क दिशाएँ live Google traffic के साथ जाँची गईं।',
            mr:
                'जवळच्या ${traffic.sampledRoutes} रस्त्यांचे live Google traffic सह परीक्षण केले.',
          ),
          updatedAt: now,
        ),
      );
    }

    if (traffic.failedRoutes > 0 || traffic.maxDelayRatio >= 1.8) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.roadBlock,
          title: _text(
            en: 'Possible route blockage or detour',
            hi: 'रास्ते में रुकावट या वैकल्पिक मार्ग संभव',
            mr: 'मार्ग अडथळा किंवा पर्यायी मार्ग शक्य',
          ),
          detail: _text(
            en:
                'Google routing shows failed or unusually delayed nearby route samples. Check map before moving.',
            hi:
                'Google routing में failed या unusually delayed route samples दिखे हैं। चलने से पहले map देखें।',
            mr:
                'Google routing मध्ये failed किंवा unusually delayed route samples दिसले. निघण्यापूर्वी map तपासा.',
          ),
          updatedAt: now,
        ),
      );
    }

    alerts.add(
      CommunityAlertItem(
        kind: CommunityAlertKind.transport,
        title: _text(
          en: 'Public transport network available',
          hi: 'सार्वजनिक परिवहन नेटवर्क उपलब्ध',
          mr: 'सार्वजनिक वाहतुक जाळे उपलब्ध',
        ),
        detail: _text(
          en:
              'Auto rickshaws, buses, taxis, and other local ride options are available around your current area.',
          hi:
              'ऑटो रिक्शा, बस, टैक्सी और अन्य स्थानीय सवारी विकल्प आपके वर्तमान क्षेत्र में उपलब्ध हैं।',
          mr:
              'ऑटो रिक्षा, बस, टॅक्सी आणि इतर स्थानिक प्रवास पर्याय तुमच्या सध्याच्या परिसरात उपलब्ध आहेत.',
        ),
        updatedAt: now,
      ),
    );

    if (nearby.activePlaces < 4 && transitCount < 2) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.lonelyRoad,
          title: _text(
            en: 'Low activity area detected',
            hi: 'कम गतिविधि वाला क्षेत्र मिला',
            mr: 'कमी हालचालीचा परिसर आढळला',
          ),
          detail: _text(
            en:
                'Few open public places and transit points were found nearby. Stay alert and prefer main roads.',
            hi:
                'नज़दीक कुछ ही खुले सार्वजनिक स्थान और transit points मिले। सतर्क रहें और मुख्य सड़कों को प्राथमिकता दें।',
            mr:
                'जवळ काहीच खुले सार्वजनिक ठिकाणे आणि transit points आढळले. सतर्क राहा आणि मुख्य रस्ते वापरा.',
          ),
          updatedAt: now,
        ),
      );
    }

    if (silentZoneCount >= 2) {
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.silentZone,
          title: _text(
            en: 'Silent-zone context nearby',
            hi: 'शांत क्षेत्र संदर्भ पास में',
            mr: 'शांत-क्षेत्र संदर्भ जवळ',
          ),
          detail: _text(
            en: '$silentZoneCount hospitals, schools, or court locations found around you.',
            hi: 'आपके आसपास $silentZoneCount अस्पताल, स्कूल, या अदालत के स्थान मिले हैं।',
            mr: 'तुमच्या आसपास $silentZoneCount रुग्णालये, शाळा, किंवा न्यायालयांची ठिकाणे आढळली.',
          ),
          updatedAt: now,
        ),
      );
    }

    if (showRoadLighting) {
      final lightingSummary = _buildLightingSummary(nearby, isLateNight);
      alerts.add(
        CommunityAlertItem(
          kind: CommunityAlertKind.lighting,
          title: lightingSummary.title,
          detail: lightingSummary.detail,
          updatedAt: now,
        ),
      );
    }

    return alerts.take(5).toList();
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
        title: _text(
          en: 'Lighting looks strong nearby',
          hi: 'पास में रोशनी अच्छी लग रही है',
          mr: 'जवळ प्रकाशयोजना मजबूत दिसते',
        ),
        detail: _text(
          en:
              '${nearby.nightActivityCount} active public places and ${nearby.transitPointCount} transport points suggest well-used, better-lit roads around you.',
          hi:
              '${nearby.nightActivityCount} सक्रिय सार्वजनिक स्थान और ${nearby.transitPointCount} परिवहन बिंदु आपके आसपास अच्छी तरह उपयोग होने वाली, बेहतर रोशनी वाली सड़कों का संकेत देते हैं।',
          mr:
              '${nearby.nightActivityCount} सक्रिय सार्वजनिक ठिकाणे आणि ${nearby.transitPointCount} वाहतूक बिंदू तुमच्याभोवती चांगले वापरलेले, चांगली प्रकाशमान रस्ते दर्शवतात.',
        ),
      );
    }

    if (lightingSupportScore >= 7) {
      return _LightingSummary(
        title: _text(
          en: 'Lighting looks moderate nearby',
          hi: 'पास में रोशनी मध्यम लग रही है',
          mr: 'जवळ प्रकाशयोजना मध्यम दिसते',
        ),
        detail: _text(
          en:
              '${nearby.nightActivityCount} public venues and ${nearby.transitPointCount} transport points were found nearby, so main roads may stay reasonably lit.',
          hi:
              'नज़दीक ${nearby.nightActivityCount} सार्वजनिक स्थान और ${nearby.transitPointCount} परिवहन बिंदु मिले, इसलिए मुख्य सड़कें काफी हद तक रोशन रह सकती हैं।',
          mr:
              'जवळ ${nearby.nightActivityCount} सार्वजनिक ठिकाणे आणि ${nearby.transitPointCount} वाहतूक बिंदू आढळले, त्यामुळे मुख्य रस्ते बर्‍यापैकी उजळ राहू शकतात.',
        ),
      );
    }

    return _LightingSummary(
      title: isLateNight
          ? _text(
              en: 'Lighting may be limited nearby',
              hi: 'पास में रोशनी सीमित हो सकती है',
              mr: 'जवळ प्रकाश मर्यादित असू शकतो',
            )
          : _text(
              en: 'Lighting coverage looks limited',
              hi: 'रोशनी कवरेज सीमित लग रही है',
              mr: 'प्रकाश कव्हरेज मर्यादित दिसते',
            ),
      detail: _text(
        en:
            'Few public venues, fuel stops, parking areas, or transit points were found nearby. Prefer brighter main roads if you move out.',
        hi:
            'नज़दीक कुछ ही सार्वजनिक स्थान, ईंधन स्टॉप, पार्किंग क्षेत्र, या परिवहन बिंदु मिले। बाहर जाएँ तो अधिक रोशनी वाली मुख्य सड़कों को प्राथमिकता दें।',
        mr:
            'जवळ काहीच सार्वजनिक ठिकाणे, इंधन स्टॉप, पार्किंग क्षेत्रे, किंवा वाहतूक बिंदू आढळले नाहीत. बाहेर गेल्यास अधिक उजळ मुख्य रस्ते निवडा.',
      ),
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

  String _text({
    required String en,
    required String hi,
    required String mr,
  }) {
    return switch (_normalizeLanguageCode(_ref.read(appLocaleProvider).languageCode)) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };
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

class _LightingSummary {
  final String title;
  final String detail;

  const _LightingSummary({required this.title, required this.detail});
}
