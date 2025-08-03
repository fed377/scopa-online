import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/main.dart';
import 'package:scopa/opponent_hand.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart' as utils;

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
          String url = data['images'][nextPlayerId];

          void incrementId() {
            x += 1;
            nextPlayerId = data['players'][(userState.turnKey + x) % 4];
            nextPlayerHand = hands[nextPlayerId];
            playerName = data['nicknames'][nextPlayerId];
            url = data['images'][nextPlayerId];
          }

          List<Widget> children = [];

          children.add(OpponentHand(
            cardSize * (nextPlayerHand.length + 1),
            cardSize,
            1,
            Alignment.centerLeft,
            playerName,
            url,
            nextPlayerHand.length,
          ));
          incrementId();
          children.add(OpponentHand(
            cardSize * (nextPlayerHand.length + 1),
            cardSize,
            2,
            Alignment.topCenter,
            playerName,
            url,
            nextPlayerHand.length,
          ));
          incrementId();
          children.add(OpponentHand(
            cardSize * (nextPlayerHand.length + 1),
            cardSize,
            3,
            Alignment.centerRight,
            playerName,
            url,
            nextPlayerHand.length,
          ));

          children.add(
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(220.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      foregroundImage: url.trim() == '' ? null : CachedNetworkImageProvider(url),
                    ),
                    Text(
                      '${data['nicknames'][userState.uid]} - ${data['turn'] == userState.playKey ? 'Your Turn' : ''}',
                      style: GoogleFonts.varelaRound(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          );

          return Stack(children: utils.pad(children));
        },
      ),
    );
  }
}
