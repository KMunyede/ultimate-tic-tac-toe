// lib/features/game/screens/game_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../settings/widgets/settings_menu.dart';
import '../../../widgets/game_board.dart';
import '../../../widgets/animated_vibrant_background.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/animations/holographic_tilt.dart';
import '../../../widgets/board_widget.dart';
import '../../../widgets/profile_stats_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/player.dart';
import '../../../utils/responsive_layout.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  StreamSubscription? _aiErrorSubscription;
  DateTime? _lastPressed;
  bool _isResumeDialogShowing = false;
  bool _dismissedGameOverCard = false;
  bool _showGameOverCard = false;
  bool _gameOverDelayActive = false;
  Timer? _gameOverTimer;

  Widget _buildMetricItem(String label, String value, AppTheme theme, {bool isHighlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withValues(alpha: 0.5),
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? theme.mainColor : theme.textColor,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final game = context.read<GameController>();
    _aiErrorSubscription = game.aiErrorStream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiErrorSubscription?.cancel();
    _gameOverTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<GameController>().saveCurrentState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSpacing = screenWidth < 380 ? 4.0 : (screenWidth < 480 ? 8.0 : 10.0);

    final res = ResponsiveLayout(context);
    final bool isTablet = res.deviceType == DeviceType.tablet || res.deviceType == DeviceType.desktop;
    final bool isLandscape = res.isLandscape;
    final bool useSidePanel = !isTablet && isLandscape; // Phone in landscape uses side panel!

    // Check for pending cloud session and show dialog safely to prevent duplicate push loops
    if (game.hasPendingCloudSession) {
      if (!_isResumeDialogShowing) {
        _isResumeDialogShowing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResumeDialog(context, game);
        });
      }
    } else {
      _isResumeDialogShowing = false;
    }

    final isGameOver = game.isOverallGameOver;
    if (isGameOver && !_dismissedGameOverCard && !_gameOverDelayActive) {
      _gameOverDelayActive = true;
      _gameOverTimer?.cancel();
      _gameOverTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) {
          setState(() {
            _showGameOverCard = true;
          });
        }
      });
    }
    if (!isGameOver) {
      _gameOverTimer?.cancel();
      _gameOverDelayActive = false;
      _showGameOverCard = false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressed == null ||
            now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _lastPressed = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () {
          final settings = context.read<SettingsController>();
          settings.toggleBoardLayout();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Layout: ${settings.currentLayoutName}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                textAlign: TextAlign.center,
              ),
              backgroundColor: settings.currentTheme.mainColor.withValues(alpha: 0.9),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              width: 240,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            ),
          );
        },
        child: AnimatedVibrantBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Expanded MultiBoardView Container
                  if (useSidePanel)
                    const Positioned(
                      left: 8.0,
                      right: 290.0, // Space on the right for the side panel!
                      top: 8.0,
                      bottom: 8.0,
                      child: InteractiveHolographicTilt(
                        child: MultiBoardView(),
                      ),
                    )
                  else
                    const Positioned(
                      left: 8.0,
                      right: 8.0,
                      top: 84.0, // Shifted down to accommodate the floating TurnTelemetryHeader!
                      bottom: 84.0, // Reserves height for the floating cloud buttons at the bottom!
                      child: InteractiveHolographicTilt(
                        child: MultiBoardView(),
                      ),
                    ),

                  // Turn & Last Move Telemetry Header & Bottom Controls
                  if (useSidePanel)
                    Positioned(
                      right: 12.0,
                      top: 8.0,
                      bottom: 8.0,
                      width: 270.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TurnTelemetryHeader(
                            game: game,
                            settings: settings,
                          ),
                          const SizedBox(height: 12.0),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FloatingCloudButton(
                                  label: 'START',
                                  icon: Icons.play_arrow_rounded,
                                  onTap: () {
                                    context.read<SoundManager>().playMoveSound();
                                    game.resetGame();
                                    setState(() {
                                      _dismissedGameOverCard = false;
                                    });
                                  },
                                ),
                                FloatingCloudButton(
                                  label: 'CONFIG',
                                  icon: Icons.tune_rounded,
                                  onTap: () {
                                    context.read<SoundManager>().playMoveSound();
                                    showDialog(
                                      context: context,
                                      builder: (context) => const SettingsMenu(),
                                    );
                                  },
                                ),
                                FloatingCloudButton(
                                  label: game.isPaused ? 'RESUME' : 'PAUSE',
                                  icon: game.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                                  onTap: (game.isOverallGameOver || game.boards.isEmpty)
                                      ? null
                                      : () {
                                          context.read<SoundManager>().playMoveSound();
                                          game.togglePause();
                                        },
                                ),
                                FloatingCloudButton(
                                  label: 'PROFILE',
                                  icon: Icons.person_outline,
                                  onTap: () {
                                    context.read<SoundManager>().playMoveSound();
                                    showDialog(
                                      context: context,
                                      builder: (context) => const ProfileStatsDialog(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Turn & Last Move Telemetry Header
                    Positioned(
                      top: 12.0,
                      left: 16.0,
                      right: 16.0,
                      height: 60.0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TurnTelemetryHeader(
                            game: game,
                            settings: settings,
                          ),
                        ),
                      ),
                    ),

                    // Gentle Floating Cloud Buttons (Start, Config, Pause, Profile)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingCloudButton(
                            label: 'START',
                            icon: Icons.play_arrow_rounded,
                            onTap: () {
                              context.read<SoundManager>().playMoveSound();
                              game.resetGame();
                              setState(() {
                                _dismissedGameOverCard = false;
                              });
                            },
                          ),
                          SizedBox(width: buttonSpacing),
                          FloatingCloudButton(
                            label: 'CONFIG',
                            icon: Icons.tune_rounded,
                            onTap: () {
                              context.read<SoundManager>().playMoveSound();
                              showDialog(
                                context: context,
                                builder: (context) => const SettingsMenu(),
                              );
                            },
                          ),
                          SizedBox(width: buttonSpacing),
                          FloatingCloudButton(
                            label: game.isPaused ? 'RESUME' : 'PAUSE',
                            icon: game.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                            onTap: (game.isOverallGameOver || game.boards.isEmpty)
                                ? null
                                : () {
                                    context.read<SoundManager>().playMoveSound();
                                    game.togglePause();
                                  },
                          ),
                          SizedBox(width: buttonSpacing),
                          FloatingCloudButton(
                            label: 'PROFILE',
                            icon: Icons.person_outline,
                            onTap: () {
                              context.read<SoundManager>().playMoveSound();
                              showDialog(
                                context: context,
                                builder: (context) => const ProfileStatsDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Premium Frosted Pause Screen Overlay
                  if (game.isPaused)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_filled_rounded, size: 100, color: Colors.white),
                                    onPressed: () {
                                      context.read<SoundManager>().playMoveSound();
                                      game.togglePause();
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'GAME PAUSED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap the play button to resume',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Premium Frosted End-Game Pop-Up Card
                  if (_showGameOverCard && !_dismissedGameOverCard)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Center(
                              child: Hero(
                                tag: 'game_over_card',
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                                  constraints: const BoxConstraints(maxWidth: 400),
                                  decoration: BoxDecoration(
                                    color: theme.boardBg.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(28.0),
                                    border: Border.all(
                                      color: theme.mainColor.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 25.0,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: theme.name == 'Rushing Wind'
                                        ? ClayBevelPainter(
                                            borderRadius: 28.0,
                                            baseColor: theme.boardBg,
                                            themeName: theme.name,
                                          )
                                        : null,
                                    child: Stack(
                                      children: [
                                        SingleChildScrollView(
                                          padding: const EdgeInsets.fromLTRB(24.0, 36.0, 24.0, 24.0), // Extra top padding to clear close button
                                          child: Builder(
                                            builder: (context) {
                                              final hook = EndGameHooks.getHook(game.matchWinner, game.isMatchDraw, game.matchId);
                                              
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Icon Emblem
                                                  Container(
                                                    padding: const EdgeInsets.all(16.0),
                                                    decoration: BoxDecoration(
                                                      color: theme.mainColor.withValues(alpha: 0.15),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      game.matchWinner == Player.X
                                                          ? Icons.emoji_events_rounded
                                                          : (game.matchWinner == Player.O
                                                              ? Icons.emoji_events_rounded
                                                              : (game.isMatchDraw
                                                                  ? Icons.handshake_rounded
                                                                  : Icons.refresh_rounded)),
                                                      size: 64.0,
                                                      color: game.matchWinner == Player.X
                                                          ? theme.mainColor
                                                          : (game.matchWinner == Player.O
                                                              ? theme.accentGlow
                                                              : theme.textColor),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  // Title / Message from dynamic hooks
                                                  Text(
                                                    hook.title,
                                                    style: TextStyle(
                                                      color: theme.textColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18.0,
                                                      letterSpacing: 1.5,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 12.0),
                                                  Text(
                                                    hook.description,
                                                    style: TextStyle(
                                                      color: theme.textColor.withValues(alpha: 0.8),
                                                      fontSize: 13.5,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  // Telemetry Stats Divider
                                                  Container(
                                                    height: 1.0,
                                                    color: theme.textColor.withValues(alpha: 0.15),
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  // Telemetry Metrics Row
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      _buildMetricItem(
                                                        "SECTOR WINS",
                                                        "${game.boardsWonX} - ${game.boardsWonO}",
                                                        theme,
                                                      ),
                                                      Container(
                                                        width: 1.0,
                                                        height: 36.0,
                                                        color: theme.textColor.withValues(alpha: 0.15),
                                                      ),
                                                      _buildMetricItem(
                                                        "XP REWARD",
                                                        settings.isGuest ? "🔒 SIGN UP" : "+100 XP",
                                                        theme,
                                                        isHighlight: !settings.isGuest,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24.0),
                                                  // Action Buttons Row (Reduced bottom clutter)
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: ElevatedButton.icon(
                                                          onPressed: () {
                                                            context.read<SoundManager>().playMoveSound();
                                                            game.resetGame();
                                                            setState(() {
                                                              _dismissedGameOverCard = false;
                                                            });
                                                          },
                                                          icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                                                          label: const Text(
                                                            "BATTLE AGAIN",
                                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0, letterSpacing: 0.5),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: theme.mainColor,
                                                            foregroundColor: Colors.white,
                                                            minimumSize: const Size.fromHeight(48.0),
                                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                            elevation: 4.0,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(14.0),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12.0),
                                                      Expanded(
                                                        flex: 1,
                                                        child: OutlinedButton.icon(
                                                          onPressed: () {
                                                            context.read<SoundManager>().playMoveSound();
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => const ProfileStatsDialog(),
                                                            );
                                                          },
                                                          icon: Icon(Icons.person_outline, color: theme.textColor, size: 18),
                                                          label: Text(
                                                            "STATS",
                                                            style: TextStyle(
                                                              color: theme.textColor,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12.0,
                                                            ),
                                                          ),
                                                          style: OutlinedButton.styleFrom(
                                                            side: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
                                                            minimumSize: const Size.fromHeight(48.0),
                                                            padding: EdgeInsets.zero,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(14.0),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }
                                          ),
                                        ),
                                        Positioned(
                                          top: 8.0,
                                          right: 8.0,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.0),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.close_rounded,
                                                  color: theme.textColor.withValues(alpha: 0.6),
                                                  size: 22.0,
                                                ),
                                                onPressed: () {
                                                  context.read<SoundManager>().playMoveSound();
                                                  setState(() {
                                                    _dismissedGameOverCard = true;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Sliding Gameplay Encouragement Banner (Tactile HUD Toast)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    top: game.liveBannerText != null ? (useSidePanel ? 12.0 : 80.0) : -100.0,
                    left: useSidePanel ? 12.0 : 20.0,
                    right: useSidePanel ? 290.0 : 20.0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        decoration: BoxDecoration(
                          color: theme.boardBg,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: NeumorphicColors.getDarkShadow(theme.boardBg),
                              offset: const Offset(4, 4),
                              blurRadius: 10,
                            ),
                            BoxShadow(
                              color: NeumorphicColors.getLightShadow(theme.boardBg),
                              offset: const Offset(-4, -4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: theme.name == 'Rushing Wind'
                              ? ClayBevelPainter(
                                  borderRadius: 20.0,
                                  baseColor: theme.boardBg,
                                  themeName: theme.name,
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Colors.orangeAccent),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    game.liveBannerText ?? "",
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResumeDialog(BuildContext context, GameController game) {
    final theme = Theme.of(context);
    final isCurrentGamePristine = game.boards.every((b) => b.cells.every((c) => c == Player.none));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume Game?'),
        content: Text(
          isCurrentGamePristine
              ? 'We found an unfinished game in the cloud. Would you like to continue or start a fresh match?'
              : 'We found an unfinished game in the cloud. Would you like to resume it, or continue your current guest game?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              game.resolvePendingSession(resume: false);
              if (mounted) {
                setState(() {
                  _dismissedGameOverCard = false;
                });
              }
            },
            child: Text(isCurrentGamePristine ? 'START NEW' : 'KEEP CURRENT'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              game.resolvePendingSession(resume: true);
              if (mounted) {
                setState(() {
                  _dismissedGameOverCard = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: const Color(0xFF0D47A1), // Dark Blue to match Player O / Tiles
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('RESUME PREVIOUS'),
          ),
        ],
      ),
    );
  }
}

class FloatingCloudButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const FloatingCloudButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<FloatingCloudButton> createState() => _FloatingCloudButtonState();
}

class _FloatingCloudButtonState extends State<FloatingCloudButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;

    // Build theme-specific decoration and text colors!
    Decoration buttonDec;
    Color contentColor;
    BorderRadius btnRadius = BorderRadius.circular(30.0);

    if (theme.name == 'Rushing Wind') {
      // Warm Clay button style
      btnRadius = BorderRadius.circular(20.0);
      buttonDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: btnRadius,
        boxShadow: [
          BoxShadow(
            color: NeumorphicColors.getDarkShadow(theme.boardBg),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: NeumorphicColors.getLightShadow(theme.boardBg),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.mainColor; // Muted Sage Green
    } else if (theme.name == 'Floating Feather') {
      // Smooth peach paper button
      btnRadius = BorderRadius.circular(16.0);
      buttonDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: btnRadius,
        border: Border.all(color: const Color(0xFFB5937E).withValues(alpha: 0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB5937E).withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.mainColor;
    } else if (theme.name == 'Rising Moon') {
      // Frosted twilight neon glass button
      btnRadius = BorderRadius.circular(30.0);
      buttonDec = BoxDecoration(
        color: const Color(0xFF453D4D).withValues(alpha: 0.30),
        borderRadius: btnRadius,
        border: Border.all(color: theme.mainColor.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.mainColor.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.mainColor;
    } else if (theme.name == 'Drifting Cloud') {
      // Blocky stone button
      btnRadius = BorderRadius.circular(8.0);
      buttonDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: btnRadius,
        border: Border.all(color: theme.textColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: theme.textColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );
      contentColor = theme.mainColor;
    } else if (theme.name == 'Crimson Leaf') {
      // Red lacquer button with gold trim
      btnRadius = BorderRadius.circular(12.0);
      buttonDec = BoxDecoration(
        color: theme.mainColor, // Autumn Crimson
        borderRadius: btnRadius,
        border: Border.all(color: theme.accentGlow, width: 1.5), // Gold trim
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.accentGlow; // glistening gold text!
    } else {
      // Fallback: Default powdery soft cloud button
      buttonDec = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: btnRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
            blurRadius: 18.0,
            spreadRadius: 1.0,
          ),
        ],
      );
      contentColor = theme.mainColor;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isVeryNarrow = screenWidth < 380;
    final bool isNarrow = screenWidth < 480;
    final bool isTablet = screenWidth >= 600;

    final double horizPadding = isVeryNarrow ? 6.0 : (isNarrow ? 10.0 : (isTablet ? 30.0 : 22.0));
    final double vertPadding = isVeryNarrow ? 8.0 : (isNarrow ? 10.0 : (isTablet ? 16.0 : 12.0));
    final double iconSize = isVeryNarrow ? 12.0 : (isNarrow ? 15.0 : (isTablet ? 22.0 : 18.0));
    final double fontSize = isVeryNarrow ? 9.2 : (isNarrow ? 11.0 : (isTablet ? 16.0 : 14.0));
    final double spacing = isVeryNarrow ? 2.0 : (isNarrow ? 4.0 : (isTablet ? 10.0 : 8.0));

    final bool isEnabled = widget.onTap != null;

    Widget buttonBody = Opacity(
      opacity: isEnabled ? 1.0 : 0.42,
      child: Container(
        decoration: buttonDec,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: btnRadius,
            onTap: isEnabled ? widget.onTap : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizPadding,
                vertical: vertPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: iconSize, color: contentColor),
                  SizedBox(width: spacing),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: contentColor.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      letterSpacing: isNarrow ? 0.6 : 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Apply BackdropFilter blur only for Rising Moon (neon glass) to achieve premium frosted tab glass!
    if (theme.name == 'Rising Moon') {
      buttonBody = ClipRRect(
        borderRadius: btnRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: buttonBody,
        ),
      );
    } else if (theme.name == 'Rushing Wind') {
      // Wrap Rushing Wind buttons in a ClayBevelPainter to match the clay cards!
      buttonBody = CustomPaint(
        painter: ClayBevelPainter(
          borderRadius: 20.0,
          baseColor: theme.boardBg,
          themeName: theme.name,
        ),
        child: buttonBody,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = sin(_controller.value * 2 * pi) * 4.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: buttonBody,
    );
  }
}

// ==========================================
//           TURN & TELEMETRY WIDGETS
// ==========================================

class TurnTelemetryHeader extends StatelessWidget {
  final GameController game;
  final SettingsController settings;

  const TurnTelemetryHeader({
    super.key,
    required this.game,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = settings.currentTheme;
    final activePlayer = game.currentPlayer;
    final isThinking = game.isAiThinking;
    
    // Theme-specific styles matching FloatingCloudButton
    BorderRadius headerRadius = BorderRadius.circular(20.0);
    Decoration headerDec;
    Color contentColor = theme.mainColor;

    if (theme.name == 'Rushing Wind') {
      headerRadius = BorderRadius.circular(20.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        boxShadow: [
          BoxShadow(
            color: NeumorphicColors.getDarkShadow(theme.boardBg),
            offset: const Offset(3, 3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: NeumorphicColors.getLightShadow(theme.boardBg),
            offset: const Offset(-3, -3),
            blurRadius: 8,
          ),
        ],
      );
    } else if (theme.name == 'Floating Feather') {
      headerRadius = BorderRadius.circular(16.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        border: Border.all(color: const Color(0xFFB5937E).withValues(alpha: 0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB5937E).withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
    } else if (theme.name == 'Rising Moon') {
      headerRadius = BorderRadius.circular(20.0);
      headerDec = BoxDecoration(
        color: const Color(0xFF453D4D).withValues(alpha: 0.30),
        borderRadius: headerRadius,
        border: Border.all(color: theme.mainColor.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.mainColor.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
    } else if (theme.name == 'Drifting Cloud') {
      headerRadius = BorderRadius.circular(8.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        border: Border.all(color: theme.textColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: theme.textColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );
    } else if (theme.name == 'Crimson Leaf') {
      headerRadius = BorderRadius.circular(12.0);
      headerDec = BoxDecoration(
        color: theme.mainColor,
        borderRadius: headerRadius,
        border: Border.all(color: theme.accentGlow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.accentGlow;
    } else {
      headerDec = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: headerRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
            blurRadius: 18.0,
          ),
        ],
      );
    }

    Widget headerBody = Container(
      decoration: headerDec,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // 1. MiniTurnBoard
          MiniTurnBoard(
            player: activePlayer,
            isThinking: isThinking,
            theme: theme,
          ),
          const SizedBox(width: 14.0),
          // 2. Active Player / AI Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isThinking ? "AI THINKING" : "ACTIVE PLAYER",
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isThinking 
                      ? "Thinking of a clever move..." 
                      : (settings.gameMode == GameMode.playerVsAi && activePlayer == Player.O
                          ? "AI Turn (O)"
                          : "Player ${activePlayer == Player.X ? "X" : "O"}'s Turn"),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );

    if (theme.name == 'Rising Moon') {
      headerBody = ClipRRect(
        borderRadius: headerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: headerBody,
        ),
      );
    } else if (theme.name == 'Rushing Wind') {
      headerBody = CustomPaint(
        painter: ClayBevelPainter(
          borderRadius: 20.0,
          baseColor: theme.boardBg,
          themeName: theme.name,
        ),
        child: headerBody,
      );
    }

    return headerBody;
  }
}

class MiniTurnBoard extends StatefulWidget {
  final Player player;
  final bool isThinking;
  final AppTheme theme;

  const MiniTurnBoard({
    super.key,
    required this.player,
    required this.isThinking,
    required this.theme,
  });

  @override
  State<MiniTurnBoard> createState() => _MiniTurnBoardState();
}

class _MiniTurnBoardState extends State<MiniTurnBoard> with SingleTickerProviderStateMixin {
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
    final Color playerColor = widget.player == Player.X 
        ? widget.theme.colorX 
        : widget.theme.colorO;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseVal = widget.isThinking 
            ? 0.3 + (_pulseController.value * 0.7) 
            : 0.6 + (_pulseController.value * 0.4);
        
        return Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: widget.theme.boardBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: playerColor.withValues(alpha: pulseVal),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: playerColor.withValues(alpha: pulseVal * 0.3),
                blurRadius: widget.isThinking ? 8.0 : 4.0,
                spreadRadius: widget.isThinking ? 1.0 : 0.0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _MiniTurnBoardPainter(
              player: widget.player,
              isThinking: widget.isThinking,
              color: playerColor,
              pulse: _pulseController.value,
            ),
          ),
        );
      },
    );
  }
}

class _MiniTurnBoardPainter extends CustomPainter {
  final Player player;
  final bool isThinking;
  final Color color;
  final double pulse;

  _MiniTurnBoardPainter({
    required this.player,
    required this.isThinking,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Draw tiny 3x3 grid lines
    final paintGrid = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Vertical grid lines
    canvas.drawLine(Offset(w / 3, 4), Offset(w / 3, h - 4), paintGrid);
    canvas.drawLine(Offset(2 * w / 3, 4), Offset(2 * w / 3, h - 4), paintGrid);
    // Horizontal grid lines
    canvas.drawLine(Offset(4, h / 3), Offset(w - 4, h / 3), paintGrid);
    canvas.drawLine(Offset(4, 2 * h / 3), Offset(w - 4, 2 * h / 3), paintGrid);

    // Draw active player symbol (X or O) in the center cell
    final double cx = w / 2;
    final double cy = h / 2;
    final double symbolSize = w / 6;

    final paintSymbol = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (player == Player.X) {
      canvas.drawLine(
        Offset(cx - symbolSize, cy - symbolSize),
        Offset(cx + symbolSize, cy + symbolSize),
        paintSymbol,
      );
      canvas.drawLine(
        Offset(cx + symbolSize, cy - symbolSize),
        Offset(cx - symbolSize, cy + symbolSize),
        paintSymbol,
      );
    } else if (player == Player.O) {
      if (isThinking) {
        final double radius = symbolSize;
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
        final double startAngle = pulse * 2 * pi;
        canvas.drawArc(rect, startAngle, 1.5 * pi, false, paintSymbol);
      } else {
        canvas.drawCircle(Offset(cx, cy), symbolSize, paintSymbol);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTurnBoardPainter oldDelegate) =>
      oldDelegate.player != player ||
      oldDelegate.isThinking != isThinking ||
      oldDelegate.color != color ||
      oldDelegate.pulse != pulse;
}

// ==========================================
//          END GAME HOOKS TELEMETRY
// ==========================================

class EndGameHook {
  final String title;
  final String description;
  const EndGameHook(this.title, this.description);
}

class EndGameHooks {
  static const List<EndGameHook> xWinHooks = [
    EndGameHook("🏆 YOU WON THE GAME!", "Superb moves! You played perfectly and claimed the victory."),
    EndGameHook("🎉 AMAZING VICTORY!", "Fantastic game! You found the winning spots and won the match."),
    EndGameHook("🌟 BRILLIANT PLAY!", "You played wonderfully and took over the board. Excellent job!"),
    EndGameHook("🎯 YOU CRACKED THE GRID!", "Every single move was spot on. What a spectacular win!"),
  ];

  static const List<EndGameHook> oWinHooks = [
    EndGameHook("🤖 THE COMPUTER WON THIS ROUND", "The computer made some clever moves. Let's try again!"),
    EndGameHook("🔋 NICE TRY!", "That was a tough match! Reset the board and see if you can win next time."),
    EndGameHook("👾 THE COMPUTER SCORED", "The AI got the winning line first. Challenge it to another game!"),
    EndGameHook("💡 GOOD GAME!", "You played well, but the computer was just one step ahead. Try again!"),
  ];

  static const List<EndGameHook> drawHooks = [
    EndGameHook("🤝 IT'S A TIE!", "An exceptionally even game! Both players matched each other move for move."),
    EndGameHook("⚡ EVEN MATCH!", "No one gave up an inch! A perfectly balanced game from start to finish."),
    EndGameHook("🌈 GREAT GAME TO BOTH!", "You both played brilliantly and finished in a perfect draw. Ready for a tiebreaker?"),
  ];

  static EndGameHook getHook(Player? winner, bool isDraw, int matchId) {
    if (winner == Player.X) {
      return xWinHooks[matchId % xWinHooks.length];
    } else if (winner == Player.O) {
      return oWinHooks[matchId % oWinHooks.length];
    } else {
      return drawHooks[matchId % drawHooks.length];
    }
  }
}
