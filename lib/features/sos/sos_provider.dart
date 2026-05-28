import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/config/app_environment.dart';
import 'package:suraksha_women_safety_app/features/auth/auth_provider.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_sms_service.dart';

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final authState = ref.watch(authProvider);
  return SOSNotifier(authState.user?.id, authState.token);
});

class SOSState {
  final bool isActive;
  final Position? currentPosition;
  final String? error;
  final bool isStreaming;
  final DateTime? lastLocationUpdate;
  final String? sosEventId;
  final String? trackingUrl;

  SOSState({
    this.isActive = false,
    this.currentPosition,
    this.error,
    this.isStreaming = false,
    this.lastLocationUpdate,
    this.sosEventId,
    this.trackingUrl,
  });

  SOSState copyWith({
    bool? isActive,
    Position? currentPosition,
    String? error,
    bool? isStreaming,
    DateTime? lastLocationUpdate,
    String? sosEventId,
    String? trackingUrl,
  }) {
    return SOSState(
      isActive: isActive ?? this.isActive,
      currentPosition: currentPosition ?? this.currentPosition,
      error: error,
      isStreaming: isStreaming ?? this.isStreaming,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      sosEventId: sosEventId ?? this.sosEventId,
      trackingUrl: trackingUrl ?? this.trackingUrl,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  socket_io.Socket? _socket;
  final String? _userId;
  final String? _token;
  StreamSubscription<Position>? _positionSubscription;
  final _dioClient = DioClient();
  final _smsService = SOSSmsService();

  SOSNotifier(this._userId, this._token) : super(SOSState()) {
    if (_userId != null && _token != null) {
      _initSocket();
    }
  }

  void _initSocket() {
    _socket = socket_io.io(
      ApiConstants.socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _token})
          .setExtraHeaders({'Authorization': 'Bearer $_token'})
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join_sos');
    });

    _socket!.onConnectError((error) {
      state = state.copyWith(error: 'Realtime connection failed: $error');
    });

    _socket!.connect();
  }

  Future<void> triggerSOS() async {
    state = state.copyWith(isActive: true, isStreaming: true, error: null);

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      state = state.copyWith(currentPosition: position);

      String? sosEventId;
      String? trackingUrl;
      try {
        final response = await _dioClient.dio.post(
          ApiConstants.createSOS,
          data: {
            'lat': position.latitude,
            'lng': position.longitude,
            'mode': 'normal',
          },
        );
        final data = response.data;
        sosEventId = data is Map<String, dynamic>
            ? (data['_id'] ?? data['id'])?.toString()
            : null;
        final shareToken = data is Map<String, dynamic>
            ? data['shareToken']?.toString()
            : null;
        final responseTrackingUrl = data is Map<String, dynamic>
            ? data['trackingUrl']?.toString()
            : null;
        trackingUrl =
            responseTrackingUrl ??
            (shareToken == null
                ? null
                : '${AppEnvironment.socketBaseUrl.replaceAll(RegExp(r'/$'), '')}/live-sos/$shareToken');
        state = state.copyWith(
          sosEventId: sosEventId,
          trackingUrl: trackingUrl,
        );
      } catch (_) {
        state = state.copyWith(
          error:
              'SOS activated. Live tracking link could not be created, but SMS will include current location.',
        );
      }

      // Emit SOS event via Socket after REST creates the shareable SOS session.
      if (_socket != null && _socket!.connected) {
        _socket!.emit('trigger_sos', {
          'lat': position.latitude,
          'lng': position.longitude,
          'sosEventId': sosEventId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      _sendEmergencySms(position, trackingUrl: trackingUrl);

      // Start continuous location updates
      _startLiveTracking();
    } catch (e) {
      state = state.copyWith(isActive: false, error: e.toString());
    }
  }

  Future<void> _sendEmergencySms(
    Position position, {
    String? trackingUrl,
  }) async {
    try {
      final sent = await _smsService.sendEmergencySms(
        position,
        trackingUrl: trackingUrl,
      );
      if (!sent) {
        state = state.copyWith(
          error: 'SOS activated. SMS permission is needed to send alert SMS.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        error: 'SOS activated. SMS alert could not be sent from this device.',
      );
    }
  }

  void _startLiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (state.isActive) {
            state = state.copyWith(currentPosition: position);
            state = state.copyWith(lastLocationUpdate: DateTime.now());
            if (_socket != null && _socket!.connected) {
              _socket!.emit('update_location', {
                'lat': position.latitude,
                'lng': position.longitude,
                'sosEventId': state.sosEventId,
              });
            }
            _dioClient.dio.post(
              ApiConstants.updateLocation,
              data: {
                'lat': position.latitude,
                'lng': position.longitude,
                if (state.sosEventId != null) 'sosEventId': state.sosEventId,
                'accuracy': position.accuracy,
                'heading': position.heading,
                'speed': position.speed,
              },
            );
          }
        });
  }

  void cancelSOS() {
    state = state.copyWith(isActive: false, isStreaming: false);
    _positionSubscription?.cancel();
    if (_socket != null) {
      _socket!.emit('cancel_sos');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}
