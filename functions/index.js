const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

/**
 * Minimalist Ultimate Tic-Tac-Toe Engine for Node.js
 */
class UltimateEngineJS {
  constructor(boards, boardResults, forcedIdx) {
    this.board = new Int8Array(81);
    this.macroBoard = new Int8Array(9); // 0: active, 1: X, -1: O, 2: Draw
    this.activeBoardIndex = (forcedIdx !== undefined && forcedIdx !== null) ? forcedIdx : -1;

    for (let b = 0; b < 9; b++) {
      for (let c = 0; c < 9; c++) {
        const val = boards[b][c];
        this.board[b * 9 + c] = (val === "X" || val === "playerX") ? 1 : ((val === "O" || val === "playerO") ? -1 : 0);
      }
      const res = boardResults[b];
      this.macroBoard[b] = res === "playerX" ? 1 : (res === "playerO" ? -1 : (res === "draw" ? 2 : 0));
    }
  }

  minimax(depth, alpha, beta, player, aiPlayer) {
    const winner = this.checkGlobalWin();
    if (winner !== 0) {
      if (winner === aiPlayer) return { score: 1000000 + depth, move: -1 };
      if (winner === 2) return { score: 0, move: -1 };
      return { score: -1000000 - depth, move: -1 };
    }
    if (depth === 0) return { score: this.evaluate(aiPlayer), move: -1 };

    const moves = this.getValidMoves();
    if (moves.length === 0) return { score: 0, move: -1 };

    // Basic move ordering: Center > Corners > Sides
    moves.sort((a, b) => {
      const scoreA = (a % 9 === 4) ? 2 : ([0, 2, 6, 8].includes(a % 9) ? 1 : 0);
      const scoreB = (b % 9 === 4) ? 2 : ([0, 2, 6, 8].includes(b % 9) ? 1 : 0);
      return scoreB - scoreA;
    });

    let bestMove = -1;
    if (player === aiPlayer) {
      let maxEval = -Infinity;
      for (const move of moves) {
        const prevState = this.applyMove(move, player);
        const eval = this.minimax(depth - 1, alpha, beta, -player, aiPlayer).score;
        this.undoMove(move, prevState);
        if (eval > maxEval) {
          maxEval = eval;
          bestMove = move;
        }
        alpha = Math.max(alpha, eval);
        if (beta <= alpha) break;
      }
      return { score: maxEval, move: bestMove };
    } else {
      let minEval = Infinity;
      for (const move of moves) {
        const prevState = this.applyMove(move, player);
        const eval = this.minimax(depth - 1, alpha, beta, -player, aiPlayer).score;
        this.undoMove(move, prevState);
        if (eval < minEval) {
          minEval = eval;
          bestMove = move;
        }
        beta = Math.min(beta, eval);
        if (beta <= alpha) break;
      }
      return { score: minEval, move: bestMove };
    }
  }

  applyMove(index, player) {
    const prevState = {
      activeIdx: this.activeBoardIndex,
      macroVal: this.macroBoard[Math.floor(index / 9)],
    };
    this.board[index] = player;
    const bIdx = Math.floor(index / 9);

    if (this.checkLocalWin(bIdx)) {
      this.macroBoard[bIdx] = player;
    } else if (this.isLocalFull(bIdx)) {
      this.macroBoard[bIdx] = 2;
    }

    const nextB = index % 9;
    this.activeBoardIndex = (this.macroBoard[nextB] !== 0) ? -1 : nextB;
    return prevState;
  }

  undoMove(index, state) {
    this.board[index] = 0;
    this.macroBoard[Math.floor(index / 9)] = state.macroVal;
    this.activeBoardIndex = state.activeIdx;
  }

  getValidMoves() {
    const moves = [];
    if (this.activeBoardIndex !== -1) {
      const start = this.activeBoardIndex * 9;
      for (let i = 0; i < 9; i++) {
        if (this.board[start + i] === 0) moves.push(start + i);
      }
    }
    if (moves.length > 0) return moves;

    for (let b = 0; b < 9; b++) {
      if (this.macroBoard[b] === 0) {
        const start = b * 9;
        for (let i = 0; i < 9; i++) {
          if (this.board[start + i] === 0) moves.push(start + i);
        }
      }
    }
    return moves;
  }

  checkLocalWin(bIdx) {
    const s = bIdx * 9;
    const wins = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
    for (const w of wins) {
      if (this.board[s + w[0]] !== 0 &&
          this.board[s + w[0]] === this.board[s + w[1]] &&
          this.board[s + w[0]] === this.board[s + w[2]]) return true;
    }
    return false;
  }

  isLocalFull(bIdx) {
    const s = bIdx * 9;
    for (let i = 0; i < 9; i++) if (this.board[s + i] === 0) return false;
    return true;
  }

  checkGlobalWin() {
    const wins = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
    for (const w of wins) {
      const a = this.macroBoard[w[0]];
      if (a !== 0 && a !== 2 && a === this.macroBoard[w[1]] && a === this.macroBoard[w[2]]) return a;
    }
    for (let i = 0; i < 9; i++) if (this.macroBoard[i] === 0) return 0;
    return 2;
  }

  evaluate(aiPlayer) {
    let score = 0;
    const weights = [30, 20, 30, 20, 50, 20, 30, 20, 30];
    for (let i = 0; i < 9; i++) {
      if (this.macroBoard[i] === aiPlayer) score += weights[i] * 100;
      else if (this.macroBoard[i] === -aiPlayer) score -= weights[i] * 100;
    }
    return score;
  }
}

exports.getAiMove = onCall({
  invoker: "allUsers",
  region: "us-central1",
}, (request) => {
  const {
    boards,
    boardResults,
    player,
    difficulty,
    boardCount,
    forcedBoardIndex,
    ruleSet,
  } = request.data;

  if (!boards || !Array.isArray(boards)) {
    throw new HttpsError("invalid-argument", "Missing required game data.");
  }

  const aiVal = player === "X" ? 1 : -1;
  const isUltimate = ruleSet === "ultimate" || boardCount === 9;

  logger.info(`AI Request: Diff=${difficulty}, Player=${player}, Ultimate=${isUltimate}`);

  // Use Minimax for Hard difficulty in Ultimate mode
  if (difficulty === "hard" && isUltimate && boards.length === 9) {
    try {
      const engine = new UltimateEngineJS(boards, boardResults, forcedBoardIndex);
      const result = engine.minimax(4, -Infinity, Infinity, aiVal, aiVal);
      if (result.move !== -1) {
        return {
          boardIndex: Math.floor(result.move / 9),
          cellIndex: result.move % 9,
        };
      }
    } catch (e) {
      logger.error("Minimax failed, falling back to heuristic", e);
    }
  }

  // Heuristic Fallback for Medium/Easy or failures
  return computeHeuristicMove(boards, boardResults, player, difficulty, forcedBoardIndex);
});

function computeHeuristicMove(boards, boardResults, player, difficulty, forcedBoardIndex) {
  const opponent = player === "X" ? "O" : "X";
  const scoredMoves = [];

  for (let b = 0; b < boards.length; b++) {
    if (boardResults[b] !== "active") continue;
    if (forcedBoardIndex !== null && forcedBoardIndex !== undefined && b !== forcedBoardIndex) continue;

    for (let c = 0; c < 9; c++) {
      if (boards[b][c] === "" || boards[b][c] === "none") {
        let score = 0;
        if (difficulty !== "easy") {
          if (isWinningMove(boards[b], c, player)) score += 10000;
          if (isWinningMove(boards[b], c, opponent)) score += 5000;
          if (c === 4) score += 500;
          if ([0, 2, 6, 8].includes(c)) score += 200;
        } else {
          score = Math.random() * 100;
        }
        scoredMoves.push({ boardIndex: b, cellIndex: c, score });
      }
    }
  }

  scoredMoves.sort((a, b) => b.score - a.score);
  return scoredMoves.length > 0 ? scoredMoves[0] : { boardIndex: 0, cellIndex: 0 };
}

function isWinningMove(board, cellIndex, p) {
  const temp = [...board];
  temp[cellIndex] = p;
  const wins = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
  return wins.some((line) => line.every((idx) => temp[idx] === p));
}
