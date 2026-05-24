import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relation': relation,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? 'Emergency Contact',
    );
  }
}

final emergencyContactsProvider =
    StateNotifierProvider<EmergencyContactsNotifier, List<EmergencyContact>>(
      (ref) => EmergencyContactsNotifier()..loadContacts(),
    );

class EmergencyContactsNotifier extends StateNotifier<List<EmergencyContact>> {
  EmergencyContactsNotifier() : super(const []);

  static const _storageKey = 'emergency_contacts_v1';

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      state = const [
        EmergencyContact(name: 'Mom', phone: '9876543210', relation: 'Mother'),
        EmergencyContact(name: 'Dad', phone: '9123456780', relation: 'Father'),
        EmergencyContact(name: 'Best Friend', phone: '9988776655', relation: 'Friend'),
      ];
      await _persist();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    state = [...state, contact];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
