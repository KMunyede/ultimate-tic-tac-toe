import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'game_controller.dart';
import 'settings_menu.dart';
import 'sound_manager.dart';
import 'widgets/game_board.dart'; // Import MultiBoardView

class TicTacToeGame extends StatefulWidget {
  final bool isPrimaryInstance;

  const TicTacToeGame({super.key, required this.isPrimaryInstance});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> with WindowListener {
  Timer? _debounce;
  bool _isDesktop = false;
  DateTime? _lastPressed;

  StreamSubscription<String>? _aiErrorSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _isDesktop = true;
      windowManager.addListener(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_aiErrorSubscription == null) {
      final gameController = context.read<GameController>();
      _aiErrorSubscription = gameController.aiErrorStream.listen((message) {
        if (mounted) {
          Future.microtask(() => _showErrorSnackbar(message));
        }
      });
    }
  }

  @override
  void dispose() {
    _aiErrorSubscription?.cancel();
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final soundManager = context.read<SoundManager>();

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);
    final brighterColor =
        hsl.withLightness((hsl.lightness * 1.7).clamp(0.0, 1.0)).toColor();

    final buttonTextColor =
        brighterColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidthFactor = 0.4;
    const double baseHeight = 48.0;

    final double newWidth = screenWidth * baseWidthFactor * 1.20;
    final double newHeight = baseHeight * 1.10;

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
        appBar: AppBar(
          title: const Text('Ultimate TicTacToe'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                soundManager.playMoveSound();
                showDialog(
                  context: context,
                  builder: (context) => const SettingsMenu(),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const Expanded(
              child: Center(
                child: MultiBoardView(), // Use MultiBoardView here
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                game.statusMessage ?? '',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: newWidth,
                    height: newHeight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brighterColor,
                        foregroundColor: buttonTextColor,
                      ),
                      onPressed: () => game.initializeGame(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> onWindowClose() async {
    if (widget.isPrimaryInstance) {
      final result = await _showExitConfirmationDialog();
      if (result == true) {
        if (_isDesktop) {
          await windowManager.destroy();
          exit(0);
        } else {
          SystemNavigator.pop();
        }
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

  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit Game'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
