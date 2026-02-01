const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

exports.getAiMove = onCall((request) => {
  // 1. Extract Data safely
  const data = request.data;
  const board = data.board; // Array of 9 strings/nulls/ints
  const player = data.player; // "X" or "O" (The AI)
  const difficulty = data.difficulty || "hard";

  // 2. Validate Input
  if (!board || board.length !== 9) {
    throw new HttpsError("invalid-argument", "Invalid board data");
  }

  // 3. Get Available Moves
  const availableMoves = getAvailableMoves(board);

  // CRITICAL FIX: Handle Draw/Full Board immediately
  if (availableMoves.length === 0) {
    return { move: -1 }; // Game is over, no moves possible.
  }

  // 4. Calculate Best Move
  let bestMove;

  // If Easy, just pick random
  if (difficulty === "easy") {
    bestMove = availableMoves[Math.floor(Math.random() * availableMoves.length)];
  } else {
    // Hard/Medium: Use Minimax
    // Optimization: If it's the very first move of the game, pick center (4) or corner (0) instantly to save CPU.
    if (availableMoves.length === 9) {
      bestMove = 4;
    } else if (availableMoves.length === 8 && board[4] === null) {
      bestMove = 4;
    } else {
      const isMaximizing = true; // AI wants to maximize its own score
      const opponent = player === "X" ? "O" : "X";

      // Depth limited to preventing timeouts, though 3x3 is fast enough for full depth.
      const result = minimax(board, player, opponent, 0, isMaximizing);
      bestMove = result.index;
    }
  }

  // 5. SAFETY NET (The Fix for your Crash)
  // If Minimax returned -1 (because it thinks it will lose anyway),
  // we force it to pick the first available move so the game continues.
  if (bestMove === -1 || bestMove === undefined) {
    logger.warn("Minimax failed to find a move. Using fallback.");
    bestMove = availableMoves[0];
  }

  logger.info(`AI (${player}) Chose move: ${bestMove}`);
  return { move: bestMove };
});

// --- HELPER FUNCTIONS ---

function getAvailableMoves(board) {
  const moves = [];
  for (let i = 0; i < board.length; i++) {
    // Check for null, empty string, or explicit "null" string depending on how Flutter sends it
    if (board[i] === null || board[i] === "" || board[i] === "null") {
      moves.push(i);
    }
  }
  return moves;
}

function checkWinner(board, player) {
  const winConditions = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
    [0, 4, 8], [2, 4, 6], // Diagonals
  ];

  for (const condition of winConditions) {
    const [a, b, c] = condition;
    // Check if board[a] matches player, ignoring empty/null
    if (board[a] === player && board[b] === player && board[c] === player) {
      return true;
    }
  }
  return false;
}

// The Recursive Brain
function minimax(newBoard, aiPlayer, humanPlayer, depth, isMaximizing) {
  const availSpots = getAvailableMoves(newBoard);

  // Terminal States (End of recursion)
  if (checkWinner(newBoard, humanPlayer)) {
    return { score: -10 + depth }; // Human won (Bad for AI)
  }
  if (checkWinner(newBoard, aiPlayer)) {
    return { score: 10 - depth }; // AI won (Good for AI)
  }
  if (availSpots.length === 0) {
    return { score: 0 }; // Draw
  }

  const moves = [];

  // Loop through available spots
  for (let i = 0; i < availSpots.length; i++) {
    const move = {};
    move.index = availSpots[i];

    // Make the move temporarily
    newBoard[availSpots[i]] = isMaximizing ? aiPlayer : humanPlayer;

    // Recursion
    if (isMaximizing) {
      // If we are AI, next turn is Human (minimizing)
      const result = minimax(newBoard, aiPlayer, humanPlayer, depth + 1, false);
      move.score = result.score;
    } else {
      // If we are Human, next turn is AI (maximizing)
      const result = minimax(newBoard, aiPlayer, humanPlayer, depth + 1, true);
      move.score = result.score;
    }

    // Undo the move
    newBoard[availSpots[i]] = null;
    moves.push(move);
  }

  // Pick the best move from the array
  let bestMove;
  if (isMaximizing) {
    let bestScore = -10000;
    for (let i = 0; i < moves.length; i++) {
      if (moves[i].score > bestScore) {
        bestScore = moves[i].score;
        bestMove = i;
      }
    }
  } else {
    let bestScore = 10000;
    for (let i = 0; i < moves.length; i++) {
      if (moves[i].score < bestScore) {
        bestScore = moves[i].score;
        bestMove = i;
      }
    }
  }

  return moves[bestMove];
}
