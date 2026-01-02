/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.getAiMove = onCall((request) => {
  // Log the incoming data for debugging
  logger.info("Received request for AI move:", request.data);

  // --- PASTE YOUR GAME LOGIC FROM 'calculateAiMove' HERE ---
  //
  // For example, it might look something like this:
  //
  // const board = request.data.board;
  // const player = request.data.player;
  // const difficulty = request.data.difficulty;
  //
  // let bestMove = -1;
  //
  // // ... your Minimax or other algorithm ...
  // // ... calculate the bestMove ...
  //
  // ---------------------------------------------------------

  // For now, let's return a random move as a placeholder
  const availableCells = [];
  const board = request.data.board;
  for (let i = 0; i < board.length; i++) {
    if (board[i] === "none") {
      availableCells.push(i);
    }
  }
  const randomIndex = Math.floor(Math.random() * availableCells.length);
  const randomMove = availableCells.length > 0 ?
    availableCells[randomIndex] :
    -1;


  logger.info("Calculated AI move:", {move: randomMove});

  // Return the calculated move to the app
  return {move: randomMove};
});
