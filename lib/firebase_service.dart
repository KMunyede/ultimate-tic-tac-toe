import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<int?> getAiMove(List<dynamic> board, String player) async {
    try {
      final callable = _functions.httpsCallable('getAiMove');
      final response = await callable.call<Map<String, dynamic>>({
        'board': board,
        'player': player,
      });

      if (response.data.containsKey('move')) {
        return response.data['move'] as int?;
      }
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Failed to call getAiMove function: ${e.code} - ${e.message}');
      }
    }
    return null;
  }
}
