import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';

class NearbyPlaceItem {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final bool? isOpenNow;
  final double? rating;

  const NearbyPlaceItem({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.isOpenNow,
    this.rating,
  });

  String distanceTextFor(String languageCode) {
    if (distanceMeters < 1000) {
      final value = '${distanceMeters.round()} m';
      return switch (_normalizeLanguageCode(languageCode)) {
        'hi' => '$value दूर',
        'mr' => '$value दूर',
        _ => '$value away',
      };
    }
    final value = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    return switch (_normalizeLanguageCode(languageCode)) {
      'hi' => '$value दूर',
      'mr' => '$value दूर',
      _ => '$value away',
    };
  }
}

String _normalizeLanguageCode(String code) {
  final normalized = code.trim().toLowerCase().split(RegExp(r'[_-]')).first;
  return normalized == 'hi' || normalized == 'mr' ? normalized : 'en';
}

enum NearbyPlaceType {
  hospitals,
  policeStations,
  pharmacies,
  washrooms,
  bloodBanks,
}

class NearbyPlacesState {
  final bool isLoading;
  final String? error;
  final NearbyPlaceType? activeType;
  final List<NearbyPlaceItem> places;

  const NearbyPlacesState({
    this.isLoading = false,
    this.error,
    this.activeType,
    this.places = const [],
  });

  NearbyPlacesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    NearbyPlaceType? activeType,
    List<NearbyPlaceItem>? places,
  }) {
    return NearbyPlacesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeType: activeType ?? this.activeType,
      places: places ?? this.places,
    );
  }
}

final nearbyPlacesProvider =
    StateNotifierProvider<NearbyPlacesNotifier, NearbyPlacesState>(
      (ref) => NearbyPlacesNotifier(ref),
    );

class NearbyPlacesNotifier extends StateNotifier<NearbyPlacesState> {
  NearbyPlacesNotifier(this._ref) : super(const NearbyPlacesState());

  final Ref _ref;
  final Dio _dio = Dio();

  @visibleForTesting
  void debugSetState(NearbyPlacesState newState) {
    state = newState;
  }

  void toggleNearby(NearbyPlaceType type) {
    if (state.isLoading) return;

    if (state.activeType == type) {
      state = const NearbyPlacesState();
      return;
    }

    fetchNearby(type);
  }

  Future<void> fetchNearby(NearbyPlaceType type) async {
    final monitor = _ref.read(safetyMonitorProvider);
    final position = monitor.position;

    if (!monitor.gpsEnabled || !monitor.permissionGranted || position == null) {
      state = state.copyWith(
        isLoading: false,
        activeType: type,
        places: const [],
        error: _text(
          en: 'Live GPS not available. Please keep location ON.',
          hi: 'लाइव GPS उपलब्ध नहीं है। कृपया लोकेशन ON रखें।',
          mr: 'लाइव्ह GPS उपलब्ध नाही. कृपया लोकेशन ON ठेवा.',
        ),
      );
      return;
    }

    final apiKey = AppEnvironment.googleMapsApiKey;
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        activeType: type,
        places: const [],
        error: _text(
          en: 'Google Maps API key is missing. Add GOOGLE_MAPS_API_KEY in build config.',
          hi: 'Google Maps API key उपलब्ध नहीं है। build config में GOOGLE_MAPS_API_KEY जोड़ें।',
          mr: 'Google Maps API key उपलब्ध नाही. build config मध्ये GOOGLE_MAPS_API_KEY जोडा.',
        ),
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeType: type,
      places: const [],
    );

    try {
      final responses = await Future.wait(
        _queryParametersFor(type, position, apiKey).map(
          (params) => _dio.get(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
            queryParameters: params,
          ),
        ),
      );

      final parsedById = <String, NearbyPlaceItem>{};

      for (final response in responses) {
        final data = response.data;
        if (data is! Map<String, dynamic>) continue;

        final status = data['status']?.toString() ?? 'UNKNOWN';
        if (status != 'OK' && status != 'ZERO_RESULTS') {
          state = state.copyWith(
            isLoading: false,
            error: _text(
              en: 'Places API error: $status',
              hi: 'Places API त्रुटि: $status',
              mr: 'Places API त्रुटी: $status',
            ),
          );
          return;
        }

        final results = data['results'];

        if (results is List) {
          for (final item in results) {
            if (item is! Map<String, dynamic>) continue;

            final geometry = item['geometry'];
            final location = geometry is Map<String, dynamic>
                ? geometry['location']
                : null;

            final lat = location is Map<String, dynamic>
                ? (location['lat'] as num?)?.toDouble()
                : null;
            final lng = location is Map<String, dynamic>
                ? (location['lng'] as num?)?.toDouble()
                : null;

            if (lat == null || lng == null) continue;

            final openingHours = item['opening_hours'];
            final ratingNum = item['rating'] as num?;
            final placeId =
                item['place_id']?.toString() ??
                '${item['name']}_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lng,
            );

            parsedById[placeId] = NearbyPlaceItem(
              id: placeId,
              name: item['name']?.toString() ?? 'Unnamed place',
              address: item['vicinity']?.toString() ?? 'Address unavailable',
              latitude: lat,
              longitude: lng,
              distanceMeters: distance,
              isOpenNow: openingHours is Map<String, dynamic>
                  ? openingHours['open_now'] as bool?
                  : null,
              rating: ratingNum?.toDouble(),
            );
          }
        }
      }

      final parsed = parsedById.values.toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      state = state.copyWith(
        isLoading: false,
        places: parsed,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        places: const [],
        error: _text(
          en: 'Unable to fetch nearby places right now. Please try again.',
          hi: 'अभी नज़दीकी स्थान लोड नहीं हो सके। कृपया फिर कोशिश करें।',
          mr: 'सध्या जवळची ठिकाणे लोड झाली नाहीत. कृपया पुन्हा प्रयत्न करा.',
        ),
      );
    }
  }

  List<Map<String, Object>> _queryParametersFor(
    NearbyPlaceType type,
    Position position,
    String apiKey,
  ) {
    final base = <String, Object>{
      'location': '${position.latitude},${position.longitude}',
      'radius': 5000,
      'key': apiKey,
      'language': _googlePlacesLanguageCode(),
    };

    if (type == NearbyPlaceType.hospitals) {
      return [
        {...base, 'type': 'hospital'},
      ];
    }

    if (type == NearbyPlaceType.policeStations) {
      return [
        {...base, 'type': 'police'},
      ];
    }

    if (type == NearbyPlaceType.pharmacies) {
      const pharmacyKeywords = [
        'medical store',
        'medical shop',
        'medical hall',
        'chemist',
        'pharmacy',
        'drug store',
        'drugstore',
        'medicals',
      ];

      return [
        {...base, 'type': 'pharmacy'},
        ...pharmacyKeywords.map((keyword) => {...base, 'keyword': keyword}),
      ];
    }

    if (type == NearbyPlaceType.bloodBanks) {
      const bloodBankKeywords = [
        'blood bank',
        'blood donation center',
        'blood centre',
        'blood storage center',
        'hospital blood bank',
      ];

      return bloodBankKeywords
          .map((keyword) => {...base, 'keyword': keyword})
          .toList();
    }

    const washroomKeywords = [
      'public toilet',
      'public restroom',
      'washroom',
      'sanitation room',
      'mall toilet',
      'petrol pump toilet',
      'Dominos toilet',
      'Pizza Hut toilet',
      'McDonalds toilet',
    ];

    return washroomKeywords
        .map((keyword) => {...base, 'keyword': keyword})
        .toList();
  }

  String _googlePlacesLanguageCode() {
    return _normalizeLanguageCode(_ref.read(appLocaleProvider).languageCode);
  }

  String _text({required String en, required String hi, required String mr}) {
    return switch (_normalizeLanguageCode(
      _ref.read(appLocaleProvider).languageCode,
    )) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };
  }
}
