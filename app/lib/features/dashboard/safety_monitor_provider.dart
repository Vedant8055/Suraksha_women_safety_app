import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';

class SafetyResource {
  final String id;
  final String type;
  final String name;
  final String address;
  final String phone;
  final int distanceMeters;

  const SafetyResource({
    required this.id,
    required this.type,
    required this.name,
    required this.address,
    required this.phone,
    required this.distanceMeters,
  });

  factory SafetyResource.fromJson(Map<String, dynamic> json) {
    return SafetyResource(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'resource',
      name: json['name']?.toString() ?? 'Safety resource',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
    );
  }
}

class SafetyCommunityAlert {
  final String category;
  final String priority;
  final int distanceMeters;
  final DateTime timestamp;
  final String summary;
  final String recommendedAction;

  const SafetyCommunityAlert({
    required this.category,
    required this.priority,
    required this.distanceMeters,
    required this.timestamp,
    required this.summary,
    required this.recommendedAction,
  });

  factory SafetyCommunityAlert.fromJson(Map<String, dynamic> json) {
    return SafetyCommunityAlert(
      category: json['category']?.toString() ?? 'Alert',
      priority: json['priority']?.toString() ?? 'information',
      distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      summary: json['summary']?.toString() ?? '',
      recommendedAction: json['recommendedAction']?.toString() ?? '',
    );
  }
}

class SafetyHeatmapTile {
  final double latitude;
  final double longitude;
  final int safetyScore;
  final String riskLevel;
  final String colorHex;
  final DateTime timestamp;

  const SafetyHeatmapTile({
    required this.latitude,
    required this.longitude,
    required this.safetyScore,
    required this.riskLevel,
    required this.colorHex,
    required this.timestamp,
  });

  factory SafetyHeatmapTile.fromJson(Map<String, dynamic> json) {
    return SafetyHeatmapTile(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      safetyScore: (json['safetyScore'] as num?)?.round() ?? 50,
      riskLevel: json['riskLevel']?.toString() ?? 'Moderate Risk',
      colorHex: json['colorHex']?.toString() ?? '#EAB308',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class UpcomingRiskAlert {
  final int distanceMeters;
  final int safetyScore;
  final String riskLevel;
  final List<String> reasons;
  final String summary;
  final String recommendedAction;

  const UpcomingRiskAlert({
    required this.distanceMeters,
    required this.safetyScore,
    required this.riskLevel,
    required this.reasons,
    required this.summary,
    required this.recommendedAction,
  });

  factory UpcomingRiskAlert.fromJson(Map<String, dynamic> json) {
    return UpcomingRiskAlert(
      distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
      safetyScore: (json['safetyScore'] as num?)?.round() ?? 50,
      riskLevel: json['riskLevel']?.toString() ?? 'Moderate Risk',
      reasons:
          (json['reasons'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      summary: json['summary']?.toString() ?? '',
      recommendedAction: json['recommendedAction']?.toString() ?? '',
    );
  }
}

class SafetyMonitorState {
  final bool gpsEnabled;
  final bool permissionGranted;
  final bool trackingActive;
  final bool isRefreshing;
  final Position? position;
  final DateTime? lastUpdatedAt;
  final int nearbyPoliceCount;
  final int nearbyHospitalCount;
  final int safetyScore;
  final String riskLabel;
  final String statusMessage;
  final int? aiConfidence;
  final bool aiConfidenceVisible;
  final String? limitedAssessmentMessage;
  final List<String> contributingFactors;
  final List<String> recommendations;
  final List<SafetyCommunityAlert> communityAlerts;
  final List<SafetyResource> nearbyResources;
  final List<SafetyHeatmapTile> heatmapTiles;
  final UpcomingRiskAlert? upcomingRisk;
  final String? summary;

  const SafetyMonitorState({
    this.gpsEnabled = false,
    this.permissionGranted = false,
    this.trackingActive = false,
    this.isRefreshing = false,
    this.position,
    this.lastUpdatedAt,
    this.nearbyPoliceCount = 0,
    this.nearbyHospitalCount = 0,
    this.safetyScore = 50,
    this.riskLabel = 'Monitoring',
    this.statusMessage = 'Initializing safety monitor...',
    this.aiConfidence,
    this.aiConfidenceVisible = false,
    this.limitedAssessmentMessage,
    this.contributingFactors = const [],
    this.recommendations = const [],
    this.communityAlerts = const [],
    this.nearbyResources = const [],
    this.heatmapTiles = const [],
    this.upcomingRisk,
    this.summary,
  });

  SafetyMonitorState copyWith({
    bool? gpsEnabled,
    bool? permissionGranted,
    bool? trackingActive,
    bool? isRefreshing,
    Position? position,
    DateTime? lastUpdatedAt,
    int? nearbyPoliceCount,
    int? nearbyHospitalCount,
    int? safetyScore,
    String? riskLabel,
    String? statusMessage,
    int? aiConfidence,
    bool? aiConfidenceVisible,
    String? limitedAssessmentMessage,
    bool clearLimitedAssessmentMessage = false,
    List<String>? contributingFactors,
    List<String>? recommendations,
    List<SafetyCommunityAlert>? communityAlerts,
    List<SafetyResource>? nearbyResources,
    List<SafetyHeatmapTile>? heatmapTiles,
    UpcomingRiskAlert? upcomingRisk,
    bool clearUpcomingRisk = false,
    String? summary,
  }) {
    return SafetyMonitorState(
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      trackingActive: trackingActive ?? this.trackingActive,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      position: position ?? this.position,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      nearbyPoliceCount: nearbyPoliceCount ?? this.nearbyPoliceCount,
      nearbyHospitalCount: nearbyHospitalCount ?? this.nearbyHospitalCount,
      safetyScore: safetyScore ?? this.safetyScore,
      riskLabel: riskLabel ?? this.riskLabel,
      statusMessage: statusMessage ?? this.statusMessage,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiConfidenceVisible: aiConfidenceVisible ?? this.aiConfidenceVisible,
      limitedAssessmentMessage: clearLimitedAssessmentMessage
          ? null
          : (limitedAssessmentMessage ?? this.limitedAssessmentMessage),
      contributingFactors: contributingFactors ?? this.contributingFactors,
      recommendations: recommendations ?? this.recommendations,
      communityAlerts: communityAlerts ?? this.communityAlerts,
      nearbyResources: nearbyResources ?? this.nearbyResources,
      heatmapTiles: heatmapTiles ?? this.heatmapTiles,
      upcomingRisk: clearUpcomingRisk ? null : (upcomingRisk ?? this.upcomingRisk),
      summary: summary ?? this.summary,
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
  Position? _lastAssessmentPosition;

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

  Future<void> refresh() async {
    final pos = state.position;
    if (pos != null) {
      _lastNearbyRefreshAt = DateTime.now();
      await _refreshSafetyIntelligence(pos, force: true);
      return;
    }
    await start();
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
        await _refreshSafetyIntelligence(pos, force: true);
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
            final movedEnough = _lastAssessmentPosition == null
                ? true
                : Geolocator.distanceBetween(
                        _lastAssessmentPosition!.latitude,
                        _lastAssessmentPosition!.longitude,
                        pos.latitude,
                        pos.longitude,
                      ) >=
                      75;
            final staleAssessment = _lastNearbyRefreshAt == null ||
                now.difference(_lastNearbyRefreshAt!) >
                    const Duration(seconds: 45);
            if (movedEnough || staleAssessment) {
              _lastNearbyRefreshAt = now;
              unawaited(_refreshSafetyIntelligence(pos));
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
      await _refreshSafetyIntelligence(pos, force: true);
    });
  }

  Future<void> _refreshSafetyIntelligence(
    Position position, {
    bool force = false,
  }) async {
    state = state.copyWith(isRefreshing: true);
    try {
      final response = await _dio.get(
        ApiConstants.safetyIntelligenceLive,
        queryParameters: {
          'lat': position.latitude,
          'lng': position.longitude,
          'heading': position.heading.isFinite ? position.heading : 0,
          'accuracy': position.accuracy,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid safety intelligence response');
      }

      final current = data['current'];
      final meta = data['meta'];
      var communityAlerts =
          (data['communityAlerts'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(SafetyCommunityAlert.fromJson)
              .toList(growable: false);
      final nearbyResources =
          (data['nearbyResources'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(SafetyResource.fromJson)
              .toList(growable: false);
      final heatmapTiles =
          (data['heatmapTiles'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(SafetyHeatmapTile.fromJson)
              .toList(growable: false);

      final currentMap = current is Map<String, dynamic> ? current : const {};
      final metaMap = meta is Map<String, dynamic> ? meta : const {};
      final upcomingRiskMap = data['upcomingRisk'];
      final policeCount =
          (metaMap['nearbyPoliceCount'] as num?)?.round() ?? state.nearbyPoliceCount;
      final hospitalCount =
          (metaMap['nearbyHospitalCount'] as num?)?.round() ??
          state.nearbyHospitalCount;
      final safetyScore =
          (currentMap['safetyScore'] as num?)?.round() ?? state.safetyScore;
      final riskLabel =
          currentMap['riskLevel']?.toString() ?? state.riskLabel;

      if (communityAlerts.isEmpty) {
        communityAlerts = _buildFallbackCommunityAlerts(
          policeCount: policeCount,
          hospitalCount: hospitalCount,
          safetyScore: safetyScore,
          riskLabel: riskLabel,
        );
      }

      _lastAssessmentPosition = position;
      state = state.copyWith(
        isRefreshing: false,
        nearbyPoliceCount: policeCount,
        nearbyHospitalCount: hospitalCount,
        safetyScore: safetyScore,
        riskLabel: riskLabel,
        aiConfidence: currentMap['aiConfidence'] as int?,
        aiConfidenceVisible: currentMap['aiConfidenceVisible'] == true,
        limitedAssessmentMessage:
            currentMap['limitedAssessmentMessage']?.toString(),
        clearLimitedAssessmentMessage:
            currentMap['limitedAssessmentMessage'] == null,
        contributingFactors:
            (currentMap['contributingFactors'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(growable: false),
        recommendations:
            (currentMap['recommendations'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(growable: false),
        communityAlerts: communityAlerts,
        nearbyResources: nearbyResources,
        heatmapTiles: heatmapTiles,
        upcomingRisk:
            upcomingRiskMap is Map<String, dynamic>
            ? UpcomingRiskAlert.fromJson(upcomingRiskMap)
            : null,
        clearUpcomingRisk: upcomingRiskMap == null,
        summary: currentMap['summary']?.toString(),
        statusMessage: force
            ? 'Safety intelligence updated from verified live context.'
            : state.statusMessage,
      );
    } on DioException {
      await _fallbackRefreshNearbyCounts(position.latitude, position.longitude);
    } catch (_) {
      await _fallbackRefreshNearbyCounts(position.latitude, position.longitude);
    } finally {
      if (state.isRefreshing) {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }

  Future<void> _fallbackRefreshNearbyCounts(double lat, double lng) async {
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
      final fallbackScore = _calculateFallbackScore(policeCount, hospitalCount);
      final risk = fallbackScore >= 80
          ? 'Safe'
          : fallbackScore >= 55
          ? 'Moderate Risk'
          : 'High Risk';

      state = state.copyWith(
        isRefreshing: false,
        nearbyPoliceCount: policeCount,
        nearbyHospitalCount: hospitalCount,
        safetyScore: fallbackScore,
        riskLabel: risk,
        communityAlerts: _buildFallbackCommunityAlerts(
          policeCount: policeCount,
          hospitalCount: hospitalCount,
          safetyScore: fallbackScore,
          riskLabel: risk,
        ),
        statusMessage:
            'Live location active. Safety intelligence is temporarily limited.',
      );
    } on DioException {
      state = state.copyWith(
        isRefreshing: false,
        communityAlerts: _buildFallbackCommunityAlerts(
          policeCount: state.nearbyPoliceCount,
          hospitalCount: state.nearbyHospitalCount,
          safetyScore: state.safetyScore,
          riskLabel: state.riskLabel,
        ),
        statusMessage:
            'Live location active. Nearby service data unavailable.',
      );
    }
  }

  List<SafetyCommunityAlert> _buildFallbackCommunityAlerts({
    required int policeCount,
    required int hospitalCount,
    required int safetyScore,
    required String riskLabel,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final isNight = hour >= 20 || hour < 6;
    final isLateNight = hour >= 23 || hour < 5;
    final showRoadLighting = hour >= 19 || hour < 6;

    return [
      SafetyCommunityAlert(
        category: 'Area Safety Score',
        priority: safetyScore < 45
            ? 'critical'
            : safetyScore < 60
            ? 'caution'
            : 'information',
        distanceMeters: 0,
        timestamp: now,
        summary:
            'Current area safety score is $safetyScore/100 ($riskLabel) based on your live GPS position.',
        recommendedAction: safetyScore < 60
            ? 'Stay alert, share live location, and keep SOS ready.'
            : 'Conditions look manageable. Continue monitoring nearby updates.',
      ),
      SafetyCommunityAlert(
        category: 'Public Transport Network',
        priority: 'information',
        distanceMeters: 400,
        timestamp: now,
        summary:
            'Auto rickshaws, buses, taxis, and other local transport options are available around your current location.',
        recommendedAction:
            'Head to a main road or busy junction for the quickest pickup.',
      ),
      if (showRoadLighting)
        SafetyCommunityAlert(
          category: 'Road Lighting',
          priority: isLateNight ? 'critical' : 'caution',
          distanceMeters: 300,
          timestamp: now,
          summary: isLateNight
              ? 'Streets may be poorly lit after midnight around your current area.'
              : 'Reduced visibility after 7 PM. Street lighting may be inconsistent nearby.',
          recommendedAction:
              'Stay on well-lit main roads and avoid isolated shortcuts.',
        ),
      SafetyCommunityAlert(
        category: 'Pedestrian Activity',
        priority: isLateNight ? 'caution' : 'information',
        distanceMeters: 250,
        timestamp: now,
        summary: isLateNight
            ? 'Very low pedestrian activity is expected after midnight in this area.'
            : isNight
            ? 'Pedestrian footfall typically reduces after 8 PM in this corridor.'
            : 'Normal pedestrian activity is expected during daytime hours near you.',
        recommendedAction: isNight
            ? 'Avoid isolated routes and stay where people are visibly present.'
            : 'Area activity looks normal. Continue with standard precautions.',
      ),
    ];
  }

  int _calculateFallbackScore(int policeCount, int hospitalCount) {
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
