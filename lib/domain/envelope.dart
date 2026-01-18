import 'dart:math';
import 'params.dart';
import 'types.dart';

class AdshrEnvelope {
  AdshrEnvelope({
    required this.sampleRate,
    this.attackSec = 0.01,
    this.decaySec = 0.08,
    this.sustainLevel = 0.6,
    this.holdSec = 0.0,
    this.releaseSec = 0.12,
  }) {
    _recalc();
  }

  final int sampleRate;

  double attackSec;
  double decaySec;
  double sustainLevel;
  double holdSec;
  double releaseSec;

  EnvStage stage = EnvStage.idle;
  double value = 0.0;

  int _counter = 0;
  late int _attackSamples, _decaySamples, _holdSamples, _releaseSamples;
  late double _attackStep, _decayStep;

  void setParams({
    required double attackSec,
    required double decaySec,
    required double sustainLevel,
    required double holdSec,
    required double releaseSec,
  }) {
    this.attackSec = max(0.0, attackSec);
    this.decaySec = max(0.0, decaySec);
    this.sustainLevel = sustainLevel.clamp(0.0, 1.0);
    this.holdSec = max(0.0, holdSec);
    this.releaseSec = max(0.0, releaseSec);
    _recalc();
  }

  void _recalc() {
    _attackSamples = max(1, (attackSec * sampleRate).round());
    _decaySamples = max(1, (decaySec * sampleRate).round());
    _holdSamples = max(0, (holdSec * sampleRate).round());
    _releaseSamples = max(1, (releaseSec * sampleRate).round());

    _attackStep = 1.0 / _attackSamples;
    _decayStep = (1.0 - sustainLevel) / _decaySamples;
  }

  void noteOn() {
    stage = EnvStage.attack;
    _counter = 0;
  }

  void noteOff() {
    if (stage != EnvStage.idle && stage != EnvStage.release) {
      stage = EnvStage.release;
      _counter = 0;
    }
  }

  bool get isAlive => stage != EnvStage.idle;

  double next() {
    switch (stage) {
      case EnvStage.idle:
        value = 0.0;
        return value;

      case EnvStage.attack:
        value += _attackStep;
        _counter++;
        if (_counter >= _attackSamples || value >= 1.0) {
          value = 1.0;
          stage = EnvStage.decay;
          _counter = 0;
        }
        return value;

      case EnvStage.decay:
        value -= _decayStep;
        _counter++;
        if (_counter >= _decaySamples || value <= sustainLevel) {
          value = sustainLevel;
          stage = (_holdSamples > 0) ? EnvStage.hold : EnvStage.sustain;
          _counter = 0;
        }
        return value;

      case EnvStage.hold:
        value = sustainLevel;
        _counter++;
        if (_counter >= _holdSamples) {
          stage = EnvStage.sustain;
          _counter = 0;
        }
        return value;

      case EnvStage.sustain:
        value = sustainLevel;
        return value;

      case EnvStage.release:
        final coef = pow(0.0001, 1.0 / _releaseSamples).toDouble();
        value *= coef;
        _counter++;
        if (_counter >= _releaseSamples || value <= 0.00005) {
          value = 0.0;
          stage = EnvStage.idle;
          _counter = 0;
        }
        return value;
    }
  }
}

extension AdshrEnvelopeFromParams on AdshrEnvelope {
  static AdshrEnvelope fromParams({required int sampleRate, required EnvelopeParams p}) {
    return AdshrEnvelope(
      sampleRate: sampleRate,
      attackSec: p.attackSec,
      decaySec: p.decaySec,
      sustainLevel: p.sustainLevel,
      holdSec: p.holdSec,
      releaseSec: p.releaseSec,
    );
  }
}
