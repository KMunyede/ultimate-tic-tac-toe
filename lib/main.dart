import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/bootstrap/app_initializer.dart';
import 'features/game/logic/game_controller.dart';
import 'features/game/screens/game_screen.dart';
import 'features/settings/logic/settings_controller.dart';
import 'core/audio/sound_manager.dart';

import 'features/auth/services/auth_service.dart';
import 'features/game/repositories/game_repository.dart';
import 'features/game/repositories/ai_repository.dart';
import 'services/stats_service.dart';
import 'features/auth/widgets/auth_gate.dart';

void main() async {
  // 1. Run all critical async bootstrap logic (dotenv, Firebase, Window constraints)
  final bool isPrimaryInstance = await AppInitializer.init();

  // 2. Initialize Core Controllers
  final settingsController = SettingsController();
  try {
    await settingsController.loadSettings();
  } catch (_) {}

  final soundManager = SoundManager(settingsController);
  await soundManager.init();

  // 3. Initialize Services and Repositories
  final gameRepo = GameRepository();
  final aiRepo = AiRepository();
  final authService = AuthService();
  final statsService = StatsService();

  // 4. Run App with minimal Provider tree
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        Provider<SoundManager>.value(value: soundManager),
        Provider<GameRepository>.value(value: gameRepo),
        Provider<AiRepository>.value(value: aiRepo),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider.value(value: statsService),
        ChangeNotifierProxyProvider<SettingsController, GameController>(
          create: (context) => GameController(
            context.read<SoundManager>(),
            context.read<SettingsController>(),
            context.read<GameRepository>(),
            context.read<AiRepository>(),
            context.read<StatsService>(),
          ),
          update: (context, settings, previousGameController) {
            final controller = previousGameController ??
                GameController(
                  context.read<SoundManager>(),
                  settings,
                  context.read<GameRepository>(),
                  context.read<AiRepository>(),
                  context.read<StatsService>(),
                );

            if (settings.resetGameRequested) {
              controller.initializeGame(useMicrotask: true);
              settings.consumeGameResetRequest();
            }
            controller.updateDependencies(settings);
            return controller;
          },
        ),
      ],
      child: MyApp(isPrimaryInstance: isPrimaryInstance),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isPrimaryInstance;

  const MyApp({super.key, required this.isPrimaryInstance});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      title: 'Ultimate TicTacToe',
      theme: settings.themeData.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(
              settings.themeData.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      home: AuthGate(
        child: const GameScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
