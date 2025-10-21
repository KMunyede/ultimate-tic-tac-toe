import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/lobby_screen.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/online_game_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'settings_menu.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';

// V6: Renamed widget to resolve name collision.

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  SettingsController _settingsController;

  GameController(this._soundManager, this._settingsController);

  List<Player> _board = List.filled(9, Player.none);
  Player _currentPlayer = Player.X;
  Player? _winner;
  bool _isDraw = false;
  List<int>? _winningLine;

  List<Player> get board => _board;
  Player get currentPlayer => _currentPlayer;
  Player? get winner => _winner;
  bool get isDraw => _isDraw;
  bool get isGameOver => _winner != null || _isDraw;

  List<int>? get winningLine => _winningLine;
  void handleTap(int index) {
    if (_board[index] != Player.none || isGameOver) {
      return;
    }

    _board[index] = _currentPlayer;
    _soundManager.playMoveSound();

    _updateGameState();
  }

  Future<void> _updateGameState() async {
    if (_checkWinner()) {
      _winner = _currentPlayer;
      _soundManager.playWinSound(); // Play sound without awaiting
      _settingsController.updateScore(_winner!);
      notifyListeners(); // Update UI to show winning line and game over state
    } else if (_checkDraw()) {
      _isDraw = true;
      _soundManager.playDrawSound();
      notifyListeners();
    } else {
      _currentPlayer = (_currentPlayer == Player.X) ? Player.O : Player.X;
      // If it's now the AI's turn, make a move.
      if (_settingsController.gameMode == GameMode.playerVsAi && _currentPlayer == Player.O && !isGameOver) {
        _makeAiMove();
      }
      notifyListeners();
    }
  }

  void _makeAiMove() {
    // Add a small delay for a more natural feel
    Future.delayed(const Duration(milliseconds: 500), () {
      if (isGameOver) return;

      int? move = _findBestMove();
      if (move != null) {
        handleTap(move);
      }
    });
  }

  int? _findBestMove() {
    switch (_settingsController.aiDifficulty) {
      case AiDifficulty.easy:
        return _findRandomMove();
      case AiDifficulty.medium:
        return _findMediumMove();
      case AiDifficulty.hard:
        return _findHardMove();
    }
  }

  int? _findHardMove() {
    int? winningMove = _findWinningMove(Player.O);
    if (winningMove != null) return winningMove;

    int? blockingMove = _findWinningMove(Player.X);
    if (blockingMove != null) return blockingMove;

    if (_board[4] == Player.none) return 4;

    return _findStrategicMove() ?? _findRandomMove();
  }

  int? _findMediumMove() {
    // Medium AI always blocks but doesn't always go for the win.
    int? blockingMove = _findWinningMove(Player.X);
    if (blockingMove != null) return blockingMove;

    // 50% chance to make a winning move if available.
    if (Random().nextBool()) {
      int? winningMove = _findWinningMove(Player.O);
      if (winningMove != null) return winningMove;
    }

    if (_board[4] == Player.none) return 4;

    return _findRandomMove();
  }

  int? _findRandomMove() {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (_board[i] == Player.none) available.add(i);
    }
    if (available.isNotEmpty) {
      available.shuffle();
      return available.first;
    }
    return null;
  }

  int? _findWinningMove(Player player) {
    for (int i = 0; i < 9; i++) {
      if (_board[i] == Player.none) {
        _board[i] = player;
        if (_checkWinner()) {
          _board[i] = Player.none;
          return i;
        }
        _board[i] = Player.none;
      }
    }
    return null;
  }

  int? _findStrategicMove() {
    // Take a random corner
    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int i in corners) {
      if (_board[i] == Player.none) return i;
    }

    // Take a random side
    List<int> sides = [1, 3, 5, 7];
    sides.shuffle();
    for (int i in sides) {
      if (_board[i] == Player.none) return i;
    }
    return null;
  }

  @override
  void dispose() {
    // Though GameController is provided at the app level and may not be disposed,
    // it's good practice to have a dispose method.
    super.dispose();
  }

  bool _checkWinner() { // This can be a private method
    const List<List<int>> winningLines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (final line in winningLines) {
      final Player first = _board[line[0]];
      if (first != Player.none && first == _board[line[1]] && first == _board[line[2]]) {
        _winningLine = line;
        return true;
      }
    }
    return false;
  }

  bool _checkDraw() { // This can be a private method
    return !_board.contains(Player.none);
  }

  void initializeGame() {
    _board = List.filled(9, Player.none);
    _currentPlayer = Player.X;
    _winner = null;
    _isDraw = false;
    _winningLine = null;
    notifyListeners();
    // If AI is player X (not the current setup, but for future), it would move here.
    if (_settingsController.gameMode == GameMode.playerVsAi && _currentPlayer == Player.O) {
      // This case is for if the AI was to go first.
      // For now, the player is always X and goes first.
    }
  }

  // Allows updating the settings controller dependency without creating a new GameController
  void updateDependencies(SettingsController newSettingsController) {
    if (_settingsController != newSettingsController) {
      _settingsController = newSettingsController;
      // You might want to react to settings changes here in the future
    }
  }
}

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> with WindowListener {
  bool _isMenuOpen = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Add this line to register the listener
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _saveWindowState() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      await prefs.setDouble('window_width', size.width);
      await prefs.setDouble('window_height', size.height);
      await prefs.setDouble('window_offsetX', position.dx);
      await prefs.setDouble('window_offsetY', position.dy);
    });
  }

  // --- WindowManagerListener Overrides ---
  @override
  void onWindowResized() => _saveWindowState();

  @override
  void onWindowMoved() => _saveWindowState();

  @override
  void onWindowClose() {}
  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMaximize() {}
  @override
  void onWindowUnmaximize() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowRestore() {}
  @override
  void onWindowEnter() {}
  @override
  void onWindowLeave() {}
  @override
  void onWindowDocked() {}
  @override
  void onWindowUndocked() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}
  @override
  void onWindowEvent(String eventName) {}

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    // Use theme colors for gradients. For Forest theme, use its specific colors.
    final Color gradientStart, gradientEnd;
    if (settings.currentTheme == AppTheme.forest) {
      gradientStart = theme.colorScheme.surface;
      gradientEnd = theme.colorScheme.secondary;
    } else {
      gradientStart = Color.lerp(theme.scaffoldBackgroundColor, Colors.white, 0.3)!;
      gradientEnd = Color.lerp(theme.scaffoldBackgroundColor, Colors.black, 0.1)!;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Tic-Tac-Toe'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.public), // Icon for online mode
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const LobbyScreen(),
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
            )
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [gradientStart, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const ScoreDisplay(),
                    const SizedBox(height: 16),
                    const GameStatusDisplay(), // UPDATED
                    const SizedBox(height: 24),
                    Expanded(
                      child: GameBoard(
                          gradientStart: gradientStart, gradientEnd: gradientEnd, currentTheme: settings.currentTheme),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GradientButton(
                          onPressed: gameController.isGameOver ? gameController.initializeGame : null,
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          textColor: theme.colorScheme.onSurface,
                          child: const Text('Play Again', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 20),
                        _GradientButton(
                          onPressed: () => _closeApp(context),
                          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                          textColor: theme.colorScheme.onSurface,
                          child: const Text('Close', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SettingsMenu(isOpen: _isMenuOpen, closeMenu: () => setState(() => _isMenuOpen = false)),
          ],
        ),
      ),
    );
  }
  
  // Helper function to close the app
  void _closeApp(BuildContext context) {
    // This works on mobile and desktop.
    // For web, it might not work depending on browser security policies.
    // A more robust web solution would involve JS interop.
    Navigator.of(context).pop(); // First pop to handle dialogs/routes
    windowManager.close();
  }

}

class GameStatusDisplay extends StatelessWidget { // RENAMED
  const GameStatusDisplay({super.key});

  String _getStatusMessage(GameController gameController) {
    if (gameController.winner != null) {
      return 'Player ${gameController.winner!.name} Wins!';
    }
    if (gameController.isDraw) {
      return 'It\'s a Draw!';
    }
    return 'Player ${gameController.currentPlayer.name}\'s Turn';
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    return Text(
      _getStatusMessage(gameController),
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch SettingsController for score updates
    final settings = context.watch<SettingsController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScoreCard(context, 'You (X)', settings.scoreX, const Color(0xFFD32F2F)),
        _buildScoreCard(
            context,
            settings.gameMode == GameMode.playerVsAi ? 'AI (O)' : 'Player O',
            settings.scoreO, const Color(0xFF388E3C)),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, String label, int score, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(blurRadius: 2.0, color: color.withOpacity(0.5), offset: const Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

class GameBoard extends StatelessWidget {
  final Color gradientStart;
  final Color gradientEnd;
  final AppTheme currentTheme;

  const GameBoard({
    super.key,
    required this.gradientStart,
    required this.gradientEnd,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    // This widget can now be used for both online and local games.
    // We try to look up the OnlineGameController. If it's null, we know we are in a local game.
    final onlineGameController = context.watch<OnlineGameController?>();
    final localGameController = context.watch<GameController?>();

    final List<Player> board = onlineGameController?.game?.board ?? localGameController!.board;
    final Function(int) handleTap = onlineGameController?.makeMove ?? localGameController!.handleTap;
    
    final gameController = context.watch<GameController?>();
    final theme = Theme.of(context);

    // Use theme colors for shadows. For Forest theme, use its specific colors.
    final Color shadowColor, lightShadowColor;
    if (currentTheme == AppTheme.forest) {
      shadowColor = theme.colorScheme.primary;
      lightShadowColor = theme.colorScheme.surface.withOpacity(0.8);
    } else {
      shadowColor = Color.lerp(theme.scaffoldBackgroundColor, Colors.black, 0.4)!;
      lightShadowColor = Color.lerp(theme.scaffoldBackgroundColor, Colors.white, 0.5)!;
    }

    return AspectRatio(
      aspectRatio: 1, // Keeps the board square
        child: Stack(
          children: [
            // The Grid
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 15.0,
              ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GameCell(
                player: board[index],
                onTap: () => handleTap(index),
                gradientStart: gradientStart,
                gradientEnd: gradientEnd,
                shadowColor: shadowColor,
                lightShadowColor: lightShadowColor,
              );
            },
            ),
            // The Winning Line Painter
            if (localGameController != null && localGameController.winner != null && localGameController.winningLine != null)
              AnimatedWinningLine(
                winningLine: localGameController.winningLine!,
                color: localGameController.winner == Player.X
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF388E3C),
              ),
          ],
        )
    );
  }
}

class GameCell extends StatefulWidget {
  final Player player;
  final VoidCallback onTap;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;
  final Color lightShadowColor;

  const GameCell({
    super.key,
    required this.player,
    required this.onTap,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowColor,
    required this.lightShadowColor,
  });

  @override
  State<GameCell> createState() => _GameCellState();
}

class _GameCellState extends State<GameCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.player != Player.none) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GameCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != oldWidget.player) {
      if (widget.player == Player.none) {
        _controller.reset();
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.gradientStart, widget.gradientEnd]),
          boxShadow: [
            BoxShadow(color: widget.shadowColor, offset: const Offset(5, 5), blurRadius: 10),
            BoxShadow(color: widget.lightShadowColor, offset: const Offset(-5, -5), blurRadius: 10),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // The painter now only depends on the animation value.
              return CustomPaint(
                size: Size.infinite,
                painter: _PlayerMarkPainter(player: widget.player, animationValue: _animation.value),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerMarkPainter extends CustomPainter {
  final Player player;
  final double animationValue;

  _PlayerMarkPainter({required this.player, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final halfSize = size.width / 2 * 0.6;

    if (player == Player.X) {
      paint.color = const Color(0xFFD32F2F);
      // Use Interval to map the animation value to two distinct phases.
      // First stroke: 0.0 -> 0.5
      final firstStrokeProgress = Interval(0.0, 0.5, curve: Curves.easeIn).transform(animationValue);
      // Second stroke: 0.5 -> 1.0
      final secondStrokeProgress = Interval(0.5, 1.0, curve: Curves.easeOut).transform(animationValue);

      // Draw first line of X
      if (firstStrokeProgress > 0.0) {
        final p1 = Offset(center.dx - halfSize, center.dy - halfSize);
        final p2 = Offset(center.dx + halfSize, center.dy + halfSize);
        canvas.drawLine(p1, Offset.lerp(p1, p2, firstStrokeProgress)!, paint);
      }
      // Draw second line of X
      if (secondStrokeProgress > 0.0) {
        final p3 = Offset(center.dx + halfSize, center.dy - halfSize);
        final p4 = Offset(center.dx - halfSize, center.dy + halfSize);
        canvas.drawLine(p3, Offset.lerp(p3, p4, secondStrokeProgress)!, paint);
      }
    } else if (player == Player.O) {
      paint.color = const Color(0xFF388E3C);
      final rect = Rect.fromCircle(center: center, radius: halfSize);
      canvas.drawArc(rect, -90 * (3.14 / 180), 360 * (3.14 / 180) * animationValue, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerMarkPainter oldDelegate) {
    return player != oldDelegate.player || (animationValue != oldDelegate.animationValue && player != Player.none);
  }
}

class AnimatedWinningLine extends StatefulWidget {
  final List<int> winningLine;
  final Color color;

  const AnimatedWinningLine({
    super.key,
    required this.winningLine,
    required this.color,
  });

  @override
  State<AnimatedWinningLine> createState() => _AnimatedWinningLineState();
}

class _AnimatedWinningLineState extends State<AnimatedWinningLine>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late Animation<double> _drawAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Controller for the initial line drawing animation
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _drawAnimation = CurvedAnimation(parent: _drawController, curve: Curves.easeOutCubic);

    // Controller for the pulsing/glowing animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // When the drawing animation completes, start the pulsing animation
    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      }
    });

    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drawAnimation, _pulseAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: _WinningLinePainter(
            winningLine: widget.winningLine,
            color: widget.color,
            drawProgress: _drawAnimation.value,
            pulseProgress: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WinningLinePainter extends CustomPainter {
  final List<int> winningLine;
  final Color color;
  final double drawProgress;
  final double pulseProgress;

  _WinningLinePainter({
    required this.winningLine,
    required this.color,
    required this.drawProgress,
    required this.pulseProgress,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    Offset getCellCenter(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(
        col * cellWidth + cellWidth / 2,
        row * cellHeight + cellHeight / 2,
      );
    }

    final startPoint = getCellCenter(winningLine.first);
    final endPoint = getCellCenter(winningLine.last);

    // Interpolate the end point based on the drawProgress
    final animatedEndPoint = Offset.lerp(startPoint, endPoint, drawProgress)!;

    // Calculate glow properties based on pulseProgress
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5 + (pulseProgress * 0.5)) // Pulsing opacity
      ..strokeWidth = 12.0 + (pulseProgress * 8.0) // Pulsing width
      ..strokeCap = StrokeCap.round // FIX: Was Cap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pulseProgress * 5); // Pulsing blur

    // Draw the glow first, so it's behind the main line
    if (drawProgress == 1.0) { // Only draw glow after line is fully drawn
      canvas.drawLine(startPoint, animatedEndPoint, glowPaint);
    }
    // Draw the main line
    canvas.drawLine(startPoint, animatedEndPoint, paint);
  }

  @override
  bool shouldRepaint(covariant _WinningLinePainter oldDelegate) {
    return winningLine != oldDelegate.winningLine ||
           color != oldDelegate.color ||
           drawProgress != oldDelegate.drawProgress ||
           pulseProgress != oldDelegate.pulseProgress;
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget child;
  final Color textColor;

  const _GradientButton({
    this.onPressed,
    required this.gradient,
    required this.child,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.4),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(color: textColor),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
