import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 50,
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MS', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.0)),
            Text('synth', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.0)),
          ],
        ),
      ),
    );
  }
}
