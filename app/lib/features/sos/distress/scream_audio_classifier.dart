import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

enum DistressSensitivity { low, medium, high }

/// On-device scream scorer (Phase C) — weighted feature classifier with
/// optional TFLite hook point. Uses bundled JSON weights when no model present.
class ScreamAudioClassifier {
  ScreamAudioClassifier._();

  static ScreamAudioClassifier? _instance;
  static ScreamAudioClassifier get instance =>
      _instance ??= ScreamAudioClassifier._();

  double _bias = -0.35;
  final Map<String, double> _weights = {
    'rms': 2.4,
    'peakRatio': 1.8,
    'highBandEnergy': 2.1,
    'zcr': 0.6,
    'sustainedMs': 0.0012,
    'pitchScore': 1.4,
  };
  final Map<DistressSensitivity, double> _thresholds = {
    DistressSensitivity.low: 0.62,
    DistressSensitivity.medium: 0.54,
    DistressSensitivity.high: 0.46,
  };

  bool _loaded = false;
  int _sampleRate = 16000;
  int _sustainedLoudMs = 0;
  DateTime? _loudStartedAt;
  double _lastRms = 0;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/distress/scream_weights.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _bias = (json['bias'] as num?)?.toDouble() ?? _bias;
      final weights = json['weights'] as Map<String, dynamic>? ?? {};
      for (final entry in weights.entries) {
        _weights[entry.key] = (entry.value as num).toDouble();
      }
      final thresholds = json['thresholds'] as Map<String, dynamic>? ?? {};
      for (final entry in thresholds.entries) {
        final key = switch (entry.key) {
          'low' => DistressSensitivity.low,
          'medium' => DistressSensitivity.medium,
          'high' => DistressSensitivity.high,
          _ => null,
        };
        if (key != null) {
          _thresholds[key] = (entry.value as num).toDouble();
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  void resetSession() {
    _sustainedLoudMs = 0;
    _loudStartedAt = null;
    _lastRms = 0;
  }

  /// Returns scream probability 0..1 and whether sustained loudness met minimum.
  ScreamAnalysisResult analyzePcm(
    Uint8List pcmBytes, {
    required int sampleRate,
    required DistressSensitivity sensitivity,
    int minSustainedMs = 450,
  }) {
    _sampleRate = sampleRate;
    final samples = _pcm16ToFloat(pcmBytes);
    if (samples.isEmpty) {
      return const ScreamAnalysisResult(score: 0, sustained: false);
    }

    final rms = _rms(samples);
    final peak = samples.map((s) => s.abs()).reduce(max);
    final peakRatio = peak > 0 ? rms / peak : 0;
    final zcr = _zeroCrossingRate(samples);
    final highBand = _highBandEnergyRatio(samples, sampleRate);
    final pitchScore = _estimatePitchScore(samples, sampleRate);

    _lastRms = rms;
    final loudEnough = rms >= _rmsThreshold(sensitivity);
    if (loudEnough) {
      _loudStartedAt ??= DateTime.now();
      _sustainedLoudMs = DateTime.now().difference(_loudStartedAt!).inMilliseconds;
    } else {
      _loudStartedAt = null;
      _sustainedLoudMs = 0;
    }

    final sustainedMs = _sustainedLoudMs.toDouble();
    final logit = _bias +
        _weights['rms']! * _sigmoid(rms * 12) +
        _weights['peakRatio']! * peakRatio +
        _weights['highBandEnergy']! * highBand +
        _weights['zcr']! * _sigmoid(zcr * 8) +
        _weights['sustainedMs']! * sustainedMs +
        _weights['pitchScore']! * pitchScore;

    final score = _sigmoid(logit);
    final threshold = _thresholds[sensitivity] ?? 0.54;
    final sustained = _sustainedLoudMs >= minSustainedMs;
    final isScream = sustained && score >= threshold;

    return ScreamAnalysisResult(
      score: score,
      sustained: sustained,
      isScream: isScream,
      rms: rms,
      sustainedMs: _sustainedLoudMs,
    );
  }

  double _rmsThreshold(DistressSensitivity sensitivity) {
    return switch (sensitivity) {
      DistressSensitivity.low => 0.12,
      DistressSensitivity.medium => 0.08,
      DistressSensitivity.high => 0.05,
    };
  }

  List<double> _pcm16ToFloat(Uint8List bytes) {
    if (bytes.length < 2) return const [];
    final bd = ByteData.sublistView(bytes);
    final count = bytes.length ~/ 2;
    final out = List<double>.filled(count, 0, growable: false);
    for (var i = 0; i < count; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  double _rms(List<double> samples) {
    var sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
  }

  double _zeroCrossingRate(List<double> samples) {
    if (samples.length < 2) return 0;
    var crossings = 0;
    for (var i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0) != (samples[i - 1] >= 0)) crossings++;
    }
    return crossings / samples.length;
  }

  double _highBandEnergyRatio(List<double> samples, int sampleRate) {
    // Simple 2-band split: energy above ~2kHz proxy via successive diff
    if (samples.length < 4) return 0;
    var low = 0.0;
    var high = 0.0;
    for (var i = 1; i < samples.length; i++) {
      final diff = (samples[i] - samples[i - 1]).abs();
      high += diff * diff;
      low += samples[i] * samples[i];
    }
    final total = low + high;
    if (total <= 0) return 0;
    return (high / total).clamp(0.0, 1.0);
  }

  double _estimatePitchScore(List<double> samples, int sampleRate) {
    // Autocorrelation-lite for 200–800 Hz (typical scream fundamentals)
    final minLag = (sampleRate / 800).round();
    final maxLag = (sampleRate / 200).round();
    if (samples.length <= maxLag + 1) return 0;

    var best = 0.0;
    for (var lag = minLag; lag <= maxLag; lag++) {
      var sum = 0.0;
      for (var i = 0; i < samples.length - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      if (sum > best) best = sum;
    }
    final energy = samples.map((s) => s * s).reduce((a, b) => a + b);
    if (energy <= 0) return 0;
    return (best / energy).clamp(0.0, 1.0);
  }

  double _sigmoid(double x) => 1 / (1 + exp(-x));

  double get lastRms => _lastRms;
  int get sampleRate => _sampleRate;
}

class ScreamAnalysisResult {
  final double score;
  final bool sustained;
  final bool isScream;
  final double rms;
  final int sustainedMs;

  const ScreamAnalysisResult({
    required this.score,
    required this.sustained,
    this.isScream = false,
    this.rms = 0,
    this.sustainedMs = 0,
  });
}
