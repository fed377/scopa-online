import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/utils.dart';

/// Seats filled by host-controlled bots when running with `--dart-define=TESTING=true`.
const botIds = ['bot1', 'bot2', 'bot3'];

/// Statuses in which a player can resume a game after reloading the page.
const activeStatuses = ['waiting', 'playing', 'finished', 'matchOver'];

const targetScore = 21;

class GameException implements Exception {
  const GameException(this.message);
  final String message;
}

/// All Firestore reads and writes for a game. Hands live in
/// `games/{id}/hands/{uid}` so only their owner can read them; the game doc
/// only exposes `handCounts`.
class GameService {
  GameService(this.uid);

  final String uid;
  final _db = FirebaseFirestore.instance;

  CollectionReference<DynaMap> get _games => _db.collection('games');

  DocumentReference<DynaMap> gameRef(String id) => _games.doc(id);

  static Timestamp _expiry() => Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)));

  Future<DocumentReference<DynaMap>> createGame({
    required bool private,
    required String nickname,
    required String image,
    bool withBots = false,
  }) {
    return _games.add({
      'players': [uid, if (withBots) ...botIds],
      'nicknames': {
        uid: nickname,
        if (withBots)
          for (final (i, bot) in botIds.indexed) bot: 'Bot ${i + 1}'
      },
      'images': {
        uid: image,
        if (withBots)
          for (final bot in botIds) bot: ''
      },
      'privacy': private ? 'private' : 'public',
      'status': 'waiting',
      'turn': 0,
      'round': 0,
      'targetScore': targetScore,
      'firstPairScore': 0,
      'secondPairScore': 0,
      'board': [],
      'handCounts': {},
      'disappearingCards': [],
      'pending': null,
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': _expiry(),
    });
  }

  Future<String?> joinGame(String code, {required String nickname, required String image}) async {
    if (!RegExp(r'^[A-Za-z0-9]{1,64}$').hasMatch(code)) return 'Invalid game code.';
    final ref = _games.doc(code);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) throw const GameException('No game found with that code.');
        final players = List<String>.from(data['players']);
        if (players.contains(uid)) return;
        if (data['status'] != 'waiting') throw const GameException('This game has already started.');
        if (players.length >= 4) throw const GameException('Game is full.');
        tx.update(ref, {
          'players': [...players, uid],
          'nicknames.$uid': nickname,
          'images.$uid': image,
        });
      });
    } on GameException catch (e) {
      return e.message;
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not join game.';
    }
    return null;
  }

  Future<DocumentReference<DynaMap>?> findActiveGame() async {
    final query =
        await _games.where('players', arrayContains: uid).where('status', whereIn: activeStatuses).limit(1).get();
    return query.docs.isEmpty ? null : query.docs.first.reference;
  }

  /// Host only. Deals a fresh hand; [newMatch] also resets the match score.
  Future<void> deal(DocumentReference<DynaMap> game, {bool nextRound = false, bool newMatch = false}) async {
    final data = (await game.get()).data()!;
    final players = List<String>.from(data['players']);
    if (players.length != 4) throw const GameException('Not enough players.');

    final deck = newDeck()..shuffle(Random.secure());
    final batch = _db.batch();
    for (final (i, player) in players.indexed) {
      batch.set(game.collection('hands').doc(player), {
        'cards': deck.sublist(i * 10, i * 10 + 10),
        'expireAt': _expiry(),
      });
    }
    batch.update(game, {
      'status': 'playing',
      'turn': 0,
      if (nextRound || newMatch) 'round': FieldValue.increment(1),
      if (newMatch) ...{'firstPairScore': 0, 'secondPairScore': 0, 'winnerPair': null},
      'handCounts': {for (final p in players) p: 10},
      'board': [],
      'disappearingCards': [],
      'pending': null,
      'lastTakerPair': null,
      for (final pair in [firstPair, secondPair]) ...{
        '${pair}Cards': [],
        '${pair}Scope': 0,
        '${pair}ScopeCards': [],
      },
      'expireAt': _expiry(),
    });
    await batch.commit();
  }

  /// First half of a play: moves [card] from [player]'s hand to the board and
  /// locks the turn until [resolvePlay] runs. Returns an error message on failure.
  Future<String?> playCard(DocumentReference<DynaMap> game, String player, String card, List<String> captured) async {
    final handRef = game.collection('hands').doc(player);
    try {
      await _db.runTransaction((tx) async {
        final data = (await tx.get(game)).data()!;
        final hand = List<String>.from((await tx.get(handRef)).data()?['cards'] ?? []);
        final seat = (data['players'] as List).indexOf(player);
        if (data['status'] != 'playing' || data['pending'] != null || seatToPlay(data['turn'], data['round']) != seat) {
          throw const GameException('Not your turn.');
        }
        if (!hand.contains(card)) throw const GameException('That card is not in your hand.');

        final options = captureOptions(List<String>.from(data['board']), card);
        final legal = options.isEmpty ? captured.isEmpty : options.any((o) => sameCards(o, captured));
        if (!legal) throw const GameException('That capture is not allowed.');

        tx.update(handRef, {
          'cards': FieldValue.arrayRemove([card])
        });
        tx.update(game, {
          'handCounts.$player': FieldValue.increment(-1),
          'board': FieldValue.arrayUnion([card]),
          'disappearingCards': [],
          'pending': {
            'player': player,
            'pair': pairForSeat(seat),
            'card': card,
            'captured': captured,
            'sweep': cardValue(card) == 1 && aceTakesAll,
          },
        });
      });
    } on GameException catch (e) {
      return e.message;
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not play card.';
    }
    return null;
  }

  /// Starts the animation of the captured cards flying to their pile.
  Future<void> showCapture(DocumentReference<DynaMap> game, List<String> cards) =>
      game.update({'disappearingCards': cards});

  /// Second half of a play: applies the pending capture, advances the turn and
  /// scores the hand when it was the last card. Safe to call from any client
  /// and more than once: it does nothing unless [card] is still pending.
  Future<void> resolvePlay(DocumentReference<DynaMap> game, String card) {
    return _db.runTransaction((tx) async {
      final data = (await tx.get(game)).data()!;
      final pending = data['pending'] as Map<String, dynamic>?;
      if (pending == null || pending['card'] != card) return;

      final pair = pending['pair'] as String;
      final captured = List<String>.from(pending['captured']);
      final board = List<String>.from(data['board']);
      final piles = {
        for (final p in [firstPair, secondPair]) p: List<String>.from(data['${p}Cards'] ?? [])
      };
      final scope = {
        for (final p in [firstPair, secondPair]) p: data['${p}Scope'] as int? ?? 0
      };
      final handOver = (data['handCounts'] as Map).values.every((n) => n == 0);
      var lastTaker = data['lastTakerPair'] as String?;

      final updates = <String, dynamic>{
        'pending': null,
        'disappearingCards': [],
        'turn': ((data['turn'] as int) + 1) % 4,
      };

      if (captured.isNotEmpty) {
        final taken = [...captured, card];
        board.removeWhere(taken.contains);
        piles[pair]!.addAll(taken);
        lastTaker = pair;
        updates['lastTakerPair'] = pair;
        // No scopa for an Ace sweep or for the last card of the hand.
        if (board.isEmpty && pending['sweep'] != true && !handOver) {
          scope[pair] = scope[pair]! + 1;
          updates['${pair}Scope'] = scope[pair];
          updates['${pair}ScopeCards'] = FieldValue.arrayUnion([card]);
        }
      }

      if (handOver) {
        // Cards left on the table go to whoever captured last.
        if (lastTaker != null) piles[lastTaker]!.addAll(board);
        board.clear();
        final (first, second) = scoreHand(piles[firstPair]!, piles[secondPair]!, scope[firstPair]!, scope[secondPair]!);
        final firstTotal = (data['firstPairScore'] as int) + first.total;
        final secondTotal = (data['secondPairScore'] as int) + second.total;
        final target = data['targetScore'] as int? ?? targetScore;
        final matchOver = max(firstTotal, secondTotal) >= target && firstTotal != secondTotal;
        updates.addAll({
          'firstPairScore': firstTotal,
          'secondPairScore': secondTotal,
          'firstPairScoreData': first.toMap(),
          'secondPairScoreData': second.toMap(),
          'status': matchOver ? 'matchOver' : 'finished',
          if (matchOver) 'winnerPair': firstTotal > secondTotal ? firstPair : secondPair,
        });
      }

      updates['board'] = board;
      for (final p in [firstPair, secondPair]) {
        updates['${p}Cards'] = piles[p];
      }
      tx.update(game, updates);
    });
  }

  /// Leaving an open lobby frees the seat; leaving a game in progress ends it
  /// for everyone.
  Future<void> leave(DocumentReference<DynaMap> game) {
    return _db.runTransaction((tx) async {
      final data = (await tx.get(game)).data();
      if (data == null) return;
      final players = List<String>.from(data['players']);
      if (!players.contains(uid)) return;
      final status = data['status'];
      final removeSelf = {
        'players': FieldValue.arrayRemove([uid])
      };
      if (status == 'waiting' && players.first != uid) {
        tx.update(game, {...removeSelf, 'nicknames.$uid': FieldValue.delete(), 'images.$uid': FieldValue.delete()});
      } else if (status == 'matchOver' || status == 'abandoned') {
        tx.update(game, removeSelf);
      } else {
        tx.update(game, {...removeSelf, 'status': 'abandoned', 'expireAt': _expiry()});
      }
    });
  }

  /// Adds this player's result to their own leaderboard entry, once per match.
  Future<void> recordMatch({
    required String matchId,
    required String name,
    required int points,
    required bool won,
  }) {
    final ref = _db.collection('leaderboard').doc(uid);
    return _db.runTransaction((tx) async {
      final old = (await tx.get(ref)).data() ?? {};
      if (old['lastGameId'] == matchId) return;
      tx.set(ref, {
        'name': name,
        'totalPoints': (old['totalPoints'] as int? ?? 0) + points,
        'gamesPlayed': (old['gamesPlayed'] as int? ?? 0) + 1,
        'wins': (old['wins'] as int? ?? 0) + (won ? 1 : 0),
        'lastGameId': matchId,
      });
    });
  }

  /// The top 10 players and this player's rank (null if they have no entry).
  Future<(List<DynaMap>, int?)> leaderboard() async {
    final leaderboard = _db.collection('leaderboard');
    final top = await leaderboard.orderBy('totalPoints', descending: true).limit(10).get();
    final mine = (await leaderboard.doc(uid).get()).data();
    int? rank;
    if (mine != null) {
      final ahead = await leaderboard.where('totalPoints', isGreaterThan: mine['totalPoints']).count().get();
      rank = (ahead.count ?? 0) + 1;
    }
    return (top.docs.map((d) => {...d.data(), 'id': d.id}).toList(), rank);
  }

  Future<List<String>> botHand(DocumentReference<DynaMap> game, String bot) async =>
      List<String>.from((await game.collection('hands').doc(bot).get()).data()?['cards'] ?? []);
}
