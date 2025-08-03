import 'package:cloud_firestore/cloud_firestore.dart';

class UserState {
  bool dealer;
  String status;
  late DocumentReference<Map<String, dynamic>> currGame;
  String uid = 'null';
  int turn = 0;
  late int turnKey;
  late String pair;
  get oppositePair => pair == 'firstPair' ? 'secondPair' : 'firstPair';
  int cardsGained = 0;
  int scope = 0;
  int round = 0;
  int get playKey => (turnKey - round) % 4;
  late String nickname;
  late String imgUrl;
  UserState(this.dealer, this.status);
}
