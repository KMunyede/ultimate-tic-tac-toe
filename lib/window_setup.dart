import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> configureWindow({required bool isPrimaryInstance}) async {
  if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  // Only the primary instance should restore the last size.
  // Secondary instances should open with a default size to avoid overlap.
  final width = isPrimaryInstance ? (prefs.getDouble('window_width') ?? 500) : 450;
  // UI UPDATE: Increased default height by 50px as requested (650 -> 700).
  final height = isPrimaryInstance ? (prefs.getDouble('window_height') ?? 700) : 600;

  // ARCHITECTURAL DECISION:
  // Due to a native C++ runtime conflict on Windows between the Firebase SDK
  // and the library used by `window_manager` (WIL), calls to get display
  // information like `getPrimaryDisplay()` are unstable and can crash the app.
  // To ensure stability, we are removing the logic that restores the window
  // position and will always center the window on startup.

  WindowOptions windowOptions = WindowOptions(
    size: Size(width.toDouble(), height.toDouble()),
    center: true,
    title: isPrimaryInstance ? 'Ultimate Tic-Tac-Toe (P1)' : 'Ultimate Tic-Tac-Toe (P2)',
    minimumSize: const Size(400, 400),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Restore position logic is removed to prevent native crashes.
    // If a last-known position exists, we can still try to set it,
    // but we accept the risk that it might be off-screen. The centering
    // above provides a safe default.
    // if (offsetX != null && offsetY != null) {
    //   await windowManager.setPosition(Offset(offsetX, offsetY));
    // }
  });
}
