import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scopa/board_card.dart';
import 'package:scopa/opponent_card.dart';

class TakenCards extends StatelessWidget {
  const TakenCards({
    super.key,
    required this.snapshot,
    required this.pair,
    required this.oppositePair,
    required this.cardSize,
  });

  final Stream<DocumentSnapshot<Map<String, dynamic>>> snapshot;
  final String pair;
  final String oppositePair;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final takenCards = (data['${pair}Cards'] as List<dynamic>).length;
        final takenScope = (data['${pair}ScopeCards'] as List<dynamic>);
        final oppositeCards = (data['${oppositePair}Cards'] as List<dynamic>).length;
        final oppositeScope = (data['${oppositePair}ScopeCards'] as List<dynamic>);

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(26.0),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (takenCards > 0)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RotatedBox(quarterTurns: 1, child: OpponentCard()),
                        ),
                      if (takenScope.isNotEmpty) BoardCard(num: takenScope.last),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (oppositeCards > 0)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RotatedBox(quarterTurns: 1, child: OpponentCard()),
                        ),
                      if (oppositeScope.isNotEmpty) BoardCard(num: oppositeScope.last),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
