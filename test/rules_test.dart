import 'package:flutter_test/flutter_test.dart';
import 'package:scopa/game/rules.dart';

void main() {
  group('captureOptions', () {
    test('nothing to capture on an empty board', () {
      expect(captureOptions([], '15'), isEmpty);
    });

    test('a single matching card beats a sum', () {
      expect(captureOptions(['35', '12', '43'], '25'), [
        ['35']
      ]);
    });

    test('offers every single match', () {
      expect(captureOptions(['35', '45'], '25'), [
        ['35'],
        ['45']
      ]);
    });

    test('finds sums of any size', () {
      final options = captureOptions(['11', '32', '43', '24'], '17');
      expect(options.length, 2);
      expect(options.any((o) => sameCards(o, ['11', '32', '24'])), isTrue);
      expect(options.any((o) => sameCards(o, ['43', '24'])), isTrue);
    });

    test('the King counts as 10', () {
      expect(captureOptions(['37', '13'], '20'), [
        ['37', '13']
      ]);
      expect(captureOptions(['30'], '20'), [
        ['30']
      ]);
    });

    test('an Ace sweeps the board', () {
      expect(captureOptions(['37', '40'], '11'), [
        ['37', '40']
      ]);
    });

    test('no capture when nothing adds up', () {
      expect(captureOptions(['37', '40'], '25'), isEmpty);
    });
  });

  group('scoring', () {
    test('napula', () {
      expect(napula(['21', '22']), 0);
      expect(napula(['21', '22', '23']), 3);
      expect(napula(['21', '22', '23', '24', '26']), 4);
      expect(napula(['21', '22', '23', '24', '25', '26', '27', '28', '29', '20']), 10);
    });

    test('primiera needs every suit', () {
      expect(primiera(['17', '27', '37']), 0);
      expect(primiera(['17', '27', '37', '47']), 84);
      expect(primiera(['17', '11', '26', '35', '40']), 21 + 18 + 15 + 10);
    });

    test('ties on diamonds and primiera score nothing', () {
      final deck = newDeck();
      final first = [
        for (final c in deck)
          if (cardSuit(c) == 1 || cardSuit(c) == 2 && cardValue(c) <= 5) c
      ];
      final second = [
        for (final c in deck)
          if (!first.contains(c)) c
      ];
      final (f, s) = scoreHand(first, second, 0, 0);
      expect(s.cards, isTrue);
      expect(f.diamonds, isFalse);
      expect(s.diamonds, isFalse);
      expect(s.setteBello, isTrue);
      expect(f.napula, 5);
      expect(f.primiera, isFalse);
      expect(s.primiera, isFalse);
    });

    test('a 20-20 card split scores nothing', () {
      final deck = newDeck();
      final (f, s) = scoreHand(deck.sublist(0, 20), deck.sublist(20), 0, 0);
      expect(f.cards, isFalse);
      expect(s.cards, isFalse);
    });

    test('totals add up', () {
      final deck = newDeck();
      final first = [
        for (final c in deck)
          if (cardSuit(c) != 4) c
      ];
      final second = [
        for (final c in deck)
          if (cardSuit(c) == 4) c
      ];
      final (f, s) = scoreHand(first, second, 2, 1);
      expect(f.total, 1 + 1 + 1 + 0 + 10 + 2);
      expect(s.total, 1);
    });
  });
}
