import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scopa/board_card.dart';

class BoardCards extends StatelessWidget {
  const BoardCards({
    super.key,
    required this.cardAnimDuration,
    required this.snapshot,
    required this.turnKey,
    required this.round,
  });

  final Duration cardAnimDuration;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> snapshot;
  final int turnKey;
  final int round;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hands = data['board'] as List<dynamic>;

        int rows = (hands.length / 3).ceil();
        int columns = min(hands.length, 3);
        var size = MediaQuery.sizeOf(context);
        double midY = size.height / 2;
        double midX = size.width / 2;
        final double cardHeight = 120;
        final double cardWidth = 87.6;
        double startY = midY - ((cardHeight * rows) / 2.0);
        double startX = midX - ((cardWidth * columns) / 2.0);

        return SizedBox.expand(
          child: Stack(
              children: List.generate(hands.length, (index) {
            final card = hands[index];
            int column = index % 3;
            int row = ((index - column) ~/ 3);
            bool contains = data['disappearingCards'].contains(card);
            bool ourCards = ((data['turn'] as int) - turnKey + round) % 2 == 0;
            return AnimatedPositioned(
                curve: Curves.easeInOut,
                duration: contains ? cardAnimDuration : Durations.short4,
                top: contains ? (!ourCards ? (2 * midY) - 26 - cardHeight : 0) : startY + cardHeight * row,
                left: contains ? (!ourCards ? (2 * midX) - 56 - cardWidth : 0) : startX + cardWidth * column,
                child: BoardCard(num: card));
          })),
        );
      },
    );
  }
}
