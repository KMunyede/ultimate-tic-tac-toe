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

class TicTacToeGame extends StatefulWidget {
  final bool isPrimaryInstance;

  const TicTacToeGame({super.key, required this.isPrimaryInstance});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> with WindowListener {
  Timer? _debounce;
  bool _isDesktop = false;

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
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final soundManager = context.read<SoundManager>();
    final settings = context.watch<SettingsController>();

    return Scaffold(
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
                builder: (context) => SettingsMenu(
                  controller: settings,
                  soundManager: soundManager,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: BoardWidget(game: game),
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

  // @override
  // void onWindowResized() => _saveWindowState();

  // @override
  // void onWindowMoved() => _saveWindowState();

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
