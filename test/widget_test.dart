import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tictactoe/features/game/logic/game_controller.dart';
import 'package:tictactoe/features/game/screens/game_screen.dart';
import 'package:tictactoe/features/settings/logic/settings_controller.dart';
import 'package:tictactoe/core/audio/sound_manager.dart';
import 'package:tictactoe/features/auth/services/auth_service.dart';
import 'package:tictactoe/services/firebase_service.dart';
import 'package:tictactoe/services/stats_service.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/models/match_session.dart';
import 'package:tictactoe/widgets/board_widget.dart';
import 'package:tictactoe/widgets/board/neumorphic_cell.dart';
import 'package:tictactoe/logic/match_referee.dart';

// Fakes to avoid platform dependencies and hangs during tests
class FakeSettingsController extends SettingsController {
  int _boardCount = 1;
  @override
  int get boardCount => _boardCount;
  
  void setTestBoardCount(int count) {
    _boardCount = count;
    notifyListeners();
  }

  @override
  Future<void> loadSettings({bool isGuest = false}) async {}
  
  @override
  GameMode get gameMode => GameMode.playerVsPlayer;
  
  @override
  GameRuleSet get ruleSet => GameRuleSet.standard;

  @override
  Future<void> updateScore(Player winner) async {}

  @override
  void consumeGameResetRequest() {}
}

class FakeSoundManager extends Fake implements SoundManager {
  @override
  Future<void> init() async {}
  @override
  Future<void> playMoveSound({Player? player}) async {}
  @override
  Future<void> playWinSound({bool isLoss = false}) async {}
  @override
  Future<void> playDrawSound() async {}
  @override
  void dispose() {}
}

class FakeFirebaseService extends Fake implements FirebaseService {
  @override
  Future<void> saveGameState(MatchSession session) async {}

  @override
  Future<MatchSession?> loadGameState() async => null;
}

class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<User?> get user => Stream.value(null);
  @override
  Future<void> signOut() async {}
}

class FakeStatsService extends Fake implements StatsService {
  @override
  Future<void> recordMatchOutcome({
    required GameMode gameMode,
    required AiDifficulty aiDifficulty,
    required MatchOutcome outcome,
  }) async {}
}

void main() {
  group('Tic-Tac-Toe Game Tests', () {
    late FakeSettingsController settingsController;
    late FakeSoundManager soundManager;
    late FakeFirebaseService firebaseService;
    late FakeAuthService authService;
    late FakeStatsService statsService;

    setUp(() {
      settingsController = FakeSettingsController();
      soundManager = FakeSoundManager();
      firebaseService = FakeFirebaseService();
      authService = FakeAuthService();
      statsService = FakeStatsService();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settingsController),
          Provider<SoundManager>.value(value: soundManager),
          Provider<FirebaseService>.value(value: firebaseService),
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider<StatsService>.value(value: statsService),
          ChangeNotifierProxyProvider<SettingsController, GameController>(
            update: (context, settings, previous) {
              previous?.updateDependencies(settings);
              return previous ??
                  GameController(
                    soundManager,
                    settings,
                    firebaseService,
                    statsService,
                  );
            },
            create: (context) => GameController(
              soundManager,
              settingsController,
              firebaseService,
              statsService,
            ),
          ),
        ],
        child: const MaterialApp(
          home: GameScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    testWidgets('Basic Gameplay and Win State (Tablet Landscape)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining("X's Turn"), findsOneWidget);
      
      final cells = find.byType(NeumorphicCell);
      expect(cells, findsAtLeastNWidgets(9));

      await tester.tap(cells.at(4)); // X
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining("O's Turn"), findsOneWidget);

      await tester.tap(cells.at(0)); // O
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining("X's Turn"), findsOneWidget);

      await tester.tap(cells.at(3)); // X
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(cells.at(1)); // O
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      
      await tester.tap(cells.at(5)); // X wins (row 3,4,5)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 4));

      // Check if one of the victory hook keywords is found
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Text &&
          (widget.data?.contains("WON") == true || widget.data?.contains("VICTORY") == true)
        ),
        findsOneWidget,
      );

      final newGameButton = find.textContaining('BATTLE');
      expect(newGameButton, findsAtLeastNWidgets(1));

      await tester.tap(newGameButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining("X's Turn"), findsOneWidget);
    });

    testWidgets('Phone Landscape Grid Enforcement (9 Boards)', (WidgetTester tester) async {
      // Small phone landscape: 640x360 (Shortest side 360 < 600)
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      settingsController.setTestBoardCount(9);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify all 9 boards are rendered
      expect(find.byType(BoardWidget), findsNWidgets(9));
    });
  });
}
