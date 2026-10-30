import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/entrance.dart';
import 'package:scopa/widgets/playing_card.dart';

/// The cards on the table. A played card slides in from its player's side;
/// captured cards fly to the capturing pair's pile (see TakenCards).
class BoardCards extends StatelessWidget {
  const BoardCards({
    super.key,
    required this.data,
    required this.seat,
    required this.pair,
    required this.cardAnimDuration,
  });

  final DynaMap data;

  /// This player's seat and pair. Our captures fly to the bottom-right pile,
  /// the opponents' to the top-left one.
  final int seat;
  final String pair;
  final Duration cardAnimDuration;

  static const _columns = 5;
  static const _gap = 14.0;

  /// Where a card played from [playerSeat] comes from, relative to the table.
  Offset _origin(int playerSeat, Size size) => switch ((playerSeat - seat) % 4) {
        0 => Offset(0, size.height * 0.4),
        1 => Offset(-size.width * 0.35, 0),
        2 => Offset(0, -size.height * 0.4),
        _ => Offset(size.width * 0.35, 0),
      };

  @override
  Widget build(BuildContext context) {
    final board = List<String>.from(data['board']);
    final disappearing = List<String>.from(data['disappearingCards'] ?? []);
    final pending = data['pending'] as Map<String, dynamic>?;
    final players = List<String>.from(data['players']);
    final ours = pending?['pair'] == pair;

    final size = MediaQuery.sizeOf(context);
    final height = CardMetrics.of(context).height * 0.92;
    final width = height * 0.73;
    final rows = (board.length / _columns).ceil();
    final columns = min(board.length, _columns);
    // The table is offset slightly upwards (see PlayBoard).
    final startY = size.height * 0.46 - (rows * (height + _gap) - _gap) / 2;
    final startX = size.width / 2 - (columns * (width + _gap) - _gap) / 2;

    Widget positioned(int index, String card) {
      final leaving = disappearing.contains(card);
      Widget child = PlayingCard(card, height: height);
      if (pending?['card'] == card) {
        child = Entrance(
          duration: const Duration(milliseconds: 420),
          offset: _origin(players.indexOf(pending!['player']), size),
          scale: 0.85,
          child: child,
        );
      }
      return AnimatedPositioned(
        key: ValueKey(card),
        curve: Motion.move,
        duration: leaving ? cardAnimDuration : Motion.medium,
        top: leaving ? (ours ? size.height - 30 - height : 30) : startY + (height + _gap) * (index ~/ _columns),
        left: leaving ? (ours ? size.width - 40 - width : 40) : startX + (width + _gap) * (index % _columns),
        child: AnimatedScale(
          scale: leaving ? 0.6 : 1,
          duration: cardAnimDuration,
          curve: Motion.move,
          child: AnimatedRotation(
            turns: leaving ? (ours ? 0.03 : -0.03) : 0,
            duration: cardAnimDuration,
            curve: Motion.move,
            child: child,
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: Stack(children: [for (final (index, card) in board.indexed) positioned(index, card)]),
    );
  }
}
