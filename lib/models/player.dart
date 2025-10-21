/// Defines the players in the game.
///
/// Moving this to its own file breaks dependency cycles and allows other
/// model and controller files to import it without importing UI code.
enum Player { none, X, O }
