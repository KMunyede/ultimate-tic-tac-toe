import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/match_session.dart';
import '../../../services/persistence_service.dart';

class GameRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PersistenceService _persistence;

  GameRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PersistenceService? persistence,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _persistence = persistence ?? PersistenceService();

  /// Saves the current game state to Local Storage, and to Firestore if authenticated.
  Future<void> saveGameState(MatchSession session) async {
    // 1. Always save locally first under key 'saved_game_session'
    try {
      await _persistence.save({'saved_game_session': session.toJson()});
      if (kDebugMode) print('💾 [GameRepository] Game state saved locally.');
    } catch (e) {
      if (kDebugMode) print('❌ [GameRepository] Error saving local state: $e');
    }

    final user = _auth.currentUser;
    if (user == null) return;

    // 2. Save to cloud
    try {
      await _firestore.collection('game_states').doc(user.uid).set({
        'session': session.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print('✅ [GameRepository] Game state saved to Firestore.');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found' || e.message?.contains('database') == true) {
        if (kDebugMode) {
          print('⚠️ [GameRepository] Firestore database not found or not initialized.');
        }
      } else {
        if (kDebugMode) print('❌ [GameRepository] Error saving to Firestore: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [GameRepository] Unexpected error: $e');
    }
  }

  /// Loads the saved game state from Firestore, with a local storage fallback.
  Future<MatchSession?> loadGameState() async {
    final user = _auth.currentUser;
    if (user == null) {
      return await _loadLocalFallback();
    }

    try {
      // Fast timeout to gracefully fallback if GMS broker fails on emulators
      final doc = await _firestore
          .collection('game_states')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists && doc.data() != null) {
        final sessionData = doc.data()!['session'] as Map<String, dynamic>;
        if (kDebugMode) print('✅ [GameRepository] Loaded from cloud.');
        
        // Sync to local cache
        try {
          await _persistence.save({'saved_game_session': sessionData});
        } catch (_) {}
        
        return MatchSession.fromJson(sessionData);
      }
    } on TimeoutException catch (_) {
      if (kDebugMode) print('ℹ️ [GameRepository] Cloud sync timed out. Loading offline state.');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('⚠️ [GameRepository] Firestore load failed: ${e.code}');
    } catch (e) {
      if (kDebugMode) print('❌ [GameRepository] Unexpected error loading state: $e');
    }

    return await _loadLocalFallback();
  }

  Future<MatchSession?> _loadLocalFallback() async {
    try {
      final localData = await _persistence.loadAll();
      if (localData.containsKey('saved_game_session')) {
        final sessionData = Map<String, dynamic>.from(localData['saved_game_session']);
        if (kDebugMode) print('💾 [GameRepository] Loaded from local fallback.');
        return MatchSession.fromJson(sessionData);
      }
    } catch (e) {
      if (kDebugMode) print('❌ [GameRepository] Error loading local fallback: $e');
    }
    return null;
  }
}
