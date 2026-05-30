import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmergencyContactsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves contacts locally even when backend sync fails', () async {
      final notifier = EmergencyContactsNotifier(syncEnabled: false);
      addTearDown(notifier.dispose);

      await notifier.addContact(
        const EmergencyContact(
          id: '',
          name: '  Asha  ',
          phone: ' +91 98765 43210 ',
          relation: '',
        ),
      );

      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.name, 'Asha');
      expect(notifier.state.first.phone, '+919876543210');
      expect(notifier.state.first.relation, 'Emergency Contact');

      final reloaded = EmergencyContactsNotifier(syncEnabled: false);
      addTearDown(reloaded.dispose);
      await reloaded.loadContacts();

      expect(reloaded.state, hasLength(1));
      expect(reloaded.state.first.phone, '+919876543210');
    });

    test('normalizes phone numbers for SMS sending', () {
      expect(
        EmergencyContact.normalizePhoneNumber(' +91 98765-43210 '),
        '+919876543210',
      );
      expect(
        EmergencyContact.normalizePhoneNumber('98765 43210'),
        '9876543210',
      );
    });

    test(
      'loading empty local storage does not wipe current contacts',
      () async {
        final notifier = EmergencyContactsNotifier(syncEnabled: false);
        addTearDown(notifier.dispose);

        await notifier.addContact(
          const EmergencyContact(
            id: '',
            name: 'Meera',
            phone: '99999 11111',
            relation: 'Sister',
          ),
        );
        SharedPreferences.setMockInitialValues({});

        await notifier.loadContacts();

        expect(notifier.state, hasLength(1));
        expect(notifier.state.first.name, 'Meera');
      },
    );
  });
}
