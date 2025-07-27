import 'dart:developer' as dev;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scopa/firebase_options.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        colorScheme: ColorScheme.dark(),
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
  Future<void> signInAnonymously() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  final List<String> deck = [
    for (int suit = 1; suit <= 4; suit++)
      for (int value in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]) '$suit$value'
  ];

  late UserState userState;

  List<String> generateShuffledDeck() {
    List<String> ret = List.from(deck);
    ret.shuffle(Random.secure());
    return ret;
  }

  void initialize() async {
    userState = UserState(false, 'empty');
    await signInAnonymously();
    userState.uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }

  //Getters
  String get uid => userState.uid;
  DocumentReference<DynaMap> get game => userState.currGame;
  Future<DynaMap> get hands async => (await game.get()).data()?['hands'];
  Future<List<dynamic>> get board async => (await game.get()).data()?['board'];
  Future<List<String>> get myHand async => (await hands)[uid];
  set status(String s) => game.update({'status': s});
  Future<List<dynamic>> get players async => await (await game.get()).data()?['players'];

  void joinGame() async {
    final String? res = await showTextInputDialog(context, 'Input Game Code', true);

    if (res == null || res.trim() == ' ') {
      showSnackBar(context, "Invalid Code");
      return;
    }

    //final String? name = await showTextInputDialog(context, 'Input Nickname', false);

    dev.log(await joinGameWithCode(res.trim(), 'nickname') ?? 'all good');
  }

  Future<String?> showTextInputDialog(BuildContext context, String title, bool cancel) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      barrierDismissible: cancel,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
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
                if (controller.text == '') return;
                Navigator.of(context).pop(controller.text); // return input
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void newGame() async {
    //final String? name = await showTextInputDialog(context, 'Input Nickname', false);

    var ref = await FirebaseFirestore.instance.collection('games').add({
      'players': [uid],
      'hands': {},
      'turn': 0,
      'status': 'waiting',
      'firstPairScore': 0,
      'secondPairScore': 0,
      'round': 0,
      'nicknames': {uid: 'name'}
    });
    userState.currGame = ref;
    userState.dealer = true;
    userState.turnKey = 0;
    userState.pair = 'secondPair';
    ref.snapshots().listen(listener);
    userState.status = 'waiting';
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
  }

  void listener(DocumentSnapshot<DynaMap> a) async {
    String status = a.get('status') as String;
    int turn = a.get('turn') as int;
    setState(() {
      userState.status = status;
      userState.turn = turn;
      userState.round = a.get('round');
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
      dev.log('first got length');
    } else if (sCards.length > fCards.length) {
      sScore += 1;
      dev.log('second got length');
    }

    if (fDiamonds > sDiamonds) {
      fScore += 1;
      dev.log('first got diamonds');
    } else if (fDiamonds < sDiamonds) {
      sScore += 1;
      dev.log('second got diamonds');
    }

    dev.log('First: $fScope. Second: $sScope');

    fScore += fScope;
    sScore += sScope;

    if (fCards.contains(27)) {
      fScore += 1;
      dev.log('first got 7');
    } else {
      sScore += 1;
      dev.log('second got 7');
    }

    if (fCards.contains(21) && fCards.contains(22) && fCards.contains(23)) {
      int score = 3;
      while (score < 10) {
        if (fCards.contains(score + 20)) {
          score += 1;
        } else {
          break;
        }
      }
      if (score == 10) {
        if (fCards.contains(20)) score += 1;
      }
      fScore += score;
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
    }

    int fPrimiera = countPrimieraPoints(fCards);
    int sPrimiera = countPrimieraPoints(sCards);

    if (fPrimiera > sPrimiera) {
      fScore += 1;
      dev.log('first got primiera');
    } else if (fPrimiera < sPrimiera) {
      sScore += 1;
      dev.log('second got primiera');
    }

    await game.update({
      'status': 'finished',
      'firstPairScore': FieldValue.increment(fScore),
      'secondPairScore': FieldValue.increment(sScore),
    });
  }

  int checkPrimieraSeed(List<dynamic> cards, int seed) {
    cards = cards..removeWhere((a) => a.toString()[0] != seed.toString());
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
        'secondPairCards': [],
        'secondPairScope': 0,
        'board': []
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [const Color.fromARGB(255, 38, 86, 40), const Color.fromARGB(255, 55, 135, 58)],
                ),
              ),
            ),
          ),
          if (userState.status != 'empty') Align(alignment: Alignment.topRight, child: Text(userState.pair)),
          if (FirebaseAuth.instance.currentUser != null)
            Align(
                alignment: Alignment.topLeft,
                child: Text(FirebaseAuth.instance.currentUser?.uid ?? 'not signed in yet')),
          switch (userState.status) {
            'empty' => buildStartMenu(),
            'waiting' => buildWaitingMenu(),
            'dealing' => buildDealingMenu(),
            'playing' => buildPlayingMenu(),
            'abandoned' => Center(child: Text('Game abandoned by a player')),
            'counting' => Center(child: Text('Score is being counted')),
            'finished' => buildFinishedMenu(),
            String() => Text('Unexpected game state: ${userState.status}'),
          },
        ],
      ),
    );
  }

  Widget buildFinishedMenu() {
    return StreamBuilder<DocumentSnapshot>(
        stream: game.snapshots(),
        builder: (context, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: pad([
              Row(
                mainAxisSize: MainAxisSize.min,
                children: pad([
                  Text('Your Score: ${snapshot.data!['${userState.pair}Score']}'),
                  Text("Opponents' Score: ${snapshot.data!['${userState.oppositePair}Score']}"),
                ]),
              ),
              ElevatedButton(
                  onPressed: () async {
                    await game.update({'round': FieldValue.increment(1)});
                    startGame();
                  },
                  child: Text('Restart game')),
            ]),
          );
        });
  }

  Widget buildPlayingMenu() {
    return Stack(
      children: [
        Align(alignment: Alignment.bottomCenter, child: buildHand()),
        Align(alignment: Alignment.center, child: buildBoardCards()),
        Align(alignment: Alignment.center, child: buildOpponentHands()),
        Align(alignment: Alignment.bottomRight, child: buildScoreBoard()),
      ],
    );
  }

  List<Widget> pad(List<Widget> widgets, {double padding = 8}) {
    return widgets.map((a) => Padding(padding: EdgeInsets.all(padding), child: a)).toList();
  }

  Widget buildScoreBoard() {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: Colors.lightGreen.shade800,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: pad([
            Column(
              mainAxisSize: MainAxisSize.min,
              children: pad([Text('Cards'), Text(userState.cardsGained.toString())]),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: pad([Text('Scope'), Text(userState.scope.toString())]),
            )
          ]),
        ),
      ),
    );
  }

  Widget buildHandCard(String num, void Function(String) playCard, {double size = 100}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          height: size,
          child: GestureDetector(onTap: () => playCard(num), child: Image(image: AssetImage(getCardFileName(num))))),
    );
  }

  Widget buildBackCard(int turns) =>
      RotatedBox(quarterTurns: turns, child: SizedBox(height: 50, child: Image(image: AssetImage('assets/back.png'))));

  Widget buildBoardCard(dynamic num) {
    String n = num as String;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(height: 100, child: Image(image: AssetImage(getCardFileName(n)))),
    );
  }

  void nextTurn() async => await game.update({'turn': ((await game.get()).data()!['turn'] + 1) % 4});

  void checkScopa() async {
    final cards = await board;
    if (cards.isEmpty) {
      await game.update({'${userState.pair}Scope': FieldValue.increment(1)});
    }
  }

  void playCard(String card) async {
    if (userState.turn != userState.playKey) {
      showSnackBar(context, 'Not your turn');
      return;
    }
    String cardNumber = card[1];
    List cards = await board;

    //Remove card from hand regardless
    await game.update({
      'hands.$uid': FieldValue.arrayRemove([card])
    });

    //Ace
    if (cardNumber == '1') {
      await game.update({
        'board': FieldValue.arrayRemove(cards),
        '${userState.pair}Cards': FieldValue.arrayUnion([...cards, card]),
      });
      nextTurn();
      return;
    }

    //Normal Take
    for (var c in cards) {
      if ((c as String)[1] == cardNumber) {
        await game.update({
          'board': FieldValue.arrayRemove([c]),
          '${userState.pair}Cards': FieldValue.arrayUnion([c, card]),
        });
        checkScopa();
        nextTurn();
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
          if ((x as String)[1] == diff.toString()) {
            await game.update({
              'board': FieldValue.arrayRemove([x, c]),
              '${userState.pair}Cards': FieldValue.arrayUnion([c, card, x])
            });
            checkScopa();
            nextTurn();
            return;
          }
        }
      }
    }

    //Normal Play
    await game.update({
      'board': FieldValue.arrayUnion([card])
    });

    nextTurn();
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
    });

    gameDoc.snapshots().listen(listener);

    userState.currGame = gameDoc;
    userState.turnKey = players.length;
    userState.dealer = false;
    userState.pair = userState.turnKey % 2 == 0 ? 'secondPair' : 'firstPair';
    setState(() => userState.status = 'waiting');

    return null;
  }

  Widget buildOpponentHands() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: game.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final hands = data['hands'] as Map<String, dynamic>;
          int x = 1;
          String nextPlayerId = data['players'][(userState.turnKey + x) % 4];
          List<dynamic> nextPlayerHand = hands[nextPlayerId];
          String playerName = data['nicknames'][nextPlayerId];

          void incrementId() {
            x += 1;
            nextPlayerId = data['players'][(userState.turnKey + x) % 4];
            nextPlayerHand = hands[nextPlayerId];
            playerName = data['nicknames'][nextPlayerId];
          }

          final left = nextPlayerHand.length;
          final leftName = playerName;
          incrementId();
          final top = nextPlayerHand.length;
          final topName = playerName;
          incrementId();
          final right = nextPlayerHand.length;
          final rightName = playerName;

          Widget c(int l, int t, AlignmentGeometry a, String n) => Align(
                alignment: a,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromARGB(255, 32, 106, 0), width: 5),
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                        colors: [const Color.fromARGB(255, 39, 93, 41), const Color.fromARGB(255, 41, 109, 43)]),
                  ),
                  child: Flex(
                    mainAxisSize: MainAxisSize.min,
                    direction: t % 2 != 0 ? Axis.horizontal : Axis.vertical,
                    children: [
                      RotatedBox(quarterTurns: t, child: Text(n)),
                      Flex(
                        direction: t % 2 == 0 ? Axis.horizontal : Axis.vertical,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(l, (n) => buildBackCard(t)),
                      )
                    ],
                  ),
                ),
              );

          return Stack(
            children: pad([
              c(left, 1, Alignment.centerLeft, leftName),
              c(top, 2, Alignment.topCenter, topName),
              c(right, 3, Alignment.centerRight, rightName),
            ]),
          );
        },
      ),
    );
  }

  Widget buildHand() {
    return StreamBuilder<DocumentSnapshot>(
      stream: game.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hands = data['hands'] as Map<String, dynamic>;
        final myHand = List<String>.from(hands[userState.uid] ?? []);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: myHand.map((n) => buildHandCard(n, playCard)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildBoardCards() {
    return StreamBuilder<DocumentSnapshot>(
      stream: game.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hands = data['board'] as List<dynamic>;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: hands.map(buildBoardCard).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildDealingMenu() {
    return Center(child: CircularProgressIndicator());
  }

  Widget buildStartMenu() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: pad([
          Text(
            'Online Scopa',
            style: TextStyle(fontFamily: 'Serif', fontSize: 25),
          ),
          const SizedBox(height: 200),
          ElevatedButton(onPressed: joinGame, child: Text("Join Game")),
          ElevatedButton(onPressed: newGame, child: Text("New Game")),
        ]),
      ),
    );
  }

  Widget buildWaitingMenu() {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText('Game ID: ${game.id}'),
        userState.dealer
            ? ElevatedButton(
                onPressed: startGame,
                child: Text('Start Game'),
              )
            : Text('Waiting for admin to start game'),
      ],
    ));
  }
}
