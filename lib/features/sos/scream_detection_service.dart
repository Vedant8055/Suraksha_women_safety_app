import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final screamDetectionProvider = Provider((ref) => ScreamDetectionService(ref));

class ScreamDetectionService {
  final Ref _ref;
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderSubscription;
  static const double screamThreshold = -20.0; // dB threshold for scream detection

  ScreamDetectionService(this._ref);

  Future<void> startMonitoring() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    
    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      if (e.decibels != null && e.decibels! > screamThreshold) {
        _ref.read(sosProvider.notifier).triggerSOS();
      }
    });

    await _recorder!.startRecorder(toFile: 'scream_monitor.aac');
  }

  Future<void> stopMonitoring() async {
    await _recorder?.stopRecorder();
    await _recorder?.closeRecorder();
    _recorderSubscription?.cancel();
    _recorder = null;
  }
}
