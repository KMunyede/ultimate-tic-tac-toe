import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/game_controller.dart';
import '../../settings/widgets/settings_menu.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/game_board.dart';
import '../../../widgets/game_status_display.dart';
import '../../../widgets/score_board.dart';
import '../../../widgets/help_dialog.dart';
import '../../auth/services/auth_service.dart';
import '../../../utils/responsive_layout.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  StreamSubscription? _aiErrorSubscription;
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameController>();
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

  @override
  void dispose() {
    _aiErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final soundManager = context.read<SoundManager>();
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
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/icon.png', fit: BoxFit.contain),
              ),
            ),
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
          ],
        ),
        floatingActionButton: isLandscape
            ? null
            : SizedBox(
                height: isMobile ? 40 : 50,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    soundManager.playMoveSound();
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

    if (isTablet) {
      // Tablet Landscape: Narrower sidebars, wider middle
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Scores (Reduced width by 20% from 180)
          SizedBox(
            width: 144,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  ScoreBoard(isSmallScreen: false, isVertical: true),
                  const SizedBox(height: 16),
                  const GameStatusDisplay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Center: Maximized Board (Takes most space)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: res.maxBoardSize * 1.3),
                child: const AspectRatio(
                  aspectRatio: 1,
                  child: MultiBoardView(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: Action Buttons (Reduced width by 20% from 160)
          SizedBox(
            width: 128,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildActionButtons(game, theme, soundManager, false, res),
            ),
          ),
        ],
      );
    }

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: 1/5 Width
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  ScoreBoard(isSmallScreen: true, isVertical: true),
                  const SizedBox(height: 8),
                  const GameStatusDisplay(),
                ],
              ),
            ),
          ),
          // Center: 3/5 Width
          const Expanded(
            flex: 3,
            child: Center(
              child: MultiBoardView(),
            ),
          ),
          // Right: 1/5 Width
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      soundManager.playMoveSound();
                      game.resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      'New Game',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      soundManager.playMoveSound();
                      showDialog(
                        context: context,
                        builder: (context) => const HelpDialog(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      'Help & About',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
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
                const GameStatusDisplay(),
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
