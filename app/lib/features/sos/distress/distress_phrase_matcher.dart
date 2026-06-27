import 'package:suraksha_women_safety_app/features/sos/distress/distress_phrases.dart';

class DistressMatchResult {
  final bool matched;
  final String? phrase;
  final String normalizedText;

  const DistressMatchResult({
    required this.matched,
    this.phrase,
    this.normalizedText = '',
  });
}

class DistressPhraseMatcher {
  static final _normalizedPhrases = DistressPhrases.all
      .map(_normalize)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static DistressMatchResult match(String rawText) {
    final normalized = _normalize(rawText);
    if (normalized.isEmpty) {
      return const DistressMatchResult(matched: false);
    }

    for (final phrase in _normalizedPhrases) {
      if (normalized == phrase || normalized.contains(phrase)) {
        return DistressMatchResult(
          matched: true,
          phrase: phrase,
          normalizedText: normalized,
        );
      }
    }

    // Fuzzy: all words of a multi-word phrase appear in order
    for (final phrase in _normalizedPhrases) {
      if (!phrase.contains(' ')) continue;
      if (_containsWordsInOrder(normalized, phrase.split(' '))) {
        return DistressMatchResult(
          matched: true,
          phrase: phrase,
          normalizedText: normalized,
        );
      }
    }

    return DistressMatchResult(matched: false, normalizedText: normalized);
  }

  static String _normalize(String input) {
    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Common STT mis-hearings
    text = text
        .replaceAll('help mi', 'help me')
        .replaceAll('bachao muje', 'bachao mujhe')
        .replaceAll('mujhe bachao', 'mujhe bachao')
        .replaceAll('mala vachava', 'mala vachva')
        .replaceAll('mala sodaa', 'mala soda');
    return text.trim();
  }

  static bool _containsWordsInOrder(String haystack, List<String> needles) {
    var index = 0;
    for (final word in needles) {
      final found = haystack.indexOf(word, index);
      if (found < 0) return false;
      index = found + word.length;
    }
    return true;
  }
}
