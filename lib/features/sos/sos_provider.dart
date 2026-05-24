import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/features/auth/auth_provider.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';

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

  SOSState({
    this.isActive = false,
    this.currentPosition,
    this.error,
    this.isStreaming = false,
    this.lastLocationUpdate,
  });

  SOSState copyWith({
    bool? isActive,
    Position? currentPosition,
    String? error,
    bool? isStreaming,
    DateTime? lastLocationUpdate,
  }) {
    return SOSState(
      isActive: isActive ?? this.isActive,
      currentPosition: currentPosition ?? this.currentPosition,
      error: error,
      isStreaming: isStreaming ?? this.isStreaming,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  IO.Socket? _socket;
  final String? _userId;
  final String? _token;
  StreamSubscription<Position>? _positionSubscription;
  final _dioClient = DioClient();

  SOSNotifier(this._userId, this._token) : super(SOSState()) {
    if (_userId != null && _token != null) {
      _initSocket();
    }
  }

  void _initSocket() {
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
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

      // Emit SOS event via Socket
      if (_socket != null && _socket!.connected) {
        _socket!.emit('trigger_sos', {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      await _dioClient.dio.post(
        ApiConstants.createSOS,
        data: {
          'lat': position.latitude,
          'lng': position.longitude,
          'mode': 'normal',
        },
      );

      // Start continuous location updates
      _startLiveTracking();
    } catch (e) {
      state = state.copyWith(isActive: false, error: e.toString());
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
              });
            }
            _dioClient.dio.post(
              ApiConstants.updateLocation,
              data: {
                'lat': position.latitude,
                'lng': position.longitude,
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
