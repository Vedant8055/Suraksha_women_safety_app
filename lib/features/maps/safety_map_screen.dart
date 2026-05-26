import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/features/maps/widgets/live_safety_controls_sheet.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class SafetyMapScreen extends StatefulWidget {
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
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 13,
  );

  final _dio = DioClient().dio;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polyline> _polylines = {};
  final List<_PlaceSuggestion> _suggestions = [];

  GoogleMapController? _mapController;
  Position? _position;
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
          _statusText =
              'Unable to fetch location. Move near open sky and try again.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _position = current;
      });

      _setOrUpdateSelfMarker(current);
      await _fetchNearby(current.latitude, current.longitude);
      _startLiveLocationStream();
      _applyInitialTargetIfAny();

      setState(() {
        _isLoading = false;
        _statusText = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusText = 'Could not fetch your location.';
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
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
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
            });

            if (_followMe && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
              );
            }
            setState(() => _statusText = 'Live tracking active');
          },
        );
  }

  Future<void> _fetchNearby(double lat, double lng) async {
    try {
      final policeRes = await _dio.get(
        ApiConstants.nearbyPolice,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final hospitalRes = await _dio.get(
        ApiConstants.nearbyHospitals,
        queryParameters: {'lat': lat, 'lng': lng},
      );

      final markers = <Marker>{};

      for (final p in policeRes.data as List<dynamic>) {
        final coords = p['location']?['coordinates'];
        if (coords is List && coords.length == 2) {
          markers.add(
            Marker(
              markerId: MarkerId('police_${p['_id']}'),
              position: LatLng(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble(),
              ),
              infoWindow: InfoWindow(
                title: p['name']?.toString() ?? 'Police Station',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              onTap: () => _buildRouteTo(
                LatLng(
                  (coords[1] as num).toDouble(),
                  (coords[0] as num).toDouble(),
                ),
              ),
            ),
          );
        }
      }

      for (final h in hospitalRes.data as List<dynamic>) {
        final coords = h['location']?['coordinates'];
        if (coords is List && coords.length == 2) {
          markers.add(
            Marker(
              markerId: MarkerId('hospital_${h['_id']}'),
              position: LatLng(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble(),
              ),
              infoWindow: InfoWindow(
                title: h['name']?.toString() ?? 'Hospital',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              onTap: () => _buildRouteTo(
                LatLng(
                  (coords[1] as num).toDouble(),
                  (coords[0] as num).toDouble(),
                ),
              ),
            ),
          );
        }
      }

      setState(() {
        _markers.removeWhere(
          (m) =>
              m.markerId.value.startsWith('police_') ||
              m.markerId.value.startsWith('hospital_'),
        );
        _markers.addAll(markers);
      });
    } on DioException {
      if (!mounted) return;
      setState(() => _statusText = 'Nearby services unavailable right now.');
    }
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
      final predictions = data is Map<String, dynamic> ? data['predictions'] : null;
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
              title: item['structured_formatting']?['main_text']?.toString() ??
                  item['description']?.toString() ??
                  '',
              subtitle: item['structured_formatting']?['secondary_text']
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
      final geometry = result is Map<String, dynamic> ? result['geometry'] : null;
      final location = geometry is Map<String, dynamic> ? geometry['location'] : null;
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

    if (apiKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF40C4FF),
              width: 5,
              points: [me, target],
            ),
          );
        _statusText = 'Road routing unavailable (missing Maps API key).';
      });
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

      _DirectionRoute? bestRoute;
      for (final routeItem in routes.whereType<Map<String, dynamic>>()) {
        final overview = routeItem['overview_polyline'];
        final points =
            overview is Map<String, dynamic> ? overview['points']?.toString() : null;
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
        final durationText = (firstLeg['duration_in_traffic'] is Map<String, dynamic>)
            ? firstLeg['duration_in_traffic']['text']?.toString()
            : (firstLeg['duration'] is Map<String, dynamic>)
                ? firstLeg['duration']['text']?.toString()
                : null;

        final route = _DirectionRoute(
          encodedPolyline: points,
          etaSeconds: durationInTrafficValue ?? durationValue ?? 1 << 30,
          distanceText: distanceText ?? '',
          durationText: durationText ?? '',
        );

        if (bestRoute == null || route.etaSeconds < bestRoute.etaSeconds) {
          bestRoute = route;
        }
      }

      if (bestRoute == null) {
        throw StateError('No valid route geometry');
      }
      final selectedRoute = bestRoute;

      final routePoints = _decodePolyline(selectedRoute.encodedPolyline);
      if (!mounted) return;
      setState(() {
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF40C4FF),
              width: 5,
              points: routePoints,
            ),
          );
        _statusText =
            'Fastest route by live traffic: ${selectedRoute.distanceText} - ${selectedRoute.durationText}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Road route unavailable, showing direct line fallback.';
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('quick_route'),
              color: const Color(0xFF40C4FF),
              width: 5,
              points: [me, target],
            ),
          );
      });
    }
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
          infoWindow: const InfoWindow(title: 'Custom Pin'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    });
    _buildRouteTo(point);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Intelligence Map')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _position == null
                ? _defaultPosition
                : CameraPosition(
                    target: LatLng(_position!.latitude, _position!.longitude),
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
          _buildTopSearchBar(),
          _buildQuickControls(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const Icon(Icons.tips_and_updates_rounded, size: 17, color: AppTheme.secondaryColor),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _statusText ?? 'Long press to drop pin. Tap markers to preview route.',
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
        ],
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
                  color: AppTheme.cardColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.search, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => _searchLocation(),
                            decoration: const InputDecoration(
                              hintText: 'Search location...',
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
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
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
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                              ),
                              title: Text(
                                suggestion.title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: suggestion.subtitle.isNotEmpty
                                  ? Text(
                                      suggestion.subtitle,
                                      style: const TextStyle(
                                        color: Colors.white60,
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
                color: isLight
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.94)
                    : AppTheme.cardColor.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openSearch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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

class _DirectionRoute {
  const _DirectionRoute({
    required this.encodedPolyline,
    required this.etaSeconds,
    required this.distanceText,
    required this.durationText,
  });

  final String encodedPolyline;
  final int etaSeconds;
  final String distanceText;
  final String durationText;
}
