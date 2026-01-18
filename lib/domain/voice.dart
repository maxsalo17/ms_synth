import 'voice_slot_instance.dart';
import 'osc_slot_config.dart';

class Voice {
  Voice({required this.midi, required this.sampleRate, required this.freqHz, required List<OscSlotConfig> slotConfigs})
    : slots = slotConfigs.take(3).map((c) => VoiceSlotInstance(sampleRate: sampleRate, baseFreqHz: freqHz, config: c)).toList();

  final int midi;
  final int sampleRate;
  final double freqHz;

  final List<VoiceSlotInstance> slots;

  void on() {
    for (final s in slots) {
      s.noteOn();
    }
  }

  void off() {
    for (final s in slots) {
      s.noteOff();
    }
  }

  bool get alive => slots.any((s) => s.alive);

  double next() {
    double sum = 0.0;
    for (final s in slots) {
      sum += s.next();
    }
    return sum;
  }
}
