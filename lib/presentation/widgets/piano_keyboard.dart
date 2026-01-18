import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuperPianoKeyboard extends StatefulWidget {
  const SuperPianoKeyboard({
    super.key,
    required this.visibleOctaves,
    required this.onNoteOn,
    required this.onNoteOff,
    this.height = 190,
    this.showLabels = true,
    this.enableComputerKeyboard = true,
    this.holdNotesWhileShifting = true,
    this.initialOctave = 4,
    this.minOctave = 0,
    this.maxOctave = 8,
  }) : assert(visibleOctaves >= 1);

  final int visibleOctaves;

  final ValueChanged<int> onNoteOn;

  final ValueChanged<int> onNoteOff;

  final double height;

  final bool showLabels;

  final bool enableComputerKeyboard;

  final bool holdNotesWhileShifting;

  final int initialOctave;

  final int minOctave;

  final int maxOctave;

  @override
  State<SuperPianoKeyboard> createState() => _SuperPianoKeyboardState();
}

class _SuperPianoKeyboardState extends State<SuperPianoKeyboard> {
  late int _baseOctave;
  late final FocusNode _focusNode;

  final Set<int> _pressedNotes = <int>{};

  final Map<int, int> _pointerToMidi = <int, int>{};

  final Set<int> _kbPressed = <int>{};

  @override
  void initState() {
    super.initState();
    _baseOctave = widget.initialOctave.clamp(widget.minOctave, _maxBaseOctaveAllowed());
    _focusNode = FocusNode(debugLabel: 'SuperPianoKeyboard');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SuperPianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _baseOctave = _baseOctave.clamp(widget.minOctave, _maxBaseOctaveAllowed());
  }

  int _maxBaseOctaveAllowed() {
    return widget.maxOctave - (widget.visibleOctaves - 1);
  }

  int _baseMidiC() => _octaveToMidiC(_baseOctave);

  static int _octaveToMidiC(int octave) {
    return (octave + 1) * 12;
  }

  bool get _canShiftLeft => _baseOctave > widget.minOctave;
  bool get _canShiftRight => _baseOctave < _maxBaseOctaveAllowed();

  void _shiftOctave(int delta) {
    if (delta == 0) return;

    setState(() {
      final next = (_baseOctave + delta).clamp(widget.minOctave, _maxBaseOctaveAllowed());
      _baseOctave = next;
    });

    if (!widget.holdNotesWhileShifting) {
      _releaseAllNotes(reason: 'octave shift');
    }
  }

  void _releaseAllNotes({required String reason}) {
    for (final midi in _pointerToMidi.values.toList()) {
      _noteOff(midi);
    }
    _pointerToMidi.clear();

    for (final midi in _kbPressed.toList()) {
      _noteOff(midi);
    }
    _kbPressed.clear();

    setState(() {
      _pressedNotes.clear();
    });
  }

  void _noteOn(int midi) {
    if (_pressedNotes.add(midi)) {
      widget.onNoteOn(midi);
      setState(() {});
    }
  }

  void _noteOff(int midi) {
    if (_pressedNotes.remove(midi)) {
      widget.onNoteOff(midi);
      setState(() {});
    } else {
      widget.onNoteOff(midi);
    }
  }

  int? _midiForFlKey(LogicalKeyboardKey k) {
    final base = _baseMidiC();

    const whiteKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.comma,
      LogicalKeyboardKey.period,
      LogicalKeyboardKey.slash,
    ];

    const whiteSemis = <int>[0, 2, 4, 5, 7, 9, 11, 12, 14, 16];

    final wi = whiteKeys.indexOf(k);
    if (wi != -1) return base + whiteSemis[wi];

    final blackMap = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.keyS: 1,
      LogicalKeyboardKey.keyD: 3,
      LogicalKeyboardKey.keyG: 6,
      LogicalKeyboardKey.keyH: 8,
      LogicalKeyboardKey.keyJ: 10,
      LogicalKeyboardKey.keyL: 13,
      LogicalKeyboardKey.semicolon: 15,
    };

    final semi = blackMap[k];
    if (semi != null) return base + semi;

    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enableComputerKeyboard) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _shiftOctave(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _shiftOctave(1);
        return KeyEventResult.handled;
      }
    }

    final midi = _midiForFlKey(event.logicalKey);
    if (midi == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (_kbPressed.add(midi)) {
        _noteOn(midi);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      if (_kbPressed.remove(midi)) {
        _noteOff(midi);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String _rangeLabel() {
    final startMidi = _baseMidiC();
    final endMidi = startMidi + widget.visibleOctaves * 12 - 1;
    return '${_noteName(startMidi)} – ${_noteName(endMidi)}';
  }

  static String _noteName(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final n = midi % 12;
    final octave = (midi ~/ 12) - 1;
    return '${names[n]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Octave down',
                onPressed: _canShiftLeft ? () => _shiftOctave(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _rangeLabel(),
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Octave up',
                onPressed: _canShiftRight ? () => _shiftOctave(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _PianoBody(
            baseMidiC: _baseMidiC(),
            visibleOctaves: widget.visibleOctaves,
            height: widget.height,
            showLabels: widget.showLabels,
            pressedNotes: _pressedNotes,
            colorScheme: cs,

            onPointerDown: (pointerId, midi) {
              _pointerToMidi[pointerId] = midi;
              _noteOn(midi);
            },
            onPointerMove: (pointerId, midi) {
              final prev = _pointerToMidi[pointerId];
              if (prev == midi) return;

              if (prev != null) _noteOff(prev);

              _pointerToMidi[pointerId] = midi;
              _noteOn(midi);
            },
            onPointerUp: (pointerId) {
              final prev = _pointerToMidi.remove(pointerId);
              if (prev != null) _noteOff(prev);
            },
          ),
          if (widget.enableComputerKeyboard) ...[
            const SizedBox(height: 8),
            Text(
              'Computer keyboard: Z X C V B N M , . /  |  Black: S D G H J L ;  |  Octaves: ← →',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _PianoBody extends StatelessWidget {
  const _PianoBody({
    required this.baseMidiC,
    required this.visibleOctaves,
    required this.height,
    required this.showLabels,
    required this.pressedNotes,
    required this.colorScheme,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
  });

  final int baseMidiC;
  final int visibleOctaves;
  final double height;
  final bool showLabels;

  final Set<int> pressedNotes;
  final ColorScheme colorScheme;

  final void Function(int pointerId, int midi) onPointerDown;
  final void Function(int pointerId, int midi) onPointerMove;
  final void Function(int pointerId) onPointerUp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final totalWidth = c.maxWidth;

        final whiteCount = 7 * visibleOctaves;
        final whiteW = totalWidth / whiteCount;

        final blackW = whiteW * 0.62;
        final blackH = height * 0.62;

        const whiteSemis = [0, 2, 4, 5, 7, 9, 11];

        const blackDefs = [
          (semi: 1, afterWhite: 0),
          (semi: 3, afterWhite: 1),
          (semi: 6, afterWhite: 3),
          (semi: 8, afterWhite: 4),
          (semi: 10, afterWhite: 5),
        ];

        final whiteRects = <_KeyRect>[];
        final blackRects = <_KeyRect>[];

        for (int octave = 0; octave < visibleOctaves; octave++) {
          for (int i = 0; i < 7; i++) {
            final midi = baseMidiC + octave * 12 + whiteSemis[i];
            final left = (octave * 7 + i) * whiteW;
            whiteRects.add(_KeyRect(rect: Rect.fromLTWH(left, 0, whiteW, height), midi: midi, isBlack: false));
          }
        }

        for (int octave = 0; octave < visibleOctaves; octave++) {
          for (final d in blackDefs) {
            final midi = baseMidiC + octave * 12 + d.semi;
            final whiteIndexGlobal = d.afterWhite + octave * 7;
            final left = (whiteIndexGlobal + 1) * whiteW - blackW * 0.5;
            blackRects.add(_KeyRect(rect: Rect.fromLTWH(left, 0, blackW, blackH), midi: midi, isBlack: true));
          }
        }

        int? hitTest(Offset localPos) {
          for (final k in blackRects) {
            if (k.rect.contains(localPos)) return k.midi;
          }
          for (final k in whiteRects) {
            if (k.rect.contains(localPos)) return k.midi;
          }
          return null;
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            final midi = hitTest(e.localPosition);
            if (midi != null) onPointerDown(e.pointer, midi);
          },
          onPointerMove: (e) {
            final midi = hitTest(e.localPosition);
            if (midi != null) onPointerMove(e.pointer, midi);
          },
          onPointerUp: (e) => onPointerUp(e.pointer),
          onPointerCancel: (e) => onPointerUp(e.pointer),
          child: CustomPaint(
            size: Size(totalWidth, height),
            painter: _PianoPainter(
              baseMidiC: baseMidiC,
              visibleOctaves: visibleOctaves,
              whiteW: whiteW,
              blackW: blackW,
              height: height,
              blackH: blackH,
              showLabels: showLabels,
              pressedNotes: pressedNotes,
              colorScheme: colorScheme,
            ),
          ),
        );
      },
    );
  }
}

class _KeyRect {
  const _KeyRect({required this.rect, required this.midi, required this.isBlack});

  final Rect rect;
  final int midi;
  final bool isBlack;
}

class _PianoPainter extends CustomPainter {
  _PianoPainter({
    required this.baseMidiC,
    required this.visibleOctaves,
    required this.whiteW,
    required this.blackW,
    required this.height,
    required this.blackH,
    required this.showLabels,
    required this.pressedNotes,
    required this.colorScheme,
  });

  final int baseMidiC;
  final int visibleOctaves;

  final double whiteW;
  final double blackW;
  final double height;
  final double blackH;

  final bool showLabels;
  final Set<int> pressedNotes;
  final ColorScheme colorScheme;

  static const _whiteSemis = [0, 2, 4, 5, 7, 9, 11];
  static const _blackDefs = [
    (semi: 1, afterWhite: 0),
    (semi: 3, afterWhite: 1),
    (semi: 6, afterWhite: 3),
    (semi: 8, afterWhite: 4),
    (semi: 10, afterWhite: 5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500);

    final whiteUp = colorScheme.surfaceContainerHigh;
    final whiteDown = colorScheme.surfaceContainer;
    final whiteBorder = colorScheme.surface;

    final blackUp = colorScheme.inverseSurface;
    final blackDown = colorScheme.inversePrimary;
    final blackBorder = colorScheme.surface;

    final labelPaint = TextPainter(textDirection: TextDirection.ltr);

    for (int octave = 0; octave < visibleOctaves; octave++) {
      for (int i = 0; i < 7; i++) {
        final midi = baseMidiC + octave * 12 + _whiteSemis[i];
        final left = (octave * 7 + i) * whiteW;
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, whiteW, height), const Radius.circular(8));

        final isPressed = pressedNotes.contains(midi);

        final fill = Paint()..color = isPressed ? whiteDown : whiteUp;
        final stroke = Paint()
          ..color = whiteBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);

        if (showLabels) {
          final label = _noteName(midi);
          labelPaint.text = TextSpan(text: label, style: textStyle);
          labelPaint.layout(maxWidth: whiteW - 6);
          labelPaint.paint(canvas, Offset(left + (whiteW - labelPaint.width) / 2, height - labelPaint.height - 6));
        }
      }
    }

    for (int octave = 0; octave < visibleOctaves; octave++) {
      for (final d in _blackDefs) {
        final midi = baseMidiC + octave * 12 + d.semi;
        final whiteIndexGlobal = d.afterWhite + octave * 7;
        final left = (whiteIndexGlobal + 1) * whiteW - blackW * 0.5;

        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, blackW, blackH), const Radius.circular(6));

        final isPressed = pressedNotes.contains(midi);

        final fill = Paint()..color = isPressed ? blackDown : blackUp;
        final stroke = Paint()
          ..color = blackBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PianoPainter oldDelegate) {
    return oldDelegate.baseMidiC != baseMidiC ||
        oldDelegate.visibleOctaves != visibleOctaves ||
        oldDelegate.whiteW != whiteW ||
        oldDelegate.blackW != blackW ||
        oldDelegate.height != height ||
        oldDelegate.blackH != blackH ||
        oldDelegate.showLabels != showLabels ||
        !setEquals(oldDelegate.pressedNotes, pressedNotes) ||
        oldDelegate.colorScheme != colorScheme;
  }

  static String _noteName(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final n = midi % 12;
    final octave = (midi ~/ 12) - 1;
    return '${names[n]}$octave';
  }
}
