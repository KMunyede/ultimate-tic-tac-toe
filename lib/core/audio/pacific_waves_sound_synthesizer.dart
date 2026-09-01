// lib/core/audio/pacific_waves_sound_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class PacificWavesSoundSynthesizer {
  static final Map<String, File> _soundCache = {};
  static const double _pitchShift = 0.45; // Standardized deeper resonance for realism

  /// Retrieves a synthesized Pacific Waves WAV file from the cache, or generates it if missing.
  static Future<File> getSound(String type) async {
    if (_soundCache.containsKey(type)) {
      final file = _soundCache[type]!;
      if (await file.exists()) {
        return file;
      }
    }

    final File file;
    switch (type) {
      case 'wave_splash':
        file = await _generateWaveSplash();
        break;
      case 'shell_clack':
        file = await _generateShellClack();
        break;
      case 'ocean_victory':
        file = await _generateOceanVictory();
        break;
      case 'deep_abyss_loss':
        file = await _generateDeepAbyssLoss();
        break;
      case 'misty_draw':
        file = await _generateMistyDraw();
        break;
      case 'whale_peek':
        file = await _generateWhalePeek();
        break;
      case 'dolphin_peek':
        file = await _generateDolphinPeek();
        break;
      case 'crab_peek':
        file = await _generateCrabPeek();
        break;
      case 'seagull_peek':
        file = await _generateSeagullPeek();
        break;
      case 'turtle_peek':
        file = await _generateTurtlePeek();
        break;
      default:
        throw ArgumentError("Unknown sound type: $type");
    }

    _soundCache[type] = file;
    return file;
  }

  /// Synthesizes a realistic Wave Splash with water sloshing and depth (Move X)
  static Future<File> _generateWaveSplash() {
    final random = Random(701);
    return _generateWavFile(
      durationSeconds: 1.0,
      sampleRate: 22050,
      waveform: (double t) {
        double spray = (random.nextDouble() - 0.5) * exp(-t * 10.0) * 0.8;
        double sloshMod = 1.0 + 0.6 * sin(2 * pi * 4.0 * t);
        double slosh = (random.nextDouble() - 0.5) * sloshMod * exp(-t * 3.0) * 0.4;
        
        // Deep sub-bass surge (30% lower than 50Hz)
        double surgeFreq = 50.0 * _pitchShift;
        double surge = sin(2 * pi * (surgeFreq - t * 10.0) * t) * exp(-t * 1.5) * 0.6;
        
        return (spray + slosh + surge).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a Shell Clack with aquatic resonance (Move O)
  static Future<File> _generateShellClack() {
    return _generateWavFile(
      durationSeconds: 0.45,
      sampleRate: 22050,
      waveform: (double t) {
        // Deeper fundamental for shell impact
        double clickFreq = 1200.0 * _pitchShift;
        double click = sin(2 * pi * clickFreq * t) * exp(-t * 40.0) * 0.7;
        
        double resFreq = 330.0 * _pitchShift;
        double resonance = sin(2 * pi * resFreq * t) * exp(-t * 8.0) * 0.4;
        
        double droplet = 0.0;
        if (t > 0.1) {
          double dt = t - 0.1;
          double dropFreq = 1800.0 * _pitchShift;
          droplet = sin(2 * pi * (dropFreq - dt * 2000.0) * dt) * exp(-dt * 20.0) * 0.3;
        }
        
        return (click + resonance + droplet).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a cinematic Ocean Victory theme with flowing water and depth
  static Future<File> _generateOceanVictory() {
    final random = Random(808);
    return _generateWavFile(
      durationSeconds: 5.0,
      sampleRate: 22050,
      waveform: (double t) {
        double current = (random.nextDouble() - 0.5) * 0.2; // Deep rumble
        double tide = (random.nextDouble() - 0.5) * sin(t * pi / 5.0) * 0.25;
        
        double melody = 0.0;
        final notes = [261.63, 329.63, 392.00, 523.25]; 
        int noteIdx = (t * 0.7).floor().clamp(0, 3);
        double noteT = t % (1/0.7);
        double freq = notes[noteIdx] * _pitchShift;
        melody = (sin(2 * pi * freq * t) + 0.4 * sin(2 * pi * freq * 1.5 * t)) * exp(-noteT * 1.2) * 0.45;

        double gulls = 0.0;
        if (t > 2.0 && t < 4.5) {
          double gt = t - 2.0;
          double gFreq = (1800.0 + 400.0 * sin(gt * 12.0)) * _pitchShift;
          gulls = sin(2 * pi * gFreq * gt) * sin(gt * pi / 2.5) * 0.12;
        }

        return (current + tide + melody + gulls).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a terrifying Deep Abyss Loss
  static Future<File> _generateDeepAbyssLoss() {
    final random = Random(909);
    return _generateWavFile(
      durationSeconds: 4.0,
      sampleRate: 22050,
      waveform: (double t) {
        double creakFreq = 40.0 * _pitchShift;
        double creak = sin(2 * pi * (creakFreq + sin(t * 8) * 4.0) * t) * 0.5;
        
        double bubbles = 0.0;
        if (random.nextDouble() > 0.96) {
          double bt = t % 0.1;
          double bFreq = 1200.0 * _pitchShift;
          bubbles = sin(2 * pi * (bFreq - bt * 5000.0) * bt) * 0.4;
        }
        
        double crush = (random.nextDouble() - 0.5) * (t > 3.0 ? 0.7 : 0.0) * (4.0 - t);
        
        double env = (4.0 - t) / 4.0;
        return (creak + bubbles + crush) * env;
      },
    );
  }

  /// Synthesizes a serene Misty Draw
  static Future<File> _generateMistyDraw() {
    final random = Random(111);
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double f1 = 220.0 * _pitchShift;
        double f2 = 277.18 * _pitchShift;
        double f3 = 329.63 * _pitchShift;
        double pad = (sin(2 * pi * f1 * t) + sin(2 * pi * f2 * t) + sin(2 * pi * f3 * t)) * 0.15;
        
        double lap = (random.nextDouble() - 0.5) * sin(2 * pi * 0.4 * t).abs() * 0.18;
        
        double chime = 0.0;
        if (t % 2.0 < 0.1) {
          double ct = t % 2.0;
          double chFreq = 880.0 * _pitchShift;
          chime = sin(2 * pi * chFreq * ct) * exp(-ct * 15.0) * 0.25;
        }
        
        return (pad + lap + chime) * sin(t * pi / 3.5);
      },
    );
  }

  /// Synthesizes Whale song
  static Future<File> _generateWhalePeek() {
    return _generateWavFile(
      durationSeconds: 4.0,
      sampleRate: 22050,
      waveform: (double t) {
        double env = sin(t * pi / 4.0);
        double baseFreq = (120.0 + 50.0 * sin(t * 0.6)) * _pitchShift;
        double whale = (sin(2 * pi * baseFreq * t) + 0.5 * sin(2 * pi * baseFreq * 1.5 * t)) * env * 0.7;
        whale *= (1.0 + 0.4 * sin(2 * pi * 4.0 * t));
        return whale;
      },
    );
  }

  /// Synthesizes Dolphin calls (Refined frequency)
  static Future<File> _generateDolphinPeek() {
    final random = Random(122);
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double clicks = 0.0;
        if (random.nextDouble() > 0.94) {
          double ct = t % 0.025;
          clicks = (random.nextDouble() - 0.5) * exp(-ct * 150.0) * 0.7;
        }
        
        // Lowered dolphin whistle frequency for better realism
        double whisFreq = 1200.0 * _pitchShift; 
        double whistle = sin(2 * pi * (whisFreq + 400.0 * sin(t * 4.0)) * t) * 0.08;
        
        return (clicks + whistle) * sin(t * pi / 3.5);
      },
    );
  }

  /// Synthesizes Crab scuttling
  static Future<File> _generateCrabPeek() {
    final random = Random();
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double scuttle = 0.0;
        if ((t * 10.0).floor() % 3 != 0) {
          double st = t % (1/10.0);
          double scuFreq = 2500.0 * _pitchShift;
          scuttle = sin(2 * pi * scuFreq * st) * exp(-st * 80.0) * 0.6;
        }
        double sand = (random.nextDouble() - 0.5) * 0.12 * sin(t * pi / 3.5);
        
        return (scuttle + sand).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Seagull cawing (Natural ~2kHz tuning)
  static Future<File> _generateSeagullPeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double sound = 0.0;
        final peaks = [0.3, 1.2, 2.1, 3.0];
        for (final p in peaks) {
          if (t >= p && t < p + 0.6) {
            double st = t - p;
            double freq = (2000.0 + 400.0 * sin(st * 12.0)) * _pitchShift;
            double vocal = (sin(2 * pi * freq * st) + 0.3 * (Random().nextDouble() - 0.5)) * sin(st * pi / 0.6);
            sound += vocal * 0.45;
          }
        }
        return sound.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Turtle movement
  static Future<File> _generateTurtlePeek() {
    return _generateWavFile(
      durationSeconds: 4.0,
      sampleRate: 22050,
      waveform: (double t) {
        double flipFreq = 35.0 * _pitchShift;
        double flipper = sin(2 * pi * flipFreq * t) * (1.0 + sin(2 * pi * 0.4 * t)) * 0.5;
        double surge = (Random().nextDouble() - 0.5) * 0.2 * sin(t * pi / 4.0);
        double bubble = (t % 1.5 < 0.08) ? sin(2 * pi * (600.0 * _pitchShift) * (t % 1.5)) * 0.3 : 0.0;
        
        return (flipper + surge + bubble) * sin(t * pi / 4.0);
      },
    );
  }

  static Future<File> _generateWavFile({
    required double durationSeconds,
    required int sampleRate,
    required double Function(double time) waveform,
  }) async {
    final int numSamples = (sampleRate * durationSeconds).toInt();
    const int numChannels = 1;
    const int bitsPerSample = 16;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int byteRate = sampleRate * blockAlign;
    final int subChunk2Size = numSamples * blockAlign;
    final int chunkSize = 36 + subChunk2Size;

    final bytes = BytesBuilder();
    bytes.add([0x52, 0x49, 0x46, 0x46]); 
    final chunkSizeData = ByteData(4)..setUint32(0, chunkSize, Endian.little);
    bytes.add(chunkSizeData.buffer.asUint8List());
    bytes.add([0x57, 0x41, 0x56, 0x45]); 
    bytes.add([0x66, 0x6D, 0x74, 0x20]); 
    bytes.add([0x10, 0x00, 0x00, 0x00]); 
    bytes.add([0x01, 0x00]); 
    bytes.add([0x01, 0x00]); 
    final sampleRateData = ByteData(4)..setUint32(0, sampleRate, Endian.little);
    bytes.add(sampleRateData.buffer.asUint8List());
    final byteRateData = ByteData(4)..setUint32(0, byteRate, Endian.little);
    bytes.add(byteRateData.buffer.asUint8List());
    bytes.add([blockAlign, 0x00]);
    bytes.add([bitsPerSample, 0x00]);
    bytes.add([0x64, 0x61, 0x74, 0x61]);
    final subChunk2SizeData = ByteData(4)..setUint32(0, subChunk2Size, Endian.little);
    bytes.add(subChunk2SizeData.buffer.asUint8List());

    final sampleBuffer = ByteData(2);
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double val = waveform(t);
      val = val.clamp(-1.0, 1.0);
      final int sampleInt = (val * 32767).toInt();
      sampleBuffer.setInt16(0, sampleInt, Endian.little);
      bytes.add(sampleBuffer.buffer.asUint8List());
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/pacific_synth_${DateTime.now().microsecondsSinceEpoch}_${(100 + Random().nextInt(900))}.wav');
    await file.writeAsBytes(bytes.takeBytes());
    return file;
  }
}
