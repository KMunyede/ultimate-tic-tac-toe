import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
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
    // Explicitly using named arguments to satisfy the analyzer
    final request = AiRequest(
      boards: boards,
      boardResults: boardResults,
      player: player,
      difficulty: difficulty,
      boardCount: boardCount,
    );

    try {
      final callable = _functions.httpsCallable('getAiMove');
      final response = await callable.call(request.toJson());

      if (response.data == null) return null;
      return AiMoveResponse.fromJson(response.data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) print('Firebase Error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) print('AI Service Error: $e');
      return null;
    }
  }
}
