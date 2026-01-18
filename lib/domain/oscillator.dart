import 'dart:math';
import 'types.dart';

class Oscillator {
  Oscillator({required this.sampleRate, this.waveform = Waveform.sine});

  final int sampleRate;
  Waveform waveform;

  double phase = 0.0;
  double freq = 440.0;

  double nextSample() {
    final inc = 2 * pi * freq / sampleRate;

    double x;
    switch (waveform) {
      case Waveform.sine:
        x = sin(phase);
        break;
      case Waveform.square:
        x = (sin(phase) >= 0) ? 1.0 : -1.0;
        break;
      case Waveform.saw:
        final t = (phase / (2 * pi)) % 1.0;
        x = 2.0 * t - 1.0;
        break;
    }

    phase += inc;
    if (phase >= 2 * pi) phase -= 2 * pi;

    return x;
  }
}
