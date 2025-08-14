import 'package:flutter/material.dart';


    var glassColor = Color.fromARGB(255, 0, 79, 0);

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

List<Widget> pad(List<Widget> widgets, {double padding = 8}) =>
    widgets.map((a) => Padding(padding: EdgeInsets.all(padding), child: a)).toList();

String getCardNum(String a) => switch (a) {
      '0' => 'K',
      '8' => 'J',
      '9' => 'Q',
      '1' => ' ',
      String() => a,
    };

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

String getSuitImage(String cardNum) => _seedIcons[int.parse(cardNum[0])] ?? '';

const Map<int, String> _seedIcons = {
  1: 'assets/heart_red.png',
  2: 'assets/diamond_red.png',
  3: 'assets/club_black.png',
  4: 'assets/spade_black.png',
};