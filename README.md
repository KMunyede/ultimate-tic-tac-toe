# Ultimate TicTacToe - Technical Blueprint (Hilmost Enterprises)

## 1. Project Overview
**Ultimate TicTacToe** is a strategic board game built with Flutter and Firebase. It features a "nested grid" mechanic where winning small 3x3 boards contributes to a larger 3x3 victory.

## 2. Core Features
- **Nested Grid Mechanics:** A 9x9 grid composed of nine 3x3 sub-boards.
- **Strategic Forcing:** Your move in a sub-board cell dictates which sub-board your opponent must play in next.
- **Game Modes:**
    - **Standard Mode:** Classic Ultimate TicTacToe rules (3-in-a-row sub-boards).
    - **Majority Mode:** A unique twist where winning the majority of sub-boards (5 out of 9) wins the match.
- **AI Opponent:** Play against a local AI with adjustable difficulty settings.
- **Cross-Platform:** Support for Android (API 35/36), Web, and Desktop (Windows/Linux/macOS).
- **Modern UI:** Dynamic theme support with dark/light modes and responsive layout.
- **Multiplayer Ready:** Firebase integration for future real-time multiplayer support.

## 3. How the App Works
### Game Logic Flow
1. **Turn Start:** The active player selects a valid cell in the "active" sub-board.
2. **Sub-board Win:** If a player gets 3-in-a-row within a sub-board, they claim that sub-board.
3. **Global Win Evaluation:** The `MatchReferee` uses a Strategy Pattern to check if the global victory conditions (Standard or Majority) are met.
4. **Active Board Redirect:** The index of the cell chosen in the sub-board becomes the index of the next sub-board the opponent must play in.

### Technical Stack
- **State Management:** `Provider` manages the complex 9x9 grid state and UI updates.
- **Persistence:** `firebase_auth` for users and `cloud_firestore` for game state syncing.
- **Audio:** `audioplayers` for immersive sound effects managed by a `SoundManager`.
- **Theming:** Custom `AppTheme` using Material 3 principles.

## 4. Deployment & Compliance
- **Web Hosting:** Deployed via Firebase Hosting.
- **Compliance:** Includes built-in Privacy Policy and Data Deletion request pages.
- **Links:**
    - **Live Web App:** [https://ultimate-tic-tac-toe-359-deaec.web.app/](https://ultimate-tic-tac-toe-359-deaec.web.app/)
    - **Privacy Policy:** [/privacy.html](https://ultimate-tic-tac-toe-359-deaec.web.app/privacy.html)

## 5. Development & Deployment Commands
- **Android Build:** `flutter build appbundle --release`
- **Web Build:** `flutter build web --release --base-href "/"`
- **Firebase Deploy:** `firebase deploy --only hosting`
- **Project Clean:** `flutter clean && flutter pub get`

## 6. Directory Structure
```text
lib/
├── logic/              # MatchReferee, Victory Strategies
├── models/             # GameModel, Player, BoardResult enums
├── services/           # FirebaseService, AIService, SoundManager
├── widgets/            # NestedGrid, GameStatus, SettingsMenu
├── main.dart           # App Entry, Firebase & Provider Setup
├── app_theme.dart      # Material 3 Design System
└── game_screen.dart    # Primary Responsive UI
```
