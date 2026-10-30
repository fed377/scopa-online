import 'package:flutter/material.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/widgets/player_badge.dart';

/// The main menu buttons shown under the title once signed in.
class StartMenu extends StatelessWidget {
  const StartMenu({
    super.key,
    required this.user,
    required this.busy,
    required this.joinGame,
    required this.newGame,
    required this.showLeaderboard,
    required this.signOut,
  });

  final UserState user;

  /// True while a game is being created or joined; the buttons are disabled.
  final bool busy;
  final void Function() joinGame;
  final void Function(bool) newGame;
  final void Function() showLeaderboard;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerBadge(name: user.nickname, imageUrl: user.imgUrl),
        const SizedBox(height: 20),
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => newGame(false),
                      icon: busy
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text('New game'),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'New private game (join by code only)',
                    onPressed: busy ? null : () => newGame(true),
                    style: IconButton.styleFrom(fixedSize: const Size(46, 46)),
                    icon: const Icon(Icons.lock_rounded, size: 20),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: busy ? null : joinGame,
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Join game'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : showLeaderboard,
                icon: const Icon(Icons.emoji_events_rounded),
                label: const Text('Leaderboard'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: busy ? null : signOut,
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
