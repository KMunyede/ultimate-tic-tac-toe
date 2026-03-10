import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'game_controller.dart';
import 'settings_menu.dart';
import 'sound_manager.dart';
import 'widgets/game_board.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    final double diagonalInches = _calculateDiagonalInches(mediaQuery);
    final bool isSmallScreen = diagonalInches < 8.0;
    final bool isSmallLandscape =
        mediaQuery.orientation == Orientation.landscape && isSmallScreen;

    final double appBarHeight = isSmallScreen ? 26.0 : 56.0;

    final primaryColor = theme.colorScheme.primary;
    final hsl = HSLColor.fromColor(primaryColor);
    final brighterColor =
        hsl.withLightness((hsl.lightness * 1.7).clamp(0.0, 1.0)).toColor();
    final buttonTextColor =
        brighterColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    final screenWidth = mediaQuery.size.width;
    const double baseWidthFactor = 0.4;
    const double baseHeight = 48.0;
    final double newWidth = screenWidth * baseWidthFactor * 1.20;
    final double newHeight = baseHeight * 1.10;

    Widget statusLabel = BreathingStatusLabel(
      message: game.statusMessage ?? '',
      isSmallScreen: isSmallScreen,
      style: isSmallScreen
          ? theme.textTheme.titleMedium
          : theme.textTheme.headlineSmall,
    );

    Widget newGameButton = SizedBox(
      width: isSmallLandscape ? 150 : newWidth,
      height: isSmallLandscape ? 36 : newHeight,
      child: ElevatedButton.icon(
        icon: Icon(Icons.refresh, size: isSmallLandscape ? 18 : 24),
        label: Text(
          'New Game',
          style: isSmallLandscape ? const TextStyle(fontSize: 13) : null,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: brighterColor,
          foregroundColor: buttonTextColor,
          padding: isSmallLandscape ? EdgeInsets.zero : null,
        ),
        onPressed: () => game.initializeGame(),
      ),
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
          preferredSize: Size.fromHeight(appBarHeight),
          child: AppBar(
            titleSpacing: isSmallScreen ? 8 : null,
            title: Text(
              'Ultimate TicTacToe',
              style: isSmallScreen ? const TextStyle(fontSize: 14) : null,
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                padding: isSmallScreen ? EdgeInsets.zero : null,
                constraints: isSmallScreen ? const BoxConstraints() : null,
                icon: const Icon(Icons.settings),
                iconSize: isSmallScreen ? 18 : 24,
                onPressed: () {
                  soundManager.playMoveSound();
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsMenu(),
                  );
                },
              ),
              if (isSmallScreen) const SizedBox(width: 8),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: isSmallLandscape
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: MultiBoardView(),
                          ),
                        ),
                        Container(
                          width: 180,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              statusLabel,
                              const SizedBox(height: 12),
                              newGameButton,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: const MultiBoardView(),
                          ),
                        ),
                        statusLabel,
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: isSmallScreen ? 16.0 : 32.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [newGameButton],
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

  double _calculateDiagonalInches(MediaQueryData data) {
    final width = data.size.width;
    final height = data.size.height;
    final pixelRatio = data.devicePixelRatio;

    const ppi = 160.0;
    final widthInches = width / ppi * pixelRatio;
    final heightInches = height / ppi * pixelRatio;

    return sqrt(widthInches * widthInches + heightInches * heightInches) / pixelRatio;
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

class BreathingStatusLabel extends StatefulWidget {
  final String message;
  final bool isSmallScreen;
  final TextStyle? style;

  const BreathingStatusLabel({
    super.key,
    required this.message,
    required this.isSmallScreen,
    this.style,
  });

  @override
  State<BreathingStatusLabel> createState() => _BreathingStatusLabelState();
}

class _BreathingStatusLabelState extends State<BreathingStatusLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.isSmallScreen ? 8.0 : 16.0,
        horizontal: 8.0,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                widget.message,
                style: widget.style?.copyWith(
                  shadows: [
                    Shadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3 * _opacityAnimation.value),
                      blurRadius: 8.0 * _controller.value,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
