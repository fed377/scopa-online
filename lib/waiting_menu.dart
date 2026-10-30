import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/main_title.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/entrance.dart';
import 'package:scopa/widgets/player_badge.dart';

/// The lobby: four seats split into the two teams, the game code to share,
/// and the host's start button.
class WaitingMenu extends StatelessWidget {
  const WaitingMenu({
    super.key,
    required this.data,
    required this.uid,
    required this.gameId,
    required this.busy,
    required this.startGame,
  });

  final DynaMap data;
  final String uid;
  final String gameId;

  /// True while the host is dealing.
  final bool busy;
  final void Function() startGame;

  Widget _seat(int seat, List<String> players) {
    final nicknames = data['nicknames'] as Map;
    final images = data['images'] as Map;
    if (seat >= players.length) {
      return const GlassPill(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text('Waiting for a player…', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
      );
    }
    final id = players[seat];
    return Entrance(
      key: ValueKey(id),
      child: PlayerBadge(
        name: '${nicknames[id] ?? '?'}${id == uid ? ' (you)' : ''}',
        imageUrl: images[id] ?? '',
        trailing: seat == 0 ? const Icon(Icons.star_rounded, color: AppColors.accent, size: 18) : null,
      ),
    );
  }

  Widget _team(String title, List<int> seats, List<String> players) => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Text(title.toUpperCase(), style: displayStyle(13, color: Colors.white70).copyWith(letterSpacing: 1.5)),
          for (final seat in seats) _seat(seat, players),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final players = List<String>.from(data['players']);
    final isHost = players.isNotEmpty && players.first == uid;
    final mySeat = players.indexOf(uid);
    // Seats 0 and 2 play together, as do seats 1 and 3.
    final myTeam = [
      for (var s = 0; s < 4; s++)
        if (pairForSeat(s) == pairForSeat(mySeat)) s
    ];
    final theirTeam = [
      for (var s = 0; s < 4; s++)
        if (!myTeam.contains(s)) s
    ];
    final full = players.length == 4;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MainTitle(fontSize: 84),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 48,
              children: [
                _team('Your team', myTeam, players),
                Padding(padding: const EdgeInsets.only(top: 48), child: Text('vs', style: displayStyle(28))),
                _team('Opponents', theirTeam, players),
              ],
            ),
            const SizedBox(height: 32),
            isHost
                ? FilledButton.icon(
                    onPressed: full && !busy ? startGame : null,
                    icon: busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(full ? 'Start game' : 'Waiting for ${4 - players.length} more…'),
                  )
                : const GlassPill(
                    child:
                        Text('Waiting for the host to start the game', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
            const SizedBox(height: 24),
            _GameCode(gameId: gameId, private: data['privacy'] == 'private'),
          ],
        ),
      ),
    );
  }
}

class _GameCode extends StatefulWidget {
  const _GameCode({required this.gameId, required this.private});

  final String gameId;
  final bool private;

  @override
  State<_GameCode> createState() => _GameCodeState();
}

class _GameCodeState extends State<_GameCode> {
  bool copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.gameId));
    setState(() => copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.private) ...[
            const Icon(Icons.lock_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
          ],
          const Text('Game code  ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          SelectableText(widget.gameId, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(width: 6),
          IconButton(
            tooltip: copied ? 'Copied' : 'Copy game code',
            onPressed: _copy,
            icon: AnimatedSwitcher(
              duration: Motion.fast,
              child: Icon(copied ? Icons.check_rounded : Icons.copy_rounded, key: ValueKey(copied), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
