import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service class for all Firebase interactions.
/// This follows the Repository Pattern, abstracting data sources from the UI.
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user anonymously.
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors or rethrow a generic one
      print("Anonymous sign-in error: ${e.message}");
      throw Exception('Could not sign in anonymously. Please try again.');
    }
  }

  /// Creates a new user with email and password.
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  /// Signs in a user with email and password.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
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
  /// Returns the gameId of the newly created game.
  Future<String> createGame() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'unauthenticated', message: 'User not logged in.');
    }

    try {
      final gameDoc = await _firestore.collection('games').add({
        'board': List.filled(9, ''), // Use empty string for none
        'players': {'playerX_uid': user.uid},
        'player_names': {user.uid: user.displayName ?? 'Player X'},
        'currentPlayerUid': user.uid,
        'status': 'waiting', // 'waiting', 'in_progress', 'finished'
        'winnerUid': null,
        'isDraw': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return gameDoc.id;
    } on FirebaseException catch (e) {
      // Log the error for debugging
      print("Error creating game: ${e.message}");
      // Re-throw a more user-friendly error
      throw Exception('Could not create the game. Please try again.');
    }
  }

  /// Joins an existing game.
  /// This uses a transaction to prevent race conditions where two players
  /// might join the same game simultaneously.
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

        if (gameData['players']['playerX_uid'] == user.uid) {
          throw Exception("You can't join your own game.");
        }

        transaction.update(gameRef, {
          'players.playerO_uid': user.uid,
          'player_names.${user.uid}': user.displayName ?? 'Player O',
          'status': 'in_progress',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      print("Error joining game: ${e.message}");
      throw Exception('Could not join the game. Please try again.');
    }
    // The exceptions from inside the transaction will be re-thrown here.
  }

  /// Listens to real-time updates for a specific game.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getGameStream(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots();
  }

  /// Makes a move in the game.
  /// The game logic (e.g., checking for a winner) should be handled by a Cloud Function
  /// triggered by this update for a secure online game. For now, we update the client.
  Future<void> makeMove(String gameId, int index, String playerSymbol, String nextPlayerUid) async {
    final user = currentUser;
    if (user == null) throw FirebaseAuthException(code: 'unauthenticated', message: 'User not logged in.');

    // In a real-world app, you would not update the board directly.
    // Instead, you'd write the move to a 'moves' subcollection and have a Cloud Function
    // validate it and update the board state to prevent cheating.
    // For this project, direct update is acceptable.
    await _firestore.collection('games').doc(gameId).update({
      'board.$index': playerSymbol,
      'currentPlayerUid': nextPlayerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the game when a winner is found or it's a draw.
  Future<void> declareOutcome(String gameId, {String? winnerUid, bool isDraw = false}) async {
     await _firestore.collection('games').doc(gameId).update({
      'status': 'finished',
      'winnerUid': winnerUid,
      'isDraw': isDraw,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}