import 'package:flutter/services.dart';

typedef NoteOn = void Function(int midi);
typedef NoteOff = void Function(int midi);

class KeyboardInputController {
  KeyboardInputController({required this.onNoteOn, required this.onNoteOff});

  final NoteOn onNoteOn;
  final NoteOff onNoteOff;

  final Set<LogicalKeyboardKey> _pressed = {};
  int baseMidi = 60;

  static final List<LogicalKeyboardKey> _whiteKeys = <LogicalKeyboardKey>[
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

  static const List<int> _whiteSemis = <int>[0, 2, 4, 5, 7, 9, 11, 12, 14, 16];

  static final Map<LogicalKeyboardKey, int> _blackMap = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.keyS: 1,
    LogicalKeyboardKey.keyD: 3,
    LogicalKeyboardKey.keyG: 6,
    LogicalKeyboardKey.keyH: 8,
    LogicalKeyboardKey.keyJ: 10,
    LogicalKeyboardKey.keyL: 13,
    LogicalKeyboardKey.semicolon: 15,
  };

  bool handle(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.bracketLeft) {
        baseMidi = (baseMidi - 12).clamp(24, 96);
        return true;
      }
      if (key == LogicalKeyboardKey.bracketRight) {
        baseMidi = (baseMidi + 12).clamp(24, 96);
        return true;
      }
    }

    final midi = _midiForFlKey(key);
    if (midi == null) return false;

    if (event is KeyDownEvent) {
      if (_pressed.add(key)) onNoteOn(midi);
      return true;
    }
    if (event is KeyUpEvent) {
      if (_pressed.remove(key)) onNoteOff(midi);
      return true;
    }
    if (event is KeyRepeatEvent) return true;

    return false;
  }

  int? _midiForFlKey(LogicalKeyboardKey k) {
    final wi = _whiteKeys.indexOf(k);
    if (wi != -1) return baseMidi + _whiteSemis[wi];

    final semi = _blackMap[k];
    if (semi != null) return baseMidi + semi;

    return null;
  }
}
