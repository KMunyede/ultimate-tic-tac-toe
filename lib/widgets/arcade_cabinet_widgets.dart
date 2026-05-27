// lib/widgets/arcade_cabinet_widgets.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import '../models/player.dart';

/// A custom high-fidelity glossy circular arcade button that simulates physical depth.
class ArcadePushButton extends StatefulWidget {
  final String label;
  final String actionText;
  final Color buttonColor;
  final VoidCallback onTap;
  final double size;

  const ArcadePushButton({
    super.key,
    required this.label,
    required this.actionText,
    required this.buttonColor,
    required this.onTap,
    this.size = 56.0,
  });

  @override
  State<ArcadePushButton> createState() => _ArcadePushButtonState();
}

class _ArcadePushButtonState extends State<ArcadePushButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late double _currentPressedOffset;

  @override
  void initState() {
    super.initState();
    _currentPressedOffset = 0.0;
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
      _currentPressedOffset = 3.5;
    });
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
        _currentPressedOffset = 0.0;
      });
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
        _currentPressedOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final Color buttonColor = widget.buttonColor;
    final theme = Theme.of(context);

    // Dynamic contrast values based on brightness
    final isDark = theme.brightness == Brightness.dark;
    final rimColor = isDark ? Colors.grey.shade800 : Colors.grey.shade400;
    final socketColor = isDark ? Colors.black87 : Colors.grey.shade300;

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flashing action tag text (e.g. "START", "SELECT")
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          // Stack rendering the button layers
          SizedBox(
            width: size + 12,
            height: size + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Button Socket / Outer Bezel Rim
                Container(
                  width: size + 10,
                  height: size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rimColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                // 2. Inner Socket Void
                Container(
                  width: size + 2,
                  height: size + 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: socketColor,
                  ),
                ),
                // 3. Physical Button Cap that translates downwards on press
                Positioned(
                  top: 6.0 + _currentPressedOffset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          buttonColor,
                          Color.lerp(buttonColor, Colors.black, 0.45)!,
                        ],
                        center: const Alignment(-0.25, -0.25),
                        radius: 0.85,
                      ),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: buttonColor.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 4,
                                offset: const Offset(0, 3.5),
                              ),
                            ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // White-hot glossy crescent highlight
                        Positioned(
                          top: size * 0.08,
                          left: size * 0.18,
                          child: Container(
                            width: size * 0.64,
                            height: size * 0.28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.all(
                                Radius.elliptical(size * 0.32, size * 0.14),
                              ),
                            ),
                          ),
                        ),
                        // Circular button cap interior text
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              widget.actionText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    offset: const Offset(0, 1.5),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An LED-pixel-styled scoring board marquee reflecting classic arcade cabinets.
class ArcadeScoreMarquee extends StatelessWidget {
  const ArcadeScoreMarquee({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;

    // Helper to format values into classic padded retro digits (e.g. 002400)
    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF020108), // Pitch-dark LED background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.accentGlow.withValues(alpha: 0.65),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.accentGlow.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1UP (Player X)
          _buildLedColumn(
            label: '1UP (X)',
            score: padScore(game.sessionWinsX),
            subLabel: 'BOARDS: ${game.boardsWonX}',
            active: game.currentPlayer == Player.X && !game.isOverallGameOver,
            glowColor: Colors.red.shade600,
          ),
          
          // HIGH SCORE
          _buildLedColumn(
            label: 'HIGH SCORE',
            score: '999990',
            subLabel: 'V2 CABINET',
            active: false,
            glowColor: Colors.amber.shade600,
          ),

          // 2UP (Player O)
          _buildLedColumn(
            label: '2UP (O)',
            score: padScore(game.sessionWinsO),
            subLabel: 'BOARDS: ${game.boardsWonO}',
            active: game.currentPlayer == Player.O && !game.isOverallGameOver,
            glowColor: const Color(0xFF0D47A1),
          ),
        ],
      ),
    );
  }

  Widget _buildLedColumn({
    required String label,
    required String score,
    required String subLabel,
    required bool active,
    required Color glowColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Label with optional blinking flash
          _BlinkingLabel(
            label: label,
            active: active,
            color: active ? glowColor : Colors.grey.shade500,
          ),
          const SizedBox(height: 6),
          // LED glowing digits
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: glowColor,
                shadows: [
                  Shadow(
                    color: glowColor.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Sub-indicator
          Text(
            subLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 7.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingLabel extends StatefulWidget {
  final String label;
  final bool active;
  final Color color;

  const _BlinkingLabel({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  State<_BlinkingLabel> createState() => _BlinkingLabelState();
}

class _BlinkingLabelState extends State<_BlinkingLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.active) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _BlinkingLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!widget.active && _blinkController.isAnimating) {
      _blinkController.stop();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 9,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: widget.color,
      shadows: widget.active
          ? [
              Shadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ]
          : [],
    );

    if (widget.active) {
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Opacity(
            opacity: _blinkController.value > 0.5 ? 1.0 : 0.35,
            child: Text(widget.label, style: style),
          );
        },
      );
    }

    return Text(widget.label, style: style);
  }
}

/// A scrolling digital marquee for Turn Status or generic messages.
class ArcadeTurnMarquee extends StatefulWidget {
  const ArcadeTurnMarquee({super.key});

  @override
  State<ArcadeTurnMarquee> createState() => _ArcadeTurnMarqueeState();
}

class _ArcadeTurnMarqueeState extends State<ArcadeTurnMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollOffset;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scrollOffset = Tween<double>(begin: 1.0, end: -1.0).animate(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;

    final String statusText = _getTurnText(game);
    final Color color = _getTurnColor(game);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF030A02), // Scrolling sign base dark-green
          border: Border.all(
            color: activeTheme.mainColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Retro LED dot grid matrix texture overlay
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: LedGridPainter(),
                ),
              ),
            ),
            // Sliding LED Marquee Text
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double scrollWidth = constraints.maxWidth;
                    final double xPosition = _scrollOffset.value * (scrollWidth * 0.65);
                    return Transform.translate(
                      offset: Offset(xPosition, 0),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: color,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTurnText(GameController game) {
    if (game.isOverallGameOver) {
      if (game.matchWinner != null) {
        return '<<< MATCH OVER: PLAYER ${game.matchWinner == Player.X ? 'X' : 'O'} WINS! PRESS START >>>';
      }
      return '<<< MATCH OVER: DRAW GAME. PRESS START >>>';
    }
    if (game.isAiThinking) {
      return '<<< SYSTEM: AI COMPUTER IS THINKING... STAND BY >>>';
    }
    return game.currentPlayer == Player.X
        ? '<<< PLAYER X TURN: INSERT COMMAND <<< '
        : ' >>> PLAYER O TURN: INSERT COMMAND >>>';
  }

  Color _getTurnColor(GameController game) {
    if (game.isOverallGameOver) {
      return Colors.amber.shade500;
    }
    if (game.isAiThinking) {
      return Colors.teal.shade400;
    }
    return game.currentPlayer == Player.X ? Colors.red.shade500 : const Color(0xFF00FFCC);
  }
}

class LedGridPainter extends CustomPainter {
  const LedGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw horizontal lines across the display to mock scanlines
    final double scanHeight = 2.0;
    for (double y = 0; y < size.height; y += scanHeight * 1.5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, scanHeight), paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A glowing cabinet bezel screen framing the multi-boards view.
class ArcadeCabinetFrame extends StatelessWidget {
  final Widget child;

  const ArcadeCabinetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Outer cabinet bezel
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF23232C),
          width: 6.0,
        ),
        boxShadow: [
          // Dynamic cabinet neon glowing backplates
          BoxShadow(
            color: activeTheme.mainColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.95),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arcade Cabinet Screen Header Logo/Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBezelScrew(),
              Text(
                'CRT-99 MULTIPLEX MONITOR',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.0,
                ),
              ),
              _buildBezelScrew(),
            ],
          ),
          const SizedBox(height: 8),
          // The Board View Surrounded by Inner Glowing CRT Tube Rim
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeTheme.accentGlow.withValues(alpha: 0.4),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeTheme.accentGlow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                child,
                // Glossy CRT glass monitor glare corner overlays
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white10,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.25, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBezelScrew() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF33333E),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 1,
          color: Colors.black45,
        ),
      ),
    );
  }
}

/// An ergonomic physical retro arcade Control Panel consolidating actions.
class ArcadeControlDeck extends StatelessWidget {
  final Widget? cardHandWidget;
  final VoidCallback onNewGame;
  final VoidCallback onHelp;
  final VoidCallback onSettings;

  const ArcadeControlDeck({
    super.key,
    required this.onNewGame,
    required this.onHelp,
    required this.onSettings,
    this.cardHandWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Brushed metallic carbon deck background
            gradient: LinearGradient(
              colors: [
                const Color(0xFF131317),
                isDark ? const Color(0xFF070709) : const Color(0xFF1A1A22),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: Colors.white10,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Power-Ups Slots Row (if chaos ruleset card exists)
              if (cardHandWidget != null) ...[
                cardHandWidget!,
                const SizedBox(height: 12),
              ],

              // 2. Tactile Push Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Option/Settings (Blue button)
                  ArcadePushButton(
                    label: 'OPTION',
                    actionText: 'CONFIG',
                    buttonColor: Colors.blue.shade600,
                    onTap: onSettings,
                  ),

                  // START / New Match (Big Red button!)
                  ArcadePushButton(
                    label: 'PLAYER 1',
                    actionText: 'START',
                    buttonColor: Colors.red.shade700,
                    size: 64.0, // Major push button
                    onTap: onNewGame,
                  ),

                  // Info/Help (Yellow button)
                  ArcadePushButton(
                    label: 'HELP',
                    actionText: 'INFO',
                    buttonColor: Colors.amber.shade600,
                    onTap: onHelp,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Arcade signature tag
              Text(
                'INSERT COIN - CREDIT 99',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
