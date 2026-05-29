import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';

final sensorServiceProvider = Provider((ref) => SensorService(ref));

class SensorService {
  final Ref _ref;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  static const double impactThreshold = 30.0;

  SensorService(this._ref);

  void startImpactDetection() {
    _accelerometerSubscription = userAccelerometerEventStream().listen((
      UserAccelerometerEvent event,
    ) {
      double acceleration = event.x.abs() + event.y.abs() + event.z.abs();

      if (acceleration > impactThreshold) {
        debugPrint('IMPACT DETECTED: $acceleration');
        _ref.read(sosProvider.notifier).triggerSOS();
      }
    });
  }

  void stopImpactDetection() {
    _accelerometerSubscription?.cancel();
  }
}
