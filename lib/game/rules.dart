import 'dart:math';

// Cards are 2-char strings `"<suit><value>"`: suit 1-4 (hearts, diamonds,
// clubs, spades), value '1'-'9' and '0' (King = 10). Diamonds are suit 2.

/// House rule: an Ace captures the whole board ("asso piglia tutto").
const aceTakesAll = true;

const firstPair = 'firstPair';
const secondPair = 'secondPair';

int cardValue(String card) => card[1] == '0' ? 10 : int.parse(card[1]);

int cardSuit(String card) => int.parse(card[0]);

/// Odd seats play together as the first pair.
String pairForSeat(int seat) => seat.isOdd ? firstPair : secondPair;

String otherPair(String pair) => pair == firstPair ? secondPair : firstPair;

/// The starting seat rotates by one every hand.
int seatToPlay(int turn, int round) => (turn + round) % 4;

List<String> newDeck() => [
      for (var suit = 1; suit <= 4; suit++)
        for (final value in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) '$suit$value'
    ];

/// Every legal set of board cards that [card] can capture. Empty when the card
/// can only be laid on the board.
List<List<String>> captureOptions(List<String> board, String card) {
  if (board.isEmpty) return [];
  final value = cardValue(card);
  if (value == 1 && aceTakesAll) return [List.of(board)];

  // A single card of equal value must be taken in preference to a sum.
  final singles = [
    for (final c in board)
      if (cardValue(c) == value) [c]
  ];
  if (singles.isNotEmpty) return singles;

  final options = <List<String>>[];
  final picked = <String>[];
  void search(int start, int remaining) {
    for (var i = start; i < board.length; i++) {
      final v = cardValue(board[i]);
      if (v > remaining) continue;
      picked.add(board[i]);
      if (v == remaining) {
        options.add(List.of(picked));
      } else {
        search(i + 1, remaining - v);
      }
      picked.removeLast();
    }
  }

  search(0, value);
  return options;
}

bool sameCards(List<String> a, List<String> b) => a.length == b.length && a.toSet().containsAll(b);

const Map<int, int> _primieraPoints = {7: 21, 6: 18, 1: 16, 5: 15, 4: 14, 3: 13, 2: 12, 8: 10, 9: 10, 10: 10};

/// Sum of the best card in each suit, or 0 when a suit is missing.
int primiera(List<String> cards) {
  var total = 0;
  for (var suit = 1; suit <= 4; suit++) {
    final best = cards.where((c) => cardSuit(c) == suit).map((c) => _primieraPoints[cardValue(c)]!).fold(0, max);
    if (best == 0) return 0;
    total += best;
  }
  return total;
}

/// Length of the diamond run starting from the Ace, if it reaches at least 3.
int napula(List<String> cards) {
  var run = 0;
  while (run < 10 && cards.contains('2${(run + 1) % 10}')) {
    run++;
  }
  return run >= 3 ? run : 0;
}

class PairScore {
  const PairScore({
    required this.cards,
    required this.diamonds,
    required this.setteBello,
    required this.primiera,
    required this.napula,
    required this.scope,
  });

  final bool cards;
  final bool diamonds;
  final bool setteBello;
  final bool primiera;
  final int napula;
  final int scope;

  int get total => (cards ? 1 : 0) + (diamonds ? 1 : 0) + (setteBello ? 1 : 0) + (primiera ? 1 : 0) + napula + scope;

  Map<String, dynamic> toMap() => {
        'cards': cards,
        'diamonds': diamonds,
        'setteBello': setteBello,
        'primiera': primiera,
        'napula': napula,
        'scope': scope,
        'total': total,
      };
}

(PairScore, PairScore) scoreHand(List<String> first, List<String> second, int firstScope, int secondScope) {
  int diamonds(List<String> cards) => cards.where((c) => cardSuit(c) == 2).length;
  final fPrimiera = primiera(first);
  final sPrimiera = primiera(second);

  PairScore score(List<String> mine, List<String> theirs, int myPrimiera, int theirPrimiera, int scope) => PairScore(
        cards: mine.length > theirs.length,
        diamonds: diamonds(mine) > diamonds(theirs),
        setteBello: mine.contains('27'),
        primiera: myPrimiera > theirPrimiera,
        napula: napula(mine),
        scope: scope,
      );

  return (
    score(first, second, fPrimiera, sPrimiera, firstScope),
    score(second, first, sPrimiera, fPrimiera, secondScope),
  );
}
