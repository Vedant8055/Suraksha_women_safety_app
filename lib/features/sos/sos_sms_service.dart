import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SOSSmsService {
  static const List<String> emergencyNumbers = [
    '7020094073',
    '9359264978',
    '8462969160',
  ];
  static const MethodChannel _channel = MethodChannel('suraksha/sms');

  Future<bool> sendEmergencySms(
    Position position, {
    String? trackingUrl,
  }) async {
    if (!Platform.isAndroid) return false;

    final permission = await Permission.sms.request();
    if (!permission.isGranted) return false;

    final mapsUrl =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    final message =
        'Kaveri is in danger, please send help to her. '
        '${trackingUrl == null ? '' : 'Track live location: $trackingUrl '}'
        'Current location: $mapsUrl '
        'Coordinates: ${position.latitude}, ${position.longitude}';

    var sentCount = 0;
    for (final phoneNumber in emergencyNumbers) {
      try {
        final sent = await _channel.invokeMethod<bool>('sendSms', {
          'phoneNumber': phoneNumber,
          'message': message,
        });
        if (sent == true) sentCount++;
      } catch (_) {
        // Continue trying the remaining emergency contacts.
      }
    }

    return sentCount > 0;
  }
}
