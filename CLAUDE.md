# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Online 4-player (2 vs 2) Scopone card game built with Flutter for the **web only**, backed by Firebase Auth (Google sign-in) and Firestore (project `scopa-4c3c2`). There is no server code: all game logic runs on the clients, protected by `firestore.rules`. The UI refuses to render in portrait orientation.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                  # unit tests for the pure game rules
flutter test test/rules_test.dart --name napula   # a single test

# Local development against the emulators (auth :9099, firestore :8080, UI :4000)
firebase emulators:start --only auth,firestore
flutter run -d chrome --dart-define=TESTING=true   # add ?player=2 etc. to the URL for more seats

flutter build web --release                    # output in build/web, served by Firebase Hosting
firebase deploy --only firestore               # rules + indexes (not deployed by CI)
```

CI (`.github/workflows/`) runs analyze, test and build, then deploys a preview channel on PRs and the live site on pushes to `main`.

## Testing mode

`testing` in `lib/main.dart` is `bool.fromEnvironment('TESTING')`. When it is on, the app:
- talks to the local emulators;
- signs in with emulator email accounts `player<N>@scopa.test`, where N comes from the `?player=N` URL parameter;
- doesn't persist the session, so sign in again after a reload to resume the game;
- fills new games with bots `bot1`-`bot3`, whose turns the host plays automatically.

## Architecture

- **`lib/game/rules.dart`**: pure, unit-tested game logic. It covers card encoding, `captureOptions`, `scoreHand`, and seat/pair/turn helpers. Change rules here, not in widgets.
- **`lib/game/game_service.dart`**: every Firestore read and write. Joins, plays, leaving and leaderboard updates are transactions.
- **`lib/main.dart`**: the auth and navigation shell. It keeps a single subscription to the current game doc and one to the player's own hand. It exposes them as `ValueNotifier`s (`gameData`, `hand`), and the status pages listen to those. Widgets receive plain `DynaMap` data and never subscribe to Firestore themselves.
- **Navigation:** the game doc's `status` drives it. When the status changes, `_showStatusPage` replaces the route stack with `pushAndRemoveUntil`. `_detach()` pops back to the start menu.
  - Statuses: `waiting → playing → finished → … → matchOver`, plus `abandoned`.
  - A player who reloads resumes their game through `findActiveGame()` after signing in.

### UI
- **`lib/theme.dart`** holds the look:
  - colors (`AppColors`), animation durations and curves (`Motion`), and `displayStyle()` for black-weight numbers
  - `buildTheme()`
  - the shared `FeltBackground` and `GlassPill`
  - Reuse these tokens instead of hard-coding colors or fonts.
- **Font:** Nunito is bundled in `assets/fonts/` and declared in `pubspec.yaml`. There is no `google_fonts`, so nothing is fetched at runtime.
- **`lib/widgets/playing_card.dart`:** `PlayingCard`, `CardBack` and `CardMetrics`. `CardMetrics` scales card size with the screen height. Every card on screen uses these.
- **Animations:** keep them transform/opacity-only (`AnimatedSlide`, `AnimatedScale`, `Entrance` in `widgets/entrance.dart`). Avoid animating width/height or blur, which janks on the web.
- **Hero transitions:** they rely on `_showStatusPage` pushing the first game page and replacing it afterwards with `pushReplacement`. `pushAndRemoveUntil` would break the `title` hero.

### Data model
- `games/{id}`: `players` (seat order: index 0 is the host), `nicknames`, `images`, `privacy`, `status`, `turn`, `round`, `board`, `handCounts`, `pending`, `disappearingCards`, `lastTakerPair`, `targetScore`, `winnerPair`, `expireAt`, and per pair (`firstPair` = odd seats, `secondPair` = even seats): `{pair}Cards`, `{pair}Scope`, `{pair}ScopeCards`, `{pair}Score`, `{pair}ScoreData`.
- `games/{id}/hands/{uid}`: `{cards}`. Only the owner can read a hand (and the host for bot seats). The host writes all hands when dealing.
- `leaderboard/{uid}`: `name`, `totalPoints`, `gamesPlayed`, `wins`, `lastGameId`. Each player updates only their own entry, once per match.
- **TTL:** to clean up old games, enable Firestore TTL on the `expireAt` field for the `games` and `hands` collection groups in the console, or with `gcloud firestore fields ttls update expireAt --collection-group=games --enable-ttl`, and the same for `hands`.

### Turn flow
A play has two phases. `playCard` validates the move in a transaction, lays the card on the board and sets `pending`, which locks the turn. After the capture animation, `resolvePlay` moves the captured cards, awards any scopa and advances `turn`. When it was the last card, it also gives the leftover board to `lastTakerPair` and scores the hand. Any client resolves a `pending` play that is stuck for 8 s.

The seat to play is `(turn + round) % 4`, so the starting seat rotates every hand.

### Cards
A card is a 2-char string `"<suit><value>"`: suit 1-4 (hearts, diamonds, clubs, spades), value `1-9` and `0` (King = 10; 8 = J, 9 = Q). Display helpers live in `lib/utils.dart`.

House rules (`rules.dart`):
- An Ace sweeps the board (`aceTakesAll`), and that is not a scopa.
- A single matching card must be taken before a sum. When several captures are possible, the player chooses (`capture_choice_dialog.dart`).
- The last play of a hand never scores a scopa.
- The match goes to 21.
