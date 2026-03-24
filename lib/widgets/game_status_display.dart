import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_controller.dart';
import '../models/player.dart';

class GameStatusDisplay extends StatefulWidget {
  const GameStatusDisplay({super.key});

  @override
  State<GameStatusDisplay> createState() => _GameStatusDisplayState();
}

class _GameStatusDisplayState extends State<GameStatusDisplay>
    with TickerProviderStateMixin {
  late AnimationController _tileController;
  late Animation<Offset> _tileOffset;
  
  late List<AnimationController> _wordControllers;
  late List<Animation<double>> _wordFades;
  late List<Animation<double>> _wordScales;

  bool _isGameOverState = false;

  @override
  void initState() {
    super.initState();
    
    // Controller for the main tile drop
    _tileController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _tileOffset = Tween<Offset>(
      begin: const Offset(0.0, -5.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _tileController,
      curve: Curves.bounceOut,
    ));

    _initWordAnimations(3);
  }

  void _initWordAnimations(int count) {
    _wordControllers = List.generate(
      count,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _wordFades = _wordControllers.map((c) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeIn))
    ).toList();

    _wordScales = _wordControllers.map((c) => 
      Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))
    ).toList();
  }

  @override
  void dispose() {
    _tileController.dispose();
    for (var c in _wordControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _runAnimations() async {
    _tileController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 600));
    
    for (var controller in _wordControllers) {
      controller.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _resetAnimations() {
    _tileController.reset();
    for (var c in _wordControllers) {
      c.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final statusText = _getStatusText(game);
        final isGameOver = game.isOverallGameOver;
        final words = statusText.split(' ');
        final color = _getStatusColor(context, game);

        if (isGameOver && !_isGameOverState) {
          _isGameOverState = true;
          if (_wordControllers.length != words.length) {
            _initWordAnimations(words.length);
          }
          _runAnimations();
        } else if (!isGameOver && _isGameOverState) {
          _isGameOverState = false;
          _resetAnimations();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final baseFontSize = (screenWidth < 400 ? 24.0 : 32.0) * 1.2;

        if (isGameOver) {
          return SlideTransition(
            position: _tileOffset,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: List.generate(words.length, (i) {
                    return FadeTransition(
                      opacity: _wordFades[i],
                      child: ScaleTransition(
                        scale: _wordScales[i],
                        child: Text(
                          words[i],
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        }

        // Standard Turn Display
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              statusText,
              key: ValueKey(statusText),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, GameController game) {
    if (game.isOverallGameOver) {
      if (game.matchWinner == Player.X) return Colors.red.shade900;
      if (game.matchWinner == Player.O) return const Color(0xFF0D47A1);
      return Colors.blueGrey.shade800;
    }
    return game.currentPlayer == Player.X ? Colors.red.shade700 : const Color(0xFF1976D2);
  }

  String _getStatusText(GameController game) {
    if (game.isOverallGameOver) {
      if (game.matchWinner != null) {
        return 'PLAYER ${game.matchWinner == Player.X ? 'X' : 'O'} WINS!';
      } else {
        return "IT'S A DRAW!";
      }
    }
    return game.isAiThinking ? 'AI IS THINKING...' : "PLAYER ${game.currentPlayer == Player.X ? 'X' : 'O'}'S TURN";
  }
}
