import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_controller.dart';

/// A service for managing and playing sound effects.
///
/// This class encapsulates the `audioplayers` logic and provides simple, clean
/// methods to play predefined game sounds. It correctly respects the user's
/// sound settings from `SettingsController`.
class SoundManager {
  final SettingsController _settingsController;

  // A single player instance is memory-efficient for sequential sound effects.
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Define asset paths as constants for easy management and to avoid typos.
  static const String _moveSoundPath = 'sounds/move.mp3';
  static const String _winSoundPath = 'sounds/win.mp3';
  static const String _drawSoundPath = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  /// Initializes the sound manager and pre-loads sounds into the cache.
  Future<void> init() async {
    // Pre-caching sounds at startup to prevent any lag on the first play.
    await _preLoadSounds();
  }

  /// Loads all game sounds into the audioplayers cache.
  Future<void> _preLoadSounds() async {
    // Use a separate, temporary audio cache instance for pre-loading.
    final cache = AudioCache(prefix: 'assets/');
    try {
      await cache.loadAll([_moveSoundPath, _winSoundPath, _drawSoundPath]);
      if (kDebugMode) {
        print("All sounds pre-loaded into cache.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error pre-loading sounds: $e");
      }
    }
  }

  /// A private helper to play a sound from assets, respecting sound settings.
  Future<void> _playSound(String soundPath) async {
    if (_settingsController.isSoundOn) {
      try {
        await _audioPlayer.play(AssetSource(soundPath));
      } catch (e) {
        // Production-ready code should handle errors, e.g., if a file is missing.
        if (kDebugMode) {
          print("Error playing sound: $e");
        }
      }
    }
  }

  /// Plays the standard move sound.
  void playMoveSound() {
    _playSound(_moveSoundPath);
  }

  /// Plays the win sound and waits for it to complete.
  Future<void> playWinSound() async {
    if (_settingsController.isSoundOn) {
      try {
        await _audioPlayer.play(AssetSource(_winSoundPath));
        // This robustly waits for the current playback to complete.
        await _audioPlayer.onPlayerComplete.first;
      } catch (e) {
        if (kDebugMode) {
          print("Error playing win sound: $e");
        }
      }
    }
  }

  /// Plays the draw sound.
  void playDrawSound() {
    _playSound(_drawSoundPath);
  }

  /// Releases the audio player resources.
  void dispose() {
    _audioPlayer.dispose();
  }
}
