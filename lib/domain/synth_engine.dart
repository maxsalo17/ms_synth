import 'dart:typed_data';

import '../../shared/utils/midi.dart';
import 'osc_slot_config.dart';
import 'voice.dart';

class SynthEngine {
  SynthEngine({required this.sampleRate, this.masterGain = 0.20, this.maxPolyphony = 8, required this.onRender})
    : slots = [
        OscSlotConfig(enabled: true, level: 0.6, voices: 1), // osc1
        OscSlotConfig(enabled: false, level: 0.4, voices: 1), // osc2
        OscSlotConfig(enabled: false, level: 0.3, voices: 1), // osc3
      ];

  final int sampleRate;
  double masterGain;
  final int maxPolyphony;

  final List<OscSlotConfig> slots;

  final Map<int, Voice> _voices = {};

  final void Function(Int16List pcm) onRender;

  int get activeVoiceCount => _voices.length;

  void setSlot(int index, OscSlotConfig config) {
    if (index < 0 || index >= 3) return;
    slots[index] = config;
  }

  OscSlotConfig getSlot(int index) => slots[index];

  void updateSlot(int index, void Function(OscSlotConfig c) mutate) {
    final c = slots[index].copy();
    mutate(c);
    slots[index] = c;
    for (final v in _voices.values) {
      if (index < v.slots.length) {
        v.slots[index].updateConfig(c);
      }
    }
  }

  void noteOn(int midi) {
    if (_voices.length >= maxPolyphony && !_voices.containsKey(midi)) {
      _voices.remove(_voices.keys.first);
    }

    final existing = _voices[midi];
    if (existing != null) {
      existing.on();
      return;
    }

    final freq = midiToFreq(midi);

    final v = Voice(midi: midi, sampleRate: sampleRate, freqHz: freq, slotConfigs: slots)..on();

    _voices[midi] = v;
  }

  void noteOff(int midi) => _voices[midi]?.off();

  Int16List render(int frames) {
    final out = Int16List(frames);

    for (int i = 0; i < frames; i++) {
      double mix = 0.0;

      for (final v in _voices.values) {
        mix += v.next();
      }

      _voices.removeWhere((_, v) => !v.alive);

      final s = (mix * masterGain).clamp(-1.0, 1.0);
      out[i] = (s * 32767).round();
    }

    onRender(out);
    return out;
  }
}
