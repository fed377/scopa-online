import 'package:flutter/material.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/playing_card.dart';

/// The captured piles: this player's pair bottom-right, the opponents
/// top-left. Each shows a count badge, with its scope fanned face up behind it.
class TakenCards extends StatelessWidget {
  const TakenCards({super.key, required this.data, required this.pair});

  final DynaMap data;
  final String pair;

  Widget _pile(String pair, double height, {required bool ours}) {
    final taken = (data['${pair}Cards'] as List? ?? []).length;
    final scope = List<String>.from(data['${pair}ScopeCards'] ?? []);
    final width = height * 0.73;
    return AnimatedOpacity(
      opacity: taken > 0 ? 1 : 0,
      duration: Motion.medium,
      child: SizedBox(
        width: width + 22 * scope.length.clamp(0, 4) + 16,
        height: height + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, card) in scope.reversed.take(4).indexed)
              Positioned(
                left: (ours ? 22.0 * (i + 1) : 0) + 8,
                top: 8,
                child: Transform.rotate(
                  angle: (ours ? -1 : 1) * 0.12 * (i + 1),
                  child: PlayingCard(card, height: height),
                ),
              ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: (ours ? 0 : 22.0 * scope.length.clamp(0, 4)) + i * 3,
                top: 8 - i * 3.0,
                child: CardBack(height: height),
              ),
            Positioned(
              left: (ours ? 0 : 22.0 * scope.length.clamp(0, 4)) + width - 10,
              top: -6,
              child: AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: _Badge(key: ValueKey(taken), count: taken),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = CardMetrics.of(context).height * 0.62;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          Align(alignment: Alignment.bottomRight, child: _pile(pair, height, ours: true)),
          Align(alignment: Alignment.topLeft, child: _pile(otherPair(pair), height, ours: false)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: AppColors.glass,
        shadows: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text('$count', textAlign: TextAlign.center, style: displayStyle(13)),
    );
  }
}
