import 'package:flutter/material.dart';
import 'package:synthesizer/presentation/synth_screen.dart';

class SynthApp extends StatelessWidget {
  const SynthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart Synth MVP',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
          selectedIcon: const SizedBox(),
        ),
      ),
      home: const SynthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
