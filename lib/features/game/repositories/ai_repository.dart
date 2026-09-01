import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../models/game_board.dart';
import '../../../models/ai_models.dart';
import '../../../models/game_enums.dart';
import '../../../models/player.dart';

class AiRepository {
  final FirebaseFunctions _functions;

  AiRepository({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: dotenv.env['FIREBASE_REGION'] ?? 'us-central1',
            );

  /// Fetches AI move from Cloud Functions with automatic REST fallback for Windows.
  Future<AiMoveResponse?> getAiMove({
    required List<GameBoard> boards,
    required Player player,
    required AiDifficulty difficulty,
    required GameRuleSet ruleSet,
    required int boardCount,
    int? forcedBoardIndex,
  }) async {
    // Serialization
    final boardsData = boards
        .map((b) => b.cells.map((c) => c == Player.none ? "" : c.name).toList())
        .toList();

    final boardResults = boards.map((b) {
      if (b.winner == Player.X) return "playerX";
      if (b.winner == Player.O) return "playerO";
      if (b.isDraw) return "draw";
      return "active";
    }).toList();

    final request = AiRequest(
      boards: boardsData,
      boardResults: boardResults,
      player: player,
      difficulty: difficulty,
      ruleSet: ruleSet,
      boardCount: boardCount,
      forcedBoardIndex: forcedBoardIndex,
    );

    // REST call for Windows/Desktop (C++ SDK compatibility fallback)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return await _getAiMoveRest(request);
    }

    try {
      final callable = _functions.httpsCallable(
        'getAiMove',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );

      final response = await callable.call(request.toJson());
      if (response.data == null) return null;

      return AiMoveResponse.fromJson(Map<String, dynamic>.from(response.data));
    } catch (e) {
      if (kDebugMode) print('❌ [AiRepository] Cloud Function Error: $e');
      return null;
    }
  }

  Future<AiMoveResponse?> _getAiMoveRest(AiRequest request) async {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final region = dotenv.env['FIREBASE_REGION'] ?? 'us-central1';
    final customUrl = dotenv.env['FIREBASE_AI_FUNCTION_URL'];

    if (projectId == null || projectId.isEmpty) {
      return null;
    }

    final url = customUrl != null && customUrl.isNotEmpty
        ? Uri.parse(customUrl)
        : Uri.https(
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (decoded.containsKey('result') && decoded['result'] != null) {
          return AiMoveResponse.fromJson(
            Map<String, dynamic>.from(decoded['result']),
          );
        }
      }
    } catch (_) {
      // Silently ignore or handle error
    }
    return null;
  }
}
