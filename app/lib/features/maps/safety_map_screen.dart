import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/features/maps/widgets/live_safety_controls_sheet.dart';
import 'package:suraksha_women_safety_app/features/routes/route_safety_provider.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class SafetyMapScreen extends ConsumerStatefulWidget {
  const SafetyMapScreen({
    super.key,
    this.initialTargetLatitude,
    this.initialTargetLongitude,
    this.initialTargetName,
  });

  final double? initialTargetLatitude;
  final double? initialTargetLongitude;
  final String? initialTargetName;

  @override
  ConsumerState<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends ConsumerState<SafetyMapScreen> {
  final _dio = DioClient().dio;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polyline> _polylines = {};
  final List<_PlaceSuggestion> _suggestions = [];

  GoogleMapController? _mapController;
  Position? _position;
  LatLng? _selectedDestination;
  String? _selectedDestinationName;
  Position? _lastJourneyPosition;
  StreamSubscription<Position>? _liveLocationSubscription;
  Timer? _searchDebounce;

  bool _locationPermissionGranted = false;
  bool _followMe = true;
  bool _trafficEnabled = false;
  MapType _mapType = MapType.normal;
  bool _isLoading = true;
  String? _statusText;
  bool _isSearchOpen = false;
  bool _isLoadingSuggestions = false;
  bool _journeyActive = false;
  bool _journeyPanelCollapsed = false;
  double _coveredDistanceMeters = 0;
  double? _routeDistanceMeters;
  int? _routeEtaSeconds;
  double? _remainingDistanceMeters;
  int? _remainingEtaSeconds;
  double? _smoothedTravelSpeedMps;
  int? _stableEtaSeconds;
  DateTime? _lastEtaUpdateAt;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _liveLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Initializing map services...';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _statusText = 'Location service is disabled.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _statusText = 'Location permission denied.';
      });
      return;
    }

    setState(() => _locationPermissionGranted = true);

    try {
      Position? current;
      try {
        current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        current = await Geolocator.getLastKnownPosition();
      }

      if (current == null) {
        setState(() {
          _isLoading = false;
          _statusText = AppLocalizations.of(context).t('unableToFetchLocation');
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _position = current;
        _isLoading = false;
        _statusText = AppLocalizations.of(context).t('loadingNearbySafetyPoints');
      });

      _setOrUpdateSelfMarker(current);
      _startLiveLocationStream();
      _applyInitialTargetIfAny();
      unawaited(_fetchNearby(current.latitude, current.longitude));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusText = AppLocalizations.of(context).t('couldNotFetchYourLocation');
      });
    }
  }

  void _applyInitialTargetIfAny() {
    final lat = widget.initialTargetLatitude;
    final lng = widget.initialTargetLongitude;
    if (lat == null || lng == null) return;
    _showTargetOnMap(
      LatLng(lat, lng),
      widget.initialTargetName?.trim().isNotEmpty == true
          ? widget.initialTargetName!
          : 'Selected Location',
    );
  }

  Future<void> _showTargetOnMap(LatLng target, String title) async {
    setState(() {
      _selectedDestination = target;
      _selectedDestinationName = title;
      _journeyActive = false;
      _journeyPanelCollapsed = false;
      _resetJourneyMetrics();
      _markers.removeWhere((m) => m.markerId.value == 'search_result');
      _markers.add(
        Marker(
          markerId: const MarkerId('search_result'),
          position: target,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      );
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
    );
    _buildRouteTo(target);
  }

  void _setOrUpdateSelfMarker(Position pos) {
    final me = LatLng(pos.latitude, pos.longitude);
    _markers.removeWhere((m) => m.markerId.value == 'me');
    _markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    _circles.removeWhere((c) => c.circleId.value == 'me_accuracy');
    _circles.add(
      Circle(
        circleId: const CircleId('me_accuracy'),
        center: me,
        radius: pos.accuracy > 0 ? pos.accuracy : 20,
        fillColor: Colors.blue.withValues(alpha: 0.12),
        strokeColor: Colors.blue.withValues(alpha: 0.35),
        strokeWidth: 1,
      ),
    );
  }

  void _startLiveLocationStream() {
    _liveLocationSubscription?.cancel();

    final LocationSettings locationSettings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 2),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Suraksha Live Location',
              notificationText: 'Tracking live location for safety features.',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          );

    _liveLocationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) {
            if (!mounted) return;

            setState(() {
              _position = pos;
              _setOrUpdateSelfMarker(pos);
              _updateJourneyProgress(pos);
              _statusText = _journeyActive
                  ? AppLocalizations.of(context).t('journeyTrackingActive')
                  : AppLocalizations.of(context).t('liveTrackingActive');
            });

            if (_followMe && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
              );
            }
          },
        );
  }

  void _selectDestination(LatLng target, String title) {
    setState(() {
      _selectedDestination = target;
      _selectedDestinationName = title;
      _journeyActive = false;
      _journeyPanelCollapsed = false;
      _resetJourneyMetrics();
    });
    _buildRouteTo(target);
  }

  void _startJourney() {
    final pos = _position;
    final destination = _selectedDestination;
    if (pos == null || destination == null) return;

    setState(() {
      _journeyActive = true;
      _journeyPanelCollapsed = true;
      _followMe = true;
      _coveredDistanceMeters = 0;
      _lastJourneyPosition = pos;
      _smoothedTravelSpeedMps = null;
      _lastEtaUpdateAt = null;
      _remainingDistanceMeters = _distanceBetween(
        LatLng(pos.latitude, pos.longitude),
        destination,
      );
      _stableEtaSeconds = _routeEtaSeconds;
      _remainingEtaSeconds = _computeStableEtaSeconds(pos);
      _statusText = AppLocalizations.of(context).t('journeyTrackingActive');
    });

    unawaited(ref.read(routeSafetyProvider.notifier).refreshNow());
    _goToMyLocation();
  }

  void _stopJourney() {
    setState(() {
      _journeyActive = false;
      _journeyPanelCollapsed = false;
      _lastJourneyPosition = null;
      _smoothedTravelSpeedMps = null;
      _stableEtaSeconds = null;
      _lastEtaUpdateAt = null;
      _statusText = AppLocalizations.of(context).t('journeyStopped');
    });
    unawaited(ref.read(routeSafetyProvider.notifier).clearActiveMapRoute());
  }

  void _resetJourneyMetrics() {
    _lastJourneyPosition = null;
    _coveredDistanceMeters = 0;
    _routeDistanceMeters = null;
    _routeEtaSeconds = null;
    _remainingDistanceMeters = null;
    _remainingEtaSeconds = null;
    _smoothedTravelSpeedMps = null;
    _stableEtaSeconds = null;
    _lastEtaUpdateAt = null;
  }

  void _setJourneyPanelCollapsed(bool collapsed) {
    if (_journeyPanelCollapsed == collapsed) return;
    setState(() => _journeyPanelCollapsed = collapsed);
  }

  void _updateJourneyProgress(Position pos) {
    final destination = _selectedDestination;
    if (!_journeyActive || destination == null) return;

    final last = _lastJourneyPosition;
    if (last != null) {
      final moved = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (moved >= 3) {
        _coveredDistanceMeters += moved;
      }
    }

    _lastJourneyPosition = pos;
    final directRemaining = _distanceBetween(
      LatLng(pos.latitude, pos.longitude),
      destination,
    );
    final routeRemaining = _routeDistanceMeters == null
        ? null
        : (_routeDistanceMeters! - _coveredDistanceMeters)
              .clamp(0, double.infinity)
              .toDouble();

    _remainingDistanceMeters = routeRemaining == null
        ? directRemaining
        : routeRemaining < directRemaining
        ? directRemaining
        : routeRemaining;
    _remainingEtaSeconds = _computeStableEtaSeconds(pos);

    if (directRemaining <= 35) {
      _journeyActive = false;
      _stableEtaSeconds = 0;
      _statusText = 'Destination reached';
    }
  }

  int? _estimateEtaSeconds(Position pos) {
    final remaining = _remainingDistanceMeters;
    if (remaining == null) return _routeEtaSeconds;

    if (pos.speed.isFinite && pos.speed > 1) {
      return (remaining / pos.speed).round();
    }

    if (_routeDistanceMeters != null &&
        _routeDistanceMeters! > 0 &&
        _routeEtaSeconds != null) {
      final progress = (remaining / _routeDistanceMeters!).clamp(0.0, 1.0);
      return (_routeEtaSeconds! * progress).round();
    }

    const walkingSpeedMetersPerSecond = 1.4;
    return (remaining / walkingSpeedMetersPerSecond).round();
  }

  int? _computeStableEtaSeconds(Position pos) {
    final estimated = _estimateEtaSeconds(pos);
    if (estimated == null) return _stableEtaSeconds ?? _routeEtaSeconds;

    final remaining = _remainingDistanceMeters;
    if (remaining == null) return estimated;

    final now = DateTime.now();
    final rawSpeed = pos.speed.isFinite ? pos.speed : 0;
    final trustworthySpeed = rawSpeed >= 1.8 && rawSpeed <= 33;
    if (trustworthySpeed) {
      final previous = _smoothedTravelSpeedMps ?? rawSpeed;
      _smoothedTravelSpeedMps = (previous * 0.72) + (rawSpeed * 0.28);
    }

    final routeBasedEta =
        (_routeDistanceMeters != null &&
            _routeDistanceMeters! > 0 &&
            _routeEtaSeconds != null)
        ? (_routeEtaSeconds! *
                  (remaining / _routeDistanceMeters!).clamp(0.0, 1.0))
              .round()
        : null;
    final speedBasedEta =
        (_smoothedTravelSpeedMps != null && _smoothedTravelSpeedMps! >= 1.8)
        ? (remaining / _smoothedTravelSpeedMps!).round()
        : null;

    var candidate = routeBasedEta ?? estimated;
    if (speedBasedEta != null && routeBasedEta != null) {
      candidate = ((routeBasedEta * 0.7) + (speedBasedEta * 0.3)).round();
    } else if (speedBasedEta != null) {
      candidate = speedBasedEta;
    }

    final lastStable = _stableEtaSeconds;
    if (lastStable == null) {
      _stableEtaSeconds = candidate;
      _lastEtaUpdateAt = now;
      return candidate;
    }

    final elapsedSeconds = _lastEtaUpdateAt == null
        ? 999
        : now.difference(_lastEtaUpdateAt!).inSeconds;
    if (elapsedSeconds < 6) {
      return lastStable;
    }

    final delta = candidate - lastStable;
    final maxStep = lastStable > 20 * 60 ? 90 : 45;
    final bounded = delta.abs() <= maxStep
        ? candidate
        : lastStable + (delta.isNegative ? -maxStep : maxStep);
    final progressAdjusted = min(lastStable, bounded);
    final floorProtected = remaining <= 80
        ? min(progressAdjusted, 60)
        : progressAdjusted;

    _stableEtaSeconds = floorProtected.clamp(0, 24 * 60 * 60);
    _lastEtaUpdateAt = now;
    return _stableEtaSeconds;
  }

  double _distanceBetween(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  Future<void> _fetchNearby(double lat, double lng) async {
    try {
      final markers = <Marker>{};
      final results = await Future.wait([
        _fetchNearbyMarkers(
          endpoint: ApiConstants.nearbyPolice,
          lat: lat,
          lng: lng,
          markerPrefix: 'police',
          markerHue: BitmapDescriptor.hueBlue,
          fallbackTitle: 'Police Station',
          serviceLabel: 'Police stations',
        ),
        _fetchNearbyMarkers(
          endpoint: ApiConstants.nearbyHospitals,
          lat: lat,
          lng: lng,
          markerPrefix: 'hospital',
          markerHue: BitmapDescriptor.hueRed,
          fallbackTitle: 'Hospital',
          serviceLabel: 'Hospitals',
        ),
      ]);

      final errors = <String>[];
      for (final result in results) {
        markers.addAll(result.markers);
        if (result.errorMessage != null) {
          errors.add(result.errorMessage!);
        }
      }

      setState(() {
        _markers.removeWhere(
          (m) =>
              m.markerId.value.startsWith('police_') ||
              m.markerId.value.startsWith('hospital_'),
        );
        _markers.addAll(markers);
        if (errors.isEmpty) {
          if (!_journeyActive &&
              (_statusText?.contains(
                    AppLocalizations.of(context).t('loadingNearbySafetyPoints'),
                  ) ??
                  false)) {
            _statusText = AppLocalizations.of(context).t('liveTrackingActive');
          }
        } else if (markers.isNotEmpty) {
          _statusText = 'Nearby services loaded with partial issues: ${errors.join(' • ')}';
        } else {
          _statusText = errors.join(' • ');
        }
      });
    } on DioException {
      if (!mounted) return;
      setState(
        () => _statusText = 'Nearby services could not be loaded. Please try again.',
      );
    }
  }

  Future<_NearbyFetchResult> _fetchNearbyMarkers({
    required String endpoint,
    required double lat,
    required double lng,
    required String markerPrefix,
    required double markerHue,
    required String fallbackTitle,
    required String serviceLabel,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {'lat': lat, 'lng': lng},
      );

      final data = response.data;
      if (data is! List) {
        return _NearbyFetchResult(
          errorMessage:
              '$serviceLabel returned an unexpected response from the server.',
        );
      }

      final markers = <Marker>{};
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final coords = item['location']?['coordinates'];
        if (coords is List && coords.length == 2) {
          final itemLat = (coords[1] as num).toDouble();
          final itemLng = (coords[0] as num).toDouble();
          final name = item['name']?.toString() ?? fallbackTitle;
          final id = item['_id']?.toString() ?? '${name}_$itemLat,$itemLng';

          markers.add(
            Marker(
              markerId: MarkerId('${markerPrefix}_$id'),
              position: LatLng(itemLat, itemLng),
              infoWindow: InfoWindow(title: name),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
              onTap: () => _selectDestination(
                LatLng(itemLat, itemLng),
                name,
              ),
            ),
          );
        }
      }

      return _NearbyFetchResult(markers: markers);
    } on DioException catch (error) {
      return _NearbyFetchResult(
        errorMessage: _describeNearbyFetchError(
          serviceLabel: serviceLabel,
          error: error,
        ),
      );
    }
  }

  String _describeNearbyFetchError({
    required String serviceLabel,
    required DioException error,
  }) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return '$serviceLabel could not load because the request timed out.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return '$serviceLabel could not load because the network connection is unavailable.';
    }

    if (error.type == DioExceptionType.badResponse) {
      if (statusCode == 401 || statusCode == 403) {
        return '$serviceLabel could not load because the server rejected the request.';
      }
      if (statusCode == 404) {
        return '$serviceLabel endpoint was not found on the server.';
      }
      if (statusCode != null) {
        return '$serviceLabel service returned HTTP $statusCode.';
      }
      return '$serviceLabel service returned an invalid response.';
    }

    return '$serviceLabel could not load right now.';
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return;

      final loc = locations.first;
      final target = LatLng(loc.latitude, loc.longitude);
      await _showTargetOnMap(target, query);
      _closeSearch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find that location.')),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _isLoadingSuggestions = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    final apiKey = AppEnvironment.googleMapsApiKey;
    if (apiKey.isEmpty) return;

    setState(() => _isLoadingSuggestions = true);
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': apiKey,
          'components': 'country:in',
        },
      );

      final data = response.data;
      final predictions = data is Map<String, dynamic>
          ? data['predictions']
          : null;
      if (predictions is! List) {
        if (!mounted) return;
        setState(() {
          _suggestions.clear();
          _isLoadingSuggestions = false;
        });
        return;
      }

      final parsed = predictions
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => _PlaceSuggestion(
              placeId: item['place_id']?.toString() ?? '',
              title:
                  item['structured_formatting']?['main_text']?.toString() ??
                  item['description']?.toString() ??
                  '',
              subtitle:
                  item['structured_formatting']?['secondary_text']
                      ?.toString() ??
                  '',
            ),
          )
          .where((s) => s.placeId.isNotEmpty && s.title.isNotEmpty)
          .take(6)
          .toList();

      if (!mounted) return;
      setState(() {
        _suggestions
          ..clear()
          ..addAll(parsed);
        _isLoadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions.clear();
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    final apiKey = AppEnvironment.googleMapsApiKey;
    if (apiKey.isEmpty) return;

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': suggestion.placeId,
          'fields': 'geometry/location,name',
          'key': apiKey,
        },
      );

      final result = response.data is Map<String, dynamic>
          ? response.data['result']
          : null;
      final geometry = result is Map<String, dynamic>
          ? result['geometry']
          : null;
      final location = geometry is Map<String, dynamic>
          ? geometry['location']
          : null;
      final lat = location is Map<String, dynamic>
          ? (location['lat'] as num?)?.toDouble()
          : null;
      final lng = location is Map<String, dynamic>
          ? (location['lng'] as num?)?.toDouble()
          : null;
      if (lat == null || lng == null) {
        await _searchLocation();
        return;
      }

      final target = LatLng(lat, lng);
      setState(() {
        _searchController.text = suggestion.title;
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
        _suggestions.clear();
      });
      await _showTargetOnMap(target, suggestion.title);
      _closeSearch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this place.')),
      );
    }
  }

  Future<void> _buildRouteTo(LatLng target) async {
    if (_position == null) return;
    final apiKey = AppEnvironment.googleMapsApiKey;
    final me = LatLng(_position!.latitude, _position!.longitude);
    final requestId = ++_routeRequestId;

    setState(() {
      final directDistance = _distanceBetween(me, target);
      _routeDistanceMeters = directDistance;
      _routeEtaSeconds = null;
      _remainingDistanceMeters = directDistance;
      _remainingEtaSeconds = _journeyActive && _position != null
          ? _computeStableEtaSeconds(_position!)
          : null;
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('quick_route_preview'),
            color: const Color(0xFF5B2A86),
            width: 6,
            points: [me, target],
            patterns: [PatternItem.dash(22), PatternItem.gap(10)],
          ),
        );
      _statusText = 'Loading best route...';
    });

    if (apiKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF4A148C),
              width: 8,
              points: [me, target],
            ),
          );
        _statusText = 'Road routing unavailable (missing Maps API key).';
      });
      _publishMapRouteToGuard(
        routePoints: [me, target],
        destinationName: _selectedDestinationName ?? 'selected destination',
        safetyScore: 50,
        safetyReason: 'Direct fallback route without Google routing',
      );
      return;
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${me.latitude},${me.longitude}',
          'destination': '${target.latitude},${target.longitude}',
          'mode': 'driving',
          'alternatives': 'true',
          'departure_time': 'now',
          'traffic_model': 'best_guess',
          'key': apiKey,
        },
      );

      final data = response.data;
      final routes = data is Map<String, dynamic> ? data['routes'] : null;
      if (routes is! List || routes.isEmpty) {
        throw StateError('No routes found');
      }

      final parsedRoutes = <_DirectionRoute>[];
      for (final routeItem in routes.whereType<Map<String, dynamic>>()) {
        final overview = routeItem['overview_polyline'];
        final points = overview is Map<String, dynamic>
            ? overview['points']?.toString()
            : null;
        if (points == null || points.isEmpty) continue;

        final legs = routeItem['legs'];
        if (legs is! List || legs.isEmpty) continue;
        final firstLeg = legs.first;
        if (firstLeg is! Map<String, dynamic>) continue;

        final durationInTrafficValue =
            (firstLeg['duration_in_traffic'] is Map<String, dynamic>)
            ? (firstLeg['duration_in_traffic']['value'] as num?)?.toInt()
            : null;
        final durationValue = (firstLeg['duration'] is Map<String, dynamic>)
            ? (firstLeg['duration']['value'] as num?)?.toInt()
            : null;
        final distanceText = (firstLeg['distance'] is Map<String, dynamic>)
            ? firstLeg['distance']['text']?.toString()
            : null;
        final distanceValue = (firstLeg['distance'] is Map<String, dynamic>)
            ? (firstLeg['distance']['value'] as num?)?.toDouble()
            : null;
        final durationText =
            (firstLeg['duration_in_traffic'] is Map<String, dynamic>)
            ? firstLeg['duration_in_traffic']['text']?.toString()
            : (firstLeg['duration'] is Map<String, dynamic>)
            ? firstLeg['duration']['text']?.toString()
            : null;
        final routePoints = _decodePolyline(points);
        if (routePoints.isEmpty) continue;
        final routeScore = _scoreRouteSafety(
          routePoints: routePoints,
          etaSeconds: durationInTrafficValue ?? durationValue,
          distanceMeters: distanceValue ?? _polylineDistance(routePoints),
        );

        parsedRoutes.add(
          _DirectionRoute(
            encodedPolyline: points,
            etaSeconds: durationInTrafficValue ?? durationValue ?? 1 << 30,
            distanceMeters: distanceValue,
            distanceText: distanceText ?? '',
            durationText: durationText ?? '',
            safetyScore: routeScore.score,
            safetyReason: routeScore.reason,
          ),
        );
      }

      if (parsedRoutes.isEmpty) {
        throw StateError('No valid route geometry');
      }
      parsedRoutes.sort((a, b) {
        final safetyCompare = b.safetyScore.compareTo(a.safetyScore);
        if (safetyCompare != 0) return safetyCompare;
        return a.etaSeconds.compareTo(b.etaSeconds);
      });
      final selectedRoute = parsedRoutes.first;

      final routePoints = _decodePolyline(selectedRoute.encodedPolyline);
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routeDistanceMeters =
            selectedRoute.distanceMeters ?? _polylineDistance(routePoints);
        _routeEtaSeconds = selectedRoute.etaSeconds;
        final pos = _position;
        if (_journeyActive && pos != null) {
          _remainingDistanceMeters = _routeDistanceMeters == null
              ? _distanceBetween(LatLng(pos.latitude, pos.longitude), target)
              : (_routeDistanceMeters! - _coveredDistanceMeters)
                    .clamp(0, double.infinity)
                    .toDouble();
          _remainingEtaSeconds = _computeStableEtaSeconds(pos);
        } else {
          _remainingDistanceMeters = _routeDistanceMeters;
          _remainingEtaSeconds = _routeEtaSeconds;
        }
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF4A148C),
              width: 8,
              points: routePoints,
            ),
          );
        _statusText =
            'Safest route selected: ${selectedRoute.distanceText} - ${selectedRoute.durationText} | score ${selectedRoute.safetyScore} | ${selectedRoute.safetyReason}';
      });
      _publishMapRouteToGuard(
        routePoints: routePoints,
        destinationName: _selectedDestinationName ?? 'selected destination',
        safetyScore: selectedRoute.safetyScore,
        safetyReason: selectedRoute.safetyReason,
      );
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) return;
      final fallbackPoints = [me, target];
      final fallbackScore = _scoreRouteSafety(
        routePoints: fallbackPoints,
        etaSeconds: null,
        distanceMeters: _distanceBetween(me, target),
      );
      setState(() {
        _routeDistanceMeters = _distanceBetween(me, target);
        _routeEtaSeconds = null;
        _statusText = 'Road route unavailable, showing direct line fallback.';
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF4A148C),
              width: 8,
              points: fallbackPoints,
            ),
          );
      });
      _publishMapRouteToGuard(
        routePoints: fallbackPoints,
        destinationName: _selectedDestinationName ?? 'selected destination',
        safetyScore: fallbackScore.score,
        safetyReason: fallbackScore.reason,
      );
    }
  }

  void _publishMapRouteToGuard({
    required List<LatLng> routePoints,
    required String destinationName,
    required int safetyScore,
    required String safetyReason,
  }) {
    if (routePoints.isEmpty) return;
    final timestamp = DateTime.now();
    unawaited(
      ref
          .read(routeSafetyProvider.notifier)
          .setActiveMapRoute(
            routePoints: routePoints
                .map(
                  (point) => RoutePoint(
                    latitude: point.latitude,
                    longitude: point.longitude,
                    timestamp: timestamp,
                  ),
                )
                .toList(growable: false),
            destinationName: destinationName,
            safetyScore: safetyScore,
            safetyReason: safetyReason,
          ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        if (index >= encoded.length) {
          return points;
        }
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= encoded.length) {
          return points;
        }
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  double _polylineDistance(List<LatLng> points) {
    if (points.length < 2) return 0;

    double total = 0;
    for (var i = 1; i < points.length; i++) {
      total += _distanceBetween(points[i - 1], points[i]);
    }
    return total;
  }

  _RouteSafetyScore _scoreRouteSafety({
    required List<LatLng> routePoints,
    required int? etaSeconds,
    required double distanceMeters,
  }) {
    var score = 68;
    final now = DateTime.now();
    final isNight = now.hour >= 21 || now.hour < 6;
    final emergencyMarkers = _markers.where(
      (marker) =>
          marker.markerId.value.startsWith('police_') ||
          marker.markerId.value.startsWith('hospital_'),
    );

    var nearbyEmergencyCount = 0;
    for (final marker in emergencyMarkers) {
      final nearest = _nearestPointDistance(routePoints, marker.position);
      if (nearest <= 700) nearbyEmergencyCount++;
    }

    score += min(nearbyEmergencyCount * 5, 22);
    if (isNight) score -= 12;
    if (distanceMeters > 12000) score -= 4;
    if (etaSeconds != null && etaSeconds > 45 * 60) score -= 4;
    score = score.clamp(0, 98);

    final reason = nearbyEmergencyCount > 0
        ? '$nearbyEmergencyCount emergency points near route'
        : isNight
        ? 'Night route, limited mapped emergency points'
        : 'Balanced by route length and nearby services';

    return _RouteSafetyScore(score: score, reason: reason);
  }

  double _nearestPointDistance(List<LatLng> routePoints, LatLng target) {
    var nearest = double.infinity;
    for (final point in routePoints) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        target.latitude,
        target.longitude,
      );
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  Future<void> _goToMyLocation() async {
    final pos = _position;
    if (pos == null || _mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
      ),
    );
  }

  void _dropPin(LatLng point) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'custom_pin');
      _markers.add(
        Marker(
          markerId: const MarkerId('custom_pin'),
          position: point,
          infoWindow: InfoWindow(title: AppLocalizations.of(context).t('customPin')),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    });
    _selectDestination(point, AppLocalizations.of(context).t('customPin'));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final position = _position;
    final journeyPanelOffset = _selectedDestination == null
        ? 18.0
        : _journeyPanelCollapsed
        ? 126.0
        : 244.0;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('safetyIntelligenceMap'))),
      body: Stack(
        children: [
          if (position == null)
            _buildLocatingView(isLight)
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (_) {},
              onLongPress: _dropPin,
              onCameraMoveStarted: () {
                if (_followMe) setState(() => _followMe = false);
              },
              markers: _markers,
              circles: _circles,
              polylines: _polylines,
              trafficEnabled: _trafficEnabled,
              compassEnabled: true,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: _mapType,
            ),
          if (position != null) ...[
            _buildTopSearchBar(),
            _buildQuickControls(),
          ],
          Positioned(
            left: 16,
            right: 16,
            bottom: journeyPanelOffset,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.9)
                      : AppTheme.cardColor.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFDCE5F6)
                        : Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 17,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _statusText ??
                            'Long press to drop pin. Tap markers to preview route.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isLight ? Color(0xFF546784) : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading && position != null)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          if (position != null && _selectedDestination != null)
            _buildJourneyPanel(isLight),
        ],
      ),
    );
  }

  Widget _buildJourneyPanel(bool isLight) {
    final destinationName = _selectedDestinationName ?? 'Selected destination';
    final remaining = _remainingDistanceMeters;
    final eta = _remainingEtaSeconds;
    final routeDistance = _routeDistanceMeters;
    final compact = _journeyPanelCollapsed;
    final progress = (routeDistance != null && routeDistance > 0)
        ? (_coveredDistanceMeters / routeDistance).clamp(0.0, 1.0)
        : 0.0;
    final accentColor = _journeyActive
        ? const Color(0xFF0F766E)
        : const Color(0xFF4A148C);
    final accentSoft = _journeyActive
        ? const Color(0xFF14B8A6)
        : const Color(0xFF7C3AED);
    final topGradient = isLight
        ? [
            const Color(0xFFFFFFFF).withValues(alpha: 0.70),
            const Color(0xFFF8FBFF).withValues(alpha: 0.58),
            const Color(0xFFEEF4FF).withValues(alpha: 0.50),
          ]
        : [
            const Color(0xFF1A2337).withValues(alpha: 0.72),
            const Color(0xFF121B2D).withValues(alpha: 0.62),
            const Color(0xFF0A1221).withValues(alpha: 0.54),
          ];
    final statusPillGradient = _journeyActive
        ? const [Color(0xFF0F766E), Color(0xFF14B8A6)]
        : const [Color(0xFF4A148C), Color(0xFF7C3AED)];
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 180) {
            _setJourneyPanelCollapsed(true);
          } else if (velocity < -180) {
            _setJourneyPanelCollapsed(false);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 8 : 10,
                16,
                (compact ? 8 : 12) + safeBottom,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: topGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.58)
                      : Colors.white.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isLight ? 0.10 : 0.26,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _setJourneyPanelCollapsed(!_journeyPanelCollapsed),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 2),
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(
                                      0xFFAFC1DE,
                                    ).withValues(alpha: 0.72)
                                  : Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (compact) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  eta == null ? '--' : _formatDuration(eta),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF172235)
                                        : Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  remaining == null
                                      ? destinationName
                                      : 'Remaining ${_formatDistance(remaining)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF60708B)
                                        : Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destinationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF8A98AE)
                                        : Colors.white54,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _journeyActionButton(
                            label: _journeyActive ? 'Stop' : 'Start',
                            icon: _journeyActive
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            onTap: _journeyActive
                                ? _stopJourney
                                : _startJourney,
                            isLight: isLight,
                            backgroundColor: _journeyActive
                                ? const Color(0xFFDC2626)
                                : accentColor,
                          ),
                          const SizedBox(width: 8),
                          _journeyRoundButton(
                            icon: Icons.keyboard_arrow_up_rounded,
                            onTap: () => _setJourneyPanelCollapsed(
                              !_journeyPanelCollapsed,
                            ),
                            isLight: isLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              routeDistance == null
                                  ? AppLocalizations.of(context).t('calculatingRoute')
                                  : '${_formatDistance(routeDistance)} total route',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60708B)
                                    : Colors.white60,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF344256)
                                  : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: statusPillGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _journeyActive
                                        ? 'Live navigation'
                                        : 'Route preview',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  destinationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF172235)
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _journeyActive
                                      ? AppLocalizations.of(context).t('followingYourRoute')
                                      : AppLocalizations.of(context).t('readyWithDistanceAndEstimatedTravelTime'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF60708B)
                                        : Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              _journeyRoundButton(
                                icon: Icons.keyboard_arrow_down_rounded,
                                onTap: () => _setJourneyPanelCollapsed(
                                  !_journeyPanelCollapsed,
                                ),
                                isLight: isLight,
                              ),
                              const SizedBox(height: 10),
                              _journeyActionButton(
                                label: AppLocalizations.of(context).t(_journeyActive ? 'stop' : 'start'),
                                icon: _journeyActive
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                onTap: _journeyActive
                                    ? _stopJourney
                                    : _startJourney,
                                isLight: isLight,
                                backgroundColor: _journeyActive
                                    ? const Color(0xFFDC2626)
                                    : accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: compact ? 8 : 7,
                        value: progress,
                        backgroundColor: isLight
                            ? const Color(0xFFDDE7F6).withValues(alpha: 0.48)
                            : Colors.white.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _journeyActive ? accentSoft : accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!compact) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 15,
                            color: isLight
                                ? const Color(0xFF60708B)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              routeDistance == null
                                  ? AppLocalizations.of(context).t('calculatingRouteDistance')
                                  : '${_formatDistance(routeDistance)} total route',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60708B)
                                    : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF344256)
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _journeyStat(
                              label: AppLocalizations.of(context).t('covered'),
                              value: _formatDistance(_coveredDistanceMeters),
                              isLight: isLight,
                              icon: Icons.explore_rounded,
                              accent: const Color(0xFF14B8A6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _journeyStat(
                              label: AppLocalizations.of(context).t('remaining'),
                              value: remaining == null
                                  ? '--'
                                  : _formatDistance(remaining),
                              isLight: isLight,
                              icon: Icons.alt_route_rounded,
                              accent: accentSoft,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _journeyStat(
                              label: AppLocalizations.of(context).t('eta'),
                              value: eta == null ? '--' : _formatDuration(eta),
                              isLight: isLight,
                              icon: Icons.schedule_rounded,
                              accent: accentColor,
                              emphasizeValue: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _journeyActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isLight,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journeyRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isLight,
    bool filled = false,
    Color? fillColor,
  }) {
    return Material(
      color: filled
          ? (fillColor ?? AppTheme.primaryColor)
          : (isLight
                ? const Color(0xFFF6F9FF)
                : Colors.white.withValues(alpha: 0.06)),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: filled
                ? Colors.white
                : (isLight ? const Color(0xFF344256) : Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _journeyStat({
    required String label,
    required String value,
    required bool isLight,
    required IconData icon,
    required Color accent,
    bool emphasizeValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  const Color(0xFFF8FBFF),
                  Color.lerp(const Color(0xFFF0F6FF), accent, 0.10)!,
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  accent.withValues(alpha: 0.12),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isLight ? 0.18 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF65758F) : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLight ? const Color(0xFF172235) : Colors.white,
                fontSize: emphasizeValue ? 16 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '<1 min';

    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildLocatingView(bool isLight) {
    final canRetry = !_isLoading && _statusText != null;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isLight ? const Color(0xFFF4F7FB) : AppTheme.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.primaryColor)
              else
                Icon(
                  Icons.location_searching_rounded,
                  size: 42,
                  color: isLight ? AppTheme.primaryColor : Colors.white70,
                ),
              const SizedBox(height: 18),
              Text(
                _statusText ?? 'Fetching your current location...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight ? const Color(0xFF26364D) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).t('mapWillOpenAroundYou'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isLight ? const Color(0xFF65758F) : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canRetry) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _initializeMap,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    setState(() => _isSearchOpen = true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchOpen = false;
      _suggestions.clear();
    });
  }

  Widget _buildTopSearchBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              axisAlignment: 1,
              child: child,
            ),
          );
        },
        child: _isSearchOpen
            ? Container(
                key: const ValueKey('search_open'),
                width: MediaQuery.of(context).size.width * 0.72,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.96)
                      : AppTheme.cardColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isLight ? 0.12 : 0.22,
                      ),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFD6E4FB)
                        : Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        Icon(
                          Icons.search,
                          color: isLight
                              ? const Color(0xFF5F6F8A)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => _searchLocation(),
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF172235)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).t('searchLocation'),
                              hintStyle: TextStyle(
                                color: isLight
                                    ? const Color(0xFF7E8DA6)
                                    : Colors.white54,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _searchLocation,
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        IconButton(
                          onPressed: _closeSearch,
                          icon: Icon(
                            Icons.close,
                            color: isLight
                                ? const Color(0xFF5F6F8A)
                                : Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_suggestions.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isLight
                                ? const Color(0xFFE3EBF7)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.location_on_outlined,
                                color: isLight
                                    ? const Color(0xFF5F6F8A)
                                    : Colors.white70,
                              ),
                              title: Text(
                                suggestion.title,
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF172235)
                                      : Colors.white,
                                ),
                              ),
                              subtitle: suggestion.subtitle.isNotEmpty
                                  ? Text(
                                      suggestion.subtitle,
                                      style: TextStyle(
                                        color: isLight
                                            ? const Color(0xFF7E8DA6)
                                            : Colors.white60,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              onTap: () => _selectSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              )
            : Material(
                key: const ValueKey('search_closed'),
                color: AppTheme.cardColor,
                shape: const CircleBorder(),
                elevation: isLight ? 3 : 5,
                shadowColor: Colors.black.withValues(
                  alpha: isLight ? 0.14 : 0.3,
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openSearch,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(Icons.search, color: Colors.white, size: 21),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickControls() {
    return Positioned(
      right: 16,
      top: _isSearchOpen ? 82 : 92,
      child: Column(
        children: <Widget>[
          _circleControl(
            icon: _followMe ? Icons.gps_fixed : Icons.gps_not_fixed,
            onTap: () {
              setState(() => _followMe = !_followMe);
              if (_followMe) {
                _goToMyLocation();
              }
            },
          ),
          const SizedBox(height: 10),
          _circleControl(
            icon: _trafficEnabled ? Icons.traffic : Icons.traffic_outlined,
            onTap: () {
              setState(() => _trafficEnabled = !_trafficEnabled);
            },
          ),
          const SizedBox(height: 10),
          _circleControl(
            icon: Icons.layers,
            onTap: () {
              setState(() {
                _mapType = _mapType == MapType.normal
                    ? MapType.hybrid
                    : _mapType == MapType.hybrid
                    ? MapType.terrain
                    : MapType.normal;
              });
            },
          ),
          const SizedBox(height: 10),
          _circleControl(icon: Icons.safety_check, onTap: _openLiveSafetySheet),
        ],
      ),
    );
  }

  void _openLiveSafetySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return LiveSafetyControlsSheet(
          position: _position,
          statusText: _statusText,
          onMyLocation: _goToMyLocation,
          onRefreshNearby: () async {
            final pos = _position;
            if (pos == null) return;
            await _fetchNearby(pos.latitude, pos.longitude);
          },
          onRetryLiveLocation: _initializeMap,
        );
      },
    );
  }

  Widget _circleControl({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.cardColor,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
  });

  final String placeId;
  final String title;
  final String subtitle;
}

class _NearbyFetchResult {
  const _NearbyFetchResult({
    this.markers = const {},
    this.errorMessage,
  });

  final Set<Marker> markers;
  final String? errorMessage;
}

class _DirectionRoute {
  const _DirectionRoute({
    required this.encodedPolyline,
    required this.etaSeconds,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationText,
    required this.safetyScore,
    required this.safetyReason,
  });

  final String encodedPolyline;
  final int etaSeconds;
  final double? distanceMeters;
  final String distanceText;
  final String durationText;
  final int safetyScore;
  final String safetyReason;
}

class _RouteSafetyScore {
  const _RouteSafetyScore({required this.score, required this.reason});

  final int score;
  final String reason;
}
