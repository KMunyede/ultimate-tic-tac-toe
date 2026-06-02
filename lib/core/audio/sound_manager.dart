import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import 'jungle_sound_synthesizer.dart';

/// A service for managing and playing sound effects.
///
/// This class encapsulates the `audioplayers` logic and provides simple, clean
/// methods to play predefined game sounds. It correctly respects the user's
/// sound settings from `SettingsController`.
class SoundManager {
  final SettingsController _settingsController;
  final Random _random = Random();

  // Pre-allocated circular audio player pool for rapid simultaneous overlapping sounds
  static const int _poolSize = 10;
  final List<AudioPlayer> _pool = List.generate(_poolSize, (_) => AudioPlayer());
  int _currentPoolIndex = 0;

  // Define asset paths as constants for easy management and to avoid typos.
  // Paths align with the 'assets/' prefix defined in pubspec.yaml
  static const String _moveSoundPath = 'sounds/move.mp3';
  static const String _winSoundPath = 'sounds/win.mp3';
  static const String _drawSoundPath = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  /// Initializes the sound manager.
  Future<void> init() async {
    if (kDebugMode) {
      print("SoundManager initialized with pool size of $_poolSize. Sounds will be loaded on first play.");
    }
  }

  /// A private helper to play a sound from assets, respecting sound settings.
  Future<void> _playSound(String soundPath, {double? playbackRate, String? jungleSoundType}) async {
    if (_settingsController.isSoundOn) {
      try {
        final player = _pool[_currentPoolIndex];
        _currentPoolIndex = (_currentPoolIndex + 1) % _poolSize;

        // We stop the player if it's currently playing a previous sound to re-trigger immediately
        await player.stop();

        if (playbackRate != null) {
          await player.setPlaybackRate(playbackRate);
        } else {
          await player.setPlaybackRate(1.0); // Reset to standard speed
        }

        if (jungleSoundType != null && _settingsController.currentTheme.name == 'Amazon Jungle') {
          final file = await JungleSoundSynthesizer.getSound(jungleSoundType);
          await player.play(DeviceFileSource(file.path));
        } else {
          await player.play(AssetSource(soundPath));
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error playing sound ($soundPath / $jungleSoundType): $e");
        }
      }
    }
  }

  /// Plays the standard move sound with micro pitch modulation.
  /// If player is provided and theme is Amazon Jungle, plays animal-specific calls.
  Future<void> playMoveSound({Player? player}) async {
    if (_settingsController.currentTheme.name == 'Amazon Jungle') {
      if (player == Player.X) {
        await _playSound('', jungleSoundType: 'toucan_chirp');
      } else if (player == Player.O) {
        await _playSound('', jungleSoundType: 'monkey_chatter');
      } else {
        // Fallback or generic menu click
        final double pitchMultiplier = 0.94 + _random.nextDouble() * 0.12;
        await _playSound('', playbackRate: pitchMultiplier, jungleSoundType: 'toucan_chirp');
      }
    } else {
      // Generate speed/pitch between 0.94 and 1.06 (micro pitch variation of +/- 6%)
      final double pitchMultiplier = 0.94 + _random.nextDouble() * 0.12;
      await _playSound(_moveSoundPath, playbackRate: pitchMultiplier);
    }
  }

  /// Plays the win sound or tribal/owl call.
  Future<void> playWinSound({bool isLoss = false}) async {
    if (_settingsController.currentTheme.name == 'Amazon Jungle') {
      if (isLoss) {
        await _playSound('', jungleSoundType: 'owl_loss');
      } else {
        await _playSound('', jungleSoundType: 'tribal_drum');
      }
    } else {
      await _playSound(isLoss ? _drawSoundPath : _winSoundPath);
    }
  }

  /// Plays the draw sound or cricket chirp.
  Future<void> playDrawSound() async {
    if (_settingsController.currentTheme.name == 'Amazon Jungle') {
      await _playSound('', jungleSoundType: 'cricket_draw');
    } else {
      await _playSound(_drawSoundPath);
    }
  }

  /// Plays a synthesized animal peek sound when they slide into view.
  Future<void> playAnimalPeekSound(int animalIndex) async {
    if (_settingsController.currentTheme.name == 'Amazon Jungle') {
      final String soundType = _getAnimalPeekSoundType(animalIndex);
      await _playSound('', jungleSoundType: soundType);
    }
  }

  String _getAnimalPeekSoundType(int index) {
    switch (index) {
      case 0:
        return 'toucan_peek';
      case 1:
        return 'snake_peek';
      case 2:
        return 'frog_peek';
      case 3:
        return 'tiger_peek';
      case 4:
        return 'lion_peek';
      default:
        return 'toucan_peek';
    }
  }

  /// Stops any currently playing sound on all players in the pool.
  Future<void> stop() async {
    for (var player in _pool) {
      try {
        await player.stop();
      } catch (e) {
        if (kDebugMode) {
          print("Error stopping sound: $e");
        }
      }
    }
  }

  /// Releases all audio player resources in the pool.
  void dispose() {
    for (var player in _pool) {
      player.dispose();
    }
  }
}
