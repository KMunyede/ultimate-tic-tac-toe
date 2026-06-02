// lib/features/game/screens/game_screen.dart

import 'dart:async';
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
import '../../../widgets/profile_stats_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/player.dart';
import '../../../utils/responsive_layout.dart';
import '../../../widgets/animal_peeking_layer.dart';
import '../widgets/floating_cloud_button.dart';
import '../widgets/turn_telemetry_header.dart';
import '../logic/end_game_hooks.dart';
import '../../../widgets/board/clay_bevel_painter.dart';

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
          child: ShaderMask(
            shaderCallback: (rect) {
              return RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.85, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
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
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  // 4. Peeking Animated Animals Layer
                  const Positioned.fill(
                    child: AnimalPeekingLayer(),
                  ),
                ],
              ),
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

