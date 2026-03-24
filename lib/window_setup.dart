import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/persistence_service.dart';

Future<void> configureWindow({required bool isPrimaryInstance}) async {
  if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  final persistence = PersistenceService();
  final data = await persistence.loadAll();

  // Only the primary instance should restore the last size.
  // Secondary instances should open with a default size to avoid overlap.
  final width = isPrimaryInstance
      ? (data['window_width']?.toDouble() ?? 500.0)
      : 450.0;
  // UI UPDATE: Increased default height by 50px as requested (650 -> 700).
  final height = isPrimaryInstance
      ? (data['window_height']?.toDouble() ?? 700.0)
      : 600.0;

  WindowOptions windowOptions = WindowOptions(
    size: Size(width, height),
    center: true,
    title: isPrimaryInstance
        ? 'Ultimate Tic-Tac-Toe (P1)'
        : 'Ultimate Tic-Tac-Toe (P2)',
    minimumSize: const Size(400, 400),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
