import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../settings/widgets/settings_menu.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/game_board.dart';
import '../../../widgets/help_dialog.dart';
import '../../../widgets/profile_stats_dialog.dart'; 
import '../../../widgets/power_up_hand_widget.dart'; 
import '../../../widgets/animated_vibrant_background.dart'; 
import '../../../widgets/arcade_cabinet_widgets.dart'; // Added Import
import '../../../widgets/game_mode_toggle.dart';
import '../../auth/services/auth_service.dart';
import '../../../utils/responsive_layout.dart';
import '../../../models/player.dart';
import '../../../widgets/animations/holographic_tilt.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  StreamSubscription? _aiErrorSubscription;
  DateTime? _lastPressed;
  Timer? _inactivityTimer;
  bool _isAutoPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final game = context.read<GameController>();
    _startInactivityTimer();
    _aiErrorSubscription = game.aiErrorStream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isAutoPaused) return; 
    
    // Feature Gate: Pause/Resume only available for Registered users
    final settings = context.read<SettingsController>();
    if (settings.isGuest) return;
    
    _inactivityTimer = Timer(const Duration(minutes: 1), () {
      if (mounted && !context.read<GameController>().isOverallGameOver) {
        setState(() {
          _isAutoPaused = true;
        });
      }
    });
  }

  void _resetInactivityTimer() {
    if (_isAutoPaused) return;
    _startInactivityTimer();
  }

  void _resumeFromInactivity() {
    setState(() {
      _isAutoPaused = false;
    });
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _aiErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = context.read<GameController>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Save state when switching apps or locking screen
      game.saveCurrentState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final soundManager = context.read<SoundManager>();
    
    // Check for pending cloud session and show dialog
    if (game.hasPendingCloudSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeDialog(context, game);
      });
    }

    final theme = Theme.of(context);
    final res = ResponsiveLayout(context);

    final isLandscape = res.isLandscape;
    final isMobile = res.deviceType == DeviceType.mobile;

    // ScoreBoard is now handled dynamically by ArcadeScoreMarquee inside layouts.

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
      child: Listener(
        onPointerDown: (_) => _resetInactivityTimer(),
        child: AnimatedVibrantBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(isLandscape ? 40 : 56),
              child: AppBar(
                title: Text(
                  'Ultimate TicTacToe',
                  style: isMobile 
                      ? TextStyle(fontSize: isLandscape ? 14 : 16) 
                      : TextStyle(fontSize: res.titleSize * (isLandscape ? 0.6 : 0.8)),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: theme.colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                centerTitle: true,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout, size: isLandscape ? 18 : 24),
                    onPressed: () => context.read<AuthService>().signOut(),
                    tooltip: 'Logout',
                  ),
                  IconButton(
                    icon: Icon(Icons.analytics_outlined, size: isLandscape ? 18 : 24),
                    onPressed: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const ProfileStatsDialog(),
                      );
                    },
                    tooltip: 'Profile & Statistics',
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline, size: isLandscape ? 18 : 24),
                    onPressed: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const HelpDialog(),
                      );
                    },
                    tooltip: 'Help & About',
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, size: isLandscape ? 18 : 24),
                    onPressed: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const SettingsMenu(),
                      );
                    },
                    tooltip: 'Settings',
                  ),
                  if (isMobile) const SizedBox(width: 4),
                ],
              ),
            ),
            body: ArcadeCabinetFrame(
              child: Stack(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: isLandscape && isMobile 
                          ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
                          : res.screenPadding,
                      child: isLandscape
                          ? _buildLandscapeLayout(game, isMobile, res)
                          : _buildPortraitLayout(game, isMobile, res),
                    ),
                  ),
                  
                  // Decoupled Floating Scoreboard Badges - Fades in ONLY when game ends!
                  Positioned(
                    top: 4,
                    left: 12,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      opacity: game.isOverallGameOver ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !game.isOverallGameOver,
                        child: const PlayerXScoreBadge(),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        opacity: game.isOverallGameOver ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !game.isOverallGameOver,
                          child: const HighScoreBadge(),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    right: 12,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      opacity: game.isOverallGameOver ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !game.isOverallGameOver,
                        child: const PlayerOScoreBadge(),
                      ),
                    ),
                  ),

                  // Floating Game Mode Toggle (completely visible but transparent)
                  Positioned(
                    top: 70,
                    left: isLandscape ? 20 : 12,
                    right: isLandscape ? null : 12,
                    width: isLandscape ? 220 : null,
                    child: const GameModeToggle(),
                  ),
                  
                  // Dynamic floating turn marquee overlay (dropping from top/sides occasionally)
                  const FloatingMarqueeOverlay(),
                  
                  if (_isAutoPaused)
                    _buildPauseOverlay(theme),
                ],
              ),
            ),
            bottomNavigationBar: isLandscape
                ? null
                : ArcadeControlDeck(
                    cardHandWidget: context.watch<SettingsController>().ruleSet == GameRuleSet.chaos
                        ? const PowerUpHandWidget()
                        : null,
                    onNewGame: () {
                      soundManager.playMoveSound();
                      _resumeFromInactivity();
                      game.resetGame();
                    },
                    onHelp: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const HelpDialog(),
                      );
                    },
                    onSettings: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const SettingsMenu(),
                      );
                    },
                  ),
            floatingActionButton: null,
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(ThemeData theme) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _resumeFromInactivity,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'GAME PAUSED',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _resumeFromInactivity,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('RESUME GAME'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResumeDialog(BuildContext context, GameController game) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume Game?'),
        content: const Text(
          'We found an unfinished game in the cloud. Would you like to continue or start a fresh match?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              game.resolvePendingSession(resume: false);
            },
            child: const Text('START NEW'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              game.resolvePendingSession(resume: true);
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

  Widget _buildPortraitLayout(
    GameController game,
    bool isMobile,
    ResponsiveLayout res,
  ) {
    return Column(
      children: [
        const SizedBox(height: 118), // Spacer to clear both floating Scoreboard and floating GameModeToggle
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                
                // Minimal padding margins instead of monitor bezel; maximizes the board display area
                const double extraWidth = 16.0;
                const double extraHeight = 16.0;
                
                // Restrict board size to fit within both maximum available width and height
                final double boardSize = min(
                  min(maxW - extraWidth, res.maxBoardSize),
                  maxH - extraHeight,
                ).clamp(100.0, 800.0);
                
                return SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: const InteractiveHolographicTilt(
                    child: MultiBoardView(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    GameController game,
    bool isMobile,
    ResponsiveLayout res,
  ) {
    final soundManager = context.read<SoundManager>();
    final settings = context.watch<SettingsController>();
    final isCandy = settings.currentTheme.name.contains('Candy Meadow');
    final isWood = settings.currentTheme.name.contains('Woodville Carve');

    return Column(
      children: [
        const SizedBox(height: 56), // Spacer to clear the floating scoreboard HUD
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column: Console Inputs & Inventories (Visible in Chaos Mode, keeps layout symmetrical in Normal)
              if (settings.ruleSet == GameRuleSet.chaos)
                const Expanded(
                  flex: 12,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 84), // Spacer to clear the floating GameModeToggle
                        PowerUpHandWidget(),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  flex: 12,
                  child: SizedBox.shrink(), // keeps layout symmetrical
                ),
              
              // Center Column: Free-Floating Swaying MultiBoardView
              Expanded(
                flex: 26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final maxH = constraints.maxHeight;
                            
                            // Minimal padding margins instead of monitor bezel; maximizes the board display area
                            const double extraWidth = 16.0;
                            const double extraHeight = 16.0;
                            
                            // Restrict board size to fit within both maximum available width and height
                            final double boardSize = min(
                              min(maxW - extraWidth, res.maxBoardSize),
                              maxH - extraHeight,
                            ).clamp(100.0, 800.0);
                            
                            return SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: const InteractiveHolographicTilt(
                                child: MultiBoardView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right Column: Tactile Console Buttons Deck
              Expanded(
                flex: 12,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ArcadePushButton(
                        label: 'PLAYER 1',
                        actionText: 'START',
                        buttonColor: isCandy 
                            ? const Color(0xFFFF4081) 
                            : (isWood ? const Color(0xFFD84315) : Colors.red.shade700),
                        size: 48.0,
                        onTap: () {
                          soundManager.playMoveSound();
                          _resumeFromInactivity();
                          game.resetGame();
                        },
                      ),
                      const SizedBox(height: 16),
                      ArcadePushButton(
                        label: 'OPTION',
                        actionText: 'CONFIG',
                        buttonColor: isCandy 
                            ? const Color(0xFF00B0FF) 
                            : (isWood ? const Color(0xFF8D6E63) : Colors.blue.shade600),
                        size: 48.0,
                        onTap: () {
                          soundManager.playMoveSound();
                          showDialog(
                            context: context,
                            builder: (context) => const SettingsMenu(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ArcadePushButton(
                        label: 'HELP',
                        actionText: 'INFO',
                        buttonColor: isCandy 
                            ? const Color(0xFFFFD54F) 
                            : (isWood ? const Color(0xFFFFB300) : Colors.amber.shade600),
                        size: 48.0,
                        onTap: () {
                          soundManager.playMoveSound();
                          showDialog(
                            context: context,
                            builder: (context) => const HelpDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A highly dynamic, floating marquee HUD that slides/drops down from the top occasionally
/// (on turn milestones, AI thinking, or game over states) with a vintage arcade bounce.
class FloatingMarqueeOverlay extends StatefulWidget {
  const FloatingMarqueeOverlay({super.key});

  @override
  State<FloatingMarqueeOverlay> createState() => _FloatingMarqueeOverlayState();
}

class _FloatingMarqueeOverlayState extends State<FloatingMarqueeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _dismissTimer;

  // Occasional state trackers
  int _prevMoveCount = -1;
  int _prevBoardsWonX = 0;
  int _prevBoardsWonO = 0;
  Player? _prevPlayer;
  bool _prevThinking = false;
  bool _prevGameOver = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Simulated organic retro bounce!
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _triggerShow({required bool keepVisible, required bool isGameOver}) {
    _dismissTimer?.cancel();
    if (mounted) {
      if (isGameOver) {
        // Dramatic, slow-drop descent for victory or draw match outcomes
        _animationController.duration = const Duration(milliseconds: 2500);
      } else {
        _animationController.duration = const Duration(milliseconds: 800);
      }
      _animationController.forward();
    }
    if (!keepVisible) {
      _dismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          _animationController.duration = const Duration(milliseconds: 600);
          _animationController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final res = ResponsiveLayout(context);
    final isLandscape = res.isLandscape;

    // Detect state changes to trigger overlay drop down
    final bool isThinking = game.isAiThinking;
    final bool isGameOver = game.isOverallGameOver;
    final Player currentPlayer = game.currentPlayer;
    final int boardsWonX = game.boardsWonX;
    final int boardsWonO = game.boardsWonO;

    // Count moves played in the current session
    int moveCount = 0;
    for (var board in game.boards) {
      for (var cell in board.cells) {
        if (cell != Player.none) {
          moveCount++;
        }
      }
    }

    bool triggerOccasionalShow = false;
    bool keepVisible = isThinking || isGameOver;

    if (_prevMoveCount == -1) {
      // First run initialization
      _prevMoveCount = moveCount;
      _prevBoardsWonX = boardsWonX;
      _prevBoardsWonO = boardsWonO;
      _prevPlayer = currentPlayer;
      _prevThinking = isThinking;
      _prevGameOver = isGameOver;

      // Show briefly at the start of a match
      triggerOccasionalShow = true;
    } else {
      // 1. Detect sub-board won
      if (boardsWonX > _prevBoardsWonX || boardsWonO > _prevBoardsWonO) {
        triggerOccasionalShow = true;
        _prevBoardsWonX = boardsWonX;
        _prevBoardsWonO = boardsWonO;
      }

      // 2. Detect turn count occasional trigger (every 6 moves)
      if (moveCount != _prevMoveCount) {
        if (moveCount % 6 == 0) {
          triggerOccasionalShow = true;
        }
        _prevMoveCount = moveCount;
      }

      // 3. Detect player change (turn tracker)
      if (currentPlayer != _prevPlayer) {
        _prevPlayer = currentPlayer;
      }

      // 4. Detect AI thinking state change (transient drop down)
      if (isThinking != _prevThinking) {
        if (isThinking) {
          triggerOccasionalShow = true;
        }
        _prevThinking = isThinking;
      }

      // 5. Detect game over (slow dropping permanent panel)
      if (isGameOver != _prevGameOver) {
        if (isGameOver) {
          triggerOccasionalShow = true;
        }
        _prevGameOver = isGameOver;
      }
    }

    if (triggerOccasionalShow || keepVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerShow(keepVisible: keepVisible, isGameOver: isGameOver);
        }
      });
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        // Adapt target position and layout symmetrically based on orientation - floats to the bottom!
        final double targetBottom = isLandscape ? 16.0 : 96.0;
        final double bottomPosition = -50.0 + (_slideAnimation.value * (targetBottom + 50.0));
        
        return Positioned(
          bottom: bottomPosition,
          // Symmetrical placement: avoid GameModeToggle on the left column in Landscape
          left: isLandscape ? 260.0 : 20.0,
          right: 20.0,
          child: Opacity(
            opacity: _slideAnimation.value.clamp(0.0, 1.0),
            child: const ArcadeTurnMarquee(),
          ),
        );
      },
    );
  }
}
