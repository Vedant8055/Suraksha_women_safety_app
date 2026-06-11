import 'dart:async';
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
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? 'Emergency Contact',
    );
  }

  EmergencyContact normalized() {
    return EmergencyContact(
      id: id,
      name: name.trim(),
      phone: normalizePhoneNumber(phone),
      relation: relation.trim().isEmpty ? 'Emergency Contact' : relation.trim(),
    );
  }

  static String normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return hasPlus ? '+$digits' : digits;
  }
}

final emergencyContactsProvider =
    StateNotifierProvider<EmergencyContactsNotifier, List<EmergencyContact>>(
      (ref) => EmergencyContactsNotifier()..loadContacts(),
    );

class EmergencyContactsNotifier extends StateNotifier<List<EmergencyContact>> {
  final Dio _dio = DioClient().dio;
  final bool _syncEnabled;
  static const String _contactsStorageKey = 'emergency_contacts_offline_v2';
  Future<void>? _loadContactsFuture;

  EmergencyContactsNotifier({bool syncEnabled = true})
    : _syncEnabled = syncEnabled,
      super(const []);

  Future<void> loadContacts() {
    return _loadContactsFuture ??= _loadContacts().whenComplete(() {
      _loadContactsFuture = null;
    });
  }

  Future<void> _loadContacts() async {
    final local = _withoutLegacyDefaultContacts(await _loadLocalContacts());
    if (local.isNotEmpty) {
      state = _mergeContacts(state, local);
      await _persistLocalContacts(state);
    }
    if (!_syncEnabled) return;

    try {
      final response = await _dio.get(ApiConstants.contacts);
      final remote = _decodeContactsResponse(response.data);
      state = _mergeContacts(state, [...local, ...remote]);
      await _persistLocalContacts(state);
    } catch (_) {
      if (state.isEmpty && local.isEmpty) {
        state = const [];
        await _persistLocalContacts(state);
      }
    }
  }

  Future<bool> hasSavedContacts() async {
    if (state.isNotEmpty) return true;
    await loadContacts();
    return state.isNotEmpty;
  }

  Future<bool> addContact(EmergencyContact contact) async {
    final normalizedContact = contact.normalized();
    if (normalizedContact.name.isEmpty || normalizedContact.phone.isEmpty) {
      throw ArgumentError('Name and phone number are required.');
    }

    final contactKey = _contactKey(normalizedContact);
    final alreadySaved = state.any(
      (current) => _contactKey(current) == contactKey,
    );
    if (alreadySaved) return false;

    final localContact = EmergencyContact(
      id: normalizedContact.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : normalizedContact.id,
      name: normalizedContact.name,
      phone: normalizedContact.phone,
      relation: normalizedContact.relation,
    );

    state = _mergeContacts([localContact], state);
    await _persistLocalContacts(state);
    if (!_syncEnabled) return true;

    unawaited(_syncAddedContact(localContact));
    return true;
  }

  Future<void> _syncAddedContact(EmergencyContact localContact) async {
    try {
      final response = await _dio.post(
        ApiConstants.contacts,
        data: {
          'name': localContact.name,
          'phone': localContact.phone,
          'relation': localContact.relation,
        },
      );
      final created = _decodeContactResponse(response.data).normalized();
      if (created.name.isEmpty || created.phone.isEmpty) return;
      state = [
        for (final current in state)
          if (current.id == localContact.id) created else current,
      ];
      await _persistLocalContacts(state);
    } catch (_) {
      // Keep local data as source of truth when offline/API fails.
    }
  }

  Future<bool> updateContact(EmergencyContact contact) async {
    final normalizedContact = contact.normalized();
    if (normalizedContact.name.isEmpty || normalizedContact.phone.isEmpty) {
      throw ArgumentError('Name and phone number are required.');
    }

    final contactKey = _contactKey(normalizedContact);
    final duplicateExists = state.any(
      (current) =>
          current.id != normalizedContact.id &&
          _contactKey(current) == contactKey,
    );
    if (duplicateExists) return false;

    state = [
      for (final current in state)
        if (current.id == normalizedContact.id) normalizedContact else current,
    ];
    await _persistLocalContacts(state);
    if (!_syncEnabled) return true;

    try {
      final response = await _dio.patch(
        '${ApiConstants.contacts}/${normalizedContact.id}',
        data: {
          'name': normalizedContact.name,
          'phone': normalizedContact.phone,
          'relation': normalizedContact.relation,
        },
      );
      final updated = _decodeContactResponse(response.data).normalized();
      state = [
        for (final current in state)
          if (current.id == updated.id) updated else current,
      ];
      await _persistLocalContacts(state);
    } catch (_) {
      // Keep local update when backend sync fails.
    }
    return true;
  }

  Future<void> deleteContact(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _persistLocalContacts(state);
    if (!_syncEnabled) return;

    try {
      await _dio.delete('${ApiConstants.contacts}/$id');
    } catch (_) {
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
            .whereType<Map>()
            .map((item) => EmergencyContact.fromJson(_stringKeyedMap(item)))
            .map((contact) => contact.normalized())
            .where(
              (contact) => contact.name.isNotEmpty && contact.phone.isNotEmpty,
            )
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
        ).normalized();
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
      final normalizedContact = contact.normalized();
      if (normalizedContact.name.isEmpty || normalizedContact.phone.isEmpty) {
        continue;
      }
      final key = _contactKey(normalizedContact);
      if (key.isEmpty) continue;
      byKey[key] = normalizedContact;
    }
    return _withoutLegacyDefaultContacts(byKey.values.toList());
  }

  String _contactKey(EmergencyContact contact) {
    final phone = EmergencyContact.normalizePhoneNumber(contact.phone);
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

  List<EmergencyContact> _decodeContactsResponse(Object? data) {
    final rawContacts = switch (data) {
      final List<dynamic> list => list,
      final Map map when map['contacts'] is List => map['contacts'] as List,
      final Map map when map['data'] is List => map['data'] as List,
      final Map map when map['emergencyContacts'] is List =>
        map['emergencyContacts'] as List,
      _ => const [],
    };

    return rawContacts
        .whereType<Map>()
        .map((item) => EmergencyContact.fromJson(_stringKeyedMap(item)))
        .toList();
  }

  EmergencyContact _decodeContactResponse(Object? data) {
    final rawContact = switch (data) {
      final Map map when map['contact'] is Map => map['contact'] as Map,
      final Map map when map['data'] is Map => map['data'] as Map,
      final Map map => map,
      _ => const <String, dynamic>{},
    };
    return EmergencyContact.fromJson(_stringKeyedMap(rawContact));
  }

  static Map<String, dynamic> _stringKeyedMap(Map map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}
