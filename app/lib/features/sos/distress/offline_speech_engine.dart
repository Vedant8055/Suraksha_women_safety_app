import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:suraksha_women_safety_app/features/sos/distress/distress_phrase_matcher.dart';
import 'package:suraksha_women_safety_app/features/sos/distress/distress_phrases.dart';

typedef DistressSpeechCallback = void Function({
  required String text,
  required bool matched,
  String? phrase,
  required bool testMode,
});

class OfflineSpeechEngine {
  OfflineSpeechEngine();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  bool _testMode = false;
  int _localeIndex = 0;
  DistressSpeechCallback? _onResult;

  bool get isListening => _listening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) => debugPrint('Distress STT error: ${error.errorMsg}'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
        }
      },
    );
    return _initialized;
  }

  void setTestMode(bool enabled) {
    _testMode = enabled;
  }

  Future<void> startListening({
    required DistressSpeechCallback onResult,
  }) async {
    _onResult = onResult;
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    if (_listening) return;
    await _listenWithNextLocale();
  }

  Future<void> stopListening() async {
    _listening = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> _listenWithNextLocale() async {
    if (!_initialized || _onResult == null) return;

    final locales = await _speech.locales();
    final preferred = DistressPhrases.speechLocales
        .where((id) => locales.any((locale) => locale.localeId == id))
        .toList(growable: false);
    final localeList = preferred.isNotEmpty
        ? preferred
        : locales.map((item) => item.localeId).take(4).toList(growable: false);
    if (localeList.isEmpty) return;

    final localeId = localeList[_localeIndex % localeList.length];
    _localeIndex++;

    _listening = true;
    await _speech.listen(
      onResult: _handleSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        onDevice: true,
      ),
    );
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    final match = DistressPhraseMatcher.match(text);
    _onResult?.call(
      text: text,
      matched: match.matched,
      phrase: match.phrase,
      testMode: _testMode,
    );

    if (result.finalResult && _listening) {
      _listening = false;
      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (_onResult != null) {
          unawaited(_listenWithNextLocale());
        }
      }));
    }
  }
}
