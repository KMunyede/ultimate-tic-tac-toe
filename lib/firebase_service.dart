import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Returns a Map containing 'boardIndex' and 'cellIndex' from the AI, or null on failure.
  Future<Map<String, dynamic>?> getAiMove(
      List<dynamic> boards, String player, String difficulty) async {
    if (kDebugMode) {
      print('FirebaseService: Calling getAiMove (Diff: $difficulty, Player: $player)');
    }

    try {
      final callable = _functions.httpsCallable('getAiMove');

      final response = await callable.call({
        'board': boards.isNotEmpty ? boards[0] : [],
        'boards': boards,
        'player': player,
        'difficulty': difficulty,
      });

      final data = response.data;
      if (kDebugMode) print('FirebaseService: Received raw data: $data');

      if (data == null) return null;

      // Scenario A: Function returns { boardIndex: X, cellIndex: Y }
      if (data is Map &&
          data.containsKey('boardIndex') &&
          data.containsKey('cellIndex')) {
        return {
          'boardIndex': (data['boardIndex'] as num).toInt(),
          'cellIndex': (data['cellIndex'] as num).toInt(),
        };
      }

      // Scenario B: Function returns { move: { boardIndex: X, cellIndex: Y } }
      if (data is Map && data.containsKey('move') && data['move'] is Map) {
        final move = data['move'] as Map;
        return {
          'boardIndex': (move['boardIndex'] as num?)?.toInt() ?? 0,
          'cellIndex': (move['cellIndex'] as num?)?.toInt() ?? 0,
        };
      }

      // Scenario C: Function returns { move: 4 } (Legacy single board)
      if (data is Map && data.containsKey('move') && data['move'] is num) {
        return {
          'boardIndex': 0,
          'cellIndex': (data['move'] as num).toInt(),
        };
      }

      // Scenario D: Function returns raw int 4 (Legacy single board raw)
      if (data is num) {
        return {
          'boardIndex': 0,
          'cellIndex': data.toInt(),
        };
      }

      if (kDebugMode) print('FirebaseService: Unknown data format or empty response.');
      return null;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('FirebaseFunctionsException: [${e.code}] ${e.message}');
        print('Details: ${e.details}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('General Exception in FirebaseService: $e');
      return null;
    }
  }
}
