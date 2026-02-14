import 'player.dart';
import 'game_enums.dart';

class AiRequest {
  final List<List<String>> boards;
  final List<String> boardResults; // "playerX", "playerO", "draw", "active"
  final Player player;
  final AiDifficulty difficulty;
  final int boardCount;

  AiRequest({
    required this.boards,
    required this.boardResults,
    required this.player,
    required this.difficulty,
    required this.boardCount,
  });

  Map<String, dynamic> toJson() => {
        'boards': boards,
        'boardResults': boardResults,
        'player': player.name,
        'difficulty': difficulty.name,
        'boardCount': boardCount,
        // Legacy support
        'board': boards.isNotEmpty ? boards[0] : [],
      };
}

class AiMoveResponse {
  final int? boardIndex; 
  final int cellIndex;

  AiMoveResponse({
    this.boardIndex,
    required this.cellIndex,
  });

  factory AiMoveResponse.fromJson(dynamic json) {
    if (json is Map) {
      if (json.containsKey('boardIndex') && json.containsKey('cellIndex')) {
        return AiMoveResponse(
          boardIndex: (json['boardIndex'] as num).toInt(),
          cellIndex: (json['cellIndex'] as num).toInt(),
        );
      }
      
      if (json.containsKey('move')) {
        final move = json['move'];
        if (move is Map) {
          return AiMoveResponse(
            boardIndex: (move['boardIndex'] as num?)?.toInt(),
            cellIndex: (move['cellIndex'] as num?)?.toInt() ?? 0,
          );
        }
        if (move is num) {
          return AiMoveResponse(boardIndex: null, cellIndex: move.toInt());
        }
      }
    }
    if (json is num) {
      return AiMoveResponse(boardIndex: null, cellIndex: json.toInt());
    }
    throw FormatException("Invalid AI response format: $json");
  }
}
