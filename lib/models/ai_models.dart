import 'player.dart';
import 'game_enums.dart';

class AiRequest {
  final List<List<String>> boards;
  final List<String> boardResults; // "playerX", "playerO", "draw", "active"
  final Player player;
  final AiDifficulty difficulty;
  final GameRuleSet ruleSet;
  final int boardCount;
  final int? forcedBoardIndex;

  AiRequest({
    required this.boards,
    required this.boardResults,
    required this.player,
    required this.difficulty,
    required this.ruleSet,
    required this.boardCount,
    this.forcedBoardIndex,
  });

  Map<String, dynamic> toJson() => {
    'boards': boards,
    'boardResults': boardResults,
    'player': player == Player.X ? "X" : "O",
    'difficulty': difficulty.name,
    'ruleSet': ruleSet.name,
    'boardCount': boardCount,
    'forcedBoardIndex': forcedBoardIndex,
    // Legacy support
    'board': boards.isNotEmpty ? boards[0] : [],
  };
}

class AiMoveResponse {
  final int? boardIndex;
  final int cellIndex;

  AiMoveResponse({this.boardIndex, required this.cellIndex});

  static int? _safeInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val);
    }
    return null;
  }

  factory AiMoveResponse.fromJson(dynamic json) {
    if (json is Map) {
      int? boardIdx;
      if (json.containsKey('boardIndex') && json['boardIndex'] != null) {
        boardIdx = _safeInt(json['boardIndex']);
      }

      int cellIdx = 0;
      if (json.containsKey('cellIndex') && json['cellIndex'] != null) {
        cellIdx = _safeInt(json['cellIndex']) ?? 0;
      } else if (json.containsKey('move')) {
        final move = json['move'];
        if (move is Map) {
          boardIdx = _safeInt(move['boardIndex']);
          cellIdx = _safeInt(move['cellIndex']) ?? 0;
        } else if (move is num) {
          cellIdx = move.toInt();
        } else if (move is String) {
          cellIdx = int.tryParse(move) ?? 0;
        }
      }
      return AiMoveResponse(boardIndex: boardIdx, cellIndex: cellIdx);
    }
    if (json is num) {
      return AiMoveResponse(boardIndex: null, cellIndex: json.toInt());
    }
    if (json is String) {
      return AiMoveResponse(boardIndex: null, cellIndex: int.tryParse(json) ?? 0);
    }
    throw FormatException("Invalid AI response format: $json");
  }
}
