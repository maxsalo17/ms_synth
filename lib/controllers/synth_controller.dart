import '../audio/pcm_audio_output.dart';
import '../domain/synth_engine.dart';
import '../domain/osc_slot_config.dart';
import '../domain/params.dart';
import '../domain/types.dart';

class SynthController {
  SynthController({required this.engine, required this.audio}) {
    audio.setGenerator(engine.render);
  }

  final SynthEngine engine;

  final PcmAudioOutput audio;

  int get activeVoices => engine.activeVoiceCount;

  List<OscSlotConfig> get slots => engine.slots;

  Future<void> init() async {
    await audio.init();
    await audio.start();
  }

  Future<void> dispose() => audio.dispose();

  void noteOn(int midi) => engine.noteOn(midi);

  void noteOff(int midi) => engine.noteOff(midi);

  OscSlotConfig slot(int i) => engine.getSlot(i);

  void setMasterGain(double gain) {
    engine.masterGain = gain.clamp(0.0, 1.0);
  }

  // --- Slot setters (важливо: clamping) ---
  void setSlotEnabled(int slot, bool enabled) {
    engine.updateSlot(slot, (c) => c.enabled = enabled);
  }

  void setSlotWaveform(int slot, Waveform w) {
    engine.updateSlot(slot, (c) => c.waveform = w);
  }

  void setSlotLevel(int slot, double level) {
    engine.updateSlot(slot, (c) => c.level = level.clamp(0.0, 1.0));
  }

  void setSlotDetuneCents(int slot, double cents) {
    engine.updateSlot(slot, (c) => c.detuneCents = cents);
  }

  void setSlotVoices(int slot, int voices) {
    engine.updateSlot(slot, (c) => c.voices = voices.clamp(1, 8));
  }

  void setSlotEnvelope(int slot, EnvelopeParams env) {
    engine.updateSlot(slot, (c) => c.env = env);
  }

  void setSlotEnvelopeAdshr(
    int slot, {
    required double a,
    required double d,
    required double s,
    required double h,
    required double r,
  }) {
    engine.updateSlot(slot, (c) {
      c.env = c.env.copyWith(attackSec: a, decaySec: d, sustainLevel: s, holdSec: h, releaseSec: r);
    });
  }
}
