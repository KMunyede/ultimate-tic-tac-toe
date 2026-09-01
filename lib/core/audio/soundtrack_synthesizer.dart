// lib/core/audio/soundtrack_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class SoundtrackSynthesizer {
  static final Map<int, File> _trackCache = {};
  static const int _sampleRate = 22050;
  static const double _bpm = 128.0;
  static const double _beatDur = 60.0 / _bpm;

  static Future<File> getTrack(int index) async {
    if (_trackCache.containsKey(index)) {
      final file = _trackCache[index]!;
      if (await file.exists()) return file;
    }

    final File file;
    switch (index) {
      case 0: file = await _genTrack("Neon Ghosts", _neonGhosts); break; // DeadMau5 style
      case 1: file = await _genTrack("Titanium Beats", _titaniumBeats); break; // Guetta/SHM style
      case 2: file = await _genTrack("Levels of Light", _levelsOfLight); break; // Avicii style
      default: throw ArgumentError("Unknown track index: $index");
    }

    _trackCache[index] = file;
    return file;
  }

  // --- Track Algorithms (Strictly High Headroom) ---

  static double _neonGhosts(double t) {
    // DeadMau5: Progressive build, plucky chords, slow filter sweeps
    double kick = _kick(t, 0.7);
    double hat = _hihat(t, 0.3);
    
    // Progressively opening filter
    double sweep = (1.0 + sin(t * 0.05)) * 0.5;
    
    // Minor progression: Am - F - C - G
    final roots = [220.0, 174.61, 261.63, 196.00];
    int bar = (t / (_beatDur * 8)).floor() % 4;
    double freq = roots[bar];
    
    // Pluck rhythm
    double pluck = (t % (_beatDur * 0.5) < 0.1) ? sin(2 * pi * freq * t) * exp(-(t % (_beatDur * 0.5)) * 20.0) : 0.0;
    
    return (kick * 0.5 + hat * 0.15 + pluck * sweep * 0.35).clamp(-1, 1) * 0.6;
  }

  static double _titaniumBeats(double t) {
    // Guetta/SHM: High energy, sawtooth stacks, driving rhythm
    double kick = _kick(t, 0.8);
    double clap = _clap(t, 0.4);
    
    // I - IV - V (C - F - G)
    final chords = [261.63, 349.23, 392.00, 349.23];
    int bar = (t / (_beatDur * 4)).floor() % 4;
    double freq = chords[bar];
    
    // Sawtooth lead (simplified)
    double synth = 0.0;
    for (int h = 1; h < 4; h++) {
      synth += (1.0 / h) * sin(2 * pi * freq * h * t);
    }
    
    // Syncopated gate
    double gate = ((t / (_beatDur * 0.25)).floor() % 8 != 3) ? 1.0 : 0.0;
    
    return (kick * 0.5 + clap * 0.25 + synth * gate * 0.25).clamp(-1, 1) * 0.6;
  }

  static double _levelsOfLight(double t) {
    // Avicii: Anthemic piano melody, syncopated bass, uplifting vibes
    double kick = _kick(t, 0.7);
    double sidechain = 1.0 - exp(-(t % _beatDur) * 15.0);
    
    // Pentatonic Melody: C - E - G - A
    final melody = [261.63, 329.63, 392.00, 440.00];
    int beat = (t / (_beatDur * 0.5)).floor() % 8;
    double freq = melody[beat % 4] * (beat > 3 ? 1.5 : 1.0);
    
    double piano = sin(2 * pi * freq * t) * exp(-(t % (_beatDur * 0.5)) * 12.0);
    double bass = sin(2 * pi * (freq / 4.0) * t) * sidechain * 0.4;
    
    return (kick * 0.5 + piano * 0.3 + bass * 0.2).clamp(-1, 1) * 0.6;
  }

  // --- Core Drum Components ---

  static double _kick(double t, double vol) {
    double beatT = t % _beatDur;
    if (beatT > 0.12) return 0.0;
    return sin(2 * pi * (60 * exp(-beatT * 50.0)) * beatT) * vol * exp(-beatT * 25.0);
  }

  static double _hihat(double t, double vol) {
    double offBeatT = (t + _beatDur / 2) % _beatDur;
    if (offBeatT > 0.04) return 0.0;
    return (Random().nextDouble() - 0.5) * vol * exp(-offBeatT * 150.0);
  }

  static double _clap(double t, double vol) {
    double clapT = (t + _beatDur) % (_beatDur * 2);
    if (clapT > 0.15) return 0.0;
    return (Random().nextDouble() - 0.5) * vol * exp(-clapT * 40.0);
  }

  // --- Engine ---

  static Future<File> _genTrack(String name, double Function(double t) synth) async {
    const double duration = 180.0; // 3 minutes
    final int samples = (duration * _sampleRate).toInt();
    final bytes = BytesBuilder();
    _writeHeader(bytes, samples, _sampleRate);
    
    for (int i = 0; i < samples; i++) {
      double t = i / _sampleRate;
      int val = (synth(t) * 32767).toInt().clamp(-32768, 32767);
      bytes.addByte(val & 0xFF);
      bytes.addByte((val >> 8) & 0xFF);
    }
    
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bgm_${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(bytes.takeBytes());
    return file;
  }

  static void _writeHeader(BytesBuilder b, int samples, int sr) {
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
