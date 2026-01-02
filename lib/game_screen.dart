import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/app_theme.dart';
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/widgets/game_board.dart';
import 'package:tictactoe/widgets/game_status_display.dart';
import 'package:tictactoe/widgets/gradient_button.dart';
import 'package:tictactoe/widgets/score_display.dart';
import 'package:window_manager/window_manager.dart';
import 'settings_menu.dart';

class TicTacToeGame extends StatefulWidget {
  final bool isPrimaryInstance;
  const TicTacToeGame({super.key, required this.isPrimaryInstance});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> with WindowListener {
  bool _isMenuOpen = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  final GlobalKey _settingsButtonKey = GlobalKey(); // Key for the settings button

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    if (_isDesktop && widget.isPrimaryInstance) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void onWindowClose() {
    _showExitConfirmationDialog();
  }

  Future<void> _showExitConfirmationDialog() async {
    // Check if the window is minimized using windowManager (Desktop only)
    if (_isDesktop) {
      bool isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (_isDesktop) {
        await windowManager.destroy();
        exit(0);
      } else {
        // On Mobile/Web, use SystemNavigator to pop the app
        SystemNavigator.pop();
      }
    }
  }

  void _saveWindowState() {
    if (!_isDesktop) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      await prefs.setDouble('window_width', size.width);
      await prefs.setDouble('window_height', size.height);
      await prefs.setDouble('window_offsetX', position.dx);
      await prefs.setDouble('window_offsetY', position.dy);
    });
  }

  @override
  void onWindowResized() => _saveWindowState();

  @override
  void onWindowMoved() => _saveWindowState();

  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMaximize() {}
  @override
  void onWindowUnmaximize() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowRestore() {}
  void onWindowEnter() {}
  void onWindowLeave() {}
  @override
  void onWindowDocked() {}
  @override
  void onWindowUndocked() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}
  @override
  void onWindowEvent(String eventName) {}

  Widget _buildGameArea(GameController gameController, SettingsController settings, Color gradientStart, Color gradientEnd) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: gameController.boards.asMap().entries.map((entry) {
          int boardIndex = entry.key;
          return Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GameBoardWidget(
                boardIndex: boardIndex,
                gradientStart: gradientStart,
                gradientEnd: gradientEnd,
                currentTheme: settings.currentTheme,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    final Color gradientStart, gradientEnd;
    if (settings.currentTheme == const AppTheme(name: 'Forest Green', mainColor: Color(0xFF2D6A4F))) {
      gradientStart = theme.colorScheme.surface;
      gradientEnd = theme.colorScheme.secondary;
    } else {
      gradientStart = Color.lerp(theme.scaffoldBackgroundColor, Colors.white, 0.3)!;
      gradientEnd = Color.lerp(theme.scaffoldBackgroundColor, Colors.black, 0.1)!;
    }

    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              title: const Text('Ultimate TicTacToe'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  key: _settingsButtonKey, // Assign the key to the settings button
                  icon: const Icon(Icons.settings),
                  tooltip: 'Main Menu',
                  onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
                )
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [gradientStart, theme.scaffoldBackgroundColor],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const ScoreDisplay(),
                    const SizedBox(height: 16),
                    const GameStatusDisplay(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildGameArea(gameController, settings, gradientStart, gradientEnd),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GradientButton(
                          onPressed: gameController.isOverallGameOver ? gameController.initializeGame : null,
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          textColor: theme.colorScheme.onSurface,
                          child: const Text('Play Again', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 20),
                        GradientButton(
                          onPressed: () => _showExitConfirmationDialog(),
                          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                          textColor: theme.colorScheme.onSurface,
                          child: const Text('Close', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SettingsMenu(
          isOpen: _isMenuOpen,
          closeMenu: () => setState(() => _isMenuOpen = false),
        ),
      ],
    );
  }
}
