import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class WaveformScopeController extends ChangeNotifier {
  WaveformScopeController({this.capacity = 4096, this.decimation = 4}) : _buf = Float32List(capacity);

  /// How many points to keep for display
  final int capacity;

  /// Skip samples (2 = take every second), to not overload UI
  final int decimation;

  final Float32List _buf;
  int _write = 0;
  bool _filled = false;

  /// Add new PCM16 (mono) chunk
  void pushPcm16(Int16List pcm) {
    // convert to [-1..1] + decimate
    for (int i = 0; i < pcm.length; i += decimation) {
      _buf[_write] = pcm[i] / 32768.0;
      _write++;
      if (_write >= _buf.length) {
        _write = 0;
        _filled = true;
      }
    }
    notifyListeners();
  }

  /// Returns snapshot in correct order (old -> new).
  /// Here we copy, but this is done only during repaint.
  Float32List snapshot() {
    final out = Float32List(_buf.length);
    if (!_filled) {
      out.setRange(0, _write, _buf);
      // rest will be zero
      return out;
    }
    final tail = _buf.length - _write;
    out.setRange(0, tail, _buf.sublist(_write));
    out.setRange(tail, out.length, _buf.sublist(0, _write));
    return out;
  }
}
