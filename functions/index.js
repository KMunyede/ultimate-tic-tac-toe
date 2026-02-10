const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

exports.getAiMove = onCall((request) => {
  const data = request.data;
  // Support both 'boards' (multi) and 'board' (single)
  let boards = data.boards;
  if (!boards && data.board) {
    boards = [data.board];
  }

  const player = data.player || "O";
  const difficulty = data.difficulty || "hard";

  if (!boards || !Array.isArray(boards)) {
    throw new HttpsError("invalid-argument", "Invalid boards data provided.");
  }

  logger.info(`AI Turn: ${player}, Difficulty: ${difficulty}, Board Count: ${boards.length}`);

  // 1. Find ALL valid moves across ALL boards that are not yet decided (won/lost)
  const allPossibleMoves = [];
  for (let b = 0; b < boards.length; b++) {
    const board = boards[b];

    // A board is playable if no one has won it yet
    const winner = getBoardWinner(board);
    if (!winner) {
      for (let c = 0; c < board.length; c++) {
        // Handle various ways an empty cell might be represented
        const val = board[c];
        if (val === "" || val === null || val === "none" || val === undefined) {
          allPossibleMoves.push({ boardIndex: b, cellIndex: c });
        }
      }
    }
  }

  // 2. If no moves exist anywhere, the match is over
  if (allPossibleMoves.length === 0) {
    logger.info("Match is complete. No moves available.");
    return { move: -1 };
  }

  // 3. Strategic Move Selection
  let chosen;

  if (difficulty === "easy") {
    chosen = allPossibleMoves[Math.floor(Math.random() * allPossibleMoves.length)];
  } else {
    // Priority 1: Can I win any board right now?
    for (const move of allPossibleMoves) {
      const tempBoard = [...boards[move.boardIndex]];
      tempBoard[move.cellIndex] = player;
      if (checkWin(tempBoard, player)) {
        chosen = move;
        break;
      }
    }

    // Priority 2: Do I need to block the opponent from winning any board?
    if (!chosen) {
      const opponent = player === "X" ? "O" : "X";
      for (const move of allPossibleMoves) {
        const tempBoard = [...boards[move.boardIndex]];
        tempBoard[move.cellIndex] = opponent;
        if (checkWin(tempBoard, opponent)) {
          chosen = move;
          break;
        }
      }
    }

    // Priority 3: Strategic positions (Centers/Corners)
    if (!chosen) {
      const centers = allPossibleMoves.filter(m => m.cellIndex === 4);
      if (centers.length > 0) {
        chosen = centers[Math.floor(Math.random() * centers.length)];
      } else {
        const corners = allPossibleMoves.filter(m => [0, 2, 6, 8].includes(m.cellIndex));
        if (corners.length > 0) {
          chosen = corners[Math.floor(Math.random() * corners.length)];
        }
      }
    }

    // Fallback: Random move
    if (!chosen) {
      chosen = allPossibleMoves[Math.floor(Math.random() * allPossibleMoves.length)];
    }
  }

  logger.info(`Decision: Board ${chosen.boardIndex}, Cell ${chosen.cellIndex}`);

  return {
    boardIndex: chosen.boardIndex,
    cellIndex: chosen.cellIndex
  };
});

function getBoardWinner(board) {
  if (checkWin(board, "X")) return "X";
  if (checkWin(board, "O")) return "O";
  return null;
}

function checkWin(board, p) {
  const wins = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];
  return wins.some(line => line.every(idx => board[idx] === p));
}
