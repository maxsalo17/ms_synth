import 'package:flutter/material.dart';
import 'package:synthesizer/presentation/widgets/logo.dart';
import 'package:synthesizer/presentation/widgets/waveform_scope.dart';

import '../audio/flutter_pcm_audio_output.dart';
import '../controllers/synth_controller.dart';
import '../controllers/waveform_scope_controller.dart';
import '../domain/synth_engine.dart';
import '../domain/types.dart';
import 'widgets/envelope_graph_editor.dart';
import 'widgets/int_knob.dart';
import 'widgets/knob.dart';
import 'widgets/piano_keyboard.dart';
import 'widgets/waveform_picker.dart';

class SynthScreen extends StatefulWidget {
  const SynthScreen({super.key});

  @override
  State<SynthScreen> createState() => _SynthScreenState();
}

class _SynthScreenState extends State<SynthScreen> {
  static const sampleRate = 48000;

  late final SynthController controller;
  late final WaveformScopeController _scope;

  @override
  void initState() {
    super.initState();

    controller = SynthController(
      engine: SynthEngine(sampleRate: sampleRate, onRender: (pcm) => _scope.pushPcm16(pcm)),
      audio: FlutterPcmAudioOutput(sampleRate: sampleRate, framesPerFeed: 512),
    );

    _scope = WaveformScopeController();

    Future.microtask(() async {
      await controller.init();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Logo(),
            Expanded(
              child: SizedBox(height: 50, child: WaveformScope(controller: _scope, height: 50)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: List.generate(controller.slots.length, (index) {
                    final slot = controller.slots[index];
                    return Expanded(
                      child: _OscSlotPanel(
                        oscIndex: index,
                        enabled: slot.enabled,
                        waveform: slot.waveform,
                        level: slot.level,
                        detuneCents: slot.detuneCents,
                        voices: slot.voices,
                        onEnabledChanged: (v) {
                          setState(() {});
                          controller.setSlotEnabled(index, v);
                        },
                        onWaveformChanged: (w) {
                          setState(() {});
                          controller.setSlotWaveform(index, w);
                        },
                        onLevelChanged: (v) {
                          setState(() {});
                          controller.setSlotLevel(index, v);
                        },
                        onDetuneChanged: (cents) {
                          setState(() {});
                          controller.setSlotDetuneCents(index, cents);
                        },
                        onVoicesChanged: (v) {
                          setState(() {});
                          controller.setSlotVoices(index, v);
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
                        child: EnvelopesEditor(
                          editors: List.generate(
                            controller.slots.length,
                            (index) => EnvelopeGraphEditor(
                              value: controller.slots[index].env,
                              height: 300,
                              onChanged: (np) {
                                controller.setSlotEnvelope(index, np);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SuperPianoKeyboard(visibleOctaves: 3, onNoteOn: controller.noteOn, onNoteOff: controller.noteOff),
        ],
      ),
    );
  }
}

class _OscSlotPanel extends StatelessWidget {
  const _OscSlotPanel({
    required this.oscIndex,
    required this.enabled,
    required this.waveform,
    required this.level,
    required this.detuneCents,
    required this.voices,
    required this.onEnabledChanged,
    required this.onWaveformChanged,
    required this.onLevelChanged,
    required this.onDetuneChanged,
    required this.onVoicesChanged,
  });

  final int oscIndex;
  final bool enabled;
  final Waveform waveform;
  final double level;
  final double detuneCents;
  final int voices;

  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<Waveform> onWaveformChanged;
  final ValueChanged<double> onLevelChanged;
  final ValueChanged<double> onDetuneChanged;
  final ValueChanged<int> onVoicesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Osc ${oscIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Switch(value: enabled, onChanged: onEnabledChanged),
              ],
            ),
            const SizedBox(height: 8),

            WaveformPicker(value: waveform, onChanged: onWaveformChanged),

            const SizedBox(height: 10),

            Row(
              children: [
                Knob(
                  label: 'Level',
                  size: 58,
                  enabled: enabled,
                  value: level,
                  min: 0,
                  max: 1,
                  valueText: (v) => v.toStringAsFixed(2),
                  onChanged: onLevelChanged,
                ),
                const SizedBox(width: 10),
                Knob(
                  label: 'Detune',
                  size: 58,
                  enabled: enabled,
                  value: detuneCents,
                  min: -50,
                  max: 50,
                  valueText: (v) => '${v.toStringAsFixed(1)}c',
                  sensitivity: 0.004,
                  onChanged: onDetuneChanged,
                ),
                const SizedBox(width: 10),
                IntKnob(label: 'Voices', size: 58, enabled: enabled, value: voices, min: 1, max: 8, onChanged: onVoicesChanged),
                const Spacer(),
                Text(enabled ? '' : 'Disabled', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
