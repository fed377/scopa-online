import 'package:flutter/material.dart';
import 'package:scopa/hand_card.dart';

class CardArc extends StatelessWidget {
  const CardArc({super.key});

  @override
  Widget build(BuildContext context) {
    double cardWidth = 73;
    double cardSpacing = 40;
    return SizedBox(
      width: 260,
      height: 200,
      child: Stack(
        children: [
          Positioned(
            left: 0 * cardSpacing,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(-0.5)
                ..translate(0, 20),
              child: HandCard('31', (_) {}, cardWidth, canHover: false),
            ),
          ),
          Positioned(
            left: 1 * cardSpacing,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(-0.25)
                ..translate(0, 6),
              child: HandCard('21', (_) {}, cardWidth, canHover: false),
            ),
          ),
          Positioned(
            left: 4 * cardSpacing,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(0.5)
                ..translate(0, 23),
              child: HandCard('41', (_) {}, cardWidth, canHover: false),
            ),
          ),
          Positioned(
            left: 3 * cardSpacing,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(0.25)
                ..translate(0, 6),
              child: HandCard('11', (_) {}, cardWidth, canHover: false),
            ),
          ),
          Positioned(
            left: 2 * cardSpacing,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateZ(0),
              child: HandCard('27', (_) {}, cardWidth, canHover: false),
            ),
          ),
        ],
      ),
    );
  }
}
