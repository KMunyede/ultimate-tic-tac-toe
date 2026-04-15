# Ultimate TicTacToe - Technical Blueprint

## 1. Project Overview
**Ultimate TicTacToe** is a strategic board game built with Flutter and Firebase. It features a "nested grid" mechanic where winning small 3x3 boards contributes to a larger 3x3 victory.

## 2. Recent Updates (v1.3.0)
- **Specialized Match Logic:** 
    - **Standard Mode:** Support for 1 or 2 boards. Winning 2 boards requires total dominance (winning both).
    - **Majority Wins:** Support for 1 to 9 boards. For 3 boards, winning 2 is required for victory, with specialized "Nice Effort" and "No Winner" outcomes.
- **Ultimate Strategy Refinement:** Fixed the "Force Move" logic to ensure Player O (AI) always respects the sub-board redirection rules.
- **Smart Guest Onboarding:** New players start as guests in Standard Mode with 1 board and a 2-board limit to simplify the initial learning curve.
- **Direct AI Controls:** Added a "Play vs Online AI" toggle directly to the main screen for quick switching between local and cloud processing.
- **UI Performance & Stability:** 
    - Removed background assets to eliminate "Image Decoder" errors and improve startup speed.
    - Fixed "double-flicker" and white flashes during board transitions and game initialization.
    - Improved marker visibility and added large winner indicators over won sub-boards.
- **Robust Cloud Connectivity:** Enhanced Firestore error handling with automatic recovery and clearer console instructions for database setup.

## 3. Core Features
- **Nested Grid Mechanics:** A 9x9 grid composed of nine 3x3 sub-boards.
- **Strategic Forcing:** Your move in a sub-board cell dictates which sub-board your opponent must play in next.
- **Game Modes:**
    - **Standard Mode:** Classic Ultimate TicTacToe rules (3-in-a-row sub-boards).
    - **Majority Mode:** A unique twist where winning the majority of sub-boards (5 out of 9) wins the match.
- **AI Opponents:**
    - **Local AI:** Built-in strategies (Easy, Medium, Hard) using an Isolate-based engine.
    - **Remote AI:** Firebase Cloud Functions for advanced move computation.
- **Multi-Platform:** Native support for Android (API 35+), iOS, Web, and Desktop (Windows/Linux/macOS).

## 4. Technical Stack & State
- **Framework:** Flutter (Material 3)
- **State Management:** `Provider` with `ChangeNotifierProxyProvider` for complex dependency injection.
- **Backend:** Firebase Auth, Cloud Firestore, Cloud Functions, Firebase Hosting.
- **Security:** App Check (SafetyNet/Play Integrity), Environment variable protection via `flutter_dotenv`.
- **Audio:** `audioplayers` for immersive sound effects and background management.

## 5. How the App Works
### Game Logic Flow
1. **Turn Start:** The active player selects a valid cell in the "active" sub-board.
2. **Sub-board Win:** If a player gets 3-in-a-row within a sub-board, they claim that sub-board.
3. **Global Win Evaluation:** The match engine checks for victory conditions (Standard 3-in-a-row or Majority 5-of-9).
4. **Active Board Redirect:** The index of the cell chosen in the sub-board becomes the index of the next sub-board the opponent must play in.

## 6. Deployment & Commands
- **Android:** `flutter build appbundle --release`
- **Web:** `flutter build web --release --base-href "/"`
- **Cloud Functions:** `firebase deploy --only functions`
- **Firebase Hosting:** `firebase deploy --only hosting`

## 7. Directory Structure
```text
lib/
├── core/               # Audio, Theme, and Window management
├── features/           # Feature-based modules
│   ├── auth/           # Auth services, Login screens, and AuthGate
│   ├── game/           # Main game logic (Controller) and UI screens
│   └── settings/       # Settings logic and menu widgets
├── services/           # Shared services (Firebase, Stats, Persistence, AI)
├── logic/              # Core game referee and win strategies
├── models/             # Data models (GameBoard, Player, MatchSession)
├── utils/              # Responsive layout and UI helpers
├── widgets/            # Reusable UI components and animations
└── main.dart           # App entry and provider tree setup
```
