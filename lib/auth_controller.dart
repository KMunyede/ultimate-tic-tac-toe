import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class AuthController with ChangeNotifier {
  final FirebaseService _firebaseService;

  AuthController(this._firebaseService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null; // Clear previous errors
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _setLoading(true);
    try {
      await _firebaseService.signInAnonymously();
      // No need to call _setLoading(false) because the auth state stream
      // will navigate away from the auth screen on success.
    } on Exception catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthException(e.code));
    } on Exception catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> createUserWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _firebaseService.createUserWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthException(e.code));
    } on Exception catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> signOut() async {
    // We don't typically need a loading state for sign-out as it's very fast
    // and the UI will rebuild via the authStateChanges stream in main.dart anyway.
    try {
      await _firebaseService.signOut();
    } on Exception catch (e) {
      // It's good practice to handle potential errors, even if rare.
      // In a real app, you might show a snackbar. For now, printing is sufficient.
      print('Sign out error: ${e.toString()}');
    }
  }

  // Helper to provide user-friendly error messages
  String _mapFirebaseAuthException(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'email-already-in-use': return 'An account already exists for that email.';
      case 'weak-password': return 'The password provided is too weak.';
      default: return 'An unknown error occurred. Please try again.';
    }
  }
}