import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

const _suitImages = {
  1: 'assets/heart_red.png',
  2: 'assets/diamond_red.png',
  3: 'assets/club_black.png',
  4: 'assets/spade_black.png',
};
const _suitNames = {1: 'hearts', 2: 'diamonds', 3: 'clubs', 4: 'spades'};
const _valueNames = {'1': 'Ace', '8': 'Jack', '9': 'Queen', '0': 'King'};

String suitImage(String card) => _suitImages[int.parse(card[0])]!;

Color cardColor(String card) => card[0] == '1' || card[0] == '2' ? AppColors.suitRed : AppColors.suitBlack;

/// The corner index: A, 2-7, J, Q, K.
String cardIndex(String card) => switch (card[1]) {
      '1' => 'A',
      '8' => 'J',
      '9' => 'Q',
      '0' => 'K',
      final v => v,
    };

/// Spoken name, e.g. "7 of diamonds".
String cardName(String card) => '${_valueNames[card[1]] ?? card[1]} of ${_suitNames[int.parse(card[0])]}';

/// Card size for the current screen, so the table fits small laptops and
/// doesn't look tiny on large monitors.
class CardMetrics {
  const CardMetrics(this.height);

  factory CardMetrics.of(BuildContext context) =>
      CardMetrics((MediaQuery.sizeOf(context).height * 0.14).clamp(84.0, 132.0));

  final double height;
  double get width => height * 0.73;
}

ShapeDecoration _cardDecoration(double width, {bool elevated = false, bool shadow = true, DecorationImage? image}) =>
    ShapeDecoration(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(width * 0.26)),
      gradient: image == null
          ? const LinearGradient(
              colors: [AppColors.cardLight, AppColors.cardDark],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            )
          : null,
      image: image,
      shadows: [
        if (shadow)
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: elevated ? 26 : 14,
            offset: Offset(0, elevated ? 12 : 4),
          ),
      ],
    );

class PlayingCard extends StatelessWidget {
  const PlayingCard(this.card, {super.key, this.height = 100, this.elevated = false});

  final String card;
  final double height;

  /// Deeper shadow, for a card lifted off the table.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.73;
    final color = cardColor(card);
    final index = Text(cardIndex(card), style: displayStyle(height * 0.25, color: color));
    return RepaintBoundary(
      child: Semantics(
        label: cardName(card),
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: _cardDecoration(width, elevated: elevated),
            child: Stack(
              children: [
                Positioned(left: width * 0.13, top: height * 0.07, child: index),
                Positioned(
                  right: width * 0.13,
                  bottom: height * 0.07,
                  child: RotatedBox(quarterTurns: 2, child: index),
                ),
                Center(child: Image.asset(suitImage(card), height: height * 0.38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.73;
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: _cardDecoration(width),
          child: Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: DecoratedBox(
              decoration: _cardDecoration(
                width * 0.9,
                shadow: false,
                image: const DecorationImage(image: AssetImage('assets/back_card.png'), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
