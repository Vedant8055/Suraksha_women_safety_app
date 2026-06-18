import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';

class SOSSmsService {
  static const MethodChannel _channel = MethodChannel('suraksha/sms');

  Future<bool> sendEmergencySms(
    Position position, {
    required List<EmergencyContact> contacts,
    String? trackingUrl,
    String? senderName,
  }) async {
    return _sendStatusSms(
      contacts: contacts,
      senderName: senderName,
      position: position,
      trackingUrl: trackingUrl,
      template: _SmsTemplate.emergency,
    );
  }

  Future<bool> sendSafeSms(
    List<EmergencyContact> contacts, {
    String? senderName,
    Position? position,
  }) async {
    return _sendStatusSms(
      contacts: contacts,
      senderName: senderName,
      position: position,
      template: _SmsTemplate.safe,
    );
  }

  Future<bool> _sendStatusSms({
    required List<EmergencyContact> contacts,
    String? senderName,
    Position? position,
    String? trackingUrl,
    required _SmsTemplate template,
  }) async {
    if (!Platform.isAndroid) return false;

    final phoneNumbers = contacts
        .map((contact) => EmergencyContact.normalizePhoneNumber(contact.phone))
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();
    if (phoneNumbers.isEmpty) return false;

    final permission = await Permission.sms.request();
    if (!permission.isGranted) return false;

    final senderLabel = senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : 'Your contact';
    final locationSnippet = position != null
        ? 'Last known location: https://maps.google.com/?q=${position.latitude},${position.longitude} Coordinates: ${position.latitude}, ${position.longitude}.'
        : '';

    final message = template == _SmsTemplate.emergency
        ? '$senderLabel is in danger. Please send help immediately. '
            '${trackingUrl == null ? '' : 'Track live location: $trackingUrl. '}'
            '${position != null ? 'Current location: https://maps.google.com/?q=${position.latitude},${position.longitude}. Coordinates: ${position.latitude}, ${position.longitude}.' : ''}'
        : '$senderLabel is now safe. The emergency alert has been cleared. $locationSnippet';

    var sentCount = 0;
    for (final phoneNumber in phoneNumbers) {
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

enum _SmsTemplate { emergency, safe }
