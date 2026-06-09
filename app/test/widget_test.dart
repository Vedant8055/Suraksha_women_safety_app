import 'package:suraksha_women_safety_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MyApp can disable startup background services for tests', () {
    const app = MyApp(startBackgroundServices: false);

    expect(app.startBackgroundServices, isFalse);
  });
}
