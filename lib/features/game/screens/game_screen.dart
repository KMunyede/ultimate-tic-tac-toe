import 'dart:async';
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
            body: Stack(
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
                if (_isAutoPaused)
                  _buildPauseOverlay(theme),
              ],
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
        const ArcadeScoreMarquee(),
        const SizedBox(height: 6),
        const GameModeToggle(),
        const SizedBox(height: 8),
        const ArcadeTurnMarquee(),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: res.maxBoardSize),
              child: const ArcadeCabinetFrame(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: MultiBoardView(),
                ),
              ),
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

    return Column(
      children: [
        // Top header LED High Scores
        const ArcadeScoreMarquee(),
        const SizedBox(height: 6),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column: Console Inputs & Inventories
              Expanded(
                flex: 12,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GameModeToggle(),
                      if (settings.ruleSet == GameRuleSet.chaos) ...[
                        const SizedBox(height: 16),
                        const PowerUpHandWidget(),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Center Column: Bezel Monitor & LED Marquee Status
              Expanded(
                flex: 26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: res.maxBoardSize,
                          ),
                          child: const ArcadeCabinetFrame(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: MultiBoardView(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const ArcadeTurnMarquee(),
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
                        buttonColor: Colors.red.shade700,
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
                        buttonColor: Colors.blue.shade600,
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
                        buttonColor: Colors.amber.shade600,
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
