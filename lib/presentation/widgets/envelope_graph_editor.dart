import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:synthesizer/presentation/widgets/knob.dart';
import '../../domain/params.dart';

class EnvelopesEditor extends StatefulWidget {
  final List<EnvelopeGraphEditor> editors;
  const EnvelopesEditor({super.key, required this.editors});

  @override
  State<EnvelopesEditor> createState() => _EnvelopesEditorState();
}

class _EnvelopesEditorState extends State<EnvelopesEditor> {
  var _currentIndex = 0;

  void _onEnvelopeSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEnvelope = widget.editors[_currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: List.generate(widget.editors.length, (i) => ButtonSegment(value: i, label: Text('Env ${i + 1}'))),
          selected: {_currentIndex},
          onSelectionChanged: (set) => _onEnvelopeSelected(set.first),
        ),
        Flexible(child: currentEnvelope),
      ],
    );
  }
}

class EnvelopeGraphEditor extends StatefulWidget {
  const EnvelopeGraphEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 160,
    this.maxTimeSec = 2.5,
    this.sustainDisplaySec = 0.7,
    this.minTimeSec = 0.0005,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 18),
    this.enabled = true,
  });

  final EnvelopeParams value;
  final ValueChanged<EnvelopeParams> onChanged;

  final double height;
  final double maxTimeSec;
  final double sustainDisplaySec;
  final double minTimeSec;
  final EdgeInsets padding;
  final bool enabled;

  @override
  State<EnvelopeGraphEditor> createState() => _EnvelopeGraphEditorState();
}

enum _DragHandle { attackPeak, holdEnd, decaySustain, sustainLevel, releaseEnd }

class _EnvelopeGraphEditorState extends State<EnvelopeGraphEditor> {
  _DragHandle? _drag;
  late EnvelopeParams _p;

  @override
  void initState() {
    super.initState();
    _p = widget.value;
  }

  @override
  void didUpdateWidget(covariant EnvelopeGraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _p = widget.value;
  }

  double get A => _p.attackSec;
  double get H => _p.holdSec;
  double get D => _p.decaySec;
  double get S => _p.sustainLevel;
  double get R => _p.releaseSec;

  void _emit(EnvelopeParams np) {
    _p = np;
    widget.onChanged(np);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.55,
      child: SizedBox(
        height: widget.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final rect = Offset.zero & Size(c.maxWidth, widget.height);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: widget.enabled ? (d) => _onPanStart(d.localPosition, rect) : null,
                    onPanUpdate: widget.enabled ? (d) => _onPanUpdate(d.localPosition, rect) : null,
                    onPanEnd: widget.enabled ? (_) => _drag = null : null,
                    onDoubleTapDown: widget.enabled
                        ? (d) {
                            final h = _hitTest(d.localPosition, rect);
                            if (h != null) _resetHandle(h);
                          }
                        : null,
                    child: CustomPaint(
                      painter: _EnvelopePainter(
                        params: _p,
                        padding: widget.padding,
                        maxTimeSec: widget.maxTimeSec,
                        sustainDisplaySec: widget.sustainDisplaySec,
                        gridColor: cs.outlineVariant.withValues(alpha: 0.35),
                        lineColor: cs.primary,
                        fillColor: cs.primary.withValues(alpha: 0.16),
                        handleColor: cs.primary,
                        textColor: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 12),
                Knob(
                  label: 'Attack',
                  value: _p.attackSec,
                  size: 40,
                  onChanged: (v) => _emit(_p.copyWith(attackSec: v)),
                ),
                const SizedBox(width: 12),
                Knob(
                  label: 'Hold',
                  value: _p.holdSec,
                  size: 40,
                  onChanged: (v) => _emit(_p.copyWith(holdSec: v)),
                ),
                const SizedBox(width: 12),
                Knob(
                  label: 'Decay',
                  value: _p.decaySec,
                  size: 40,
                  onChanged: (v) => _emit(_p.copyWith(decaySec: v)),
                ),
                const SizedBox(width: 12),
                Knob(
                  label: 'Sustain',
                  value: _p.sustainLevel,
                  size: 40,
                  onChanged: (v) => _emit(_p.copyWith(sustainLevel: v)),
                ),
                const SizedBox(width: 12),
                Knob(
                  label: 'Release',
                  value: _p.releaseSec,
                  size: 40,
                  onChanged: (v) => _emit(_p.copyWith(releaseSec: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetHandle(_DragHandle h) {
    switch (h) {
      case _DragHandle.attackPeak:
        _emit(_p.copyWith(attackSec: 0.01));
        break;
      case _DragHandle.holdEnd:
        _emit(_p.copyWith(holdSec: 0.0));
        break;
      case _DragHandle.decaySustain:
        _emit(_p.copyWith(decaySec: 0.08));
        break;
      case _DragHandle.sustainLevel:
        _emit(_p.copyWith(sustainLevel: 0.6));
        break;
      case _DragHandle.releaseEnd:
        _emit(_p.copyWith(releaseSec: 0.12));
        break;
    }
  }

  void _onPanStart(Offset pos, Rect rect) {
    _drag = _hitTest(pos, rect);
  }

  _DragHandle? _hitTest(Offset pos, Rect rect) {
    final g = _geom(rect);
    final pts = g.points;
    const hitR = 14.0;

    bool near(Offset a, Offset b) => (a - b).distance <= hitR;

    if (near(pos, pts.attackPeak)) return _DragHandle.attackPeak;
    if (near(pos, pts.holdEnd)) return _DragHandle.holdEnd;
    if (near(pos, pts.decaySustain)) return _DragHandle.decaySustain;
    if (near(pos, pts.sustainEnd)) return _DragHandle.sustainLevel;
    if (near(pos, pts.releaseEnd)) return _DragHandle.releaseEnd;

    return null;
  }

  void _onPanUpdate(Offset pos, Rect rect) {
    if (_drag == null) return;

    final g = _geom(rect);
    final toTime = g.toTime;
    final toLevel = g.toLevel;

    final t = toTime(pos.dx).clamp(0.0, widget.maxTimeSec);
    final y = toLevel(pos.dy).clamp(0.0, 1.0);

    final t1 = A;
    final t2 = A + H;
    final t3 = A + H + D;
    final t4 = t3 + widget.sustainDisplaySec;

    EnvelopeParams np = _p;

    switch (_drag!) {
      case _DragHandle.attackPeak:
        {
          final newA = t.clamp(widget.minTimeSec, widget.maxTimeSec);

          np = np.copyWith(attackSec: newA);
          break;
        }

      case _DragHandle.holdEnd:
        {
          final newHoldEnd = t.clamp(t1, widget.maxTimeSec);
          final newH = (newHoldEnd - t1).clamp(0.0, widget.maxTimeSec);
          np = np.copyWith(holdSec: newH);
          break;
        }

      case _DragHandle.decaySustain:
        {
          final newDecayEnd = t.clamp(t2 + widget.minTimeSec, widget.maxTimeSec);
          final newD = (newDecayEnd - t2).clamp(widget.minTimeSec, widget.maxTimeSec);
          final newS = y.clamp(0.0, 1.0);

          np = np.copyWith(decaySec: newD, sustainLevel: newS);
          break;
        }

      case _DragHandle.sustainLevel:
        {
          final newS = y.clamp(0.0, 1.0);
          np = np.copyWith(sustainLevel: newS);
          break;
        }

      case _DragHandle.releaseEnd:
        {
          final newReleaseEnd = t.clamp(t4 + widget.minTimeSec, widget.maxTimeSec + widget.sustainDisplaySec + 3);
          final newR = (newReleaseEnd - t4).clamp(widget.minTimeSec, 10.0);
          np = np.copyWith(releaseSec: newR);
          break;
        }
    }

    np = np.copyWith(
      attackSec: np.attackSec.clamp(widget.minTimeSec, 10.0),
      decaySec: np.decaySec.clamp(widget.minTimeSec, 10.0),
      holdSec: np.holdSec.clamp(0.0, 10.0),
      releaseSec: np.releaseSec.clamp(widget.minTimeSec, 10.0),
      sustainLevel: np.sustainLevel.clamp(0.0, 1.0),
    );

    _emit(np);
  }

  _EnvelopeGeometry _geom(Rect rect) {
    final inner = Rect.fromLTWH(
      rect.left + widget.padding.left,
      rect.top + widget.padding.top,
      rect.width - widget.padding.horizontal,
      rect.height - widget.padding.vertical,
    );

    double toX(double timeSec) => inner.left + (timeSec / widget.maxTimeSec) * inner.width;
    double toY(double level) => inner.bottom - (level.clamp(0.0, 1.0) * inner.height);

    double toTime(double x) => ((x - inner.left) / inner.width) * widget.maxTimeSec;
    double toLevel(double y) => ((inner.bottom - y) / inner.height);

    final tA = A;
    final tH = A + H;
    final tD = A + H + D;
    final tS = tD + widget.sustainDisplaySec;
    final tR = tS + R;

    final points = _EnvelopePoints(
      attackPeak: Offset(toX(tA), toY(1.0)),
      holdEnd: Offset(toX(tH), toY(1.0)),
      decaySustain: Offset(toX(tD), toY(S)),
      sustainEnd: Offset(toX(tS), toY(S)),
      releaseEnd: Offset(toX(tR), toY(0.0)),
      start: Offset(toX(0), toY(0)),
    );

    return _EnvelopeGeometry(inner: inner, toX: toX, toY: toY, toTime: toTime, toLevel: toLevel, points: points);
  }
}

class _EnvelopeGeometry {
  _EnvelopeGeometry({
    required this.inner,
    required this.toX,
    required this.toY,
    required this.toTime,
    required this.toLevel,
    required this.points,
  });

  final Rect inner;
  final double Function(double) toX;
  final double Function(double) toY;
  final double Function(double) toTime;
  final double Function(double) toLevel;
  final _EnvelopePoints points;
}

class _EnvelopePoints {
  _EnvelopePoints({
    required this.start,
    required this.attackPeak,
    required this.holdEnd,
    required this.decaySustain,
    required this.sustainEnd,
    required this.releaseEnd,
  });

  final Offset start;
  final Offset attackPeak;
  final Offset holdEnd;
  final Offset decaySustain;
  final Offset sustainEnd;
  final Offset releaseEnd;
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({
    required this.params,
    required this.padding,
    required this.maxTimeSec,
    required this.sustainDisplaySec,
    required this.gridColor,
    required this.lineColor,
    required this.fillColor,
    required this.handleColor,
    required this.textColor,
  });

  final EnvelopeParams params;
  final EdgeInsets padding;
  final double maxTimeSec;
  final double sustainDisplaySec;

  final Color gridColor;
  final Color lineColor;
  final Color fillColor;
  final Color handleColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = Rect.fromLTWH(
      rect.left + padding.left,
      rect.top + padding.top,
      rect.width - padding.horizontal,
      rect.height - padding.vertical,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final x = inner.left + inner.width * (i / 5);
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), gridPaint);
    }

    for (int i = 0; i <= 4; i++) {
      final y = inner.top + inner.height * (i / 4);
      canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), gridPaint);
    }

    double toX(double t) => inner.left + (t / maxTimeSec) * inner.width;
    double toY(double v) => inner.bottom - (v.clamp(0.0, 1.0) * inner.height);

    final A = params.attackSec;
    final H = params.holdSec;
    final D = params.decaySec;
    final S = params.sustainLevel;
    final R = params.releaseSec;

    final t0 = 0.0;
    final t1 = A;
    final t2 = A + H;
    final t3 = A + H + D;
    final t4 = t3 + sustainDisplaySec;
    final t5 = t4 + R;

    final p0 = Offset(toX(t0), toY(0));
    final p1 = Offset(toX(t1), toY(1));
    final p2 = Offset(toX(t2), toY(1));
    final p3 = Offset(toX(t3), toY(S));
    final p4 = Offset(toX(t4), toY(S));
    final p5 = Offset(toX(t5), toY(0));

    final path = Path()..moveTo(p0.dx, p0.dy);

    _addExpSegment(path, p0, p1, exp: 3.2);

    path.lineTo(p2.dx, p2.dy);

    _addExpSegment(path, p2, p3, exp: 2.6);

    path.lineTo(p4.dx, p4.dy);

    _addExpSegment(path, p4, p5, exp: 2.8);

    final fill = Path.from(path)
      ..lineTo(p5.dx, inner.bottom)
      ..lineTo(inner.left, inner.bottom)
      ..close();

    canvas.drawPath(fill, Paint()..color = fillColor);

    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    _drawHandle(canvas, p1);
    _drawHandle(canvas, p2);
    _drawHandle(canvas, p3);
    _drawHandle(canvas, p4);
    _drawHandle(canvas, p5);

    final tp = TextPainter(textDirection: TextDirection.ltr);

    _label(tp, canvas, inner, 'A ${_fmtMs(A)}', Offset(p1.dx - 18, inner.bottom + 2));
    _label(tp, canvas, inner, 'H ${_fmtMs(H)}', Offset(p2.dx - 18, inner.bottom + 2));
    _label(tp, canvas, inner, 'D ${_fmtMs(D)}', Offset(p3.dx - 18, inner.bottom + 2));
    _label(tp, canvas, inner, 'S ${(S * 100).round()}%', Offset(p4.dx - 22, inner.bottom + 2));
    _label(tp, canvas, inner, 'R ${_fmtMs(R)}', Offset(p5.dx - 18, inner.bottom + 2));
  }

  void _drawHandle(Canvas canvas, Offset p) {
    final outer = Paint()..color = handleColor;
    final inner = Paint()..color = Colors.black.withValues(alpha: 0.15);

    canvas.drawCircle(p, 6.0, outer);
    canvas.drawCircle(p, 3.0, inner);
  }

  void _label(TextPainter tp, Canvas canvas, Rect inner, String text, Offset pos) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: 11, color: textColor),
    );
    tp.layout();

    final x = pos.dx.clamp(inner.left, inner.right - tp.width);
    final y = pos.dy;
    tp.paint(canvas, Offset(x, y));
  }

  void _addExpSegment(Path path, Offset a, Offset b, {required double exp}) {
    const steps = 22;
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;

      final y = 1 - math.pow(1 - t, exp).toDouble();
      final x = a.dx + (b.dx - a.dx) * t;
      final yy = a.dy + (b.dy - a.dy) * y;
      path.lineTo(x, yy);
    }
  }

  String _fmtMs(double sec) {
    final ms = sec * 1000.0;
    if (ms < 1) return '${ms.toStringAsFixed(2)}ms';
    if (ms < 10) return '${ms.toStringAsFixed(1)}ms';
    if (ms < 1000) return '${ms.toStringAsFixed(0)}ms';
    return '${sec.toStringAsFixed(2)}s';
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) => old.params != params;
}
