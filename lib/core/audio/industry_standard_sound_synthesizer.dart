// lib/core/audio/industry_standard_sound_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class IndustryStandardSoundSynthesizer {
  static final Map<String, File> _soundCache = {};

  /// Retrieves a synthesized Studio Pro WAV file from the cache, or generates it if missing.
  static Future<File> getSound(String type) async {
    if (_soundCache.containsKey(type)) {
      final file = _soundCache[type]!;
      if (await file.exists()) {
        return file;
      }
    }

    final File file;
    switch (type) {
      case 'standard_move':
        file = await _generateStandardMove();
        break;
      case 'pro_victory':
        file = await _generateProVictory();
        break;
      case 'pro_draw':
        file = await _generateProDraw();
        break;
      case 'pro_loss':
        file = await _generateProLoss();
        break;
      default:
        throw ArgumentError("Unknown sound type: $type");
    }

    _soundCache[type] = file;
    return file;
  }

  /// Synthesizes a soft, professional "Tock" (Move)
  static Future<File> _generateStandardMove() {
    return _generateWavFile(
      durationSeconds: 0.15,
      sampleRate: 22050,
      waveform: (double t) {
        // Soft impact (440Hz dampened)
        double freq = 440.0;
        double tone = sin(2 * pi * freq * t) * exp(-t * 30.0) * 0.6;
        
        // Wood-like click
        double clickFreq = 1200.0;
        double click = sin(2 * pi * clickFreq * t) * exp(-t * 100.0) * 0.4;
        
        return (tone + click).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a clean, professional Victory chime
  static Future<File> _generateProVictory() {
    return _generateWavFile(
      durationSeconds: 2.0,
      sampleRate: 22050,
      waveform: (double t) {
        double sound = 0.0;
        final notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
        for (int i = 0; i < notes.length; i++) {
          double delay = i * 0.15;
          if (t > delay) {
            double dt = t - delay;
            sound += sin(2 * pi * notes[i] * dt) * exp(-dt * 4.0) * 0.2;
          }
        }
        return sound.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a neutral, clean Draw sound
  static Future<File> _generateProDraw() {
    return _generateWavFile(
      durationSeconds: 1.5,
      sampleRate: 22050,
      waveform: (double t) {
        double f1 = 392.00; // G4
        double f2 = 493.88; // B4
        double sound = (sin(2 * pi * f1 * t) + sin(2 * pi * f2 * t)) * 0.15 * exp(-t * 2.0);
        return sound.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a soft, non-punishing Loss sound
  static Future<File> _generateProLoss() {
    return _generateWavFile(
      durationSeconds: 2.0,
      sampleRate: 22050,
      waveform: (double t) {
        double freq = 220.0 * (1.0 - t * 0.2); // Descending soft bass
        double sound = sin(2 * pi * freq * t) * exp(-t * 1.5) * 0.3;
        return sound.clamp(-1.0, 1.0);
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
    final file = File('${directory.path}/pro_synth_${DateTime.now().microsecondsSinceEpoch}_${(100 + Random().nextInt(900))}.wav');
    await file.writeAsBytes(bytes.takeBytes());
    return file;
  }
}