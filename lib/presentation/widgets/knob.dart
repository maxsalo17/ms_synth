import 'dart:math' as math;
import 'package:flutter/material.dart';

class Knob extends StatefulWidget {
  const Knob({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.size = 56,
    this.label,
    this.valueText,
    this.enabled = true,
    this.sensitivity = 0.006,
  });

  final double value;
  final ValueChanged<double> onChanged;

  final double min;
  final double max;
  final double size;
  final String? label;
  final String Function(double v)? valueText;

  final bool enabled;

  final double sensitivity;

  @override
  State<Knob> createState() => _KnobState();
}

class _KnobState extends State<Knob> {
  late double _v0;

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = _clamp(widget.value);
    final t = (v - widget.min) / (widget.max - widget.min);

    final label = widget.label;
    final valueText = widget.valueText?.call(v) ?? _defaultValueText(v);

    final disabled = !widget.enabled;

    final surface = cs.surface;
    final surfaceVariant = cs.surfaceContainerHighest;
    final outline = cs.outlineVariant;
    final primary = cs.primary;

    final fillColor = disabled ? surfaceVariant.withValues(alpha: 0.6) : surfaceVariant;
    final ringColor = disabled ? outline.withValues(alpha: 0.6) : outline;
    final activeColor = disabled ? primary.withValues(alpha: 0.4) : primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkResponse(
            radius: widget.size * 0.75,
            containedInkWell: true,
            onTap: disabled ? null : () {},
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: disabled
                  ? null
                  : (_) {
                      _v0 = v;
                    },
              onPanUpdate: disabled
                  ? null
                  : (d) {
                      final delta = (widget.max - widget.min) * widget.sensitivity * (-d.delta.dy);
                      final nv = _clamp(_v0 + delta);
                      _v0 = nv;
                      widget.onChanged(nv);
                    },
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _KnobPainter(t: t, fill: fillColor, ring: ringColor, active: activeColor, surface: surface),
                  child: Center(
                    child: Text(
                      valueText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: disabled ? cs.onSurface.withValues(alpha: 0.45) : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: disabled ? cs.onSurface.withValues(alpha: 0.45) : cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  String _defaultValueText(double v) {
    if ((widget.max - widget.min) <= 8) return v.toStringAsFixed(2);
    if ((widget.max - widget.min) <= 200) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0);
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({required this.t, required this.fill, required this.ring, required this.active, required this.surface});

  final double t;
  final Color fill;
  final Color ring;
  final Color active;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2.0;
    final c = Offset(size.width / 2.0, size.height / 2.0);

    final bg = Paint()..color = fill;
    canvas.drawCircle(c, r, bg);

    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, r * 0.08);
    canvas.drawCircle(c, r - ringPaint.strokeWidth / 2, ringPaint);

    final start = _degToRad(225);
    final sweep = _degToRad(270) * t.clamp(0.0, 1.0);

    final arcPaint = Paint()
      ..color = active
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.2, r * 0.11);

    final rect = Rect.fromCircle(center: c, radius: r - arcPaint.strokeWidth / 2 - r * 0.06);
    canvas.drawArc(rect, start, sweep, false, arcPaint);

    final angle = start + sweep;
    final pointerLen = r * 0.62;
    final p1 = c;
    final p2 = Offset(c.dx + math.cos(angle) * pointerLen, c.dy + math.sin(angle) * pointerLen);

    final pointerPaint = Paint()
      ..color = surface.withValues(alpha: 0.85)
      ..strokeWidth = math.max(2.0, r * 0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, pointerPaint);
  }

  double _degToRad(double d) => d * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant _KnobPainter old) {
    return old.t != t || old.fill != fill || old.ring != ring || old.active != active || old.surface != surface;
  }
}
