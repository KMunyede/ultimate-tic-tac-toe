// lib/firebase_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'models/ai_models.dart';
import 'models/game_enums.dart';
import 'models/player.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<AiMoveResponse?> getAiMove({
    required List<List<String>> boards,
    required List<String> boardResults,
    required Player player,
    required AiDifficulty difficulty,
    required int boardCount,
  }) async {
    final request = AiRequest(
      boards: boards,
      boardResults: boardResults,
      player: player,
      difficulty: difficulty,
      boardCount: boardCount,
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
      if (kDebugMode) print('Firebase AI Exception: $e');
      return null;
    }
  }

  Future<AiMoveResponse?> _getAiMoveRest(AiRequest request) async {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final region = dotenv.env['FIREBASE_REGION'] ?? 'us-central1';

    if (projectId == null || projectId.isEmpty) {
      if (kDebugMode) {
        print('REST AI Error: FIREBASE_PROJECT_ID is missing in .env');
      }
      return null;
    }

    final url = Uri.https(
      '$region-$projectId.cloudfunctions.net',
      '/getAiMove',
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
      if (kDebugMode) print('REST AI Exception: $e');
    }
    return null;
  }
}
