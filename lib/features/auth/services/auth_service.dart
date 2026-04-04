import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign in as a Guest (Anonymous)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Anonymous Sign In Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Google Sign-In with industry-standard guest-linking support
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Industry Practice: If user is already signed in anonymously, link the accounts
      // to preserve guest session progress.
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        return await _auth.currentUser!.linkWithCredential(credential);
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
  Future<UserCredential?> linkEmailPassword(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final user = _auth.currentUser;
      
      if (user != null) {
        return await user.linkWithCredential(credential);
      }
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No current guest user found to link.',
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Linking Email Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Create a new Email/Password account
  Future<UserCredential?> signUp(String email, String password) async {
    try {
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
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      if (kDebugMode) print('Sign Out Error: $e');
    }
  }
}
