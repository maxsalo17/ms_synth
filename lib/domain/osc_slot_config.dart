import 'types.dart';
import 'params.dart';

class OscSlotConfig {
  OscSlotConfig({
    this.enabled = true,
    this.waveform = Waveform.sine,
    this.level = 0.5, // 0..1
    this.detuneCents = 0.0, // -1200..1200
    this.voices = 1, // 1..8
    EnvelopeParams? env,
  }) : env = env ?? const EnvelopeParams();

  bool enabled;
  Waveform waveform;
  double level;
  double detuneCents;
  int voices;
  EnvelopeParams env;

  OscSlotConfig copy() =>
      OscSlotConfig(enabled: enabled, waveform: waveform, level: level, detuneCents: detuneCents, voices: voices, env: env);
}
