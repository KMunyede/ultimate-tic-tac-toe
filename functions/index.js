const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

exports.getAiMove = onCall((request) => {
  // --- Destructure the NEW, richer payload from the app ---
  const {
    boards,
    boardResults, // ["active", "playerX", "active"]
    player,
    difficulty,
    boardCount,
  } = request.data;

  // --- Input Validation ---
  if (!boards || !Array.isArray(boards) || !boardResults) {
    throw new HttpsError("invalid-argument", "Missing required game data.");
  }

  const opponent = player === "X" ? "O" : "X";
  const requiredWins = getRequiredWins(boardCount);

  logger.info(
    `AI Turn: ${player} vs ${opponent}, Diff: ${difficulty}, ` +
    `Boards: ${boardCount}, WinsNeeded: ${requiredWins}`,
  );

  // --- Move Scoring Logic ---
  const scoredMoves = [];

  for (let b = 0; b < boards.length; b++) {
    // Only consider moves on boards that are still active
    if (boardResults[b] !== "active") continue;

    for (let c = 0; c < 9; c++) {
      if (boards[b][c] === "" || boards[b][c] === "none") {
        let score = 0;
        const move = { boardIndex: b, cellIndex: c };

        // --- Hard & Medium Difficulty Logic ---
        if (difficulty === "hard" || difficulty === "medium") {
          // Priority 1: Does this move win me the entire match? (+1,000,000)
          if (
            isWinningMoveForBoard(boards[b], c, player) &&
            doesBoardWinCompleteMatch(b, player, boardResults, requiredWins)
          ) {
            score += 1000000;
          }

          // Priority 2: Do I need to block the opponent from winning the match? (+500,000)
          if (
            isWinningMoveForBoard(boards[b], c, opponent) &&
            doesBoardWinCompleteMatch(b, opponent, boardResults, requiredWins)
          ) {
            score += 500000;
          }

          // Priority 3: Does this move win me just THIS board? (+15,000)
          if (isWinningMoveForBoard(boards[b], c, player)) {
            score += 15000;
          }

          // Priority 4: Do I need to block the opponent on THIS board? (+10,000)
          if (isWinningMoveForBoard(boards[b], c, opponent)) {
            score += 10000;
          }

          // Positional bonuses (Center, Corners)
          if (c === 4) score += 500;
          if ([0, 2, 6, 8].includes(c)) score += 200;
        }

        // Easy just gets a random score to shuffle moves
        if (difficulty === "easy") {
          score = Math.random() * 100;
        }

        scoredMoves.push({ ...move, score });
      }
    }
  }

  // --- Decision Making ---
  if (scoredMoves.length === 0) {
    logger.warn("No valid moves found. Game should have ended.");
    return { boardIndex: 0, cellIndex: 0 }; // Should be unreachable
  }

  // Sort by highest score first
  scoredMoves.sort((a, b) => b.score - a.score);

  const bestScore = scoredMoves[0].score;
  const bestMoves = scoredMoves.filter((m) => m.score === bestScore);

  // If multiple moves have the same top score, pick one randomly
  const chosenMove = bestMoves[Math.floor(Math.random() * bestMoves.length)];

  logger.info(
    `Best Score: ${bestScore}. Chose move: Board ${chosenMove.boardIndex}, ` +
    `Cell ${chosenMove.cellIndex} from ${bestMoves.length} top-tier options.`,
  );

  return { boardIndex: chosenMove.boardIndex, cellIndex: chosenMove.cellIndex };
});

// --- Helper Functions ---

/**
 * Checks if placing a piece at a cell index wins the board.
 * @param {Array} board The 9-cell board state.
 * @param {number} cellIndex The cell index to test.
 * @param {string} player The player ("X" or "O").
 * @return {boolean} True if the move wins the board.
 */
function isWinningMoveForBoard(board, cellIndex, player) {
  const tempBoard = [...board];
  tempBoard[cellIndex] = player;
  return checkWin(tempBoard, player);
}

/**
 * Checks if winning a specific board results in winning the whole match.
 * @param {number} winningBoardIndex The index of the board being won.
 * @param {string} player The player ("X" or "O").
 * @param {Array} boardResults Current results of all boards.
 * @param {number} requiredWins Wins needed for match victory.
 * @return {boolean} True if the match is won.
 */
function doesBoardWinCompleteMatch(
  winningBoardIndex,
  player,
  boardResults,
  requiredWins,
) {
  let currentWins = 1; // The board we are hypothetically winning
  for (let i = 0; i < boardResults.length; i++) {
    if (i === winningBoardIndex) continue;
    if (boardResults[i] === (player === "X" ? "playerX" : "playerO")) {
      currentWins++;
    }
  }
  return currentWins >= requiredWins;
}

/**
 * Determines how many board wins are needed for a match victory.
 * @param {number} boardCount Total number of boards.
 * @return {number} Wins needed.
 */
function getRequiredWins(boardCount) {
  if (boardCount <= 1) return 1;
  return Math.floor(boardCount / 2) + 1;
}

/**
 * Checks for a win on a single 9-cell board.
 * @param {Array} board The board cells.
 * @param {string} p The player mark.
 * @return {boolean} True if player has won.
 */
function checkWin(board, p) {
  const wins = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6], // Diagonals
  ];
  return wins.some((line) => line.every((idx) => board[idx] === p));
}
