// lib/core/audio/jungle_sound_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class JungleSoundSynthesizer {
  static final Map<String, File> _soundCache = {};
  static const double _pitchShift = 0.7; // 30% reduction

  /// Retrieves a synthesized jungle WAV file from the cache, or generates it if missing.
  static Future<File> getSound(String type) async {
    if (_soundCache.containsKey(type)) {
      final file = _soundCache[type]!;
      if (await file.exists()) {
        return file;
      }
    }

    final File file;
    switch (type) {
      case 'toucan_chirp':
        file = await _generateToucanChirp();
        break;
      case 'monkey_chatter':
        file = await _generateMonkeyChatter();
        break;
      case 'tribal_drum':
        file = await _generateTribalDrum();
        break;
      case 'owl_loss':
        file = await _generateOwlLoss();
        break;
      case 'cricket_draw':
        file = await _generateCricketDraw();
        break;
      case 'toucan_peek':
        file = await _generateToucanPeek();
        break;
      case 'snake_peek':
        file = await _generateSnakePeek();
        break;
      case 'frog_peek':
        file = await _generateFrogPeek();
        break;
      case 'tiger_peek':
        file = await _generateTigerPeek();
        break;
      case 'lion_peek':
        file = await _generateLionPeek();
        break;
      default:
        throw ArgumentError("Unknown sound type: $type");
    }

    _soundCache[type] = file;
    return file;
  }

  /// Synthesizes a Twig Snap sound (Move X)
  static Future<File> _generateToucanChirp() {
    return _generateWavFile(
      durationSeconds: 0.25,
      sampleRate: 22050,
      waveform: (double t) {
        double crack = 0.0;
        if (t < 0.05) {
          crack = (Random().nextDouble() - 0.5) * exp(-t * 100.0) * 0.9;
        }
        double resFreq = 150.0 * _pitchShift;
        double resonance = sin(2 * pi * resFreq * t) * exp(-t * 20.0) * 0.5;
        return crack + resonance;
      },
    );
  }

  /// Synthesizes a Leaf Rustle & Wood Click sound (Move O)
  static Future<File> _generateMonkeyChatter() {
    return _generateWavFile(
      durationSeconds: 0.35,
      sampleRate: 22050,
      waveform: (double t) {
        double tMod = t % 0.18;
        double clickFreq = 110.0 * _pitchShift;
        double click = sin(2 * pi * clickFreq * tMod) * exp(-tMod * 40.0) * 0.6;
        double rustle = (Random().nextDouble() - 0.5) * sin(t * pi / 0.35) * 0.2;
        return click + rustle;
      },
    );
  }

  /// Synthesizes a celebratory deep jungle victory theme
  static Future<File> _generateTribalDrum() {
    return _generateWavFile(
      durationSeconds: 4.0,
      sampleRate: 22050,
      waveform: (double t) {
        double flute = 0.0;
        double fluteVolume = 0.0;
        double freq = 0.0;

        if (t >= 0.0 && t < 0.8) {
          freq = 440.0;
          fluteVolume = sin(t * pi / 0.8) * 0.3;
        } else if (t >= 0.8 && t < 1.6) {
          freq = 523.25;
          fluteVolume = sin((t - 0.8) * pi / 0.8) * 0.3;
        } else if (t >= 1.6 && t < 2.4) {
          freq = 587.33;
          fluteVolume = sin((t - 1.6) * pi / 0.8) * 0.3;
        } else if (t >= 2.4 && t < 3.2) {
          freq = 783.99;
          fluteVolume = sin((t - 2.4) * pi / 0.8) * 0.35;
        } else if (t >= 3.2 && t < 4.0) {
          freq = 659.25;
          fluteVolume = sin((t - 3.2) * pi / 0.8) * 0.3;
        }

        if (fluteVolume > 0.0) {
          double shiftFreq = freq * _pitchShift;
          double vibrato = 1.0 + 0.015 * sin(2 * pi * 6.0 * t);
          double fMod = shiftFreq * vibrato;
          double osc = sin(2 * pi * fMod * t) 
                     + 0.4 * sin(2 * pi * fMod * 3.0 * t) 
                     + 0.2 * sin(2 * pi * fMod * 5.0 * t);
          double breath = (Random().nextDouble() - 0.5) * 0.2;
          flute = (osc + breath) * fluteVolume;
        }

        double drum = 0.0;
        final List<double> strikes = [0.0, 0.5, 1.0, 1.2, 1.8, 2.3, 2.5, 3.0, 3.5];
        for (final strike in strikes) {
          if (t >= strike) {
            double st = t - strike;
            if (st < 0.45) {
              double drumFreq = (strike % 1.0 == 0) ? 52.0 : 78.0;
              double shiftDrum = drumFreq * _pitchShift;
              double env = exp(-st * 10.0);
              drum += sin(2 * pi * shiftDrum * st) * env * 0.7;
            }
          }
        }

        double lionRoar = 0.0;
        if (t >= 0.0 && t < 1.2) {
          double lionEnv = sin(t * pi / 1.2);
          double carrierFreq = 75.0 * _pitchShift;
          double carrier = sin(2 * pi * carrierFreq * t) + 0.5 * sin(2 * pi * (carrierFreq * 2) * t);
          double growlMod = 1.0 + 0.8 * sin(2 * pi * 24.0 * t);
          double rumble = (Random().nextDouble() - 0.5) * 0.3;
          lionRoar = (carrier * growlMod * 0.4 + rumble * 0.25) * lionEnv * 0.75;
        }

        double signal = (flute * 0.8) + (drum * 0.7) + (lionRoar * 0.6);
        return signal.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes an ultra-deep Growling Predator Roar (Loss)
  static Future<File> _generateOwlLoss() {
    return _generateWavFile(
      durationSeconds: 2.2,
      sampleRate: 22050,
      waveform: (double t) {
        double env = sin(t * pi / 2.2).clamp(0.0, 1.0);
        double cFreq = 68.0 * _pitchShift;
        double subFreq = 34.0 * _pitchShift;
        double carrier = sin(2 * pi * cFreq * t) + 0.7 * sin(2 * pi * subFreq * t);
        double growlMod = 1.0 + 0.8 * sin(2 * pi * 15.0 * t);
        double rumble = (Random().nextDouble() - 0.5) * 0.25;
        double roar = (carrier * growlMod * 0.5 + rumble * 0.2) * env * 0.95;
        return roar;
      },
    );
  }

  /// Synthesizes a tranquil deep night breeze (Draw)
  static Future<File> _generateCricketDraw() {
    return _generateWavFile(
      durationSeconds: 2.5,
      sampleRate: 22050,
      waveform: (double t) {
        double env = sin(t * pi / 2.5).clamp(0.0, 1.0);
        double dFreq = 98.0 * _pitchShift;
        double drone = sin(2 * pi * dFreq * t) + 0.3 * sin(2 * pi * (dFreq * 2) * t);
        double wind = (Random().nextDouble() - 0.5) * 0.15 * sin(t * pi / 2.5);
        double tMod = t % 0.2;
        double cricFreq = 450.0 * _pitchShift;
        double cricket = sin(2 * pi * cricFreq * tMod) * sin(tMod * pi / 0.2) * 0.08;
        return (drone * 0.2 + wind * 0.5 + cricket) * env;
      },
    );
  }

  /// Synthesizes Toucan call sequence
  static Future<File> _generateToucanPeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double sound = 0.0;
        final List<double> chirpTimes = [0.2, 0.8, 1.5, 2.2, 2.9];
        for (final chirp in chirpTimes) {
          if (t >= chirp && t < chirp + 0.5) {
            double st = t - chirp;
            double freq = (950.0 + st * 1500.0) * _pitchShift;
            sound += sin(2 * pi * freq * st) * sin(st * pi / 0.5) * 0.4;
          }
        }
        return sound.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Snake hiss
  static Future<File> _generateSnakePeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double rustle = (Random().nextDouble() - 0.5) * 0.1;
        double hiss = 0.0;
        final List<List<double>> intervals = [[0.3, 1.3], [1.8, 2.8]];
        for (final intv in intervals) {
          if (t >= intv[0] && t < intv[1]) {
            double st = t - intv[0];
            double dur = intv[1] - intv[0];
            double hFreq = 7200.0 * _pitchShift;
            hiss += (Random().nextDouble() - 0.5) * sin(2 * pi * hFreq * st) * sin(st * pi / dur) * 0.4;
          }
        }
        return (rustle + hiss).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Tree Frog croak
  static Future<File> _generateFrogPeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double frog = 0.0;
        final List<double> times = [0.3, 1.2, 2.1];
        for (final stTime in times) {
          if (t >= stTime && t < stTime + 0.7) {
            double st = t - stTime;
            double pitch = 148.0 * _pitchShift;
            double trem = 1.0 + 0.8 * sin(2 * pi * 36.0 * st);
            frog += sin(2 * pi * pitch * st) * trem * sin(st * pi / 0.7) * 0.5;
          }
        }
        return frog.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Tiger growl
  static Future<File> _generateTigerPeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double growl = 0.0;
        if (t >= 0.2 && t < 2.0) {
          double env = sin((t - 0.2) * pi / 1.8);
          double carrier = 64.0 * _pitchShift;
          growl = (sin(2 * pi * carrier * t) * (1.0 + 0.8 * sin(2 * pi * 15.0 * t)) * 0.5 + (Random().nextDouble() - 0.5) * 0.2) * env;
        }
        return growl.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes Lion roar
  static Future<File> _generateLionPeek() {
    return _generateWavFile(
      durationSeconds: 3.5,
      sampleRate: 22050,
      waveform: (double t) {
        double roar = 0.0;
        if (t >= 0.2 && t < 2.5) {
          double env = sin((t - 0.2) * pi / 2.3);
          double freq = 58.0 * _pitchShift;
          roar = (sin(2 * pi * freq * t) * (1.0 + 0.8 * sin(2 * pi * 20.0 * t)) * 0.6 + (Random().nextDouble() - 0.5) * 0.3) * env;
        }
        return roar.clamp(-1.0, 1.0);
      },
    );
  }

  /// Low-level WAV file generator writing signed 16-bit Mono PCM bytes.
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

    // 1. RIFF header chunk
    bytes.add([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    final chunkSizeData = ByteData(4)..setUint32(0, chunkSize, Endian.little);
    bytes.add(chunkSizeData.buffer.asUint8List());
    bytes.add([0x57, 0x41, 0x56, 0x45]); // "WAVE"

    // 2. "fmt " subchunk details
    bytes.add([0x66, 0x6D, 0x74, 0x20]); // "fmt "
    bytes.add([0x10, 0x00, 0x00, 0x00]); // Subchunk1Size = 16
    bytes.add([0x01, 0x00]); // AudioFormat = 1 (PCM)
    bytes.add([0x01, 0x00]); // NumChannels = 1 (Mono)
    final sampleRateData = ByteData(4)..setUint32(0, sampleRate, Endian.little);
    bytes.add(sampleRateData.buffer.asUint8List());
    final byteRateData = ByteData(4)..setUint32(0, byteRate, Endian.little);
    bytes.add(byteRateData.buffer.asUint8List());
    bytes.add([blockAlign, 0x00]); // BlockAlign
    bytes.add([bitsPerSample, 0x00]); // BitsPerSample = 16

    // 3. "data" subchunk details
    bytes.add([0x64, 0x61, 0x74, 0x61]); // "data"
    final subChunk2SizeData = ByteData(4)..setUint32(0, subChunk2Size, Endian.little);
    bytes.add(subChunk2SizeData.buffer.asUint8List());

    // 4. Sample wave generation
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
    final file = File('${directory.path}/jungle_synth_${DateTime.now().microsecondsSinceEpoch}_${(100 + Random().nextInt(900))}.wav');
    await file.writeAsBytes(bytes.takeBytes());
    return file;
  }
}
