import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scopa/hand_card.dart';
import 'package:scopa/user_state.dart';

class Hand extends StatelessWidget {
  const Hand({
    super.key,
    required this.userState,
    required this.snapshot,
    required this.cardSize,
    required this.playCard,
  });
  final Stream<DocumentSnapshot<Map<String, dynamic>>> snapshot;
  final double cardSize;
  final void Function(String) playCard;
  final UserState userState;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hands = data['hands'] as Map<String, dynamic>;
        final myHand = List<String>.from(hands[userState.uid] ?? []);
        final midPosition = MediaQuery.sizeOf(context).width / 2;
        final startPos = midPosition - (myHand.length / 2) * cardSize;

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: List.generate(
                myHand.length,
                (x) {
                  return AnimatedPositioned(
                    duration: Durations.short4,
                    bottom: 10,
                    left: (startPos + x * cardSize) - cardSize / 2,
                    child: HandCard(myHand[x], playCard, cardSize),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
