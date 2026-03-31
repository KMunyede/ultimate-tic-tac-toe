import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added Import
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart'; // [FIX] Required for multi-platform configuration
import 'firebase_service.dart'; // Added Import
import 'game_controller.dart';
import 'game_screen.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';
import 'window_setup.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Safe DotEnv Load
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) print("Warning: .env file not found or failed to load: $e");
  }

  // 2. Safe Firebase Init
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) print("Firebase Initialization Error: $e");
  }

  // 3. Platform Specifics
  bool isPrimaryInstance = true;
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setIcon('assets/icon.png');
      if (kReleaseMode) {
        WindowOptions windowOptions = const WindowOptions(size: Size(800, 600));
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.setPreventClose(true);
        });
      }
      await configureWindow(isPrimaryInstance: isPrimaryInstance);
    } catch (e) {
      if (kDebugMode) print("WindowManager Error: $e");
    }
  }

  // 4. Controller Init
  final settingsController = SettingsController();
  try {
    await settingsController.loadSettings();
  } catch (e) {
    if (kDebugMode) print("Settings Load Error: $e");
  }

  final soundManager = SoundManager(settingsController);
  await soundManager.init();

  final firebaseService = FirebaseService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        Provider<SoundManager>(
          create: (_) => soundManager,
          dispose: (_, manager) => manager.dispose(),
        ),
        Provider<FirebaseService>.value(value: firebaseService),
        ChangeNotifierProxyProvider<SettingsController, GameController>(
          create: (context) => GameController(
            context.read<SoundManager>(),
            context.read<SettingsController>(),
            context.read<FirebaseService>(), // Added argument
          ),
          update: (context, settings, previousGameController) {
            // Re-create the GameController if settings that affect game logic change
            // Or just update dependencies. Here we handle the logic to potentially reset.
            final controller = previousGameController ??
                GameController(
                  context.read<SoundManager>(),
                  settings,
                  context.read<FirebaseService>(), // Added argument
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
      home: TicTacToeGame(isPrimaryInstance: widget.isPrimaryInstance),
      debugShowCheckedModeBanner: false,
    );
  }
}
