import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'game_controller.dart';
//import 'settings_controller.dart';
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

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _isDesktop = true;
      windowManager.addListener(this);
    }
    // Add a listener to show SnackBars when a status message is available
    context.read<GameController>().addListener(_showStatusMessage);
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    context.read<GameController>().removeListener(_showStatusMessage);
    _debounce?.cancel();
    super.dispose();
  }

  void _showStatusMessage() {
    final game = context.read<GameController>();
    final message = game.statusMessage;
    if (message != null) {
      final isError = message.startsWith('Error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
      game.clearStatusMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final soundManager = context.read<SoundManager>();
    
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
                builder: (context) => const SettingsMenu(),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: BoardWidget(),
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
