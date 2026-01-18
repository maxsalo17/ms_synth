import 'dart:math';
import 'dart:math' as math;

import 'envelope.dart';
import 'osc_slot_config.dart';
import 'oscillator_core.dart';

class VoiceSlotInstance {
  VoiceSlotInstance({required this.sampleRate, required this.baseFreqHz, required OscSlotConfig config})
    : config = config.copy(),
      env = AdshrEnvelope(
        sampleRate: sampleRate,
        attackSec: config.env.attackSec,
        decaySec: config.env.decaySec,
        sustainLevel: config.env.sustainLevel,
        holdSec: config.env.holdSec,
        releaseSec: config.env.releaseSec,
      ),
      _oscillators = List.generate(
        config.voices.clamp(1, 8),
        (_) => OscillatorCore(sampleRate: sampleRate, waveform: config.waveform),
      );

  final int sampleRate;
  final double baseFreqHz;

  OscSlotConfig config;
  final AdshrEnvelope env;
  final List<OscillatorCore> _oscillators;

  void noteOn() => env.noteOn();
  void noteOff() => env.noteOff();
  bool get alive => env.isAlive;

  // cents -> frequency multiplier
  double _centsToMul(double cents) => pow(2.0, cents / 1200.0).toDouble();

  double next() {
    if (!config.enabled) return 0.0;

    final amp = env.next(); // 0..1
    if (amp <= 0.0) return 0.0;

    // spread voices around detuneCents
    final n = _oscillators.length;

    // If voices=1 - simply detuneCents
    // If >1 - uniformly from -detune..+detune
    double sum = 0.0;

    for (int i = 0; i < n; i++) {
      final t = (n == 1) ? 0.0 : (i / (n - 1)) * 2.0 - 1.0; // -1..+1
      final cents = config.detuneCents * t;
      final f = baseFreqHz * _centsToMul(cents);

      _oscillators[i].waveform = config.waveform; // for live updates
      sum += _oscillators[i].nextSample(f);
    }

    // final unisonMix = sum / n;
    final unisonMix = sum / math.sqrt(n);

    return unisonMix * amp * config.level;
  }

  void _ensureUnisonCount(int desired) {
    final n = desired.clamp(1, 8);

    if (_oscillators.length == n) return;

    if (_oscillators.length < n) {
      final add = n - _oscillators.length;
      for (int i = 0; i < add; i++) {
        final o = OscillatorCore(sampleRate: sampleRate, waveform: config.waveform);

        if (_oscillators.isNotEmpty) o.phase = Random().nextDouble() * 2 * pi;
        _oscillators.add(o);
      }
    } else {
      _oscillators.removeRange(n, _oscillators.length);
    }
  }

  void updateConfig(OscSlotConfig newConfig) {
    config = newConfig.copy();

    env.setParams(
      attackSec: config.env.attackSec,
      decaySec: config.env.decaySec,
      sustainLevel: config.env.sustainLevel,
      holdSec: config.env.holdSec,
      releaseSec: config.env.releaseSec,
    );

    _ensureUnisonCount(config.voices);

    for (final o in _oscillators) {
      o.waveform = config.waveform;
    }
  }
}
