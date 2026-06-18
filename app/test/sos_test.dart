import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SOSProvider Tests', () {
    test('Initial state should be inactive', () {
      final notifier = SOSNotifier.test(userId: 'user_123', token: 'token_123');
      addTearDown(notifier.dispose);

      expect(notifier.state.isActive, false);
      expect(notifier.state.currentPosition, null);
    });

    test('cancelSOS should set isActive to false', () async {
      final notifier = SOSNotifier.test(userId: 'user_123', token: 'token_123');
      addTearDown(notifier.dispose);

      await notifier.cancelSOS();
      expect(notifier.state.isActive, false);
    });
  });
}
