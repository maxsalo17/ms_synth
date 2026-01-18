import 'package:flutter/material.dart';

class EnvelopePanel extends StatelessWidget {
  const EnvelopePanel({
    super.key,
    required this.a,
    required this.d,
    required this.s,
    required this.h,
    required this.r,
    required this.onChanged,
  });

  final double a, d, s, h, r;
  final void Function(double a, double d, double s, double h, double r) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _slider(label: 'Attack (s)', value: a, min: 0.001, max: 0.5, onChanged: (v) => onChanged(v, d, s, h, r)),
        _slider(label: 'Decay (s)', value: d, min: 0.001, max: 0.8, onChanged: (v) => onChanged(a, v, s, h, r)),
        _slider(label: 'Sustain (0..1)', value: s, min: 0.0, max: 1.0, onChanged: (v) => onChanged(a, d, v, h, r)),
        _slider(label: 'Hold (s)', value: h, min: 0.0, max: 1.5, onChanged: (v) => onChanged(a, d, s, v, r)),
        _slider(label: 'Release (s)', value: r, min: 0.001, max: 1.5, onChanged: (v) => onChanged(a, d, s, h, v)),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 64, child: Text(value.toStringAsFixed(3), textAlign: TextAlign.right)),
      ],
    );
  }
}
