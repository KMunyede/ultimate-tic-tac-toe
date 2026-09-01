import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import 'frequency_matched_synthesizer.dart';
// import 'soundtrack_synthesizer.dart';

/// A service for managing and playing sound effects and background music.
class SoundManager {
  final SettingsController _settingsController;
  final Random _random = Random();

  // Audio Player Pools
  static const int _poolSize = 10;
  final List<AudioPlayer> _pool = List.generate(_poolSize, (_) => AudioPlayer());
  int _currentPoolIndex = 0;
  
  // Background Music Player
  final AudioPlayer _bgmPlayer = AudioPlayer();
  // bool _isBgmPlaying = false; // Temporarily unused in Markers Only mode

  // Master Volume Levels (Industry Standard Softness)
  static const double _masterSfxVolume = 0.6;
  static const double _masterBgmVolume = 0.4;

  static const String _moveSoundPath = 'sounds/move.mp3';
  static const String _winSoundPath = 'sounds/win.mp3';
  static const String _drawSoundPath = 'sounds/draw.mp3';

  SoundManager(this._settingsController);

  Future<void> init() async {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(_masterBgmVolume);
    for (var player in _pool) {
      await player.setVolume(_masterSfxVolume);
    }
  }

  /// Starts random background music from the EDM collection.
  Future<void> startBackgroundMusic() async {
    return; // Temporarily disabled: Markers Only mode
    // if (!_settingsController.isSoundOn || _isBgmPlaying) return;
    // ...
  }

  /// Stops background music.
  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
    // _isBgmPlaying = false;
  }

  /// Plays a sound from the frequency-matched synthesizer or assets.
  Future<void> _playSound(String soundPath, {double? playbackRate, String? fmSoundType}) async {
    if (_settingsController.isSoundOn) {
      try {
        final player = _pool[_currentPoolIndex];
        _currentPoolIndex = (_currentPoolIndex + 1) % _poolSize;

        await player.stop();
        if (playbackRate != null) {
          await player.setPlaybackRate(playbackRate);
        } else {
          await player.setPlaybackRate(1.0);
        }

        if (fmSoundType != null) {
          final file = await FrequencyMatchedSynthesizer.getSound(fmSoundType);
          await player.play(DeviceFileSource(file.path));
        } else {
          await player.play(AssetSource(soundPath));
        }
      } catch (e) {
        if (kDebugMode) print("Error playing sound: $e");
      }
    }
  }

  Future<void> playMoveSound({Player? player, int filledCellCount = 0}) async {
    final themeName = _settingsController.currentTheme.name;
    final double intensityShift = (filledCellCount / 9.0) * 0.15;

    if (themeName == 'Amazon Jungle') {
      await _playSound('', fmSoundType: 'leaf_rustle', playbackRate: 1.0 + intensityShift);
    } else if (themeName == 'Pacific Waves') {
      await _playSound('', fmSoundType: 'wave_splash', playbackRate: 1.0 + intensityShift);
    } else {
      final double pitchMultiplier = 0.94 + _random.nextDouble() * 0.12 + intensityShift;
      await _playSound(_moveSoundPath, playbackRate: pitchMultiplier);
    }
  }

  Future<void> playWinSound({bool isLoss = false}) async {
    await _playSound(isLoss ? _drawSoundPath : _winSoundPath);
  }

  Future<void> playDrawSound() async {
    await _playSound(_drawSoundPath);
  }

  /// Plays a synthesized frequency-matched animal sound.
  Future<void> playAnimalPeekSound(int animalIndex) async {
    return; // Temporarily disabled: Markers Only mode
    /*
    final themeName = _settingsController.currentTheme.name;
    String? soundType;

    if (themeName == 'Amazon Jungle') {
      switch (animalIndex) {
        case 0: soundType = 'toucan_peek'; break;
        case 1: soundType = 'snake_peek'; break;
        case 2: soundType = 'frog_peek'; break;
        case 3: soundType = 'tiger_peek'; break;
        case 4: soundType = 'lion_peek'; break;
      }
    } else if (themeName == 'Pacific Waves') {
      switch (animalIndex) {
        case 0: soundType = 'seagull_peek'; break;
        case 1: soundType = 'panda_peek'; break;
        case 2: soundType = 'crab_peek'; break;
        case 3: soundType = 'whale_peek'; break;
        case 4: soundType = 'turtle_peek'; break;
      }
    } else {
      final animals = ['dolphin_peek', 'toucan_peek', 'panda_peek', 'lion_peek', 'frog_peek'];
      soundType = animals[_random.nextInt(animals.length)];
    }

    if (soundType != null) {
      await _playSound('', fmSoundType: soundType);
    }
    */
  }

  Future<void> stop() async {
    for (var player in _pool) {
      await player.stop();
    }
    await _bgmPlayer.stop();
    // _isBgmPlaying = false;
  }

  void dispose() {
    for (var player in _pool) {
      player.dispose();
    }
    _bgmPlayer.dispose();
  }
}
