import 'package:flutter/material.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/score_card.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/entrance.dart';

/// Shown after each hand (`finished`) and at the end of a match (`matchOver`).
class FinishedMenu extends StatelessWidget {
  const FinishedMenu({
    super.key,
    required this.data,
    required this.pair,
    required this.isHost,
    required this.busy,
    required this.onContinue,
  });

  final DynaMap data;
  final String pair;
  final bool isHost;

  /// True while the host is dealing.
  final bool busy;

  /// Deals the next hand, or starts a new match once the match is over.
  final void Function() onContinue;

  List<Widget> buildScoreWidgets(Map score) => [
        if (score['setteBello'] == true)
          ScoreCard(
            num: '7',
            icon: Image.asset('assets/diamond_red.png'),
            color: AppColors.suitRed,
            text: 'Seven of Diamonds',
          ),
        if (score['cards'] == true)
          ScoreCard(
            num: '',
            icon: const Icon(Icons.layers_rounded, color: AppColors.suitBlack, size: 40),
            color: AppColors.suitBlack,
            text: 'Most cards',
          ),
        if (score['diamonds'] == true)
          ScoreCard(
            num: '',
            icon: Image.asset('assets/diamond_red.png'),
            color: AppColors.suitRed,
            text: 'Most diamonds',
          ),
        if (score['primiera'] == true)
          ScoreCard(
            num: '',
            icon: Text('7', textAlign: TextAlign.center, style: displayStyle(36, color: AppColors.suitBlack)),
            color: AppColors.suitBlack,
            text: 'Primiera',
          ),
        if ((score['napula'] ?? 0) > 0)
          ScoreCard(
            num: '1-${score['napula']}',
            icon: Image.asset('assets/diamond_red.png'),
            color: AppColors.suitRed,
            text: 'Napula (${score['napula']})',
          ),
        if ((score['scope'] ?? 0) > 0)
          ScoreCard(
            num: score['scope'].toString(),
            icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.suitBlack, size: 40),
            color: AppColors.suitBlack,
            text: score['scope'] == 1 ? '1 Scopa' : '${score['scope']} Scope',
          ),
      ];

  Widget _pairRow(String label, String pair, int delayOffset) {
    final score = data['${pair}ScoreData'] as Map? ?? {};
    final cards = buildScoreWidgets(score);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label  +${score['total'] ?? 0}', style: displayStyle(20)),
        SizedBox(
          height: 150,
          child: cards.isEmpty
              ? const Center(child: Text('No points this hand', style: TextStyle(color: Colors.white70)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, card) in cards.indexed)
                      Entrance(delay: Duration(milliseconds: 120 * (delayOffset + i)), child: card),
                  ],
                ),
        ),
      ],
    );
  }

  /// Counts up from the score before this hand to the current one.
  Widget _total(String label, String pair, Color color) {
    final total = data['${pair}Score'] as int? ?? 0;
    final gained = (data['${pair}ScoreData'] as Map?)?['total'] as int? ?? 0;
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: total - gained, end: total),
          duration: const Duration(milliseconds: 1200),
          curve: Motion.enter,
          builder: (context, value, _) => Text('$value', style: displayStyle(56, color: color)),
        ),
        Text(label.toUpperCase(), style: displayStyle(12, color: Colors.white70).copyWith(letterSpacing: 1.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final opponents = otherPair(pair);
    final matchOver = data['status'] == 'matchOver';
    final won = data['winnerPair'] == pair;
    final ourCards = buildScoreWidgets(data['${pair}ScoreData'] as Map? ?? {}).length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Entrance(
              child: Text(
                matchOver ? (won ? 'You won the match!' : 'You lost the match') : 'Hand over',
                style: displayStyle(44, color: matchOver && won ? AppColors.accent : Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 28,
              children: [
                _total('You', pair, AppColors.accent),
                Text('·', style: displayStyle(40, color: Colors.white54)),
                _total('Them', opponents, Colors.white),
              ],
            ),
            const SizedBox(height: 4),
            Text('First to ${data['targetScore'] ?? 21}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            _pairRow('Your team', pair, 0),
            _pairRow('Opponents', opponents, ourCards),
            const SizedBox(height: 12),
            isHost
                ? FilledButton.icon(
                    onPressed: busy ? null : onContinue,
                    icon: busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Icon(matchOver ? Icons.replay_rounded : Icons.play_arrow_rounded),
                    label: Text(matchOver ? 'New match' : 'Next hand'),
                  )
                : GlassPill(
                    child: Text(
                      matchOver ? 'Waiting for the host to start a new match' : 'Waiting for the host to deal',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
