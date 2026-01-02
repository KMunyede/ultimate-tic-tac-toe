import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_controller.dart';

/// A service for managing and playing sound effects.
///
/// This class encapsulates the `audioplayers` logic and provides simple, clean
/// methods to play predefined game sounds. It correctly respects the user's
/// sound settings from `SettingsController`.
///
/// ARCHITECTURAL DECISION:
/// We use a single, long-lived `AudioPlayer` instance. For simple sound effects
/// that don't need to overlap, this is efficient and avoids the overhead of
/// creating new player instances. The `audioplayers` package automatically
/// handles caching of assets after their first playback, which gives us
/// low-latency performance on subsequent plays without needing the legacy `AudioCache` API.
class SoundManager {
  final SettingsController _settingsController;

  // A single player instance is memory-efficient for sequential sound effects.
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Define asset paths as constants for easy management and to avoid typos.
  // Using .mp3 as per your confirmation.
  static const String _moveSoundPath = 'sounds/move.mp3';
  static const String _winSoundPath = 'sounds/win.mp3';
  static const String _drawSoundPath = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  /// Initializes the sound manager.
  Future<void> init() async {
    // No explicit pre-loading is needed with this modern setup.
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
