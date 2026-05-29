import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'phone': phone,
    'relation': relation,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['_id'] ?? '').toString(),
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
  final Dio _dio = DioClient().dio;
  static const String _contactsStorageKey = 'emergency_contacts_offline_v2';

  EmergencyContactsNotifier() : super(const []);

  Future<void> loadContacts() async {
    final local = _withoutLegacyDefaultContacts(await _loadLocalContacts());
    if (local.isNotEmpty) {
      state = local;
      await _persistLocalContacts(state);
    }

    try {
      final response = await _dio.get(ApiConstants.contacts);
      final decoded = response.data as List<dynamic>;
      final remote = decoded
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
      state = _mergeContacts(local, remote);
      await _persistLocalContacts(state);
    } on DioException {
      if (local.isEmpty) {
        state = const [];
        await _persistLocalContacts(state);
      }
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    final localContact = EmergencyContact(
      id: contact.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : contact.id,
      name: contact.name,
      phone: contact.phone,
      relation: contact.relation,
    );

    state = [localContact, ...state];
    await _persistLocalContacts(state);

    try {
      final response = await _dio.post(
        ApiConstants.contacts,
        data: {
          'name': contact.name,
          'phone': contact.phone,
          'relation': contact.relation,
        },
      );
      final created = EmergencyContact.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = [
        for (final current in state)
          if (current.id == localContact.id) created else current,
      ];
      await _persistLocalContacts(state);
    } on DioException {
      // Keep local data as source of truth when offline/API fails.
    }
  }

  Future<void> updateContact(EmergencyContact contact) async {
    state = [
      for (final current in state)
        if (current.id == contact.id) contact else current,
    ];
    await _persistLocalContacts(state);

    try {
      final response = await _dio.patch(
        '${ApiConstants.contacts}/${contact.id}',
        data: {
          'name': contact.name,
          'phone': contact.phone,
          'relation': contact.relation,
        },
      );
      final updated = EmergencyContact.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = [
        for (final current in state)
          if (current.id == updated.id) updated else current,
      ];
      await _persistLocalContacts(state);
    } on DioException {
      // Keep local update when backend sync fails.
    }
  }

  Future<void> deleteContact(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _persistLocalContacts(state);

    try {
      await _dio.delete('${ApiConstants.contacts}/$id');
    } on DioException {
      // Keep local delete when backend sync fails.
    }
  }

  Future<List<EmergencyContact>> _loadLocalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contactsStorageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      if (raw.trimLeft().startsWith('[')) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) return const [];

        return decoded
            .whereType<Map<String, dynamic>>()
            .map(EmergencyContact.fromJson)
            .toList();
      }

      final decoded = raw.split('\n').where((e) => e.trim().isNotEmpty).map((
        line,
      ) {
        final parts = line.split('|');
        return EmergencyContact(
          id: parts.isNotEmpty ? parts[0] : '',
          name: parts.length > 1 ? parts[1] : '',
          phone: parts.length > 2 ? parts[2] : '',
          relation: parts.length > 3 ? parts[3] : 'Emergency Contact',
        );
      }).toList();
      return decoded;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistLocalContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsStorageKey, raw);
  }

  List<EmergencyContact> _mergeContacts(
    List<EmergencyContact> local,
    List<EmergencyContact> remote,
  ) {
    final byKey = <String, EmergencyContact>{};
    for (final contact in [...local, ...remote]) {
      final key = _contactKey(contact);
      if (key.isEmpty) continue;
      byKey[key] = contact;
    }
    return _withoutLegacyDefaultContacts(byKey.values.toList());
  }

  String _contactKey(EmergencyContact contact) {
    final phone = contact.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.isNotEmpty) return 'phone:$phone';
    if (contact.id.isNotEmpty) return 'id:${contact.id}';
    return '';
  }

  List<EmergencyContact> _withoutLegacyDefaultContacts(
    List<EmergencyContact> contacts,
  ) {
    const legacyPhones = {'7020094073', '9359264978', '8462969160'};
    return contacts.where((contact) {
      final phone = contact.phone.replaceAll(RegExp(r'\D'), '');
      return !contact.id.startsWith('default_') &&
          !legacyPhones.contains(phone);
    }).toList();
  }
}
