import 'dart:math';

double midiToFreq(int midi) => 440.0 * pow(2.0, (midi - 69) / 12.0);
