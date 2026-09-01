// lib/core/audio/frequency_matched_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class FrequencyMatchedSynthesizer {
  static final Map<String, File> _soundCache = {};

  static Future<File> getSound(String type) async {
    if (_soundCache.containsKey(type)) {
      final file = _soundCache[type]!;
      if (await file.exists()) return file;
    }

    final File file;
    switch (type) {
      case 'dolphin_peek': file = await _genAnimal('dolphin', _dolphinLogic); break;
      case 'toucan_peek': file = await _genAnimal('toucan', _toucanLogic); break;
      case 'panda_peek': file = await _genAnimal('panda', _pandaLogic); break;
      case 'crab_peek': file = await _genAnimal('crab', _crabLogic); break;
      case 'snake_peek': file = await _genAnimal('snake', _snakeLogic); break;
      case 'frog_peek': file = await _genAnimal('frog', _frogLogic); break;
      case 'lion_peek': file = await _genAnimal('lion', _lionLogic); break;
      case 'tiger_peek': file = await _genAnimal('tiger', _tigerLogic); break;
      case 'whale_peek': file = await _genAnimal('whale', _whaleLogic); break;
      case 'turtle_peek': file = await _genAnimal('turtle', _turtleLogic); break;
      case 'wave_splash': file = await _genSimple(3.0, _waveLogic); break;
      case 'leaf_rustle': file = await _genSimple(1.5, _leafLogic); break;
      case 'twig_snap': file = await _genSimple(0.5, _twigLogic); break;
      default: throw ArgumentError("Unknown sound: $type");
    }

    _soundCache[type] = file;
    return file;
  }

  // --- Animal 15s Ambient Loop Logic (60Hz - 1500Hz) ---

  static double _dolphinLogic(double t) {
    // Soft rhythmic cackles/clicks (800Hz) every 3 seconds
    if ((t % 3.0) > 0.8) return 0.0;
    double burstT = t % 3.0;
    double click = ((burstT * 20).floor() % 2 == 0) ? sin(2 * pi * 800 * t) : 0.0;
    return click * exp(-burstT * 4.0) * 0.4;
  }

  static double _toucanLogic(double t) {
    // Low croaks (200Hz - 600Hz) every 4 seconds
    if ((t % 4.0) > 1.2) return 0.0;
    double burstT = t % 4.0;
    double croak = sin(2 * pi * (200 + 400 * sin(t * 10).abs()) * t);
    return croak * exp(-burstT * 3.0) * 0.5;
  }

  static double _pandaLogic(double t) {
    // Low bleats (400Hz) and grunts (200Hz)
    double cycle = t % 5.0;
    if (cycle < 1.0) return sin(2 * pi * 400 * t) * exp(-cycle * 5.0) * 0.4;
    if (cycle > 2.5 && cycle < 3.5) return sin(2 * pi * 200 * t) * exp(-(cycle-2.5) * 8.0) * 0.3;
    return 0.0;
  }

  static double _crabLogic(double t) {
    // Rhythmic scuttle (500Hz) + shell click (1200Hz)
    double scuttle = sin(2 * pi * 500 * t) * 0.2 * (sin(t * 20).abs());
    double click = (t % 2.0 < 0.1) ? sin(2 * pi * 1200 * t) * 0.3 : 0.0;
    return (scuttle + click) * 0.5;
  }

  static double _snakeLogic(double t) {
    // Low frequency slither/vibration (150Hz - 400Hz)
    double vibrato = sin(2 * pi * (150 + 250 * sin(t * 5).abs()) * t);
    return vibrato * 0.2 * (sin(t * pi / 15.0)); // Fade in/out loop
  }

  static double _frogLogic(double t) {
    // Deep Ribbit (300Hz) + Chorus drone (900Hz)
    double ribbit = (t % 3.0 < 0.5) ? sin(2 * pi * 300 * t) * exp(-(t%3.0) * 10.0) : 0.0;
    double drone = sin(2 * pi * 900 * t) * 0.1 * sin(t * 0.5);
    return (ribbit + drone) * 0.6;
  }

  static double _lionLogic(double t) {
    // Deep Growl (60Hz) + Resonant Roar (250Hz)
    double growl = sin(2 * pi * (60 + 20 * sin(t * 2)) * t) * 0.4;
    double roar = (t % 7.0 < 2.0) ? sin(2 * pi * 250 * t) * sin((t%7.0) * pi / 2.0) * 0.5 : 0.0;
    return (growl + roar) * 0.7;
  }

  static double _tigerLogic(double t) {
    // Low Chuff (80Hz) + Muted Roar (300Hz)
    double chuff = (t % 4.0 < 0.3) ? (Random().nextDouble() - 0.5) * 0.5 : 0.0; // Filtered noise logic
    double roar = (t % 8.0 > 5.0) ? sin(2 * pi * 300 * t) * 0.4 : 0.0;
    return (chuff + roar) * 0.6;
  }

  static double _whaleLogic(double t) {
    // Deep Hum (100Hz) + Resonant Song (500Hz)
    double hum = sin(2 * pi * 100 * t) * 0.5;
    double song = sin(2 * pi * (500 + 100 * sin(t * 0.5)) * t) * 0.3 * sin(t * pi / 15.0);
    return (hum + song) * 0.5;
  }

  static double _turtleLogic(double t) {
    // Heavy Breath (300Hz) + Low Grunt (150Hz)
    double breath = sin(2 * pi * 300 * t) * 0.2 * sin(t * pi / 3.0).abs();
    double grunt = (t % 6.0 < 0.5) ? sin(2 * pi * 150 * t) * 0.4 : 0.0;
    return (breath + grunt) * 0.5;
  }

  // --- Environmental Effects ---

  static double _waveLogic(double t) => (sin(2 * pi * 80 * t) * 0.3 + (Random().nextDouble() - 0.5) * 0.1) * sin(t * pi / 3.0);
  static double _leafLogic(double t) => (Random().nextDouble() - 0.5) * 0.15 * exp(-t * 2.0);
  static double _twigLogic(double t) => (Random().nextDouble() - 0.5) * 0.6 * exp(-t * 100.0);

  // --- Synthesis Engine ---

  static Future<File> _genAnimal(String name, double Function(double t) wave) => _gen(15.0, name, wave);
  static Future<File> _genSimple(double dur, double Function(double t) wave) => _gen(dur, 'effect', wave);

  static Future<File> _gen(double dur, String name, double Function(double t) wave) async {
    final int sr = 22050;
    final int samples = (dur * sr).toInt();
    final bytes = BytesBuilder();
    _writeWavHeader(bytes, samples, sr);
    for (int i = 0; i < samples; i++) {
      double t = i / sr;
      int val = (wave(t) * 32767).toInt().clamp(-32768, 32767);
      bytes.addByte(val & 0xFF);
      bytes.addByte((val >> 8) & 0xFF);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/fm_synth_${name}_${DateTime.now().microsecondsSinceEpoch}.wav');
    await file.writeAsBytes(bytes.takeBytes());
    return file;
  }

  static void _writeWavHeader(BytesBuilder b, int samples, int sr) {
    b.add([0x52, 0x49, 0x46, 0x46]); 
    int size = 36 + samples * 2;
    b.add([size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF]);
    b.add([0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00]); 
    b.add([sr & 0xFF, (sr >> 8) & 0xFF, (sr >> 16) & 0xFF, (sr >> 24) & 0xFF]);
    int br = sr * 2;
    b.add([br & 0xFF, (br >> 8) & 0xFF, (br >> 16) & 0xFF, (br >> 24) & 0xFF]);
    b.add([0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61]);
    int ds = samples * 2;
    b.add([ds & 0xFF, (ds >> 8) & 0xFF, (ds >> 16) & 0xFF, (ds >> 24) & 0xFF]);
  }
}
