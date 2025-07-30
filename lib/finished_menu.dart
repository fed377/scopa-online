import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/score_card.dart';
import 'package:scopa/utils.dart';

class FinishedMenu extends StatelessWidget {
  const FinishedMenu(
    this.data,
    this.pair,
    this.oppositePair,
    this.callback,
    this.dealer, {
    super.key,
  });

  final Stream<DocumentSnapshot<Map<String, dynamic>>> data;
  final String pair;
  final String oppositePair;
  final void Function() callback;
  final bool dealer;

  List<Widget> buildScoreWidgets(score) => [
        if (score['setteBello'])
          ScoreCard(
            num: '7',
            icon: Image.asset('assets/diamond_red.png'),
            color: Colors.red,
            text: 'Seven of Diamonds',
          ),
        if (score['cards'])
          ScoreCard(
            num: ' ',
            icon: Text(' '),
            color: Colors.transparent,
            text: 'More Total Cards',
          ),
        if (score['diamonds'])
          ScoreCard(
            num: ' ',
            icon: Image.asset('assets/diamond_red.png'),
            color: Colors.red,
            text: 'More Total Diamonds',
          ),
        if (score['primiera'])
          ScoreCard(
            num: '',
            icon: Text('7',
                style: GoogleFonts.varelaRound(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
            color: Colors.black,
            text: 'Primiera',
          ),
        if (score['napula'] > 0)
          ScoreCard(
            num: '1-${score['napula']}',
            icon: Image.asset('assets/diamond_red.png'),
            color: Colors.red,
            text: 'Napula',
          ),
        if (score['scope'] > 0)
          ScoreCard(
            num: score['scope'].toString(),
            icon: Icon(Icons.cleaning_services_rounded, color: Colors.black, size: 40),
            color: Colors.black,
            text: '${score['scope']} Scope',
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          final Map<String, dynamic> score = data!['${pair}ScoreData'] as Map<String, dynamic>;

          return Stack(
            children: pad([
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(100.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (score['setteBello'])
                        ScoreCard(
                          num: '7',
                          icon: Image.asset('assets/diamond_red.png'),
                          color: Colors.red,
                          text: 'Seven of Diamonds',
                        ),
                      if (score['cards'])
                        ScoreCard(
                          num: ' ',
                          icon: Text(' '),
                          color: Colors.transparent,
                          text: 'More Total Cards',
                        ),
                      if (score['diamonds'])
                        ScoreCard(
                          num: ' ',
                          icon: Image.asset('assets/diamond_red.png'),
                          color: Colors.red,
                          text: 'More Total Diamonds',
                        ),
                      if (score['primiera'])
                        ScoreCard(
                          num: '',
                          icon: Text('7',
                              style: GoogleFonts.varelaRound(
                                  color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
                          color: Colors.black,
                          text: 'Primiera',
                        ),
                      if (score['napula'] > 0)
                        ScoreCard(
                          num: '1-${score['napula']}',
                          icon: Image.asset('assets/diamond_red.png'),
                          color: Colors.red,
                          text: 'Napula',
                        ),
                      if (score['scope'] > 0)
                        ScoreCard(
                          num: score['scope'].toString(),
                          icon: Icon(Icons.cleaning_services_rounded, color: Colors.black, size: 40),
                          color: Colors.black,
                          text: '${score['scope']} Scope',
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: pad([
                        Text('Your Score: ${snapshot.data!['${pair}Score']}'),
                        Text("Opponents' Score: ${snapshot.data!['${oppositePair}Score']}"),
                      ]),
                    ),
                    if (dealer)
                      FilledButton(
                        onPressed: callback,
                        child: Text('Restart game (round ${snapshot.data!['round'] + 1})'),
                      ),
                  ],
                ),
              ),
            ]),
          );
        });
  }
}

///        'primiera': fPrimiera > sPrimiera,
///        'setteBello': fCards.contains('27'),
///        'scope': fScope,
///        'cards': fCards.length > sCards.length,
///        'diamonds': fDiamonds > sDiamonds,
///        'napula': fNapula,
