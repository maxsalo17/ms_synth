import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../controllers/waveform_scope_controller.dart';

class WaveformScope extends StatelessWidget {
  const WaveformScope({
    super.key,
    required this.controller,
    this.height = 120,
    this.showGrid = false,
    this.showBackground = false,
  });

  final WaveformScopeController controller;
  final double height;
  final bool showGrid;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final data = controller.snapshot();
        return SizedBox(
          height: height,
          child: CustomPaint(
            painter: _ScopePainter(
              data: data,
              lineColor: cs.primary,
              gridColor: cs.outlineVariant.withValues(alpha: 0.35),
              bgColor: cs.surfaceContainerHighest,
              showGrid: showGrid,
              showBackground: showBackground,
            ),
          ),
        );
      },
    );
  }
}

class _ScopePainter extends CustomPainter {
  _ScopePainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.bgColor,
    required this.showGrid,
    required this.showBackground,
  });

  final Float32List data;
  final Color lineColor;
  final Color gridColor;
  final Color bgColor;
  final bool showGrid;
  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;

    // background
    if (showBackground) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()..color = bgColor);
    }

    final inner = r.deflate(10);

    // grid
    if (showGrid) {
      final p = Paint()
        ..color = gridColor
        ..strokeWidth = 1;

      // vertical
      for (int i = 0; i <= 4; i++) {
        final x = inner.left + inner.width * (i / 4);
        canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), p);
      }
      // horizontal
      for (int i = 0; i <= 4; i++) {
        final y = inner.top + inner.height * (i / 4);
        canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), p);
      }
    }

    // waveform
    final midY = inner.top + inner.height / 2;
    final scaleY = inner.height;

    final path = Path();
    final slowData = data.sublist(0, data.length - 200);
    final slowN = slowData.length;
    if (slowN <= 1) return;

    final slowDataWidth = inner.width * 0.8;

    for (int i = 0; i < slowN; i++) {
      final x = inner.left + slowDataWidth * (i / (slowN - 1));
      final y = midY - (slowData[i].clamp(-1.0, 1.0) * scaleY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fastData = data.sublist(data.length - 200);
    final fastN = fastData.length;
    if (fastN <= 1) return;

    final fastDataWidth = inner.width - slowDataWidth;

    for (int i = 0; i < fastN; i++) {
      final x = inner.left + slowDataWidth + fastDataWidth * (i / (fastN - 1));
      final y = midY - (fastData[i].clamp(-1.0, 1.0) * scaleY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScopePainter old) {
    return true;
  }
}
