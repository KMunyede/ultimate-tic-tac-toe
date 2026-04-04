# Ultimate TicTacToe - Technical Blueprint

## 1. Project Overview
**Ultimate TicTacToe** is a strategic board game built with Flutter and Firebase. It features a "nested grid" mechanic where winning small 3x3 boards contributes to a larger 3x3 victory.

## 2. Recent Updates (v1.2.0)
- **Feature-First Architecture:** Deep modularization of the codebase into `core/`, `features/`, and `services/` for better scalability and maintenance.
- **Refined Authentication:** 
    - Full support for Google Sign-In and Email/Password authentication.
    - **Guest Flow (Auto-Pivot):** Anonymous accounts can be seamlessly linked to permanent accounts (`linkWithCredential`) to preserve guest stats.
    - **Account Recovery:** Implemented a robust "Need Help?" password reset and recovery flow.
- **App Check Implementation:** Initial integration of Firebase App Check for enhanced API security.
- **Legal Compliance:** Static legal pages (`privacy.html`, `terms.html`) hosted via Firebase Hosting and linked within the app settings.
- **Enhanced AI Strategy:** Synchronized AI logic across Local (Isolate-based) and Remote (Cloud Functions) providers.
- **UI/UX Polish:** Added responsive layout support for tablets/desktop, custom animations for game transitions, and confetti effects for victories.

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
