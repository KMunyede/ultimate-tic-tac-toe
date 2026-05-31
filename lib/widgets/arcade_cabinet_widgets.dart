// lib/widgets/arcade_cabinet_widgets.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/theme/app_theme.dart';
import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import '../models/player.dart';
import '../utils/responsive_layout.dart';
import '../services/stats_service.dart';

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
    final isLight = theme.brightness == Brightness.light;
    
    final rimColor = isLight 
        ? Color.lerp(theme.scaffoldBackgroundColor, Colors.grey.shade400, 0.45)!
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade400);
    final socketColor = isLight
        ? Color.lerp(theme.scaffoldBackgroundColor, Colors.grey.shade500, 0.7)!
        : (isDark ? Colors.black87 : Colors.grey.shade300);

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
                        color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
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
                          Color.lerp(buttonColor, isLight ? Colors.white : Colors.black, isLight ? 0.22 : 0.45)!,
                        ],
                        center: const Alignment(-0.25, -0.25),
                        radius: 0.85,
                      ),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: buttonColor.withValues(alpha: isLight ? 0.35 : 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: isLight 
                                    ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.12) ?? Colors.black12
                                    : Colors.black.withValues(alpha: 0.7),
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
    final isLight = currentTheme.brightness == Brightness.light;

    // Helper to format values into classic padded retro digits (e.g. 002400)
    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    final scoreboardBg = isLight
        ? Colors.white.withValues(alpha: 0.45)
        : currentTheme.scaffoldBg.withValues(alpha: 0.35);
    final scoreboardBorderColor = isLight
        ? currentTheme.mainColor.withValues(alpha: 0.20)
        : currentTheme.accentGlow.withValues(alpha: 0.45);
    final scoreboardGlowColor = isLight
        ? currentTheme.mainColor.withValues(alpha: 0.05)
        : currentTheme.accentGlow.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scoreboardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreboardBorderColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreboardGlowColor,
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
            context: context,
            currentTheme: currentTheme,
            label: '1UP (X)',
            score: padScore(game.sessionWinsX),
            subLabel: 'BOARDS: ${game.boardsWonX}',
            active: game.currentPlayer == Player.X && !game.isOverallGameOver,
            glowColor: Colors.red.shade600,
          ),
          
          // HIGH SCORE
          _buildLedColumn(
            context: context,
            currentTheme: currentTheme,
            label: 'HIGH SCORE',
            score: '999990',
            subLabel: 'V2 CABINET',
            active: false,
            glowColor: Colors.amber.shade600,
          ),

          // 2UP (Player O)
          _buildLedColumn(
            context: context,
            currentTheme: currentTheme,
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
    required BuildContext context,
    required AppTheme currentTheme,
    required String label,
    required String score,
    required String subLabel,
    required bool active,
    required Color glowColor,
  }) {
    final isLight = currentTheme.brightness == Brightness.light;

    Color getActiveColor(Color baseNeon) {
      if (!isLight) return baseNeon;
      if (baseNeon == Colors.red.shade600) {
        return const Color(0xFFB71C1C); // Deep Crimson
      }
      if (baseNeon == const Color(0xFF0D47A1) || baseNeon == Colors.blue.shade600) {
        return const Color(0xFF0D47A1); // Deep Navy
      }
      if (baseNeon == Colors.amber.shade600) {
        return const Color(0xFFE65100); // Deep Orange Bronze
      }
      return currentTheme.textColor;
    }

    final displayColor = getActiveColor(glowColor);
    final activeTextColor = active 
        ? displayColor 
        : (isLight ? currentTheme.textColor.withValues(alpha: 0.45) : Colors.grey.shade500);

    return Expanded(
      child: Column(
        children: [
          // Label with optional blinking flash
          _BlinkingLabel(
            label: label,
            active: active,
            color: activeTextColor,
          ),
          const SizedBox(height: 6),
          // LED glowing digits
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLight ? Colors.white.withValues(alpha: 0.95) : Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isLight 
                    ? currentTheme.mainColor.withValues(alpha: 0.15) 
                    : Colors.white10,
              ),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: displayColor,
                shadows: isLight
                    ? []
                    : [
                        Shadow(
                          color: displayColor.withValues(alpha: 0.8),
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
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              color: isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey,
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
  final double fontSize;

  const _BlinkingLabel({
    required this.label,
    required this.active,
    required this.color,
    this.fontSize = 9.0,
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
    final settings = context.watch<SettingsController>();
    final isLight = settings.currentTheme.brightness == Brightness.light;

    final style = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: widget.color,
      shadows: (widget.active && !isLight)
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
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final isLight = activeTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final String statusText = _getTurnText(game, activeTheme);
    final Color color = _getTurnColor(game, activeTheme);

    final double fontSize = res.isLessThan7Inch ? 9.5 : 11.5;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isLight 
                  ? Colors.white.withValues(alpha: 0.15) 
                  : const Color(0xFF0C100B).withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: isLight
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing tactical LED status beacon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: _pulseController.value * 0.7 + 0.3),
                        boxShadow: isLight
                            ? []
                            : [
                                BoxShadow(
                                  color: color.withValues(alpha: _pulseController.value * 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1.5,
                                )
                              ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Unified text style
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: color,
                    shadows: isLight
                        ? []
                        : [
                            Shadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTurnText(GameController game, AppTheme theme) {
    final isCandy = theme.name.contains('Candy Meadow');
    final isWood = theme.name.contains('Woodville Carve');

    if (game.isOverallGameOver) {
      if (game.matchWinner != null) {
        final String winnerName = game.matchWinner == Player.X 
            ? (isCandy ? 'LADYBUGS' : (isWood ? 'SLATE X' : 'PLAYER X'))
            : (isCandy ? 'DONUTS' : (isWood ? 'STONE O' : 'PLAYER O'));
        return 'MATCH OVER • $winnerName WIN';
      }
      return 'MATCH OVER • DRAW MATCH';
    }
    if (game.isAiThinking) {
      return 'AI COMPUTER THINKING • STAND BY';
    }
    
    final String activePlayerName = game.currentPlayer == Player.X 
        ? (isCandy ? 'LADYBUG' : (isWood ? 'SLATE X' : 'PLAYER X'))
        : (isCandy ? 'DONUT' : (isWood ? 'STONE O' : 'PLAYER O'));
    return '$activePlayerName TURN • READY';
  }

  Color _getTurnColor(GameController game, AppTheme theme) {
    final isLight = theme.brightness == Brightness.light;
    if (game.isOverallGameOver) {
      return isLight ? const Color(0xFFE65100) : Colors.amber.shade500;
    }
    if (game.isAiThinking) {
      return isLight ? const Color(0xFF006064) : Colors.teal.shade400;
    }
    return game.currentPlayer == Player.X 
        ? (isLight ? const Color(0xFFB71C1C) : Colors.red.shade500) 
        : (isLight ? const Color(0xFF0D47A1) : const Color(0xFF00FFCC));
  }
}

class LedGridPainter extends CustomPainter {
  final bool isLight;
  const LedGridPainter({this.isLight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()
      ..color = isLight ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw horizontal lines across the display to mock scanlines
    final double scanHeight = 2.0;
    for (double y = 0; y < size.height; y += scanHeight * 1.5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, scanHeight), paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant LedGridPainter oldDelegate) => oldDelegate.isLight != isLight;
}

/// A glowing cabinet bezel screen framing the multi-boards view.
class ArcadeCabinetFrame extends StatelessWidget {
  final Widget child;

  const ArcadeCabinetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Return child directly so the boards float completely free and independent
    // directly on the animated space/meadow gradients without being confined
    // to a rigid rectangular cabinet monitor!
    return child;
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
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final themeName = activeTheme.name;
    final isLight = activeTheme.brightness == Brightness.light;

    final isCandy = themeName.contains('Candy Meadow');
    final isWood = themeName.contains('Woodville Carve');

    final deckGradientColors = isCandy
        ? [
            const Color(0xFF8D6E63), // Warm wood top
            const Color(0xFF5D4037), // Warm wood bottom
          ]
        : (isWood
            ? [
                const Color(0xFF3E2723), // Rich mahogany top
                const Color(0xFF271A15), // Rich mahogany bottom
              ]
            : [ // Neon Cyberpulse
                const Color(0xFF131317),
                const Color(0xFF070709),
              ]);

    final deckBorderColor = isCandy
        ? const Color(0xFF5D4037).withValues(alpha: 0.5)
        : (isWood
            ? const Color(0xFF3E2723)
            : Colors.white10);

    final deckShadowColor = isLight
        ? activeTheme.textColor.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.5);

    // Calculate sizes dynamically: fewer boards = larger buttons, more boards = smaller buttons.
    final int boardsCount = game.boards.length;
    final double baseButtonSize;
    if (boardsCount <= 1) {
      baseButtonSize = 62.0;
    } else if (boardsCount <= 4) {
      baseButtonSize = 52.0;
    } else if (boardsCount <= 9) {
      baseButtonSize = 44.0;
    } else {
      baseButtonSize = 38.0;
    }

    final double startButtonSize = baseButtonSize * 1.15; // Start button is always slightly larger!
    final double otherButtonSize = baseButtonSize;
    
    final double joystickSize = boardsCount <= 1 
        ? 80.0 
        : (boardsCount <= 4 ? 70.0 : (boardsCount <= 9 ? 60.0 : 52.0));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // Brushed metallic carbon/silver deck background
            gradient: LinearGradient(
              colors: deckGradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: deckBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: deckShadowColor,
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Screws in the top-left and top-right of the control deck console
              Positioned(
                top: 8,
                left: 8,
                child: ArcadeScrewWidget(isLight: isLight, size: 10.0),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: ArcadeScrewWidget(isLight: isLight, size: 10.0),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Power-Ups Slots Row (if chaos ruleset card exists)
                    if (cardHandWidget != null) ...[
                      cardHandWidget!,
                      const SizedBox(height: 12),
                    ],

                    // 2. Controller Section: Interactive Joystick (Left) + Action Buttons (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InteractiveJoystickWidget(size: joystickSize),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Option/Settings
                              ArcadePushButton(
                                label: 'SETTINGS',
                                actionText: 'SETTINGS',
                                buttonColor: isCandy 
                                    ? const Color(0xFF00B0FF) 
                                    : (isWood ? const Color(0xFF8D6E63) : Colors.blue.shade600),
                                size: otherButtonSize,
                                onTap: onSettings,
                              ),

                              // START / New Match (Big button!)
                              ArcadePushButton(
                                label: 'PLAYER 1',
                                actionText: 'START',
                                buttonColor: isCandy 
                                    ? const Color(0xFFFF4081) 
                                    : (isWood ? const Color(0xFFD84315) : Colors.red.shade700),
                                size: startButtonSize,
                                onTap: onNewGame,
                              ),

                              // Info/Help
                              ArcadePushButton(
                                label: 'HELP',
                                actionText: 'INFO',
                                buttonColor: isCandy 
                                    ? const Color(0xFFFFD54F) 
                                    : (isWood ? const Color(0xFFFFB300) : Colors.amber.shade600),
                                size: otherButtonSize,
                                onTap: onHelp,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Arcade signature tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GlowingCoinSlotWidget(),
                        const SizedBox(width: 16),
                        Text(
                          'CREDIT 99',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: isLight ? Colors.grey.shade700 : Colors.amber.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floating glassmorphic score badge for Player X, glowing with dull crimson.
class PlayerXScoreBadge extends StatelessWidget {
  const PlayerXScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final isActive = game.currentPlayer == Player.X && !game.isOverallGameOver;
    final dullCrimson = isLight ? const Color(0xFFB71C1C) : currentTheme.colorX;

    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    // Responsive sizing based on the 4 diagonal display categories
    final double width = res.isLessThan7Inch
        ? 110.0
        : (res.is7To8Inch ? 122.0 : (res.is8To10Inch ? 135.0 : 145.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 10.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;
    final double blinkLabelFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double scoreFontSize = res.isLessThan7Inch ? 11.0 : 13.0;
    final double boardsWonFontSize = res.isLessThan7Inch ? 6.5 : 7.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63), // Warm wood plank color
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFFFB74D) : const Color(0xFF5D4037),
              width: isActive ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E), // Embossed dark wood
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? const Color(0xFFFFB300) : const Color(0xFF3E2723),
                  width: isActive ? 2.0 : 1.0,
                ),
              )
            : BoxDecoration( // Neon Cyberpulse
                color: isLight
                    ? Colors.white.withValues(alpha: 0.15)
                    : currentTheme.scaffoldBg.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isActive
                      ? dullCrimson.withValues(alpha: 0.8)
                      : dullCrimson.withValues(alpha: 0.25),
                  width: isActive ? 2.0 : 1.2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: dullCrimson.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ));

    return ClipRRect(
      borderRadius: isCandy || isWood
          ? BorderRadius.circular(14)
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCandy) ...[
                    _buildLadybugIcon(size: 11),
                    const SizedBox(width: 4),
                  ],
                  _BlinkingLabel(
                    label: isCandy ? 'LADYBUG' : (isWood ? 'SLATE X' : '1UP (X)'),
                    active: isActive,
                    color: isCandy
                        ? (isActive ? Colors.redAccent.shade100 : Colors.grey.shade400)
                        : (isWood
                            ? (isActive ? const Color(0xFFFFB300) : Colors.grey.shade500)
                            : (isActive ? dullCrimson : currentTheme.textColor.withValues(alpha: 0.45))),
                    fontSize: blinkLabelFontSize,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCandy || isWood
                      ? const Color(0xFF3E2723).withValues(alpha: 0.25)
                      : (isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCandy || isWood ? Colors.black26 : (isLight ? currentTheme.mainColor.withValues(alpha: 0.15) : Colors.white10),
                  ),
                ),
                child: Text(
                  padScore(game.sessionWinsX),
                  style: TextStyle(
                    fontSize: scoreFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isCandy
                        ? const Color(0xFFFFCCBC)
                        : (isWood ? const Color(0xFFFFE0B2) : dullCrimson),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'BOARDS: ${game.boardsWonX}',
                style: TextStyle(
                  fontSize: boardsWonFontSize,
                  fontWeight: FontWeight.w900,
                  color: isCandy
                      ? Colors.orange.shade100
                      : (isWood ? const Color(0xFFFFE0B2).withValues(alpha: 0.7) : (isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey.shade500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floating glassmorphic score badge for Player O, glowing with dull steel blue.
class PlayerOScoreBadge extends StatelessWidget {
  const PlayerOScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final isActive = game.currentPlayer == Player.O && !game.isOverallGameOver;
    final dullBlue = isLight ? const Color(0xFF0D47A1) : currentTheme.colorO;

    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    // Responsive sizing based on the 4 diagonal display categories
    final double width = res.isLessThan7Inch
        ? 110.0
        : (res.is7To8Inch ? 122.0 : (res.is8To10Inch ? 135.0 : 145.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 10.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;
    final double blinkLabelFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double scoreFontSize = res.isLessThan7Inch ? 11.0 : 13.0;
    final double boardsWonFontSize = res.isLessThan7Inch ? 6.5 : 7.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63), // Warm wood plank color
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFFFB74D) : const Color(0xFF5D4037),
              width: isActive ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E), // Embossed dark wood
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? const Color(0xFFFFB300) : const Color(0xFF3E2723),
                  width: isActive ? 2.0 : 1.0,
                ),
              )
            : BoxDecoration( // Neon Cyberpulse
                color: isLight
                    ? Colors.white.withValues(alpha: 0.15)
                    : currentTheme.scaffoldBg.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(
                  color: isActive
                      ? dullBlue.withValues(alpha: 0.8)
                      : dullBlue.withValues(alpha: 0.25),
                  width: isActive ? 2.0 : 1.2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: dullBlue.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ));

    return ClipRRect(
      borderRadius: isCandy || isWood
          ? BorderRadius.circular(14)
          : const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCandy) ...[
                    _buildDonutIcon(size: 11),
                    const SizedBox(width: 4),
                  ],
                  _BlinkingLabel(
                    label: isCandy ? 'DONUT' : (isWood ? 'STONE O' : '2UP (O)'),
                    active: isActive,
                    color: isCandy
                        ? (isActive ? Colors.pinkAccent.shade100 : Colors.grey.shade400)
                        : (isWood
                            ? (isActive ? const Color(0xFFFFB300) : Colors.grey.shade500)
                            : (isActive ? dullBlue : currentTheme.textColor.withValues(alpha: 0.45))),
                    fontSize: blinkLabelFontSize,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCandy || isWood
                      ? const Color(0xFF3E2723).withValues(alpha: 0.25)
                      : (isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCandy || isWood ? Colors.black26 : (isLight ? currentTheme.mainColor.withValues(alpha: 0.15) : Colors.white10),
                  ),
                ),
                child: Text(
                  padScore(game.sessionWinsO),
                  style: TextStyle(
                    fontSize: scoreFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isCandy
                        ? const Color(0xFFFFCCBC)
                        : (isWood ? const Color(0xFFFFE0B2) : dullBlue),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'BOARDS: ${game.boardsWonO}',
                style: TextStyle(
                  fontSize: boardsWonFontSize,
                  fontWeight: FontWeight.w900,
                  color: isCandy
                      ? Colors.orange.shade100
                      : (isWood ? const Color(0xFFFFE0B2).withValues(alpha: 0.7) : (isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey.shade500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floating glassmorphic central stats plate displaying high score record, glowing with dull amber.
class HighScoreBadge extends StatelessWidget {
  const HighScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final dullAmber = isLight ? const Color(0xFFE65100) : const Color(0xFFFFB300);

    // Responsive sizing based on the 4 diagonal display categories
    final double width = res.isLessThan7Inch
        ? 96.0
        : (res.is7To8Inch ? 108.0 : (res.is8To10Inch ? 120.0 : 130.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 8.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;
    final double highLabelFontSize = res.isLessThan7Inch ? 7.0 : 8.0;
    final double scoreFontSize = res.isLessThan7Inch ? 12.0 : 14.0;
    final double cabinetFontSize = res.isLessThan7Inch ? 6.5 : 7.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63), // Warm wood plank color
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5D4037), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E), // Carved wood panel style
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3E2723), width: 1.0),
              )
            : BoxDecoration( // Neon Cyberpulse
                color: isLight
                    ? Colors.white.withValues(alpha: 0.12)
                    : currentTheme.scaffoldBg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dullAmber.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HIGH SCORE',
                style: TextStyle(
                  fontSize: highLabelFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isCandy
                      ? const Color(0xFFFFCCBC)
                      : (isWood ? const Color(0xFFFFB300) : dullAmber),
                  shadows: isLight || isCandy || isWood
                      ? []
                      : [
                          Shadow(
                            color: dullAmber.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '999990',
                style: TextStyle(
                  fontSize: scoreFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isCandy
                      ? const Color(0xFFFFB300)
                      : (isWood ? const Color(0xFFFFE0B2) : dullAmber),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isCandy ? 'SWEET PLANK' : (isWood ? 'WOOD RECORD' : 'V2 CABINET'),
                style: TextStyle(
                  fontSize: cabinetFontSize,
                  fontWeight: FontWeight.w900,
                  color: isCandy
                      ? Colors.orange.shade100
                      : (isWood ? const Color(0xFFFFE0B2).withValues(alpha: 0.6) : (isLight ? currentTheme.textColor.withValues(alpha: 0.5) : Colors.grey.shade600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildLadybugIcon({double size = 12.0}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFE53935),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Separation line
        Container(
          width: 1.0,
          height: size,
          color: Colors.black,
        ),
        // Spots
        Positioned(
          left: size * 0.15,
          top: size * 0.25,
          child: Container(width: 1.5, height: 1.5, color: Colors.black),
        ),
        Positioned(
          right: size * 0.15,
          top: size * 0.25,
          child: Container(width: 1.5, height: 1.5, color: Colors.black),
        ),
        // Head
        Positioned(
          top: 0,
          child: Container(
            width: size * 0.4,
            height: size * 0.25,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDonutIcon({double size = 12.0}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFFF4081), // Pink glazing
      border: Border.all(color: const Color(0xFFE5A882), width: size * 0.25), // Golden pastry hole
    ),
  );
}

class ArcadeScrewWidget extends StatelessWidget {
  final bool isLight;
  final double size;
  const ArcadeScrewWidget({super.key, required this.isLight, this.size = 14.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HexScrewPainter(isLight: isLight),
      ),
    );
  }
}

class HexScrewPainter extends CustomPainter {
  final bool isLight;
  HexScrewPainter({required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dark bottom shadow (depth rim)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isLight ? 0.25 : 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + 1), radius, shadowPaint);

    // 2. Beveled metal outer rim
    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: isLight
            ? [Colors.grey.shade300, Colors.grey.shade500]
            : [const Color(0xFF555562), const Color(0xFF22222A)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    // 3. Inner Hex Socket
    final hexPaint = Paint()
      ..color = isLight ? Colors.grey.shade800 : const Color(0xFF0F0F12)
      ..style = PaintingStyle.fill;

    final hexPath = Path();
    final double hexRadius = radius * 0.45;
    for (int i = 0; i < 6; i++) {
      final double angle = i * pi / 3;
      final double x = center.dx + cos(angle) * hexRadius;
      final double y = center.dy + sin(angle) * hexRadius;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    // 4. Specular reflection highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      -2.2,
      1.0,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HexScrewPainter oldDelegate) => oldDelegate.isLight != isLight;
}

class InteractiveJoystickWidget extends StatefulWidget {
  final double size;
  const InteractiveJoystickWidget({super.key, this.size = 72.0});

  @override
  State<InteractiveJoystickWidget> createState() => _InteractiveJoystickWidgetState();
}

class _InteractiveJoystickWidgetState extends State<InteractiveJoystickWidget> with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    
    // Ball top color matches the active theme
    Color ballColor = const Color(0xFFFF1744); // Neon default red
    if (activeTheme.name.contains('Candy Meadow')) {
      ballColor = const Color(0xFFFF4081); // Candy pink
    } else if (activeTheme.name.contains('Woodville Carve')) {
      ballColor = const Color(0xFFFF9100); // Amber orange
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onHover: (event) {
        final double halfSize = widget.size / 2;
        final double dx = (event.localPosition.dx - halfSize) / halfSize;
        final double dy = (event.localPosition.dy - halfSize) / halfSize;
        setState(() {
          _tiltX = dx.clamp(-1.0, 1.0);
          _tiltY = dy.clamp(-1.0, 1.0);
        });
      },
      onExit: (_) => setState(() {
        _isHovered = false;
        _tiltX = 0.0;
        _tiltY = 0.0;
      }),
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          // If not hovered, sway gently in a slow infinite circle
          double finalTiltX = _tiltX;
          double finalTiltY = _tiltY;
          if (!_isHovered) {
            final double angle = _idleController.value * 2 * pi;
            finalTiltX = cos(angle) * 0.18;
            finalTiltY = sin(angle) * 0.18;
          }

          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: JoystickPainter(
              tiltX: finalTiltX,
              tiltY: finalTiltY,
              ballColor: ballColor,
              isLight: activeTheme.brightness == Brightness.light,
            ),
          );
        },
      ),
    );
  }
}

class JoystickPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;
  final Color ballColor;
  final bool isLight;

  JoystickPainter({
    required this.tiltX,
    required this.tiltY,
    required this.ballColor,
    required this.isLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    // 1. Dark Recess Hole Well
    final wellPaint = Paint()
      ..shader = RadialGradient(
        colors: isLight
            ? [Colors.grey.shade400, Colors.grey.shade600]
            : [const Color(0xFF070709), const Color(0xFF202028)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, wellPaint);

    final wellBorder = Paint()
      ..color = isLight ? Colors.grey.shade700 : const Color(0xFF33333E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, wellBorder);

    // 2. Black Rubber Dust Washer
    final double washerRadius = radius * 0.6;
    final Offset washerCenter = center + Offset(tiltX * radius * 0.14, tiltY * radius * 0.14);
    
    final washerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(washerCenter.dx, washerCenter.dy + 1.5), washerRadius, washerShadow);

    final washerPaint = Paint()
      ..color = isLight ? const Color(0xFF222222) : const Color(0xFF15151A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(washerCenter, washerRadius, washerPaint);

    // Inner well hole inside washer
    final washerHolePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(washerCenter, washerRadius * 0.25, washerHolePaint);

    // 3. Chrome Shaft
    final Offset ballCenter = center + Offset(tiltX * radius * 0.42, tiltY * radius * 0.42);
    
    final shaftShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = radius * 0.16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(washerCenter + const Offset(1, 2), ballCenter + const Offset(1, 2), shaftShadowPaint);

    final shaftPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade300, Colors.white, Colors.grey.shade500, Colors.grey.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(washerCenter, ballCenter))
      ..strokeWidth = radius * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(washerCenter, ballCenter, shaftPaint);

    // 4. sphere Ball Top
    final double ballRadius = radius * 0.38;
    
    final ballShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset(ballCenter.dx + 2, ballCenter.dy + 4), ballRadius, ballShadow);

    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(ballColor, Colors.white, 0.4)!,
          ballColor,
          Color.lerp(ballColor, Colors.black, 0.5)!,
        ],
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    // Specular high gloss white shine on ball
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter + Offset(-ballRadius * 0.3, -ballRadius * 0.3), ballRadius * 0.18, shinePaint);
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) =>
      oldDelegate.tiltX != tiltX || oldDelegate.tiltY != tiltY || oldDelegate.ballColor != ballColor || oldDelegate.isLight != isLight;
}

class GlowingCoinSlotWidget extends StatefulWidget {
  const GlowingCoinSlotWidget({super.key});

  @override
  State<GlowingCoinSlotWidget> createState() => _GlowingCoinSlotWidgetState();
}

class _GlowingCoinSlotWidgetState extends State<GlowingCoinSlotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final isLight = activeTheme.brightness == Brightness.light;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final double val = _glowController.value;
        // Pulsing high-contrast amber/neon orange glow
        final orangeGlow = const Color(0xFFFF3D00).withValues(alpha: 0.35 + 0.65 * val);
        final textColor = isLight ? const Color(0xFFD84315) : const Color(0xFFFF6D00);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLight ? Colors.grey.shade200 : const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isLight ? Colors.grey.shade400 : const Color(0xFF33333E),
              width: 1.5,
            ),
            boxShadow: isLight
                ? []
                : [
                    BoxShadow(
                      color: orangeGlow.withValues(alpha: orangeGlow.a * 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vertical glowing coin slot opening
              Container(
                width: 3.5,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF070709),
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(
                    color: orangeGlow,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orangeGlow,
                      blurRadius: 3 * val,
                      spreadRadius: 0.5 * val,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stenciled text
              Text(
                'INSERT COIN',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: textColor,
                  shadows: isLight
                      ? []
                      : [
                          Shadow(
                            color: textColor.withValues(alpha: 0.6),
                            blurRadius: 3,
                          ),
                        ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A beautiful, drifting, glassmorphic HUD badge that displays live tactical suggestions,
/// active rule telemetry, XP gains, and dynamic AI status to keep the player highly hooked!
class TacticalTelemetryBadge extends StatelessWidget {
  const TacticalTelemetryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final statsService = context.watch<StatsService>();
    
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    // Dynamic Level & XP values
    final currentStats = statsService.stats;
    final int totalXp = isGuest ? 0 : currentStats.totalXp;
    
    // Simple level calculation: 1 level per 500 XP baseline
    final int level = isGuest ? 1 : ((totalXp / 500).floor() + 1);
    final int xpInLevel = isGuest ? 0 : (totalXp % 500);
    final double xpProgress = isGuest ? 0.0 : ((xpInLevel / 500.0).clamp(0.0, 1.0));

    // Exciting warm alert/suggestion ticker based on current board state
    String suggestion = isGuest ? "SIGN UP TO SAVE YOUR LEVEL & STATS" : "READY PLAYER ONE • PLAN YOUR NEXT MOVE";
    Color telemetryColor = isGuest
        ? (isLight ? const Color(0xFFD84315) : const Color(0xFFFF7043))
        : (isLight ? const Color(0xFFE65100) : const Color(0xFFFFB300));

    if (game.isOverallGameOver) {
      suggestion = "GAME OVER • GREAT MATCH!";
      telemetryColor = isLight ? Colors.green.shade700 : Colors.greenAccent;
    } else if (game.isAiThinking) {
      suggestion = "THE COMPUTER IS PLANNING A MOVE...";
      telemetryColor = isLight ? Colors.purple.shade700 : Colors.purpleAccent;
    } else if (game.currentPlayer == Player.O) {
      suggestion = "WAITING FOR OPPONENT'S TURN...";
      telemetryColor = isLight ? Colors.red.shade700 : Colors.redAccent;
    } else if (!isGuest) {
      // Analyze current board status for threats
      bool boardThreat = false;
      int forcedIdx = game.forcedBoardIndex ?? -1;
      if (forcedIdx != -1 && forcedIdx < game.boards.length && !game.boards[forcedIdx].isGameOver) {
        if (game.boards[forcedIdx].hasThreat(Player.O)) {
          suggestion = "CAREFUL • OPPONENT MIGHT WIN BOARD ${forcedIdx + 1}!";
          telemetryColor = isLight ? Colors.red.shade700 : Colors.redAccent;
          boardThreat = true;
        }
      }
      if (!boardThreat) {
        if (settings.ruleSet == GameRuleSet.ultimate && forcedIdx != -1) {
          suggestion = "NOTICE • YOU MUST PLAY ON BOARD ${forcedIdx + 1}";
        } else if (settings.ruleSet == GameRuleSet.chaos && (game.shieldCardsX > 0 || game.eraserCardsX > 0)) {
          suggestion = "POWER-UP AVAILABLE • USE A CARD NOW!";
          telemetryColor = isLight ? Colors.blue.shade700 : Colors.cyanAccent;
        } else {
          suggestion = "YOUR TURN • TAP ANY OPEN CELL TO PLAY!";
        }
      }
    }

    final double width = res.isLessThan7Inch ? 230.0 : 280.0;
    final double titleFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double progressHeight = res.isLessThan7Inch ? 4.0 : 6.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFFF5F5DC), // Warm cream
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF3E2723).withValues(alpha: 0.85), // Rich warm dark wood
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF271510), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration( // Neon Cyberpulse
                color: isLight
                    ? Colors.white.withValues(alpha: 0.2)
                    : currentTheme.scaffoldBg.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentTheme.mainColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.mainColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: XP & Level Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGuest ? 'GUEST MODE (STATS LOCKED)' : 'LVL $level PROGRESSION',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: isGuest
                          ? (isLight ? const Color(0xFFD84315) : const Color(0xFFFF7043))
                          : (isCandy
                              ? const Color(0xFF5D4037)
                              : (isWood ? const Color(0xFFFFB74D) : currentTheme.textColor.withValues(alpha: 0.7))),
                    ),
                  ),
                  Text(
                    '$xpInLevel/500 XP',
                    style: TextStyle(
                      fontSize: titleFontSize - 1.0,
                      fontWeight: FontWeight.w900,
                      color: isCandy
                          ? const Color(0xFF8D6E63)
                          : (isWood ? const Color(0xFFFFB74D).withValues(alpha: 0.8) : currentTheme.textColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // XP Progress Bar
              Container(
                height: progressHeight,
                decoration: BoxDecoration(
                  color: isCandy || isWood
                      ? Colors.black12
                      : currentTheme.textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: xpProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCandy
                            ? [const Color(0xFFFF4081), const Color(0xFFFF80AB)]
                            : (isWood
                                ? [const Color(0xFFFFB300), const Color(0xFFFFE082)]
                                : [currentTheme.mainColor, currentTheme.accentGlow]),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Live Tactical Suggestion Ticker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCandy || isWood ? Colors.black12 : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    // Dynamic small blinking beacon
                    _LiveBeacon(color: telemetryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: titleFontSize - 1.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: telemetryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBeacon extends StatefulWidget {
  final Color color;
  const _LiveBeacon({required this.color});

  @override
  State<_LiveBeacon> createState() => _LiveBeaconState();
}

class _LiveBeaconState extends State<_LiveBeacon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
