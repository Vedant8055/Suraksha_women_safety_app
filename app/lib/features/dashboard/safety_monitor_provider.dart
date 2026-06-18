import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';

class SafetyMonitorState {
  final bool gpsEnabled;
  final bool permissionGranted;
  final bool trackingActive;
  final Position? position;
  final DateTime? lastUpdatedAt;
  final int nearbyPoliceCount;
  final int nearbyHospitalCount;
  final int safetyScore;
  final String riskLabel;
  final String statusMessage;

  const SafetyMonitorState({
    this.gpsEnabled = false,
    this.permissionGranted = false,
    this.trackingActive = false,
    this.position,
    this.lastUpdatedAt,
    this.nearbyPoliceCount = 0,
    this.nearbyHospitalCount = 0,
    this.safetyScore = 50,
    this.riskLabel = 'Monitoring',
    this.statusMessage = 'Initializing safety monitor...',
  });

  SafetyMonitorState copyWith({
    bool? gpsEnabled,
    bool? permissionGranted,
    bool? trackingActive,
    Position? position,
    DateTime? lastUpdatedAt,
    int? nearbyPoliceCount,
    int? nearbyHospitalCount,
    int? safetyScore,
    String? riskLabel,
    String? statusMessage,
  }) {
    return SafetyMonitorState(
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      trackingActive: trackingActive ?? this.trackingActive,
      position: position ?? this.position,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      nearbyPoliceCount: nearbyPoliceCount ?? this.nearbyPoliceCount,
      nearbyHospitalCount: nearbyHospitalCount ?? this.nearbyHospitalCount,
      safetyScore: safetyScore ?? this.safetyScore,
      riskLabel: riskLabel ?? this.riskLabel,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

final safetyMonitorProvider =
    StateNotifierProvider<SafetyMonitorNotifier, SafetyMonitorState>(
      (ref) => SafetyMonitorNotifier(),
    );

class SafetyMonitorNotifier extends StateNotifier<SafetyMonitorState> {
  SafetyMonitorNotifier() : super(const SafetyMonitorState());

  final Dio _dio = DioClient().dio;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _nearbyRefreshTimer;
  bool _started = false;
  DateTime? _lastNearbyRefreshAt;

  Future<void> start() async {
    if (_started && state.trackingActive) return;
    _started = true;

    try {
      await _ensureGpsAndPermission();
      if (!state.gpsEnabled || !state.permissionGranted) {
        state = state.copyWith(trackingActive: false);
        _started = false;
        return;
      }

      await _bootstrapPosition();
      _startLivePositionStream();
      _startNearbyRefreshLoop();
    } catch (_) {
      _started = false;
      state = state.copyWith(trackingActive: false);
    }
  }

  Future<void> retry() async {
    _started = false;
    await stop();
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      await Geolocator.openLocationSettings();
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    try {
      await start();
    } catch (_) {
      state = state.copyWith(trackingActive: false);
    }
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _nearbyRefreshTimer?.cancel();
    _nearbyRefreshTimer = null;
    state = state.copyWith(trackingActive: false);
  }

  Future<void> _ensureGpsAndPermission() async {
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    final deniedForever = permission == LocationPermission.deniedForever;

    state = state.copyWith(
      gpsEnabled: gpsEnabled,
      permissionGranted: granted,
      statusMessage: !gpsEnabled
          ? 'GPS is off. Turn on location to capture live area data.'
          : deniedForever
          ? 'Location permission permanently denied. Enable it in App Settings.'
          : !granted
          ? 'Location permission required for realtime safety monitoring.'
          : 'GPS connected. Capturing realtime safety data.',
      riskLabel: !gpsEnabled || !granted ? 'Location Off' : state.riskLabel,
    );
  }

  Future<void> _bootstrapPosition() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null) {
        state = state.copyWith(
          position: pos,
          lastUpdatedAt: DateTime.now(),
          trackingActive: true,
          statusMessage: 'Live location stream active.',
        );
        await _fetchNearbyCounts(pos.latitude, pos.longitude);
      }
    } catch (_) {}
  }

  void _startLivePositionStream() {
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
            intervalDuration: const Duration(seconds: 8),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Suraksha Safety Monitor',
              notificationText: 'Capturing realtime area safety data.',
              enableWakeLock: false,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (pos) {
            state = state.copyWith(
              position: pos,
              trackingActive: true,
              lastUpdatedAt: DateTime.now(),
              statusMessage: 'Realtime area monitoring in progress.',
            );

            final now = DateTime.now();
            if (_lastNearbyRefreshAt == null ||
                now.difference(_lastNearbyRefreshAt!) >
                    const Duration(seconds: 60)) {
              _lastNearbyRefreshAt = now;
              _fetchNearbyCounts(pos.latitude, pos.longitude);
            }
          },
          onError: (_) {
            state = state.copyWith(
              trackingActive: false,
              statusMessage: 'Live location stream paused.',
            );
          },
        );
  }

  void _startNearbyRefreshLoop() {
    _nearbyRefreshTimer?.cancel();
    _nearbyRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      final pos = state.position;
      if (pos == null) return;
      await _fetchNearbyCounts(pos.latitude, pos.longitude);
    });
  }

  Future<void> _fetchNearbyCounts(double lat, double lng) async {
    try {
      final policeRes = await _dio.get(
        ApiConstants.nearbyPolice,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final hospitalRes = await _dio.get(
        ApiConstants.nearbyHospitals,
        queryParameters: {'lat': lat, 'lng': lng},
      );

      final policeData = policeRes.data;
      final hospitalData = hospitalRes.data;
      final policeCount = policeData is List ? policeData.length : 0;
      final hospitalCount = hospitalData is List ? hospitalData.length : 0;
      final score = _calculateScore(policeCount, hospitalCount);
      final risk = score >= 80
          ? 'Low Risk'
          : score >= 55
          ? 'Moderate Risk'
          : 'High Risk';

      state = state.copyWith(
        nearbyPoliceCount: policeCount,
        nearbyHospitalCount: hospitalCount,
        safetyScore: score,
        riskLabel: risk,
        statusMessage: policeCount == 0 && hospitalCount == 0
            ? 'GPS active. No mapped police/hospital found in 10km radius.'
            : 'Realtime area monitoring in progress.',
      );
    } on DioException {
      state = state.copyWith(
        statusMessage: 'Live location active. Nearby service data unavailable.',
      );
    }
  }

  int _calculateScore(int policeCount, int hospitalCount) {
    var score = 40 + (policeCount * 8) + (hospitalCount * 6);
    if (state.position != null && state.position!.accuracy <= 20) {
      score += 8;
    }
    if (state.trackingActive) {
      score += 6;
    }
    if (score > 98) score = 98;
    return score;
  }
}
