import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<int?> getAiMove(List<dynamic> board, String player, String difficulty) async {
    if (kDebugMode) {
      print('Attempting to call Firebase Function: getAiMove with difficulty: $difficulty...');
    }

    try {
      final callable = _functions.httpsCallable('getAiMove');
      final response = await callable.call<Map<String, dynamic>>({
        'board': board,
        'player': player,
        'difficulty': difficulty, // Added the missing parameter
      });

      if (response.data.containsKey('move')) {
        if (kDebugMode) {
          print('Successfully received AI move from Firebase: ${response.data['move']}');
        }
        return response.data['move'] as int?;
      }
      return null;
    } on FirebaseFunctionsException {
      // Re-throw the exception to be caught by the caller
      rethrow;
    }
  }
}
