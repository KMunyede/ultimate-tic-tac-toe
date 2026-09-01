// lib/features/game/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../widgets/animated_vibrant_background.dart';
import '../../../widgets/game_board.dart';
import '../../../widgets/animations/holographic_tilt.dart';
import '../widgets/turn_telemetry_header.dart';
import '../widgets/floating_cloud_button.dart';
import '../../../widgets/profile_stats_dialog.dart';
import '../../settings/widgets/settings_menu.dart';
import '../../../widgets/animal_peeking_layer.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  DateTime? _lastPressed;
  bool _isPaused = false;
  bool _dismissedGameOverCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _isPaused = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
          );
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: AnimatedVibrantBackground(
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                    // 1. Top Telemetry (Floating)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                  child: TurnTelemetryHeader(game: game, settings: settings),
                ),

                // 2. Gameplay Layer (Expanded to take middle space)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onDoubleTap: () {
                            HapticFeedback.lightImpact();
                            settings.toggleBoardLayout();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: InteractiveHolographicTilt(
                            child: const MultiBoardView(),
                          ),
                        ),
                      ),
                      
                      // Animal Peeking Layer inside the gameplay area
                      const AnimalPeekingLayer(),
                    ],
                  ),
                ),

                // 3. Action Buttons (Bottom Bar - Floating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                      FloatingCloudButton(
                        label: 'Start',
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          game.resetGame();
                        },
                      ),
                      FloatingCloudButton(
                        label: 'Pause',
                        icon: Icons.pause_rounded,
                        onTap: () => setState(() => _isPaused = true),
                      ),
                      FloatingCloudButton(
                        label: 'Settings',
                        icon: Icons.settings_rounded,
                        onTap: () => showDialog(context: context, builder: (_) => const SettingsMenu()),
                      ),
                      FloatingCloudButton(
                        label: 'Profile',
                        icon: Icons.person_rounded,
                        onTap: () => showDialog(context: context, builder: (_) => const ProfileStatsDialog()),
                      ),
                      ],
                    ),
                  ),
                ),

                    ],
                  ),
                ),
                
                // Overlays
                if (_isPaused)
                  PauseOverlay(theme: theme, onResume: () => setState(() => _isPaused = false)),

                if (game.isGameOverOverlayReady && !_dismissedGameOverCard)
                  GameOverOverlay(onDismiss: () => setState(() => _dismissedGameOverCard = true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
