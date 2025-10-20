import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/main.dart';

void main() {
  testWidgets('Tic-Tac-Toe game test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the initial state of the game.
    expect(find.text("Player X's Turn"), findsOneWidget);
    expect(find.text('X'), findsNothing);
    expect(find.text('O'), findsNothing);

    // Find all the game board cells (GestureDetectors).
    final cells = find.byType(GestureDetector);
    expect(cells, findsNWidgets(9));

    // Player X takes the center square.
    await tester.tap(cells.at(4));
    await tester.pump();

    // Verify the board updated.
    expect(find.text('X'), findsOneWidget);
    expect(find.text("Player O's Turn"), findsOneWidget);

    // Player O takes the top-left square.
    await tester.tap(cells.at(0));
    await tester.pump();

    // Verify the board updated.
    expect(find.text('O'), findsOneWidget);
    expect(find.text("Player X's Turn"), findsOneWidget);

    // Find the "Play Again" button (it shouldn't exist yet).
    expect(find.text('Play Again'), findsNothing);

    // Continue game to a win condition for X
    // X: 4, O: 0
    await tester.tap(cells.at(1)); // X
    await tester.pump();
    await tester.tap(cells.at(2)); // O
    await tester.pump();
    await tester.tap(cells.at(7)); // X
    await tester.pump();

    // Verify the win state
    expect(find.text('Player X Wins!'), findsOneWidget);

    // Verify the "Play Again" button now exists
    final playAgainButton = find.widgetWithText(ElevatedButton, 'Play Again');
    expect(playAgainButton, findsOneWidget);

    // Tap "Play Again" and verify the game resets
    await tester.tap(playAgainButton);
    await tester.pump();

    expect(find.text("Player X's Turn"), findsOneWidget);
    expect(find.text('X'), findsNothing);
  });
}
