import 'package:flutter/material.dart';
import '../../domain/types.dart';

class WaveformPicker extends StatelessWidget {
  const WaveformPicker({super.key, required this.value, required this.onChanged});

  final Waveform value;
  final ValueChanged<Waveform> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Waveform: ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        SegmentedButton<Waveform>(
          segments: const [
            ButtonSegment(value: Waveform.sine, label: Text('Sine')),
            ButtonSegment(value: Waveform.saw, label: Text('Saw')),
            ButtonSegment(value: Waveform.square, label: Text('Square')),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }
}
