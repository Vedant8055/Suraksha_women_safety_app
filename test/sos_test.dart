import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_women_safety_app/features/sos/sos_provider.dart';

void main() {
  group('SOSProvider Tests', () {
    test('Initial state should be inactive', () {
      final notifier = SOSNotifier('user_123', 'token_123');
      expect(notifier.state.isActive, false);
      expect(notifier.state.currentPosition, null);
    });

    test('cancelSOS should set isActive to false', () {
      final notifier = SOSNotifier('user_123', 'token_123');
      notifier.cancelSOS();
      expect(notifier.state.isActive, false);
    });
  });
}
