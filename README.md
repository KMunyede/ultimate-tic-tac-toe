# tictactoe

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Game Logic

The game is an enhanced version of Tic-Tac-Toe that can be played on one, two, or three boards at the same time. It supports both **Player vs. Player** and **Player vs. AI** modes. The AI's intelligence can be set to different difficulty levels, and it uses a Firebase Cloud Function to determine its moves.

## Game Rules

-   Players alternate placing their marks ('X' or 'O') in empty cells on any of the active boards.
-   A board is won when a player achieves three of their marks in a horizontal, vertical, or diagonal row. Once a board is won, no more moves can be made on it.
-   The ultimate goal is to win **all** of the game boards. A player is declared the overall winner only when they have won every board in play.
-   If all boards are filled or won and no single player has conquered them all, the game ends in a draw.

## User Interface & User Experience

-   **Color Palette**: The UI features customizable themes, including a "Forest Green" option. Colors from the selected theme are used to create attractive gradients and a visually appealing game board.
-   **Themes**: The game includes a settings menu where players can switch between different visual themes to suit their preferences.
-   **Screen Adaptation**: The layout is designed to be responsive. The game boards are arranged horizontally and the UI adjusts to accommodate the number of boards in play, ensuring a good experience on various screen sizes.
-   **Sound**: To enhance the user experience, the game includes sound effects that provide feedback for key events such as making a move, winning a game, or a draw.

## Firebase Connections

-   **Authentication**: Firebase Authentication is used to manage user sign-in and identity.
-   **AI Opponent**: The Player vs. AI mode is powered by a Firebase Cloud Function, which calculates and returns the AI's next move based on the current state of the board.
