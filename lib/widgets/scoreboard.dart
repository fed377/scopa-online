import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// Compact match score shown during play: "You 13 · 4 Them · to 21".
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.ours, required this.theirs, required this.target});

  final int ours;
  final int theirs;
  final int target;

  Widget _score(int value, Color color) => AnimatedSwitcher(
        duration: Motion.medium,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Motion.enter)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text('$value', key: ValueKey(value), style: displayStyle(22, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70);
    return GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('YOU', style: label),
          const SizedBox(width: 8),
          _score(ours, AppColors.accent),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('·', style: label),
          ),
          _score(theirs, Colors.white),
          const SizedBox(width: 8),
          const Text('THEM', style: label),
          const SizedBox(width: 14),
          Text('to $target', style: label),
        ],
      ),
    );
  }
}
