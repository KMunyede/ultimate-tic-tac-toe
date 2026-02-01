import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for ScaffoldMessenger
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'game_controller.dart';
import 'settings_menu.dart';
import 'sound_manager.dart';
import 'widgets/board_widget.dart';

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

  // NEW: Subscription for GameController error events
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

    // Lazy-load the subscription when dependencies change (i.e., when widget mounts)
    if (_aiErrorSubscription == null) {
      final gameController = context.read<GameController>();

      // Subscribe to the AI error stream
      _aiErrorSubscription = gameController.aiErrorStream.listen((message) {
        // Use Future.microtask to ensure the SnackBar call happens after the build phase is complete,
        // preventing "Scaffold.of() called with a context that does not contain a Scaffold" errors.
        if (mounted) {
          Future.microtask(() => _showErrorSnackbar(message));
        }
      });
    }
  }

  @override
  void dispose() {
    // CRUCIAL: Cancel the subscription to avoid memory leaks
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

    // Calculate a brighter version of the primary color for buttons
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);
    final brighterColor =
        hsl.withLightness((hsl.lightness * 1.7).clamp(0.0, 1.0)).toColor();

    // Ensure text contrast on the brighter button
    final buttonTextColor =
        brighterColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    // Base button dimensions for scaling
    final screenWidth = MediaQuery.of(context).size.width;
    // Use a percentage of the screen width for a responsive base size
    const double baseWidthFactor = 0.4;
    const double baseHeight = 48.0; // Standard material button height

    final double newWidth = screenWidth * baseWidthFactor * 1.20; // 20% larger
    final double newHeight = baseHeight * 1.10; // 10% larger

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastPressed == null ||
                now.difference(_lastPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                child: BoardWidget(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                game.statusMessage ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
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
          // On Mobile/Web, use SystemNavigator to pop the app
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
