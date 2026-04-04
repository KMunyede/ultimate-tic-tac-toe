// lib/firebase_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_models.dart';
import '../models/game_enums.dart';
import '../models/player.dart';
import '../models/match_session.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves the current game state to Firestore
  Future<void> saveGameState(MatchSession session) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('game_states').doc(user.uid).set({
        'session': session.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error saving game state: $e');
    }
  }

  /// Loads the saved game state from Firestore
  Future<MatchSession?> loadGameState() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('game_states').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final sessionData = doc.data()!['session'] as Map<String, dynamic>;
        return MatchSession.fromJson(sessionData);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading game state: $e');
    }
    return null;
  }

  Future<AiMoveResponse?> getAiMove({
    required List<List<String>> boards,
    required List<String> boardResults,
    required Player player,
    required AiDifficulty difficulty,
    required GameRuleSet ruleSet,
    required int boardCount,
    int? forcedBoardIndex,
  }) async {
    final request = AiRequest(
      boards: boards,
      boardResults: boardResults,
      player: player,
      difficulty: difficulty,
      ruleSet: ruleSet,
      boardCount: boardCount,
      forcedBoardIndex: forcedBoardIndex,
    );

    // REST call for Windows
    if (!kIsWeb && Platform.isWindows) {
      return await _getAiMoveRest(request);
    }

    try {
      final callable = _functions.httpsCallable(
        'getAiMove',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final response = await callable.call(request.toJson());

      if (response.data == null) return null;

      return AiMoveResponse.fromJson(Map<String, dynamic>.from(response.data));
    } catch (e) {
      return null;
    }
  }

  Future<AiMoveResponse?> _getAiMoveRest(AiRequest request) async {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final region = dotenv.env['FIREBASE_REGION'] ?? 'us-central1';

    if (projectId == null || projectId.isEmpty) {
      return null;
    }

    final url = Uri.https(
      '$region-$projectId.cloudfunctions.net',
      'getAiMove',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': request.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (decoded.containsKey('result') && decoded['result'] != null) {
          return AiMoveResponse.fromJson(
            Map<String, dynamic>.from(decoded['result']),
          );
        }
      }
    } catch (e) {
      // Silently ignore or handle error
    }
    return null;
  }
}
