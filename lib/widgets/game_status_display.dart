import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/logic/game_controller.dart';
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
        final theme = Theme.of(context);
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final isLandscape = screenWidth > screenHeight;
        final shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;
        final isMobile = shortestSide < 600;
        final isTablet = shortestSide >= 600 && shortestSide < 1024;
        
        // Calculate diagonal inches for precision scaling
        final double diagonalInches = sqrt(pow(screenWidth / 160, 2) + pow(screenHeight / 160, 2));
        final bool isSmallLandscape = isLandscape && diagonalInches < 7.0;
        
        // Conservative font sizing for better overall UI fit
        double baseFontSize = (screenWidth < 400 ? 18.0 : 22.0) * 1.2;
        String displayStatusText = statusText;

        if (isLandscape) {
          if (isMobile) {
            // Further reduction for phones in landscape to maximize vertical board space
            baseFontSize = isSmallLandscape ? 13.0 : 16.0;
          } else if (isTablet) {
            baseFontSize = 20.0; // Moderate reduction for 7-10 inch tablets
          } else {
            baseFontSize = 26.0; // Large screens / Desktop
          }
        }

        final words = displayStatusText.split(' ');
        final color = _getStatusColor(context, game);
        
        // Match the background color of the boards
        final hsl = HSLColor.fromColor(theme.scaffoldBackgroundColor);
        final boardEquivalentColor = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();

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

        if (isGameOver) {
          return SlideTransition(
            position: _tileOffset,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  color: boardEquivalentColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
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
                            color: color,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
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
        return Container(
          width: double.infinity,
          // Ignore horizontal padding boundaries in small landscape mode
          padding: EdgeInsets.only(
            top: isLandscape ? 4 : 20, 
            bottom: isLandscape ? 4 : 15,
            left: isSmallLandscape ? 0 : 4,
            right: isSmallLandscape ? 0 : 4,
          ),
          decoration: isLandscape ? BoxDecoration(
            color: boardEquivalentColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayStatusText,
                    key: ValueKey(displayStatusText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: baseFontSize * 0.7, 
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (game.winTargetMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: WobbleFlashMessage(
                    message: game.winTargetMessage,
                    baseFontSize: baseFontSize,
                    color: color,
                  ),
                ),
            ],
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
        // PRIORITY: Use the refined message from GameController (handles "No winner!" vs "No wins")
        return game.statusMessage ?? "No winner!";
      }
    }
    return game.isAiThinking ? 'AI IS THINKING...' : "PLAYER ${game.currentPlayer == Player.X ? 'X' : 'O'}'S TURN";
  }
}

class WobbleFlashMessage extends StatefulWidget {
  final String message;
  final double baseFontSize;
  final Color color;

  const WobbleFlashMessage({
    super.key,
    required this.message,
    required this.baseFontSize,
    required this.color,
  });

  @override
  State<WobbleFlashMessage> createState() => _WobbleFlashMessageState();
}

class _WobbleFlashMessageState extends State<WobbleFlashMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wobble;
  late Animation<double> _flash;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _wobble = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _flash = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Run immediately then every 30 seconds
    _runAnimation();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _runAnimation();
    });
  }

  void _runAnimation() {
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _flash.value,
          child: Transform.rotate(
            angle: _wobble.value,
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (widget.baseFontSize * 0.7) * 0.95,
                color: widget.color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w900, // Extra Bold
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      },
    );
  }
}
