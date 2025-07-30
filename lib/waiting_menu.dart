import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scopa/hand_card.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';

class WaitingMenu extends StatelessWidget {
  const WaitingMenu({
    super.key,
    required this.userState,
    required this.gameId,
    required this.startGame,
  });

  final UserState userState;
  final String gameId;
  final void Function() startGame;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('Game ID: $gameId'),
                OutlinedButton(
                  child: Icon(Icons.copy_rounded),
                  onPressed: () => Clipboard.setData(ClipboardData(text: gameId)),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pad([
              HandCard('23', (_) {}, 150),
              Text(
                'Online Scopa',
                style: TextStyle(fontFamily: 'Serif', fontSize: 25),
              ),
              userState.dealer
                  ? FilledButton(
                      onPressed: startGame,
                      child: Text('Start Game'),
                    )
                  : Text('Waiting for admin to start game'),
            ]),
          ),
        ),
      ],
    ));
  }
}
