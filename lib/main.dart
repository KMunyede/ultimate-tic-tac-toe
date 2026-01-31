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
  // Removing debugPrintLayouts as it clogs the console in production
  // debugPrintLayouts = true;

  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Initialize DotEnv before accessing it in DefaultFirebaseOptions
  await dotenv.load(fileName: ".env");

  // [FIX] Initialize Firebase with platform-specific options.
  // We use a try-catch block to handle the "duplicate-app" error on Android
  // which sometimes occurs even with the Firebase.apps.isEmpty check.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    } else {
      // If duplicate-app, we assume initialization succeeded in the background.
      if (kDebugMode) {
        print("Firebase already initialized by native layer. Continuing...");
      }
    }
  }

  bool isPrimaryInstance = true;
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await windowManager.setIcon('assets/icon.png');
    if (kReleaseMode) {
      WindowOptions windowOptions = const WindowOptions(size: Size(800, 600));
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setPreventClose(true);
      });
    }
  }

  await configureWindow(isPrimaryInstance: isPrimaryInstance);

  final settingsController = SettingsController();
  await settingsController.loadSettings();

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
                settings.themeData.colorScheme.onPrimary),
          ),
        ),
      ),
      home: TicTacToeGame(isPrimaryInstance: widget.isPrimaryInstance),
      debugShowCheckedModeBanner: false,
    );
  }
}
