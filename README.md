# Ultimate TicTacToe - Technical Blueprint (Hilmost Enterprises)

## 1. Project Overview
**Ultimate TicTacToe** is a strategic board game built with Flutter and Firebase. It features a "nested grid" mechanic where winning small 3x3 boards contributes to a larger 3x3 victory.

## 2. Core Architecture
- **State Management:** Provider pattern for game state and settings.
- **Game Logic:** Strategy Pattern for match rules (supporting "Majority Wins" and "Standard Positional" modes).
- **Backend:** Firebase Suite (Auth, Firestore, Cloud Functions).
- **Theme:** Custom `AppTheme` with dark/light mode and modern aesthetic.

## 3. Game Logic Specification
### Match Rules (`lib/logic/match_referee.dart`)
- **MajorityMatchRules:** A unique variation where winning a simple majority (e.g., 5 out of 9) of small boards wins the match.
- **StandardMatchRules (Planned):** Traditional Ultimate TicTacToe where winning 3 boards in a row/column/diagonal wins.
- **Forcing Mechanic:** Moves in a small board cell determine the specific small board the opponent must play in next.

## 4. Technology Stack & Dependencies
- **Flutter SDK:** ^3.0.0
- **Android Target:** API 35 (Compile SDK 36)
- **Firebase SDKs:**
  - `firebase_auth`: User session management.
  - `cloud_firestore`: Real-time game state and multiplayer syncing.
  - `firebase_analytics`: User attribution (Requires `AD_ID` permission).
  - `cloud_functions`: Server-side game validation.
- **Assets:** Custom sounds (`assets/sounds/`), high-res icon (`assets/icon.png`), and `.env` for configuration.

## 5. Deployment & Compliance Configuration
- **Android Manifest:** Contains `com.google.android.gms.permission.AD_ID`.
- **Signing:** Uses `upload-keystore.jks` with 10,000-day validity. 
- **Privacy Policy:** [Live Link](https://ultimate-tic-tac-toe-359-deaec.web.app/privacy.html)
- **Data Deletion:** [Request URL](https://ultimate-tic-tac-toe-359-deaec.web.app/delete-account.html)

## 6. How to Recreate via AI Prompt
*To reconstruct this app in a new session, provide this prompt to Gemini:*

> "I am building a Flutter app called 'Ultimate TicTacToe'. 
> 1. Create a `MatchReferee` using a Strategy Pattern that evaluates a list of `BoardResult` enums.
> 2. Implement `MajorityMatchRules` (win count majority) and prepare for `StandardMatchRules` (3-in-a-row).
> 3. Set up a `GameController` using Provider to manage a 9x9 nested grid state.
> 4. Configure Firebase Auth for sign-in and Firestore for syncing a `GameModel` containing `boardStates` and `currentTurn`.
> 5. The UI should use a custom `AppTheme` and a responsive `GameScreen` with a `NestedGrid` widget.
> 6. Configure Android for API 35/36 with the `AD_ID` permission."

## 7. Directory Structure
```text
lib/
├── logic/              # MatchReferee, Victory Logic
├── models/             # GameModel, Player, BoardResult
├── services/           # FirebaseService, AIService, SoundManager
├── widgets/            # NestedGrid, GameStatus, MoveHistory
├── main.dart           # App Entry & Provider Setup
├── app_theme.dart      # Design System
└── game_screen.dart    # Primary UI
```

## 8. Development Commands
- **Build:** `flutter build appbundle --release`
- **Deploy Docs:** `firebase deploy --only hosting`
- **Clean:** `flutter clean && flutter pub get`
