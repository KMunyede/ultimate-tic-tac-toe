# Ultimate Tic-Tac-Toe

This Flutter project is an advanced version of the classic Tic-Tac-Toe game, featuring multiple boards, AI opponents, and customizable settings.

## Getting Started

To get started with this project, clone the repository and run `flutter pub get` to install the required dependencies. Then, run the app on your desired device or emulator.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Game Logic

The core of the game is managed by the `GameController`, which handles the game state, player moves, and win conditions.

### Game States

- **Boards**: The game can be played on one, two, or three boards simultaneously. Each board is represented by a `GameBoard` object, which maintains its own state.
- **Player Turn**: The `_currentPlayer` variable tracks whose turn it is (Player X or Player O).
- **Win Conditions**: A player wins a board by getting three of their marks in a row, column, or diagonal. The overall winner is the player who wins all the boards.
- **Draw**: A board is considered a draw if all its cells are filled and no player has won. The overall game is a draw if all boards are completed and there is no overall winner.

## UI and UX Behaviour

The user interface is designed to be intuitive and visually appealing.

- **Responsive Layout**: The UI adapts to different screen sizes and orientations, ensuring a good user experience on various devices.
- **Themes**: Players can customize the look and feel of the game by choosing from a selection of themes in the settings menu.
- **Sound Effects**: The game includes sound effects for key events such as making a move, winning a board, and winning the game.

## Settings Implementation

The `SettingsController` class manages the game's settings, which are persisted to the device using `shared_preferences`.

- **Game Mode**: Players can choose between "Player vs. Player" and "Player vs. AI" modes.
- **AI Difficulty**: In "Player vs. AI" mode, players can select the AI's difficulty level (Easy, Medium, or Hard).
- **Board Layout**: Players can choose to play on a single board, two boards, or three boards.
- **Sound**: The sound effects can be enabled or disabled in the settings.
- **Score**: The game keeps track of the score for Player X and Player O, which can be reset in the settings.

## Communication with Firebase Functions

The "Player vs. AI" mode leverages a Firebase Cloud Function to determine the AI's moves.

- **`getAiMove` Function**: When it's the AI's turn, the app calls the `getAiMove` Firebase Function, passing the current board state and the current player. The function returns the AI's calculated best move.
- **AI Difficulty**: The AI's difficulty level (Medium or Hard) is passed to the Firebase Function to adjust the complexity of the move calculation. For the "Easy" difficulty, a random move is generated locally on the device.
