import 'package:flutter/material.dart' show ElevatedButton, GestureDetector;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tictactoe/main.dart' show MyApp;
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/sound_manager.dart' show SoundManager;

void main() {
  testWidgets('Tic-Tac-Toe game test', (WidgetTester tester) async {
    final settingsController = SettingsController();
    await settingsController.loadSettings();
    final soundManager = SoundManager(settingsController);
    await soundManager.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsController),
          Provider<SoundManager>(
            create: (_) => soundManager,
            dispose: (_, manager) => manager.dispose(),
          ),
          ChangeNotifierProxyProvider<SettingsController, GameController>(
            update: (context, settings, previous) {
              previous?.updateDependencies(settings);
              return previous ??
                  GameController(
                    context.read<SoundManager>(),
                    settings,
                  );
            },
            create: (context) => GameController(
              context.read<SoundManager>(),
              context.read<SettingsController>(),
            ),
          ),
        ],
        child: const MyApp(isPrimaryInstance: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Player X's Turn"), findsOneWidget, reason: "Game should start with Player X's turn");
    expect(find.text('X'), findsNothing);
    expect(find.text('O'), findsNothing);

    final cells = find.byType(GestureDetector);
    expect(cells, findsNWidgets(9));

    await tester.tap(cells.at(4));
    await tester.pump();

    expect(find.text('X'), findsOneWidget);
    expect(find.text("Player O's Turn"), findsOneWidget);

    await tester.tap(cells.at(0));
    await tester.pump();

    expect(find.text('O'), findsOneWidget);
    expect(find.text("Player X's Turn"), findsOneWidget);

    expect(find.text('Play Again'), findsNothing);

    await tester.tap(cells.at(1)); // X
    await tester.pump();
    await tester.tap(cells.at(2)); // O
    await tester.pump();
    await tester.tap(cells.at(7)); // X
    await tester.pump();

    expect(find.text('Player X Wins!'), findsOneWidget);

    final playAgainButton = find.widgetWithText(ElevatedButton, 'Play Again');
    expect(playAgainButton, findsOneWidget);

    await tester.tap(playAgainButton);
    await tester.pump();

    expect(find.text("Player X's Turn"), findsOneWidget);
    expect(find.text('X'), findsNothing);
  });
}
