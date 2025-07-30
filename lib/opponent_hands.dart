import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/main.dart';
import 'package:scopa/opponent_card.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';

class OpponentHands extends StatelessWidget {
  const OpponentHands({
    super.key,
    required this.game,
    required this.userState,
    required this.cardSize,
  });

  final DocumentReference<DynaMap> game;
  final UserState userState;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: game.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hands = data['hands'] as Map<String, dynamic>;
          int x = 1;
          String nextPlayerId = data['players'][(userState.turnKey + x) % 4];
          List<dynamic> nextPlayerHand = hands[nextPlayerId];
          String playerName = data['nicknames'][nextPlayerId];

          void incrementId() {
            x += 1;
            nextPlayerId = data['players'][(userState.turnKey + x) % 4];
            nextPlayerHand = hands[nextPlayerId];
            playerName = data['nicknames'][nextPlayerId];
          }

          final left = nextPlayerHand.length;
          final leftName = playerName;
          incrementId();
          final top = nextPlayerHand.length;
          final topName = playerName;
          incrementId();
          final right = nextPlayerHand.length;
          final rightName = playerName;

          Widget c(int l, int t, AlignmentGeometry a, String n) {
            final fullWidth = cardSize * (l + 1);

            return Align(
              alignment: a,
              child: RotatedBox(
                quarterTurns: t,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotatedBox(
                      quarterTurns: -t,
                      child: Text(
                        n,
                        style: GoogleFonts.varelaRound(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: fullWidth,
                      height: 200,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: List.generate(
                          l,
                          (x) => AnimatedPositioned(
                            duration: Durations.short4,
                            bottom: 10,
                            left: x * cardSize,
                            child: OpponentCard(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: pad([
              c(left, 1, Alignment.centerLeft, leftName),
              c(top, 2, Alignment.topCenter, topName),
              c(right, 3, Alignment.centerRight, rightName),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(220.0),
                  child: Text(
                      '${data['nicknames'][userState.uid]} - ${data['turn'] == userState.playKey ? 'Your Turn' : ''}',
                      style: GoogleFonts.varelaRound(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
