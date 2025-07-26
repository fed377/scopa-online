import 'dart:developer' as dev;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scopa/firebase_options.dart';
import 'package:scopa/user_state.dart';

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
    final String? res = await showTextInputDialog(context, 'Input Game Code');
    if (res == null || res.trim() == ' ') {
      showSnackBar(context, "Invalid Code");
      return;
    }
    dev.log(await joinGameWithCode(res) ?? 'all good');
  }

  Future<String?> showTextInputDialog(BuildContext context, String title) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
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
    var ref = await FirebaseFirestore.instance.collection('games').add({
      'players': [uid],
      'hands': {},
      'turn': 0,
      'status': 'waiting',
      'firstPairScore': 0,
      'secondPairScore': 0,
      'round': 0,
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
    //TODO: Count score
    await game.update({'status': 'finished'});
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

  Widget buildFinishedMenu() => ElevatedButton(
      onPressed: () async {
        await game.update({'round': FieldValue.increment(1)});
        startGame();
      },
      child: Text('Restart game'));

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

  String getCardFileName(String card) {
    return '${int.parse(card[1])}_of_${getSeed(int.parse(card[0]))}.png';
  }

  Widget buildPlayingMenu() {
    return Stack(
      children: [
        Align(alignment: Alignment.bottomCenter, child: buildHand()),
        Align(alignment: Alignment.center, child: buildBoard()),
        Align(alignment: Alignment.center, child: buildOpponentHands()),
        Align(alignment: Alignment.bottomRight, child: buildScoreBoard()),
      ],
    );
  }

  Widget buildScoreBoard() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Cards'), Text(userState.cardsGained.toString())],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Scope'), Text(userState.scope.toString())],
            )
          ],
        ),
      ),
    );
  }

  Widget buildHandCard(String num, {double size = 100}) {
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

  Future<String?> joinGameWithCode(String code) async {
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
      'players': FieldValue.arrayUnion([uid])
    });

    gameDoc.snapshots().listen(listener);

    userState.currGame = gameDoc;
    userState.turnKey = players.length;
    userState.dealer = false;
    userState.pair = userState.turnKey % 2 == 0 ? 'secondPair' : 'firstPair';
    setState(() {
      userState.status = 'waiting';
    });

    return null;
  }

  void checkGameOver(List<dynamic> board) {
    //TODO: Implement by checking total length of taken cards (including scope)
  }

  Widget buildOpponentHands() {
    return StreamBuilder<DocumentSnapshot>(
      stream: game.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hands = data['hands'] as Map<String, dynamic>;
        int x = 1;
        String nextPlayerId = data['players'][(userState.turnKey + x) % 4];
        List<dynamic> nextPlayerHand = hands[nextPlayerId];

        void incrementId() {
          x += 1;
          nextPlayerId = data['players'][(userState.turnKey + x) % 4];
          nextPlayerHand = hands[nextPlayerId];
        }

        final int left = nextPlayerHand.length;
        incrementId();
        final top = nextPlayerHand.length;
        incrementId();
        final right = nextPlayerHand.length;

        Widget c(int l, int t, AlignmentGeometry a) => Align(
              alignment: a,
              child: Flex(
                direction: t % 2 == 0 ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(l, (n) => buildBackCard(t)),
              ),
            );

        return Stack(
          children: [
            c(left, 1, Alignment.centerLeft),
            c(top, 2, Alignment.topCenter),
            c(right, 3, Alignment.centerRight),
          ],
        );
      },
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
              children: myHand.map(buildHandCard).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildBoard() {
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
        children: [
          ElevatedButton(onPressed: joinGame, child: Text("Join Game")),
          ElevatedButton(onPressed: newGame, child: Text("New Game")),
        ],
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
