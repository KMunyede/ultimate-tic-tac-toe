import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'models/game_model.dart';
import 'models/player.dart'; // Import the new player model

/// A service class for all Firebase interactions.
/// This follows the Repository Pattern, abstracting data sources from the UI.
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Explicitly setting the region to us-central1 to match the HTTP call and ensure consistency.
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Object? get presencedata => null;

  /// Signs in a user anonymously.
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) await _updateUserPresence(userCredential.user!.uid);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Anonymous sign-in error: ${e.message}");
      throw Exception('Could not sign in anonymously. Please try again.');
    }
  }

  /// Creates a new user with email and password.
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) await _updateUserPresence(userCredential.user!.uid);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Email sign-up error: ${e.message}");
      rethrow;
    }
  }

  /// Signs in a user with email and password.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) await _updateUserPresence(userCredential.user!.uid);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Email sign-in error: ${e.message}");
      rethrow;
    }
  }

  /// ARCHITECTURAL ADDITION: Manages user presence in Realtime Database.
  /// This is the key to cleaning up stale games.
  Future<void> _updateUserPresence(String uid) async {
    final presenceRef = _rtdb.ref('status/$uid');
    // Use RTDB's server timestamp for accuracy.
    final presenceData = {
      'isOnline': true,
      'last_online': ServerValue.timestamp,
    };
    // FIX: Use the correct variable name `presenceData`
    await presenceRef.set(presenceData);

    // Set up the onDisconnect hook. This is the magic part.
    // When the user disconnects, Firebase itself will update the status.
    await presenceRef.onDisconnect().set({
      'isOnline': false,
      'last_online': ServerValue.timestamp,
    });
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
      throw Exception('Could not sign out. Please try again.');
    }
  }

  /// Creates a new game document in Firestore.
  Future<String> createGame() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'unauthenticated', message: 'User not logged in.');
    }

    try {
      final gameDoc = await _firestore.collection('games').add({
        'board': List.filled(9, ''),
        // Consolidate player info into a single map for easier access.
        'players': {
          'playerX': {
            'uid': user.uid,
            'displayName': user.displayName ?? 'Player X',
          }
        },
        'player_names': {user.uid: user.displayName ?? 'Player X'}, // Use displayName if available
        'currentPlayerUid': user.uid,
        'status': 'waiting', // 'waiting', 'in_progress', 'finished'
        'winnerUid': null,
        'isDraw': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [FirebaseService] Game created successfully with ID: ${gameDoc.id}');
      return gameDoc.id;
    } on FirebaseException catch (e) {
      print("Error creating game: ${e.message}");
      throw Exception('Could not create the game. Please try again.');
    }
  }

  /// Joins an existing game.
  Future<void> joinGame(String gameId) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'unauthenticated', message: 'User not logged in.');
    }

    final gameRef = _firestore.collection('games').doc(gameId);

    try {
      await _firestore.runTransaction((transaction) async {
        final gameSnapshot = await transaction.get(gameRef);

        if (!gameSnapshot.exists) {
          throw Exception('Game not found.');
        }

        final gameData = gameSnapshot.data();
        if (gameData == null) {
          throw Exception('Game data is invalid.');
        }

        if (gameData['status'] != 'waiting') {
          throw Exception('This game is already in progress or has finished.');
        }

        if (gameData['players']['playerX']['uid'] == user.uid) {
          throw Exception("You can't join your own game.");
        }

        transaction.update(gameRef, {
          // Use dot notation to update a nested object in Firestore.
          'players.playerO': {
            'uid': user.uid,
            'displayName': user.displayName ?? 'Player O',
          },
          // Keep player_names for backward compatibility or simple lookups if needed.
          'player_names.${user.uid}': user.displayName ?? 'Player O', 
          'status': 'in_progress',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ [FirebaseService] User ${user.uid} joined game $gameId successfully.');
      });
    } on FirebaseException catch (e) {
      print("Error joining game: ${e.message}");
      throw Exception('Could not join the game. Please try again.');
    }
  }

  /// Listens to real-time updates for a specific game, returning a stream of `Game` objects.
  Stream<Game> getGameStream(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
          print('✅ [FirebaseService] Received game update for $gameId. Exists: ${snapshot.exists}');
          return Game.fromSnapshot(snapshot);
        });
  }

  /// Makes a move in the game.
  /// This now uses a transaction to ensure atomicity and security.
  Future<void> makeMove(String gameId, int index) async {
    final user = currentUser;
    if (user == null) throw FirebaseAuthException(code: 'unauthenticated', message: 'User not logged in.');
  
    final gameRef = _firestore.collection('games').doc(gameId);
  
    try {
      await _firestore.runTransaction((transaction) async {
        final gameSnapshot = await transaction.get(gameRef);
        if (!gameSnapshot.exists) {
          throw Exception("Game not found.");
        }
  
        final gameData = gameSnapshot.data()!;
        final Game game = Game.fromSnapshot(gameSnapshot);
  
        // --- Validation inside the transaction ---
        if (game.status != GameStatus.in_progress) {
          throw Exception("Game is not in progress.");
        }
        if (game.currentPlayerUid != user.uid) {
          throw Exception("It's not your turn.");
        }
        if (game.board[index] != Player.none) {
          throw Exception("This cell is already taken.");
        }
  
        // --- Apply the move ---
        final newBoard = List<Player>.from(game.board);
        final currentPlayerSymbol = game.isPlayerX(user.uid) ? Player.X : Player.O;
        newBoard[index] = currentPlayerSymbol;
  
        final Map<String, dynamic> updates = {
          // FIX: Correctly map the Player enum back to strings for Firestore.
          // Player.X -> 'X', Player.O -> 'O', Player.none -> ''
          'board': newBoard.map((p) {
            if (p == Player.none) return '';
            return p.name; // .name gives the string representation of the enum, e.g., 'X' or 'O'
          }).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
  
        // --- Check for winner or draw ---
        final winner = _checkWinner(newBoard, currentPlayerSymbol);
        if (winner != null) {
          updates['status'] = 'finished';
          updates['winnerUid'] = user.uid;
        } else if (!newBoard.contains(Player.none)) {
          updates['status'] = 'finished';
          updates['isDraw'] = true;
        } else {
          // --- Switch to the next player ---
          // FIX: Read from the raw gameData map which has the correct nested structure.
          // The `game` model object is not yet updated to reflect this.
          final playerXUid = gameData['players']['playerX']['uid'];
          final playerOUid = gameData['players']['playerO']['uid'];
          updates['currentPlayerUid'] = (user.uid == playerXUid) ? playerOUid : playerXUid;
        }
  
        transaction.update(gameRef, updates);
      });
    } on FirebaseException catch (e) {
      // Handle Firestore-specific errors
      print("Error making move: ${e.message}");
      throw Exception('Could not make the move. Please try again.');
    } catch (e) {
      // Handle our custom validation exceptions
      print("Validation error on move: $e");
      rethrow; // Re-throw to be caught by the UI
    }
  }

  /// A stream of available games that are waiting for a second player.
  Stream<QuerySnapshot> getAvailableGames() {
    return _firestore
        .collection('games')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .limit(20) // To prevent excessive reads and costs
        .snapshots();
  }

  /// Private helper to check for a winner. Can be used within transactions.
  Player? _checkWinner(List<Player> board, Player player) {
    const winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6]             // diagonals
    ];

    for (var combo in winningCombos) {
      if (board[combo[0]] == player &&
          board[combo[1]] == player &&
          board[combo[2]] == player) {
        return player;
      }
    }
    return null;
  }

  /// Calls the Firebase Cloud Function to calculate the AI's move.
  Future<int> getAiMove(List<String> board, String difficulty) async {
    // WORKAROUND: Cloud Functions plugin doesn't support Windows/Linux.
    // We use a direct HTTP call instead.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return _getAiMoveHttp(board, difficulty);
    }

    try {
      final HttpsCallable callable = _functions.httpsCallable('calculateAiMove');
      final result = await callable.call(<String, dynamic>{
        'board': board,
        'difficulty': difficulty,
        'aiPlayer': 'O', 
      });
      return result.data['move'] as int;
    } catch (e) {
      print("Error calling calculateAiMove: $e");
      throw Exception('Failed to get AI move');
    }
  }

  Future<int> _getAiMoveHttp(List<String> board, String difficulty) async {
    final user = currentUser;
    final token = user != null ? await user.getIdToken() : null;
    
    final projectId = _firestore.app.options.projectId;
    // Default region is us-central1.
    final url = Uri.parse('https://us-central1-$projectId.cloudfunctions.net/calculateAiMove');
    print("DEBUG: Attempting to call Cloud Function at: $url");

    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      if (token != null) {
        request.headers.add(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      // The onCall protocol expects data wrapped in "data"
      request.write(jsonEncode({
        "data": {
          'board': board,
          'difficulty': difficulty,
          'aiPlayer': 'O',
        }
      }));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse is Map && jsonResponse.containsKey('result')) {
          final result = jsonResponse['result'];
          // function returns { move: chosenMove }
          if (result is Map && result.containsKey('move')) {
             return result['move'] as int;
          }
        }
        throw Exception("Invalid response format: $responseBody");
      } else {
        throw Exception("HTTP Error ${response.statusCode}: $responseBody");
      }
    } catch (e) {
      print("Error calling calculateAiMove (HTTP): $e");
      throw Exception('Failed to get AI move via HTTP');
    } finally {
      client.close();
    }
  }
}
