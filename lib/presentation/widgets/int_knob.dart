import 'package:flutter/material.dart';
import 'knob.dart';

class IntKnob extends StatelessWidget {
  const IntKnob({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.size = 56,
    this.label,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double size;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Knob(
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      size: size,
      enabled: enabled,
      label: label,
      sensitivity: 0.01,
      valueText: (v) => v.round().toString(),
      onChanged: (v) => onChanged(v.round().clamp(min, max)),
    );
  }
}
