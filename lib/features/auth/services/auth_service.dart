import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/player_stats.dart';
import '../../../services/stats_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    // Required initialization for version 7.2.0+
    // Note: Scopes are no longer passed here in 7.2.0;
    // they are passed to authenticate() or authorizeScopes() instead.
    _initializeGoogleSignInSafe();
  }

  void _initializeGoogleSignInSafe() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      if (kDebugMode) {
        print("Safely caught Google Sign-In initialization error: $e");
      }
    }
  }

  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign in as a Guest (Anonymous)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Anonymous Sign In Error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  /// Shared helper to delete the old anonymous Firestore user doc and merge stats into the new user doc
  Future<void> mergeAnonymousStats(String oldUid, UserCredential userCred) async {
    try {
      final oldDocRef = FirebaseFirestore.instance.collection('users').doc(oldUid);
      final oldSnapshot = await oldDocRef.get();
      final oldData = oldSnapshot.exists ? oldSnapshot.data() : null;

      if (oldSnapshot.exists) {
        try {
          await oldDocRef.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Safely caught old guest doc deletion error: $e');
          }
        }
      }

      final newUid = userCred.user?.uid;
      if (newUid != null && oldData != null) {
        final newDocRef = FirebaseFirestore.instance.collection('users').doc(newUid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final newSnapshot = await transaction.get(newDocRef);
          final oldStats = PlayerStats.fromJson(
            Map<String, dynamic>.from(oldData['player_stats'] ?? {}),
          );

          PlayerStats newStats = const PlayerStats();
          if (newSnapshot.exists && newSnapshot.data() != null) {
            newStats = PlayerStats.fromJson(
              Map<String, dynamic>.from(newSnapshot.data()!['player_stats'] ?? {}),
            );
          }

          final mergedStats = PlayerStats(
            totalXp: newStats.totalXp + oldStats.totalXp,
            winsVsAiEasy: newStats.winsVsAiEasy + oldStats.winsVsAiEasy,
            lossesVsAiEasy: newStats.lossesVsAiEasy + oldStats.lossesVsAiEasy,
            drawsVsAiEasy: newStats.drawsVsAiEasy + oldStats.drawsVsAiEasy,
            winsVsAiMedium: newStats.winsVsAiMedium + oldStats.winsVsAiMedium,
            lossesVsAiMedium: newStats.lossesVsAiMedium + oldStats.lossesVsAiMedium,
            drawsVsAiMedium: newStats.drawsVsAiMedium + oldStats.drawsVsAiMedium,
            winsVsAiHard: newStats.winsVsAiHard + oldStats.winsVsAiHard,
            lossesVsAiHard: newStats.lossesVsAiHard + oldStats.lossesVsAiHard,
            drawsVsAiHard: newStats.drawsVsAiHard + oldStats.drawsVsAiHard,
            winsLocalPvp: newStats.winsLocalPvp + oldStats.winsLocalPvp,
            lossesLocalPvp: newStats.lossesLocalPvp + oldStats.lossesLocalPvp,
            drawsLocalPvp: newStats.drawsLocalPvp + oldStats.drawsLocalPvp,
            currentStreak: newStats.currentStreak > oldStats.currentStreak
                ? newStats.currentStreak
                : oldStats.currentStreak,
            maxStreak: newStats.maxStreak > oldStats.maxStreak
                ? newStats.maxStreak
                : oldStats.maxStreak,
          );

          transaction.set(newDocRef, {
            'player_stats': mergedStats.toJson(),
            'mergedFrom': oldUid,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
      }

      if (userCred.user != null) {
        await StatsService.instance?.syncWithFirestore(userCred.user!.uid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Safely caught stats merge error: $e');
      }
    }
  }

  /// Google Sign-In with industry-standard guest-linking support
  Future<UserCredential?> signInWithGoogle({AuthCredential? mockCredential}) async {
    try {
      AuthCredential credential;
      if (mockCredential != null) {
        credential = mockCredential;
      } else {
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
      }

      // Industry Practice: If user is already signed in anonymously, link the accounts
      // to preserve guest session progress.
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final cred = await currentUser.linkWithCredential(credential);
          if (cred.user != null) {
            await StatsService.instance?.syncWithFirestore(cred.user!.uid);
          }
          return cred;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
            final oldUid = currentUser.uid;
            final userCred = await _auth.signInWithCredential(credential);
            await mergeAnonymousStats(oldUid, userCred);
            return userCred;
          }
          rethrow;
        }
      }

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Google Sign In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      if (kDebugMode) print('Google Sign In General Error: $e');
      rethrow;
    }
  }

  /// Link an existing Guest session to Email/Password
  Future<UserCredential?> linkEmailPassword(
      String email, String password) async {
    return signUp(email, password);
  }

  /// Create a new Email/Password account with guest session linking & fallback-merge support
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final cred = await currentUser.linkWithCredential(credential);
          if (cred.user != null) {
            await StatsService.instance?.syncWithFirestore(cred.user!.uid);
          }
          return cred;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
            final oldUid = currentUser.uid;
            final userCred = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            await mergeAnonymousStats(oldUid, userCred);
            return userCred;
          }
          rethrow;
        }
      }

      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Sign Up Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Standard Email/Password Sign In
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Sign In Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Request a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('--- PASSWORD RESET DEBUG ---');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('---------------------------');
      }
      rethrow;
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Google Sign-In signout is platform-dependent
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      if (kDebugMode) print('Sign Out Error: $e');
    }
  }
}
