import 'package:flutter/material.dart';
import 'package:scopa/card_arc.dart';
import 'package:scopa/main_title.dart';
import 'package:scopa/utils.dart';

class StartMenu extends StatelessWidget {
  const StartMenu({
    super.key,
    required this.joinGame,
    required this.newGame,
    required this.showLeaderboard,
  });

  final void Function() joinGame;
  final void Function(bool) newGame;
  final void Function() showLeaderboard;

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(glassColor),
        textStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white)));
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: pad([MainTitle()]),
          ),
          Hero(tag: 'arc', child: CardArc()),
          SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: pad([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: FilledButton(
                      onPressed: () => newGame(false),
                      style: style,
                      child: Text("Start Game"),
                    )),
                    const SizedBox(width: 10),
                    IconButton.outlined(onPressed: () => newGame(true), icon: Icon(Icons.lock_rounded)),
                  ],
                ),
                FilledButton(onPressed: joinGame, style: style, child: Text("Join Game")),
                FilledButton(onPressed: showLeaderboard, style: style, child: Text("Show Leaderboard")),
              ].map((e) => SizedBox(height: 40, child: e)).toList()),
            ),
          ),
        ],
      ),
    );
  }
}
