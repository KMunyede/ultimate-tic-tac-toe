import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> setupWindow() async {
  // Ensure that plugin services are initialized so that `windowManager` can be used.
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final width = prefs.getDouble('window_width') ?? 400;
  final height = prefs.getDouble('window_height') ?? 400;
  final offsetX = prefs.getDouble('window_offsetX');
  final offsetY = prefs.getDouble('window_offsetY');

  WindowOptions windowOptions = WindowOptions(
    size: Size(width, height),
    center: offsetX == null || offsetY == null, // Center if no position is saved
    title: 'Ultimate Tic-Tac-Toe',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (offsetX != null && offsetY != null) {
      await windowManager.setPosition(Offset(offsetX, offsetY));
    }
  });
}