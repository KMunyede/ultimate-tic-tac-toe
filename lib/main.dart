import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import this library
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_controller.dart';
import 'auth_screen.dart';
import 'firebase_service.dart';
import 'game_controller.dart';
import 'game_screen.dart';
import 'window_setup.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';
import 'firebase_options.dart';

void main(List<String> args) async {
  // Add this line to force error logging
  debugPrintLayouts = true; 

  WidgetsFlutterBinding.ensureInitialized();

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

  await dotenv.load();

  // Use the standard FlutterFire initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
        Provider.value(value: firebaseService),
        ChangeNotifierProvider(
            create: (context) => AuthController(firebaseService)),
        Provider<SoundManager>(
          create: (_) => soundManager,
          dispose: (_, manager) => manager.dispose(),
        ),
        ChangeNotifierProxyProvider<SettingsController, GameController>(
          create: (context) => GameController(
            context.read<SoundManager>(),
            context.read<SettingsController>(),
            context.read<FirebaseService>(),
          ),
          update: (context, settings, previousGameController) {
            if (previousGameController == null) {
              return GameController(
                context.read<SoundManager>(),
                settings,
                context.read<FirebaseService>(),
              );
            }

            if (settings.resetGameRequested) {
              previousGameController.initializeGame();
              settings.consumeGameResetRequest();
            }
            previousGameController.updateDependencies(settings);
            return previousGameController;
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
      // UI FIX: Changed the main application title.
      title: 'Ultimate TicTacToe',
      theme: settings.themeData.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.all(settings.themeData.colorScheme.onPrimary),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: context.read<FirebaseService>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.hasData
              ? TicTacToeGame(isPrimaryInstance: widget.isPrimaryInstance)
              : const AuthScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
