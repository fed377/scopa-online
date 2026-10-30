import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// A card-shaped tile for one scoring category. Hovering lifts it and reveals
/// what it was awarded for.
class ScoreCard extends StatefulWidget {
  const ScoreCard({super.key, required this.num, required this.icon, required this.color, required this.text});

  final String num;
  final Widget icon;
  final Color color;
  final String text;

  @override
  State<ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<ScoreCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovering = true),
        onExit: (_) => setState(() => hovering = false),
        child: Tooltip(
          message: widget.text,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: hovering ? 1 : 0,
                duration: Motion.fast,
                // As wide as the card, so long labels don't push the cards apart.
                child: SizedBox(
                  width: 76,
                  height: 26,
                  child: OverflowBox(
                    maxWidth: 220,
                    child: Text(widget.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              AnimatedSlide(
                offset: hovering ? const Offset(0, -0.12) : Offset.zero,
                duration: Motion.medium,
                curve: Motion.enter,
                child: AnimatedScale(
                  scale: hovering ? 1.12 : 1,
                  duration: Motion.medium,
                  curve: Motion.enter,
                  child: SizedBox(
                    width: 76,
                    height: 104,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: roundedShape(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.cardLight, AppColors.cardDark],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        shadows: const [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4))],
                      ),
                      child: Stack(
                        children: [
                          Center(child: SizedBox(height: 40, child: widget.icon)),
                          Positioned(
                              left: 10, top: 8, child: Text(widget.num, style: displayStyle(22, color: widget.color))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
