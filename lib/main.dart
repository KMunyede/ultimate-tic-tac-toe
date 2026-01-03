import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'game_controller.dart';
import 'game_screen.dart';
import 'window_setup.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';
import 'firebase_service.dart';

void main(List<String> args) async {
  debugPrintLayouts = true;

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      title: 'Ultimate TicTacToe',
      theme: settings.themeData.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.all(settings.themeData.colorScheme.onPrimary),
          ),
        ),
      ),
      home: TicTacToeGame(isPrimaryInstance: widget.isPrimaryInstance),
      debugShowCheckedModeBanner: false,
    );
  }
}
