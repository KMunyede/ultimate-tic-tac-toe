import 'package:audioplayers/audioplayers.dart';
import 'settings_controller.dart';

class SoundManager {
  final SettingsController _settingsController;
  final AudioPlayer _player = AudioPlayer();

  // Asset paths for the sounds
  static const String _moveSound = 'sounds/move.mp3';
  static const String _winSound = 'sounds/win.mp3';
  static const String _drawSound = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  Future<void> init() async {
    // With audioplayers, you can set a global volume or handle it per play.
    // Here, we check the setting before playing any sound.
    // Pre-caching sounds for lower latency.
    // Create an AudioCache instance that uses our player instance.
    final cache = AudioCache(prefix: 'assets/');
    cache.fixedPlayer = _player;
    await cache.loadAll([_moveSound, _winSound, _drawSound]);
  }

  Future<void> _playSound(String soundPath) async {
    if (_settingsController.isSoundOn) {
      await _player.play(AssetSource(soundPath));
    }
  }

  void playMoveSound() {
    _playSound(_moveSound);
  }

  Future<void> playWinSound() async {
    if (_settingsController.isSoundOn) {
      // The play method completes when the sound starts. We need to wait for it to finish.
      // We can listen to the onPlayerComplete stream for this.
      await _player.play(AssetSource(_winSound));
      await _player.onPlayerComplete.first; // Wait for the sound to finish
    }
  }

  void playDrawSound() {
    _playSound(_drawSound);
  }

  void dispose() {
    // Release the audio player resources.
    _player.dispose();
  }
}

extension on AudioCache {
  set fixedPlayer(AudioPlayer fixedPlayer) {}
}