import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/features/dashboard/safety_monitor_provider.dart';

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

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
  }
}

enum NearbyPlaceType { hospitals, policeStations, washrooms, bloodBanks }

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
        error: 'Live GPS not available. Please keep location ON.',
      );
      return;
    }

    final apiKey = AppEnvironment.googleMapsApiKey;
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        activeType: type,
        places: const [],
        error:
            'Google Maps API key is missing. Add GOOGLE_MAPS_API_KEY in build config.',
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
            error: 'Places API error: $status',
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
        error: 'Unable to fetch nearby places right now. Please try again.',
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
}
