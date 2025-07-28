import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/firebase_options.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';

const testing = true;

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
  bool initialized = false;

  List<String> generateShuffledDeck() {
    List<String> ret = List.from(deck);
    ret.shuffle(Random.secure());
    return ret;
  }

  void initialize() async {
    userState = UserState(false, 'empty');
    await signInAnonymously();
    userState.uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => initialized = true);
  }

  @override
  void initState() {
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

  final double cardSize = 50;

  StreamSubscription? streamSub;

  void joinGame() async {
    final String? res = await showTextInputDialog(context, 'Input Game Code', true);

    if (res == null || res.trim() == ' ') {
      showSnackBar(context, "Invalid Code");
      return;
    }

    final String? name = testing ? 'name' : await showTextInputDialog(context, 'Input Nickname', false);

    dev.log(await joinGameWithCode(res.trim(), name!) ?? 'all good');
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

  Future<void> newGame() async {
    final String? name = testing ? 'NAME' : await showTextInputDialog(context, 'Input Nickname', false);

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
        uid: name,
        if (testing) ...{'1': 'one', '2': 'two', '3': 'three'}
      }
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
    } else if (sCards.length > fCards.length) {
      sScore += 1;
    }

    if (fDiamonds > sDiamonds) {
      fScore += 1;
    } else if (fDiamonds < sDiamonds) {
      sScore += 1;
    }

    dev.log('First: $fScope. Second: $sScope');

    fScore += fScope;
    sScore += sScope;

    if (fCards.contains('27')) {
      fScore += 1;
    } else {
      sScore += 1;
    }

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

  bool first = false;

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      initialize();
      return CircularProgressIndicator();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!first) {
        first = true;
        await newGame();
        startGame();
      }
    });
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

  bool scoreHover = false;

  Widget buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.all(26.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => scoreHover = true),
        onExit: (_) => setState(() => scoreHover = false),
        child: AnimatedContainer(
          curve: Curves.easeOutQuad,
          height: scoreHover ? 120 : 100,
          width: scoreHover ? 240 : 200,
          duration: Durations.short4,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color.fromARGB(scoreHover ? 120 : 47, 255, 255, 255), blurRadius: scoreHover ? 20 : 10)
            ],
            borderRadius: BorderRadius.circular(scoreHover ? 30 : 20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: pad([Text('Cards'), Text(userState.cardsGained.toString())]),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: pad([Text('Scope'), Text(userState.scope.toString())]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, bool> hovering = {};

  Widget buildOpponentCard() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 100,
      width: 73,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          Container(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 30,
                  spreadRadius: -100,
                )
              ]),
              child: Align(
                  alignment: Alignment.center, child: Image(height: 100, image: AssetImage('assets/back_card.png')))),
        ],
      ),
    );
  }

  Widget buildHandCard(String num, void Function(String) playCard) {
    Color color = num[0] == '1' || num[0] == '2' ? Colors.red : Colors.black;
    bool hover = hovering[num] ?? false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovering[num] = true),
        onExit: (_) => setState(() => hovering[num] = false),
        child: GestureDetector(
          onTap: () => playCard(num),
          child: AnimatedContainer(
            duration: Durations.long3,
            curve: Curves.easeOutCirc,
            height: hover ? 125 : 100,
            width: hover ? 100 : 73,
            transform: Matrix4.identity()..translate(0, hover ? -cardSize : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20)],
            ),
            child: Stack(
              children: [
                Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(20),
                        blurRadius: 30,
                        spreadRadius: -100,
                      )
                    ]),
                    child: Align(
                        alignment: Alignment.center, child: Image(height: 40, image: AssetImage(getSeedImage(num))))),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
                    child: Text(
                      getCardNum(num[1]),
                      style: GoogleFonts.varelaRound(color: color, fontSize: 25, fontWeight: FontWeight.w900),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getCardNum(String a) => switch (a) {
        '0' => 'K',
        '8' => 'J',
        '9' => 'Q',
        '1' => ' ',
        String() => a,
      };

  Widget buildBackCard(int turns) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: RotatedBox(
            quarterTurns: turns, child: SizedBox(height: 50, child: Image(image: AssetImage('assets/back_card.png')))),
      );

  Widget buildBoardCard(dynamic num) {
    Color color = num[0] == '1' || num[0] == '2' ? Colors.red : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 100,
        width: 73,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20)],
        ),
        child: Stack(
          children: [
            Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 30,
                    spreadRadius: -100,
                  )
                ]),
                child:
                    Align(alignment: Alignment.center, child: Image(height: 40, image: AssetImage(getSeedImage(num))))),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
                child: Text(
                  getCardNum(num[1]),
                  style: GoogleFonts.varelaRound(color: color, fontSize: 25, fontWeight: FontWeight.w900),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void nextTurn() async => await game.update({'turn': ((await game.get()).data()!['turn'] + 1) % 4});

  void checkScopa() async {
    final cards = await board;
    if (cards.isEmpty) {
      await game.update({'${userState.pair}Scope': FieldValue.increment(1)});
    }
  }

  List<String> disappearingCards = [];
  Duration cardAnimDuration = Durations.long4;

  void playCard(String card) async {
    if (userState.turn != userState.playKey) return;

    String cardNumber = card[1];
    List cards = await board;

    //Remove card from hand regardless
    await game.update({
      'hands.$uid': FieldValue.arrayRemove([card]),
      'board': FieldValue.arrayUnion([card])
    });

    await Future.delayed(Durations.extralong4);

    //Ace
    if (cardNumber == '1') {
      setState(() => disappearingCards = [...cards, card]);
      Future.delayed(cardAnimDuration, () async {
        await game.update({
          'board': FieldValue.arrayRemove([...cards, card]),
          '${userState.pair}Cards': FieldValue.arrayUnion([...cards, card]),
        });
        if (!testing) nextTurn();
      });

      return;
    }

    //Normal Take
    for (var c in cards) {
      if ((c as String)[1] == cardNumber) {
        setState(() => disappearingCards = [c, card]);
        Future.delayed(cardAnimDuration, () async {
          await game.update({
            'board': FieldValue.arrayRemove([c, card]),
            '${userState.pair}Cards': FieldValue.arrayUnion([c, card]),
          });
          if (!testing) nextTurn();
        });
        checkScopa();
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
            setState(() => disappearingCards = [x, c, card]);
            Future.delayed(cardAnimDuration, () async {
              await game.update({
                'board': FieldValue.arrayRemove([x, c, card]),
                '${userState.pair}Cards': FieldValue.arrayUnion([x, c, card]),
              });
              if (!testing) nextTurn();
              dev.log('sum take');
            });
            checkScopa();
            return;
          }
        }
      }
    }

    if (!testing) nextTurn();
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

    streamSub?.cancel();
    streamSub = gameDoc.snapshots().listen(listener);

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

          Widget c(int l, int t, AlignmentGeometry a, String n) {
            final fullWidth = cardSize * (l + 1);

            return Align(
              alignment: a,
              child: RotatedBox(
                quarterTurns: t,
                child: Container(
                  width: fullWidth,
                  height: 200,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: List.generate(
                        l,
                        (x) => AnimatedPositioned(
                          duration: Durations.short4,
                          bottom: 10,
                          left: x * cardSize,
                          child: buildOpponentCard(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

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
        final midPosition = MediaQuery.sizeOf(context).width / 2;
        final startPos = midPosition - (myHand.length / 2) * cardSize;

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: List.generate(
                myHand.length,
                (x) => AnimatedPositioned(
                  duration: Durations.short4,
                  bottom: 10,
                  left: startPos + x * cardSize,
                  child: buildHandCard(myHand[x], playCard),
                ),
              ),
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

        int rows = (hands.length / 3).ceil();
        int columns = min(hands.length, 3);
        var size = MediaQuery.sizeOf(context);
        double midY = size.height / 2;
        double midX = size.width / 2;
        final double cardHeight = 120;
        final double cardWidth = 87.6;
        double startY = midY - ((cardHeight * rows) / 2.0);
        double startX = midX - ((cardWidth * columns) / 2.0);

        return SizedBox.expand(
          child: Stack(
              children: List.generate(hands.length, (index) {
            final card = hands[index];
            int column = index % 3;
            int row = ((index - column) / 3) as int;
            bool contains = disappearingCards.contains(card);
            return AnimatedPositioned(
                curve: Curves.easeInOut,
                duration: contains ? cardAnimDuration : Durations.short4,
                top: contains ? (2 * midY) : startY + cardHeight * row,
                left: contains ? (2 * midX) : startX + cardWidth * column,
                child: buildBoardCard(card));
          })),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: pad([
          buildHandCard('23', (_) {}),
          Text(
            'Online Scopa',
            style: TextStyle(fontFamily: 'Serif', fontSize: 25),
          ),
          FilledButton(onPressed: joinGame, child: Text("Join Game")),
          FilledButton(onPressed: newGame, child: Text("New Game")),
        ]),
      ),
    );
  }

  Widget buildWaitingMenu() {
    return Center(
        child: Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('Game ID: ${game.id}'),
                OutlinedButton(
                  child: Icon(Icons.copy_rounded),
                  onPressed: () => Clipboard.setData(ClipboardData(text: game.id)),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pad([
              buildHandCard('23', (_) {}),
              Text(
                'Online Scopa',
                style: TextStyle(fontFamily: 'Serif', fontSize: 25),
              ),
              userState.dealer
                  ? FilledButton(
                      onPressed: startGame,
                      child: Text('Start Game'),
                    )
                  : Text('Waiting for admin to start game'),
            ]),
          ),
        ),
      ],
    ));
  }
}
