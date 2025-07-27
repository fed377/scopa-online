String getCardFileName(String card) {
  return '${int.parse(card[1])}_of_${getSeed(int.parse(card[0]))}.png';
}

String getSeed(int n) {
  switch (n) {
    case 1:
      return "hearts";
    case 2:
      return "diamonds";
    case 3:
      return "clubs";
    default:
      return "spades";
  }
}

const Map<int, int> _scoring = {
  1: 16,
  2: 12,
  3: 13,
  4: 14,
  5: 15,
  6: 18,
  7: 21,
  8: 10,
  9: 10,
  0: 10,
};

int getPrimieraPoints(cardNum) => _scoring[cardNum] ?? 0;
