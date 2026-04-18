import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../settings/widgets/settings_menu.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/game_board.dart';
import '../../../widgets/game_status_display.dart';
import '../../../widgets/score_board.dart';
import '../../../widgets/help_dialog.dart';
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

    // Constrain ScoreBoard width for better proportions on tablets
    Widget scoreBoard = Container(
      constraints: BoxConstraints(maxWidth: isMobile ? 400 : 600),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 4.0 : res.spacing / 2,
        horizontal: isMobile ? 8.0 : res.spacing,
      ),
      child: ScoreBoard(isSmallScreen: isMobile),
    );

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
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isLandscape ? 40 : 56),
            child: AppBar(
              title: Text(
                'Ultimate TicTacToe',
                style: isMobile 
                    ? TextStyle(fontSize: isLandscape ? 14 : 16) 
                    : TextStyle(fontSize: res.titleSize * (isLandscape ? 0.6 : 0.8)),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, size: isLandscape ? 18 : 24),
                  onPressed: () => context.read<AuthService>().signOut(),
                  tooltip: 'Logout',
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
                      ? _buildLandscapeLayout(game, scoreBoard, isMobile, res)
                      : _buildPortraitLayout(game, scoreBoard, isMobile, res),
                ),
              ),
              if (_isAutoPaused)
                _buildPauseOverlay(theme),
            ],
          ),
          floatingActionButton: isLandscape
              ? null
              : SizedBox(
                  height: isMobile ? 40 : 50,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      soundManager.playMoveSound();
                      _resumeFromInactivity(); // Clear pause state and reset timer
                      game.resetGame();
                    },
                    icon: Icon(Icons.refresh, size: isMobile ? 20 : 24),
                    label: Text(
                      'New Game',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    elevation: 2,
                  ),
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
    Widget scoreBoard,
    bool isMobile,
    ResponsiveLayout res,
  ) {
    return Column(
      children: [
        scoreBoard,
        const GameModeToggle(),
        const GameStatusDisplay(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: res.maxBoardSize),
              child: const AspectRatio(
                aspectRatio: 1,
                child: MultiBoardView(),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 60 : 100), // Space for FAB
      ],
    );
  }

  Widget _buildLandscapeLayout(
    GameController game,
    Widget scoreBoard,
    bool isMobile,
    ResponsiveLayout res,
  ) {
    final theme = Theme.of(context);
    final soundManager = context.read<SoundManager>();
    // Only show persistent settings on Desktop/Large screens. 
    // Hide on 7-inch/Tablets in landscape to save space.
    final isLargeScreen = res.deviceType == DeviceType.desktop;
    final isTablet = res.deviceType == DeviceType.tablet;

    // Combine Tablet and Mobile Landscape for a consistent three-column proportional layout
    if (isTablet || isMobile) {
      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Proportional Width (Scores and Toggles)
              Expanded(
                flex: 12,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScoreBoard(isSmallScreen: isMobile, isVertical: true),
                      const SizedBox(height: 12),
                      const GameModeToggle(),
                    ],
                  ),
                ),
              ),
              // Center: Proportional Width (The Board)
              Expanded(
                flex: 30,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? res.maxBoardSize * 1.2 : res.maxBoardSize,
                    ),
                    child: const AspectRatio(
                      aspectRatio: 1,
                      child: MultiBoardView(),
                    ),
                  ),
                ),
              ),
              // Right: Proportional Width (Action Buttons)
              Expanded(
                flex: 12,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          soundManager.playMoveSound();
                          _resumeFromInactivity();
                          game.resetGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'New Game',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          soundManager.playMoveSound();
                          showDialog(
                            context: context,
                            builder: (context) => const HelpDialog(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Help & About',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: GameStatusDisplay(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Title and Scores
            Expanded(
              flex: isMobile ? 2 : 3,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ultimate TicTacToe',
                      style: TextStyle(
                        fontSize: res.titleSize,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: res.spacing),
                    scoreBoard,
                    const GameModeToggle(),
                    if (!isLargeScreen) ...[
                      SizedBox(height: res.spacing),
                      _buildActionButtons(game, theme, soundManager, isMobile, res),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(width: res.spacing),
            // Center: The Board
            Expanded(
              flex: isMobile ? 4 : 6,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: res.maxBoardSize),
                  child: const AspectRatio(
                    aspectRatio: 1,
                    child: MultiBoardView(),
                  ),
                ),
              ),
            ),
            if (isLargeScreen) ...[
              SizedBox(width: res.spacing),
              // Right side: Persistent Settings for Tablets/Desktop
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SettingsPanel(),
                ),
              ),
            ],
          ],
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: GameStatusDisplay(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    GameController game,
    ThemeData theme,
    SoundManager soundManager,
    bool isMobile,
    ResponsiveLayout res,
  ) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            soundManager.playMoveSound();
            _resumeFromInactivity(); // Clear pause state and reset timer
            game.resetGame();
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('New Game'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            minimumSize: Size(double.infinity, isMobile ? 48 : 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        SizedBox(height: res.spacing / 2),
        OutlinedButton.icon(
          onPressed: () {
            soundManager.playMoveSound();
            showDialog(
              context: context,
              builder: (context) => const HelpDialog(),
            );
          },
          icon: const Icon(Icons.help_outline, size: 20),
          label: const Text('Help & About'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, isMobile ? 48 : 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: SettingsMenu(isPersistent: true),
    );
  }
}
