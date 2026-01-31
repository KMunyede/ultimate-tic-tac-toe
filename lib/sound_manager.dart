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
  // Paths should align with the 'assets/' prefix defined in pubspec.yaml
  static const String _moveSoundPath = 'sounds/move.mp3';
  static const String _winSoundPath = 'sounds/win.mp3';
  static const String _drawSoundPath = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  /// Initializes the sound manager. Pre-loading is now handled implicitly by
  /// the modern audioplayers API when using AssetSource.
  Future<void> init() async {
    if (kDebugMode) {
      print("SoundManager initialized. Sounds will be loaded on first play.");
    }
    // No explicit pre-loading necessary with AssetSource.
  }

  /// A private helper to play a sound from assets, respecting sound settings.
  Future<void> _playSound(String soundPath) async {
    if (_settingsController.isSoundOn) {
      try {
        await _audioPlayer.stop(); // Stop any currently playing sound
        // We use AssetSource as recommended by the latest audioplayers API
        await _audioPlayer.play(AssetSource(soundPath));
      } catch (e) {
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

  /// Plays the win sound.
  Future<void> playWinSound() async {
    await _playSound(_winSoundPath);
  }

  /// Plays the draw sound.
  void playDrawSound() {
    _playSound(_drawSoundPath);
  }

  /// Stops any currently playing sound.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping sound: $e");
      }
    }
  }

  /// Releases the audio player resources.
  void dispose() {
    _audioPlayer.dispose();
  }
}
