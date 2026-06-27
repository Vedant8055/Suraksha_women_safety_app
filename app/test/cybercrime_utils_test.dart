import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/cybercrime_constants.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/utils/cybercrime_utils.dart';

void main() {
  group('CybercrimeConstants', () {
    test('report categories match backend count', () {
      expect(CybercrimeConstants.reportCategories.length, 12);
    });

    test('category keys resolve for every report category', () {
      for (final category in CybercrimeConstants.reportCategories) {
        expect(
          CybercrimeConstants.reportCategoryKey(category),
          isNotEmpty,
        );
      }
    });
  });

  group('localAnalyze', () {
    test('flags OTP requests as elevated risk', () {
      final result = localAnalyze('Please share your OTP now', '', []);
      expect(result.riskLevel, 'MEDIUM');
      expect(result.threatSummary.toLowerCase(), contains('credential'));
    });

    test('returns low risk for benign text', () {
      final result = localAnalyze('Hello, how are you?', '', []);
      expect(result.riskLevel, 'LOW');
    });

    test('detects blackmail language', () {
      final result = localAnalyze('', 'They sent morphed photos and want money', []);
      expect(result.riskLevel, 'MEDIUM');
      expect(result.threatSummary.toLowerCase(), contains('blackmail'));
    });
  });
}
