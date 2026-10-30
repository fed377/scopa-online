import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// The "Scopone" title. It always renders at full size and is scaled to
/// [fontSize] by a FittedBox, so the hero flight between screens scales it
/// smoothly instead of re-laying out the text.
class MainTitle extends StatelessWidget {
  const MainTitle({super.key, this.fontSize = 128});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'title',
      child: SizedBox(
        height: fontSize * 1.2,
        child: FittedBox(
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withAlpha(150)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Scopone', style: displayStyle(128).copyWith(letterSpacing: -2)),
            ),
          ),
        ),
      ),
    );
  }
}
