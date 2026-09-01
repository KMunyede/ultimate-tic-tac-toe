import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:window_manager/window_manager.dart';

import '../../firebase_options.dart';
import '../window/window_setup.dart';

class AppInitializer {
  /// Safely runs all mandatory async boot tasks.
  /// Returns `true` if this is the primary window instance (relevant for desktop).
  static Future<bool> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Safe dotenv Load
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (kDebugMode) print('⚠️ .env file not found or failed to load.');
    }

    // 2. Safe Firebase Init
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        Firebase.app();
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) print('🔥 FIREBASE INIT ERROR: $e\n$stackTrace');
    }

    // 3. Platform Specifics (Window Manager)
    bool isPrimaryInstance = true;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await windowManager.ensureInitialized();
        if (kReleaseMode) {
          WindowOptions windowOptions = const WindowOptions(size: Size(800, 600));
          windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.setPreventClose(true);
          });
        }
        await configureWindow(isPrimaryInstance: isPrimaryInstance);
      } catch (e) {
        if (kDebugMode) print('⚠️ WindowManager init failed: $e');
      }
    }

    return isPrimaryInstance;
  }
}
