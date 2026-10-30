import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scopa/capture_choice_dialog.dart';
import 'package:scopa/card_arc.dart';
import 'package:scopa/finished_menu.dart';
import 'package:scopa/firebase_options.dart';
import 'package:scopa/game/game_service.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/main_title.dart';
import 'package:scopa/playing_menu.dart';
import 'package:scopa/sign_in_menu.dart';
import 'package:scopa/start_menu.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/user_state.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/waiting_menu.dart';

/// Run with `--dart-define=TESTING=true` to use the local Firebase emulators
/// and fill new games with host-controlled bots.
const testing = bool.fromEnvironment('TESTING');

/// Game statuses (`status` field of `games/{id}`):
/// waiting   - lobby, until the host starts it with 4 players
/// playing   - a hand is in progress; `turn` and `round` give the seat to play
/// finished  - the hand was scored, the host deals the next one
/// matchOver - a pair reached `targetScore`
/// abandoned - a player left mid-game

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (testing) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scopa',
      home: const MyHomePage(),
      theme: buildTheme(),
      builder: (context, child) => MediaQuery.orientationOf(context) == Orientation.portrait
          ? const Material(
              child: Stack(
                children: [
                  FeltBackground(),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          Icon(Icons.screen_rotation_rounded, size: 56, color: Colors.white),
                          Text(
                            'Rotate your device to landscape to play.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : child!,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Duration cardAnimDuration = Durations.long4;

  UserState? user;
  GameService? service;

  /// The game this player is in, and its status; null on the start menu.
  DocumentReference<DynaMap>? game;
  String? status;

  final gameData = ValueNotifier<DynaMap?>(null);
  final hand = ValueNotifier<List<String>>([]);

  /// True while an action the player started (sign in, create, join, deal) runs.
  final busy = ValueNotifier(false);

  /// The route showing the current game, replaced as its status changes.
  Route<void>? _gameRoute;

  StreamSubscription<User?>? _authSub;
  StreamSubscription? _gameSub;
  StreamSubscription? _handSub;

  /// Resolves a play left pending by a player who disconnected mid-animation.
  Timer? _pendingTimer;
  String? _watchedPending;

  bool _playing = false;
  bool _botPlaying = false;
  String? _recordedMatch;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelGameSubs();
    gameData.dispose();
    hand.dispose();
    busy.dispose();
    super.dispose();
  }

  Future<void> _onAuth(User? u) async {
    _detach();
    if (u == null) {
      setState(() {
        user = null;
        service = null;
      });
      return;
    }
    setState(() {
      user = UserState(
        uid: u.uid,
        nickname: u.displayName ?? 'user-${u.uid.substring(0, 5)}',
        imgUrl: u.photoURL ?? '',
      );
      service = GameService(u.uid);
    });
    try {
      final active = await service!.findActiveGame();
      if (active != null && mounted) _attach(active);
    } on FirebaseException catch (e) {
      _showSnackBar('Could not look for your active game: ${e.message}');
    }
  }

  /// Runs [action] with [busy] set, ignoring taps while another action runs.
  Future<void> _run(Future<void> Function() action) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await action();
    } finally {
      busy.value = false;
    }
  }

  Future<void> _signIn() => _run(() async {
        try {
          testing ? await _signInTestPlayer() : await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        } on FirebaseAuthException catch (e) {
          if (e.code != 'popup-closed-by-user' && e.code != 'cancelled-popup-request') {
            _showSnackBar('Sign-in failed: ${e.message}');
          }
        }
      });

  /// Testing only: signs in to an auth-emulator account picked by the `?player=N`
  /// URL parameter, so each tab can take a different seat and signing in again
  /// resumes the same player.
  Future<void> _signInTestPlayer() async {
    final player = Uri.base.queryParameters['player'] ?? '1';
    final email = 'player$player@scopa.test';
    const password = 'emulator-only';
    final auth = FirebaseAuth.instance;
    // A persisted user makes Auth start before useAuthEmulator runs on the next
    // load, silently pointing the app at production. Don't persist test sessions.
    await auth.setPersistence(Persistence.NONE);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName('Player $player');
      await auth.signOut();
      await auth.signInWithEmailAndPassword(email: email, password: password);
    }
  }

  void _attach(DocumentReference<DynaMap> ref) {
    _cancelGameSubs();
    game = ref;
    _gameSub = ref.snapshots().listen(_onGame, onError: (Object e) => _showSnackBar('Connection error: $e'));
    _handSub = ref.collection('hands').doc(user!.uid).snapshots().listen(
          (snap) => hand.value = List<String>.from(snap.data()?['cards'] ?? []),
          onError: (Object e) => _showSnackBar('Connection error: $e'),
        );
  }

  void _cancelGameSubs() {
    _gameSub?.cancel();
    _handSub?.cancel();
    _pendingTimer?.cancel();
    _gameSub = null;
    _handSub = null;
    _pendingTimer = null;
    _watchedPending = null;
  }

  /// Stops following the current game and returns to the start menu.
  void _detach() {
    _cancelGameSubs();
    game = null;
    status = null;
    gameData.value = null;
    hand.value = [];
    _gameRoute = null;
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onGame(DocumentSnapshot<DynaMap> snap) {
    final data = snap.data();
    if (data == null || !(data['players'] as List).contains(user!.uid)) {
      _detach();
      return;
    }
    gameData.value = data;
    final newStatus = data['status'] as String;
    if (newStatus != status) {
      status = newStatus;
      _showStatusPage(newStatus);
    }
    if (newStatus == 'matchOver') _recordMatch(snap.id, data);
    _watchPending(data);
    if (testing) _playBots();
  }

  /// Shows the page for [status]. The first game page is pushed over the start
  /// menu and later ones replace it, so the outgoing page stays alive during
  /// the transition and hero widgets (the title) can fly between them.
  void _showStatusPage(String status) {
    final navigator = Navigator.of(context);
    final route = PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
        child: Scaffold(
          body: Stack(
            children: [
              const FeltBackground(),
              ValueListenableBuilder(
                valueListenable: gameData,
                builder: (context, data, _) => data == null
                    ? const SizedBox()
                    : ValueListenableBuilder(
                        valueListenable: busy,
                        builder: (context, busy, _) => _pageFor(status, data, busy),
                      ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _canLeaveFreely(status)
                      ? FilledButton.icon(
                          onPressed: _leaveGame,
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Back to menu'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _confirmLeave,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Leave'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.enter);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );

    final previous = _gameRoute;
    _gameRoute = route;
    if (previous != null && previous.isActive) {
      // Close dialogs (e.g. the capture choice) left open over the old page.
      navigator.popUntil((r) => r == previous || r.isFirst);
      if (previous.isCurrent) {
        navigator.pushReplacement(route);
        return;
      }
    }
    navigator.push(route);
  }

  bool _canLeaveFreely(String status) => status == 'abandoned' || status == 'matchOver';

  /// Leaving mid-game ends it for everyone, so ask first.
  Future<void> _confirmLeave() async {
    final data = gameData.value;
    final status = data?['status'] as String?;
    final isHost = (data?['players'] as List?)?.firstOrNull == user?.uid;
    if (status == null || _canLeaveFreely(status) || (status == 'waiting' && !isHost)) {
      return _leaveGame();
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the game?'),
        content: Text(status == 'waiting'
            ? 'You are the host: leaving closes the lobby for everyone.'
            : 'Leaving ends the game for all four players.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true) await _leaveGame();
  }

  Widget _pageFor(String status, DynaMap data, bool busy) {
    final uid = user!.uid;
    final players = List<String>.from(data['players']);
    final isHost = players.isNotEmpty && players.first == uid;
    final pair = pairForSeat(players.indexOf(uid));
    return switch (status) {
      'waiting' => WaitingMenu(data: data, uid: uid, gameId: game?.id ?? '', busy: busy, startGame: _deal),
      'playing' => ValueListenableBuilder(
          valueListenable: hand,
          builder: (context, cards, _) => PlayingMenu(
            data: data,
            hand: cards,
            uid: uid,
            playCard: _playCard,
            cardAnimDuration: cardAnimDuration,
          ),
        ),
      'finished' || 'matchOver' => FinishedMenu(
          data: data,
          pair: pair,
          isHost: isHost,
          busy: busy,
          onContinue: () => _deal(nextRound: status == 'finished', newMatch: status == 'matchOver'),
        ),
      'abandoned' => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white70),
              Text('Game abandoned', style: displayStyle(32)),
              const Text('A player left the game.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      _ => Center(child: Text('Unexpected game status: $status')),
    };
  }

  Future<void> _newGame(bool private) => _run(() async {
        try {
          final ref = await service!.createGame(
            private: private,
            nickname: user!.nickname,
            image: user!.imgUrl,
            withBots: testing,
          );
          _attach(ref);
        } on FirebaseException catch (e) {
          _showSnackBar('Could not create game: ${e.message}');
        }
      });

  Future<void> _deal({bool nextRound = false, bool newMatch = false}) => _run(() async {
        final ref = game;
        if (ref == null) return;
        try {
          await service!.deal(ref, nextRound: nextRound, newMatch: newMatch);
        } on GameException catch (e) {
          _showSnackBar(e.message);
        } on FirebaseException catch (e) {
          _showSnackBar('Could not deal: ${e.message}');
        }
      });

  Future<void> _playCard(String card) async {
    final data = gameData.value;
    final ref = game;
    if (_playing || data == null || ref == null) return;

    final options = captureOptions(List<String>.from(data['board']), card);
    var captured = options.isEmpty ? <String>[] : options.first;
    if (options.length > 1) {
      final choice = await showCaptureChoice(context, card, options);
      if (choice == null) return;
      captured = choice;
    }

    _playing = true;
    try {
      await _play(ref, user!.uid, card, captured);
    } finally {
      _playing = false;
    }
  }

  /// Plays [card] for [player]: lays it on the board, animates the capture,
  /// then resolves the play, which hands the turn to the next seat.
  Future<void> _play(DocumentReference<DynaMap> ref, String player, String card, List<String> captured) async {
    try {
      final error = await service!.playCard(ref, player, card, captured);
      if (error != null) {
        _showSnackBar(error);
        return;
      }
      if (captured.isNotEmpty) {
        await Future.delayed(Durations.extralong4);
        await service!.showCapture(ref, [...captured, card]);
        await Future.delayed(cardAnimDuration);
      }
      await service!.resolvePlay(ref, card);
    } on FirebaseException catch (e) {
      _showSnackBar('Could not play card: ${e.message}');
    }
  }

  void _watchPending(DynaMap data) {
    final card = (data['pending'] as Map?)?['card'] as String?;
    if (card == _watchedPending) return;
    _watchedPending = card;
    _pendingTimer?.cancel();
    final ref = game;
    if (card == null || ref == null) return;
    _pendingTimer = Timer(const Duration(seconds: 8), () => service?.resolvePlay(ref, card).catchError((Object _) {}));
  }

  /// Testing only: the host plays the first card of whichever bot is to play.
  Future<void> _playBots() async {
    final data = gameData.value;
    final ref = game;
    if (_botPlaying || data == null || ref == null) return;
    final players = List<String>.from(data['players']);
    if (data['status'] != 'playing' || data['pending'] != null || players.first != user!.uid) return;
    final bot = players[seatToPlay(data['turn'], data['round'])];
    if (!botIds.contains(bot)) return;

    _botPlaying = true;
    try {
      await Future.delayed(Durations.extralong4);
      final cards = await service!.botHand(ref, bot);
      final board = List<String>.from(gameData.value?['board'] ?? []);
      if (cards.isNotEmpty) {
        final options = captureOptions(board, cards.first);
        await _play(ref, bot, cards.first, options.isEmpty ? [] : options.first);
      }
    } finally {
      _botPlaying = false;
    }
    // Snapshots that arrived while the bot was playing were skipped.
    if (game == ref) _playBots();
  }

  void _recordMatch(String gameId, DynaMap data) {
    final matchId = '$gameId-${data['round']}';
    if (_recordedMatch == matchId) return;
    _recordedMatch = matchId;
    final pair = pairForSeat((data['players'] as List).indexOf(user!.uid));
    service!
        .recordMatch(
          matchId: matchId,
          name: user!.nickname,
          points: data['${pair}Score'] as int,
          won: data['winnerPair'] == pair,
        )
        .catchError((Object e) => _showSnackBar('Could not update the leaderboard: $e'));
  }

  Future<void> _leaveGame() async {
    final ref = game;
    _detach();
    if (ref == null) return;
    try {
      await service?.leave(ref);
    } on FirebaseException catch (e) {
      _showSnackBar('Error leaving game: ${e.message}');
    }
  }

  Future<void> _joinGame() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Game"),
        content: SizedBox(
          height: 400,
          width: 350,
          child: StreamBuilder<QuerySnapshot<DynaMap>>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .where('status', isEqualTo: 'waiting')
                .where('privacy', isEqualTo: 'public')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Could not load games: ${snapshot.error}'));
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.glass));
              }
              final docs = snapshot.data!.docs.where((d) => (d['players'] as List).length < 4).toList();
              if (docs.isEmpty) return const Center(child: Text('No open games'));
              return ListView(
                children: [
                  for (final doc in docs)
                    ListTile(
                      shape: roundedShape(16),
                      leading: const Icon(Icons.groups_rounded),
                      title: Text(
                        (doc['nicknames'] as Map).values.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${(doc['players'] as List).length}/4 players'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).pop(doc.id),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text("Cancel")),
          FilledButton.icon(
            onPressed: () async {
              final code = await _showTextInputDialog(context, 'Enter game code');
              if (code != null && context.mounted) Navigator.of(context).pop(code);
            },
            icon: const Icon(Icons.keyboard_rounded, size: 18),
            label: const Text("Enter code"),
          ),
        ],
      ),
    );

    if (code == null || code.trim().isEmpty) return;
    await _run(() async {
      final error = await service!.joinGame(code.trim(), nickname: user!.nickname, image: user!.imgUrl);
      if (error != null) {
        _showSnackBar(error);
        return;
      }
      _attach(service!.gameRef(code.trim()));
    });
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    void submit() {
      if (controller.text.trim().isNotEmpty) Navigator.of(context).pop(controller.text.trim());
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          maxLength: 64,
          controller: controller,
          style: const TextStyle(color: AppColors.suitBlack, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: "Game code", prefixIcon: Icon(Icons.tag_rounded)),
          autofocus: true,
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          FilledButton(onPressed: submit, child: const Text("Join")),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  static const _medals = [Color(0xFFE0A800), Color(0xFF9E9E9E), Color(0xFFB0703C)];

  Future<void> _showLeaderboard() async {
    final List<DynaMap> entries;
    final int? rank;
    try {
      (entries, rank) = await service!.leaderboard();
    } on FirebaseException catch (e) {
      _showSnackBar('Could not load the leaderboard: ${e.message}');
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leaderboard"),
        content: SizedBox(
          width: 350,
          height: 400,
          child: Column(
            children: [
              Text(
                rank == null ? 'Finish a match to join the leaderboard' : 'Your rank: #$rank',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text("No players on the leaderboard yet"))
                    : ListView(
                        children: [
                          for (final (i, entry) in entries.indexed)
                            ListTile(
                              shape: roundedShape(16),
                              selected: entry['id'] == user?.uid,
                              selectedColor: AppColors.suitBlack,
                              selectedTileColor: AppColors.accent.withAlpha(70),
                              leading: SizedBox(
                                width: 32,
                                child: i < 3
                                    ? Icon(Icons.emoji_events_rounded, color: _medals[i])
                                    : Text('#${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: displayStyle(16, color: AppColors.suitBlack)),
                              ),
                              title: Text(
                                '${entry['name'] ?? 'Unknown'}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text('Games: ${entry['gamesPlayed'] ?? 0} · Wins: ${entry['wins'] ?? 0}'),
                              trailing: Text('${entry['totalPoints'] ?? 0}',
                                  style: displayStyle(20, color: AppColors.suitBlack)),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FeltBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MainTitle(),
                  const CardArc(),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: busy,
                    builder: (context, busy, _) => AnimatedSwitcher(
                      duration: Motion.slow,
                      switchInCurve: Motion.enter,
                      switchOutCurve: Motion.enter,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
                      ),
                      child: user == null
                          ? SignInMenu(key: const ValueKey('signIn'), signIn: _signIn, busy: busy)
                          : StartMenu(
                              key: const ValueKey('start'),
                              user: user!,
                              busy: busy,
                              joinGame: _joinGame,
                              newGame: _newGame,
                              showLeaderboard: _showLeaderboard,
                              signOut: FirebaseAuth.instance.signOut,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
