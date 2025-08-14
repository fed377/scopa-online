import 'package:flutter/material.dart';

class MainTitle extends StatelessWidget {
  const MainTitle({
    super.key,
    this.fontSize = 128,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'title',
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.white.withAlpha(135)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Stack(
          children: [
            Text(
              'Scopone',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: fontSize, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
