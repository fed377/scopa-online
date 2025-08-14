import 'dart:async';
import 'dart:developer' as dev;
import 'dart:js_interop';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scopa/finished_menu.dart';
import 'package:scopa/firebase_options.dart';
import 'package:scopa/playing_menu.dart';
import 'package:scopa/sign_in_menu.dart';
import 'package:scopa/start_menu.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/waiting_menu.dart';
import 'package:web/web.dart' as web;

const testing = !kReleaseMode; // Set to true for testing purposes, false in production

/// Possible Status:
/// Empty     - No players, this status only shows in UserState class, NOT IN FIRESTORE
/// Waiting   - not enough players joined yet, or admin hasn't started game yet
/// Dealing   - cards are being dealt by the dealer
/// Playing   - hands are being played, turn shown by turn variable
/// Counting  - dealer is counting score
/// Finished  - game is done, scores are being shown
/// Uneven turnkey means firstpair

typedef DynaMap = Map<String, dynamic>;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scopa',
      routes: {'main': (context) => MyHomePage()},
      initialRoute: 'main',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> signIn() async {
    try {
      if (kIsWeb) {
        // Use signInWithPopup for web
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        var user = userCredential.user!;
        userState.uid = user.uid;
        userState.nickname = user.displayName ?? userCredential.user!.uid;
        userState.imgUrl = user.photoURL ?? '';
        setState(() {});
        if (testing) startTestGame(null);
      }
    } catch (e) {
      showSnackBar(context, "Sign-in failed: $e");
    }
  }

  void initialize() async {
    userState = UserState(false, 'empty');
  }

  @override
  void initState() {
    super.initState();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        userState.uid = user.uid;
        userState.nickname = user.displayName ?? 'user-${user.uid.substring(0, 5)}';
        userState.imgUrl = user.photoURL ?? '';
        setState(() {});
      } else {
        userState.uid = 'null';
        setState(() {});
      }
    });

    web.window.onbeforeunload = (web.Event event) {
      if (userState.status != 'finished' && userState.status != 'empty') {
        if (event.isA<web.BeforeUnloadEvent>()) {}
        userState.status = 'abandoned';
        userState.currGame.update({
          'status': 'abandoned',
          'players': FieldValue.arrayRemove([userState.uid]),
        });
      }
    }.toJS;
    initialize();
    super.initState();
  }

  //Getters
  String get uid => userState.uid;
  DocumentReference<DynaMap> get game => userState.currGame;
  Future<DynaMap> get hands async => (await game.get()).data()?['hands'];
  Future<List<dynamic>> get board async => (await game.get()).data()?['board'];
  Future<List<String>> get myHand async => (await hands)[uid];
  Future<List<dynamic>> get players async => await (await game.get()).data()?['players'];

  set status(String s) => game.update({'status': s});

  late UserState userState;
  Duration cardAnimDuration = Durations.long4;
  StreamSubscription? streamSub;

  bool first = false;
  bool scoreHover = false;
  final double cardSize = 50;

  final List<String> deck = [
    for (int s = 1; s <= 4; s++)
      for (int v in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]) '$s$v'
  ];
  List<String> disappearingCards = [];
  Map<String, bool> hovering = {};

  Future<String?> showTextInputDialog(BuildContext context, String title, bool cancel) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      barrierDismissible: cancel,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            maxLength: 20,
            controller: controller,
            decoration: InputDecoration(hintText: "Enter text here"),
            autofocus: true,
          ),
          actions: [
            if (cancel)
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // cancel
                child: Text("Cancel"),
              ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim() == '') return;
                Navigator.of(context).pop(controller.text); // return input
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void pushNewPage() {
    Widget page;
    switch (userState.status) {
      case 'empty':
        page = userState.uid == 'null'
            ? SignInMenu(signIn: signIn)
            : StartMenu(
                joinGame: joinGame,
                newGame: newGame,
                showLeaderboard: showLeaderboard,
              );
        break;
      case 'waiting':
        page = WaitingMenu(
          userState: userState,
          gameId: game.id,
          startGame: startGame,
        );
        break;
      case 'dealing':
        page = Center(child: CircularProgressIndicator());
        break;
      case 'playing':
        page = PlayingMenu(
          game: game,
          userState: userState,
          snapshot: game.snapshots(),
          cardSize: cardSize,
          playCard: playCard,
          cardAnimDuration: cardAnimDuration,
        );
        break;
      case 'abandoned':
        page = Center(child: Text('Game abandoned by a player'));
        break;
      case 'counting':
        page = Center(child: Text('Score is being counted'));
        break;
      case 'finished':
        page = FinishedMenu(
          game.snapshots(),
          userState.pair,
          userState.oppositePair,
          restartGame,
          userState.dealer,
        );
        break;
      default:
        page = Text('Unexpected game status: ${userState.status}');
    }
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => Scaffold(
        body: Stack(
          children: [
            if (userState.status != 'empty')
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(onPressed: leaveGame, child: Text('Exit Game')),
                ),
              ),
            buildBG(),
            page,
          ],
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + blur transition
        final blur = 10 * (1 - animation.value);
        return FadeTransition(
          opacity: animation,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 400),
    ));
  }

  void listener(DocumentSnapshot<DynaMap> a) async {
    String status = a.get('status') as String;
    int turn = a.get('turn') as int;
    setState(() {
      if (userState.status != status) {
        userState.status = status;
        pushNewPage();
      }
      userState.turn = turn;
      userState.round = a.get('round');
      userState.users = a.get('players');
      try {
        userState.cardsGained = (a.get('${userState.pair}Cards') as List<dynamic>).length;
        userState.scope = a.get('${userState.pair}Scope');
      } catch (e) {
        userState.cardsGained = 0;
        userState.scope = 0;
      }
    });

    var hnds = await hands;
    if (hnds.values.every((e) => e.isEmpty) && a.get('status') == 'playing' && a.get('players').length == 4) {
      var brd = await board;

      await game.update({'status': 'counting', 'firstPairCards': FieldValue.arrayUnion(brd)});
      if (userState.dealer) countScores();
    }
  }

  SizedBox buildBG() {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 52, 199, 89), Color.fromARGB(255, 25, 97, 43)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    streamSub?.cancel();
    super.dispose();
  }

  void requestJoinCode() async {
    final String? res = await showTextInputDialog(context, 'Input Game Code', true);

    if (res == null || res.trim() == ' ') {
      showSnackBar(context, "Invalid Code");
      return;
    }

    final String? result = await joinGameWithCode(res.trim(), userState.nickname);
    if (result != null) {
      showSnackBar(context, result);
    } else {
      showSnackBar(context, "Joined game successfully!");
    }
  }

  void joinGame() async {
    String? res = await showDialog<String>(
      barrierDismissible: true,
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Join Game"),
        content: SizedBox(
          height: 400,
          width: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .where('status', isEqualTo: 'waiting')
                .where('privacy', isEqualTo: 'public')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text('No open games');
              }
              return ListView(
                children: docs.map<Widget>((doc) {
                  final nicknames = (doc['nicknames'] as Map).values.join(', ');
                  return ListTile(
                    title: Text(doc.id),
                    subtitle: Text(nicknames),
                    onTap: () => Navigator.of(context).pop(doc.id),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          FilledButton(onPressed: requestJoinCode, child: Text("Type Code")),
          TextButton(onPressed: Navigator.of(context).pop, child: Text("Exit")),
        ],
      ),
    );

    if (res == null || res.trim() == '') {
      return;
    }

    dev.log(await joinGameWithCode(res.trim(), userState.nickname) ?? 'Join game successfully!');
  }

  Future<void> newGame(bool private) async {
    var ref = await FirebaseFirestore.instance.collection('games').add({
      'players': [
        uid,
        if (testing) ...['1', '2', '3']
      ],
      'hands': {},
      'turn': 0,
      'status': 'waiting',
      'firstPairScore': 0,
      'secondPairScore': 0,
      'round': 0,
      'nicknames': {
        uid: userState.nickname,
        if (testing) ...{'1': 'one', '2': 'two', '3': 'three'}
      },
      'images': {
        uid: userState.imgUrl,
        if (testing) ...{'1': ' ', '2': ' ', '3': ' '}
      }
    });
    userState.currGame = ref;
    userState.dealer = true;
    userState.turnKey = 0;
    userState.pair = 'secondPair';
    ref.snapshots().listen(listener);
    userState.status = 'waiting';
    pushNewPage();
  }

  void startGame() async {
    var playerList = await players;
    if (playerList.length != 4) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Not enough players");
      return;
    }

    status = 'dealing';
    await dealCards();
    status = 'playing';
    pushNewPage();
  }

  Future<String?> joinGameWithCode(String code, String nickname) async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore.collection('games').doc(code).get();

    if (!query.exists) {
      return 'No game found with that code.';
    }

    final gameDoc = query.reference;
    final gameData = query.data();

    List<dynamic> players = gameData!['players'] ?? [];

    if (players.length >= 4) {
      return 'Game is full.';
    }

    if (players.contains(uid)) {
      return 'You are already in the game.';
    }

    await gameDoc.update({
      'players': FieldValue.arrayUnion([uid]),
      'nicknames.$uid': nickname,
      'images.$uid': userState.imgUrl,
    });

    streamSub?.cancel();
    streamSub = gameDoc.snapshots().listen(listener);

    userState.currGame = gameDoc;
    userState.turnKey = players.length;
    userState.dealer = false;
    userState.pair = userState.turnKey % 2 == 0 ? 'secondPair' : 'firstPair';
    setState(() => userState.status = 'waiting');
    pushNewPage();

    return null;
  }

  void restartGame() async {
    await game.update({'round': FieldValue.increment(1)});
    startGame();
  }

  void leaveGame() async {
    if (userState.status != 'empty') {
      try {
        await userState.currGame.update({
          'players': FieldValue.arrayRemove([userState.uid]),
          'status': 'abandoned',
        });
      } catch (e) {
        showSnackBar(context, "Error leaving game: $e");
      }
    }
    setState(() {
      userState = UserState(false, 'empty');
      first = false;
    });

    pushNewPage();
  }

  void nextTurn() async => await game.update({'turn': ((await game.get()).data()!['turn'] + 1) % 4});

  void checkScopa(String cardPlayed) async {
    final cards = await board;
    if (cards.isEmpty) {
      await game.update({
        '${userState.pair}Scope': FieldValue.increment(1),
        '${userState.pair}ScopeCards': FieldValue.arrayUnion([cardPlayed]),
      });
    }
  }

  void playCard(String card) async {
    if (userState.turn != userState.playKey) return;

    if (!testing) nextTurn();

    String cardNumber = card[1];
    List cards = await board;

    //Remove card from hand regardless
    await game.update({
      'hands.$uid': FieldValue.arrayRemove([card]),
      'board': FieldValue.arrayUnion([card]),
      'disappearingCards': [],
    });

    await Future.delayed(Durations.extralong4);

    //Ace
    if (cardNumber == '1') {
      await game.update({
        'disappearingCards': [...cards, card]
      });
      Future.delayed(cardAnimDuration, () async {
        await game.update({
          'board': FieldValue.arrayRemove([...cards, card]),
          '${userState.pair}Cards': FieldValue.arrayUnion([...cards, card]),
          'disappearingCards': [],
        });
      });

      return;
    }

    //Normal Take
    for (var c in cards) {
      if ((c as String)[1] == cardNumber) {
        await game.update({
          'disappearingCards': [c, card]
        });
        Future.delayed(cardAnimDuration, () async {
          await game.update({
            'board': FieldValue.arrayRemove([c, card]),
            '${userState.pair}Cards': FieldValue.arrayUnion([c, card]),
            'disappearingCards': [],
          });
          checkScopa(card);
        });
        return;
      }
    }

    //Sum Take
    for (var c in cards) {
      int num = int.parse((c as String)[1]);
      int target = int.parse(cardNumber);
      if (num < target - 1) {
        int diff = target - num;
        for (var x in cards) {
          if ((x as String)[1] == diff.toString() && x != c && x != card) {
            await game.update({
              'disappearingCards': [x, c, card]
            });
            Future.delayed(cardAnimDuration, () async {
              await game.update({
                'board': FieldValue.arrayRemove([x, c, card]),
                '${userState.pair}Cards': FieldValue.arrayUnion([x, c, card]),
                'disappearingCards': [],
              });
              checkScopa(card);
            });
            return;
          }
        }
      }
    }
  }

  void countScores() async {
    var snapshot = await game.get();
    var data = snapshot.data();
    List<dynamic> fCards = data!['firstPairCards'];
    List<dynamic> sCards = data['secondPairCards'];
    int fDiamonds = fCards.where((a) => a.toString()[0] == '2').toList().length;
    int sDiamonds = sCards.where((a) => a.toString()[0] == '2').toList().length;
    int fScope = data['firstPairScope'];
    int sScope = data['secondPairScope'];

    int fScore = 0;
    int sScore = 0;

    if (fCards.length > sCards.length) {
      fScore += 1;
    } else if (sCards.length > fCards.length) {
      sScore += 1;
    }

    if (fDiamonds > sDiamonds) {
      fScore += 1;
    } else if (fDiamonds < sDiamonds) {
      sScore += 1;
    }

    fScore += fScope;
    sScore += sScope;

    if (fCards.contains('27')) {
      fScore += 1;
    } else {
      sScore += 1;
    }

    int fNapula = 0;

    int sNapula = 0;

    if (fCards.contains(21) && fCards.contains(22) && fCards.contains(23)) {
      int score = 3;
      while (score < 10) {
        if (fCards.contains('${score + 20}')) {
          score += 1;
        } else {
          break;
        }
      }
      if (score == 10) {
        if (fCards.contains('20')) score += 1;
      }
      fScore += score;
      fNapula = score;
    } else if (sCards.contains(21) && sCards.contains(22) && sCards.contains(23)) {
      int score = 3;
      while (score < 10) {
        if (sCards.contains(score + 20)) {
          score += 1;
        } else {
          break;
        }
      }
      if (score == 10) {
        if (sCards.contains(20)) score += 1;
      }
      sScore += score;
      sNapula = score;
    }

    int fPrimiera = countPrimieraPoints(fCards);
    int sPrimiera = countPrimieraPoints(sCards);

    if (fPrimiera > sPrimiera) {
      fScore += 1;
    } else if (fPrimiera < sPrimiera) {
      sScore += 1;
    }

    await game.update({
      'status': 'finished',
      'firstPairScore': FieldValue.increment(fScore),
      'firstPairScoreData': {
        'primiera': fPrimiera > sPrimiera,
        'setteBello': fCards.contains('27'),
        'scope': fScope,
        'cards': fCards.length > sCards.length,
        'diamonds': fDiamonds > sDiamonds,
        'napula': fNapula,
      },
      'secondPairScoreData': {
        'primiera': sPrimiera > fPrimiera,
        'setteBello': sCards.contains('27'),
        'scope': sScope,
        'cards': sCards.length > fCards.length,
        'diamonds': sDiamonds > fDiamonds,
        'napula': sNapula,
      },
      'secondPairScore': FieldValue.increment(sScore),
    });

    final ppl = await players;

    incrementScore(data['nicknames'][ppl[0]], ppl[0], fScore);
    incrementScore(data['nicknames'][ppl[1]], ppl[1], sScore);
    incrementScore(data['nicknames'][ppl[2]], ppl[2], fScore);
    incrementScore(data['nicknames'][ppl[3]], ppl[3], sScore);
  }

  void incrementScore(String name, String id, int score) async {
    final doc = FirebaseFirestore.instance.collection('leaderboard').doc(id);
    final data = await doc.get();
    if (data.exists) {
      await doc.update({
        'totalPoints': FieldValue.increment(score),
        'gamesPlayed': FieldValue.increment(1),
      });
    } else {
      await doc.set({
        'totalPoints': score,
        'name': name,
        'gamesPlayed': 1,
      });
    }
  }

  void showLeaderboard() async {
    var scores = await FirebaseFirestore.instance.collection('leaderboard').orderBy('totalPoints').limit(10).get();
    var data = scores.docs;
    if (data.isEmpty) {
      showSnackBar(context, "No scores available.");
      return;
    }

    var entries = data
        .map((doc) => {
              'score': doc.data()['totalPoints'],
              'name': doc.data()['name'],
              'id': doc.id,
              'gamesPlayed': doc.data()['gamesPlayed'] ?? 0,
            })
        .toList();

    List<Widget> scoreWidgets = entries.map<Widget>((entry) {
      return ListTile(
        title: Text(entry['id'].split('-')[0]),
        trailing: Text(entry['score'].toString()),
        subtitle: Text('Games Played: ${entry['gamesPlayed']}'),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Leaderboard"),
          content: SizedBox(
            width: 350,
            height: 400,
            child: Column(
              children: [
                Text(
                    'You are at: ${entries.indexWhere((e) => e['id'] == '${userState.nickname}-${userState.uid}') + 1}'),
                const SizedBox(height: 12),
                Expanded(
                  child: scoreWidgets.isEmpty
                      ? Center(child: Text("No users\non leaderboard"))
                      : ListView(children: scoreWidgets),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  int checkPrimieraSeed(List<dynamic> cards, int seed) {
    cards = cards.where((a) => a.toString()[0] == seed.toString()).toList();
    if (cards.isEmpty) {
      return 0;
    } else {
      cards = cards.map(getPrimieraPoints).toList();
      cards.sort();
      return cards.last;
    }
  }

  int countPrimieraPoints(List<dynamic> cards) {
    return [1, 2, 3, 4].fold(0, (value, element) => value + checkPrimieraSeed(cards, element));
  }

  Future<void> dealCards() async {
    List<String> cards = generateShuffledDeck();
    var ppl = await players;
    await game.update(
      {
        'hands': {
          ppl[0]: cards.sublist(0, 10),
          ppl[1]: cards.sublist(10, 20),
          ppl[2]: cards.sublist(20, 30),
          ppl[3]: cards.sublist(30)
        },
        'status': 'playing',
        'firstPairCards': [],
        'firstPairScope': 0,
        'firstPairScopeCards': [],
        'secondPairCards': [],
        'secondPairScope': 0,
        'secondPairScopeCards': [],
        'board': [],
        'disappearingCards': [],
      },
    );
  }

  List<String> generateShuffledDeck() {
    List<String> ret = List.from(deck);
    ret.shuffle(Random.secure());
    return ret;
  }

  Random rand = Random();

  List<Color> blobColors = [
    Colors.deepPurple.shade900,
    const Color.fromARGB(255, 0, 41, 190),
    const Color.fromARGB(255, 94, 0, 172)
  ];

  Widget buildPlayingMenu(UserState userState, Stream<DocumentSnapshot<Map<String, dynamic>>> snapshot, double cardSize,
      void Function(String) playCard, Duration cardAnimDuration) {
    return PlayingMenu(
        game: game,
        userState: userState,
        snapshot: snapshot,
        cardSize: cardSize,
        playCard: playCard,
        cardAnimDuration: cardAnimDuration);
  }

  void startTestGame(_) async {
    if (!first) {
      first = true;
      if (testing) {
        return;
        await newGame(false);
        startGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    if (isPortrait) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please rotate your device to landscape mode for the best experience.',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
        body: Stack(
      children: [
        buildBG(),
        userState.uid == 'null'
            ? SignInMenu(signIn: signIn)
            : StartMenu(joinGame: joinGame, newGame: newGame, showLeaderboard: showLeaderboard),
      ],
    ));
  }
}
