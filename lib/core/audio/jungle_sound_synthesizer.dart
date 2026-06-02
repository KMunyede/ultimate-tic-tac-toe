// lib/core/audio/jungle_sound_synthesizer.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class JungleSoundSynthesizer {
  static final Map<String, File> _soundCache = {};

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

  /// Synthesizes a Twig Snap sound (Move X - Snapping twig)
  static Future<File> _generateToucanChirp() {
    final random = Random(101);
    return _generateWavFile(
      durationSeconds: 0.16,
      sampleRate: 22050,
      waveform: (double t) {
        // Twig snap: extremely sharp initial transient crack followed by wood resonance
        double crack = 0.0;
        if (t < 0.035) {
          crack = (random.nextDouble() - 0.5) * exp(-t * 150.0) * 0.95;
        }
        double resonance = sin(2 * pi * 150.0 * t) * exp(-t * 26.0) * 0.45;
        return crack + resonance;
      },
    );
  }

  /// Synthesizes a Leaf Rustle & Wood Click sound (Move O)
  static Future<File> _generateMonkeyChatter() {
    final random = Random(202);
    return _generateWavFile(
      durationSeconds: 0.28,
      sampleRate: 22050,
      waveform: (double t) {
        // Rustling dry leaves layered with a warm hollow wood click
        double tMod = t % 0.14;
        double click = sin(2 * pi * 110.0 * tMod) * exp(-tMod * 48.0) * 0.52;
        double rustle = (random.nextDouble() - 0.5) * sin(t * pi / 0.28) * 0.16;
        return click + rustle;
      },
    );
  }

  /// Synthesizes a celebratory deep jungle victory theme song layered with a soaring African
  /// bamboo flute melody and three synthesized animal calls: a growling Lion roar, chirping Toucan,
  /// and playful Monkey chatter (Move X win / Player Win).
  static Future<File> _generateTribalDrum() {
    final random = Random(505);
    return _generateWavFile(
      durationSeconds: 3.2,
      sampleRate: 22050,
      waveform: (double t) {
        // --- 1. SOARING TRIBAL FLUTE MELODY (African Bamboo Flute - Lion King Theme Style) ---
        double flute = 0.0;
        double fluteVolume = 0.0;
        double freq = 0.0;

        if (t >= 0.0 && t < 0.6) {
          // Note 1: A4 (440 Hz)
          freq = 440.0;
          fluteVolume = sin(t * pi / 0.6) * 0.28;
        } else if (t >= 0.6 && t < 1.2) {
          // Note 2: C5 (523.25 Hz)
          freq = 523.25;
          fluteVolume = sin((t - 0.6) * pi / 0.6) * 0.28;
        } else if (t >= 1.2 && t < 1.8) {
          // Note 3: D5 (587.33 Hz)
          freq = 587.33;
          fluteVolume = sin((t - 1.2) * pi / 0.6) * 0.28;
        } else if (t >= 1.8 && t < 2.4) {
          // Note 4: G5 (783.99 Hz) - Soaring high note!
          freq = 783.99;
          fluteVolume = sin((t - 1.8) * pi / 0.6) * 0.32;
        } else if (t >= 2.4 && t < 3.2) {
          // Note 5: E5 (659.25 Hz) - Majestic unresolved resolution
          freq = 659.25;
          fluteVolume = sin((t - 2.4) * pi / 0.8) * 0.28;
        }

        if (fluteVolume > 0.0) {
          // Vibrato (6Hz pitch modulation)
          double vibrato = 1.0 + 0.015 * sin(2 * pi * 6.0 * t);
          double fMod = freq * vibrato;
          
          // Waveform: Sine + 3rd and 5th harmonics for hollow woodwind breathy character
          double osc = sin(2 * pi * fMod * t) 
                     + 0.35 * sin(2 * pi * fMod * 3.0 * t) 
                     + 0.15 * sin(2 * pi * fMod * 5.0 * t);
          
          // Layer in breathy blowing wind noise
          double breath = (random.nextDouble() - 0.5) * 0.18;
          
          flute = (osc + breath) * fluteVolume;
        }

        // --- 2. DEEP TRIBAL CONGAS & DJEMBES (Striking syncopated patterns) ---
        double drum = 0.0;
        final List<double> strikes = [0.0, 0.4, 0.8, 1.0, 1.4, 1.8, 2.0, 2.4, 2.8];
        for (final strike in strikes) {
          if (t >= strike) {
            double st = t - strike;
            if (st < 0.35) {
              // Alternate between low djembe bass (52Hz) and high wood conga (78Hz)
              double drumFreq = (strike % 0.8 == 0) ? 52.0 : 78.0;
              double env = exp(-st * 12.0);
              drum += sin(2 * pi * drumFreq * st) * env * 0.65;
            }
          }
        }

        // --- 3. ANIMAL SOUND 1: MAJESTIC LION ROAR (Starts at t = 0.0 to 0.9s) ---
        double lionRoar = 0.0;
        if (t >= 0.0 && t < 0.9) {
          double lionEnv = sin(t * pi / 0.9);
          double carrier = sin(2 * pi * 75.0 * t) + 0.5 * sin(2 * pi * 150.0 * t);
          double growlMod = 1.0 + 0.8 * sin(2 * pi * 24.0 * t);
          double rumble = (random.nextDouble() - 0.5) * 0.28;
          lionRoar = (carrier * growlMod * 0.35 + rumble * 0.22) * lionEnv * 0.70;
        }

        // --- 4. ANIMAL SOUND 2: CHIRPING BIRD / TOUCAN (Starts at t = 1.0s to 1.6s) ---
        double toucanChirp = 0.0;
        if (t >= 1.0 && t < 1.6) {
          double st = t - 1.0;
          double chirpEnv = sin(st * pi / 0.6);
          // Swooping high frequency sliding chirp (exotic jungle bird call)
          double chirpFreq = 1200.0 + st * 1500.0 + sin(st * 40.0) * 120.0;
          toucanChirp = sin(2 * pi * chirpFreq * st) * chirpEnv * 0.22;
        }

        // --- 5. ANIMAL SOUND 3: PLAYFUL MONKEY CHATTER (Starts at t = 2.0s to 2.8s) ---
        double monkeyChatter = 0.0;
        if (t >= 2.0 && t < 2.8) {
          double st = t - 2.0;
          double chatterEnv = sin(st * pi / 0.8);
          // Rapid monkey clicks (chattering notes modulated at 12Hz)
          double clickMod = sin(st * 2 * pi * 12.0) > 0.1 ? 1.0 : 0.0;
          double clickFreq = 420.0 + sin(st * 30.0) * 80.0;
          monkeyChatter = sin(2 * pi * clickFreq * st) * clickMod * chatterEnv * 0.20;
        }

        // --- 6. MIX EVERYTHING TOGETHER ---
        double finalSignal = (flute * 0.8) + (drum * 0.7) + (lionRoar * 0.65) + (toucanChirp * 0.45) + (monkeyChatter * 0.40);
        return finalSignal.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes an ultra-deep growling Predator Roar sound (Loss)
  static Future<File> _generateOwlLoss() {
    final random = Random(303);
    return _generateWavFile(
      durationSeconds: 1.8,
      sampleRate: 22050,
      waveform: (double t) {
        // Deep Growling Predator Roar (Move O win / Player Loss)
        // Super-low pitch carrier (68Hz) layered with sub-bass rumble (34Hz) and amplitude tremolo modulation (18Hz)
        double env = sin(t * pi / 1.8).clamp(0.0, 1.0);
        
        // 68Hz low growl carrier + 34Hz sub-bass component + 136Hz first harmonic
        double carrier = sin(2 * pi * 68.0 * t) + 0.65 * sin(2 * pi * 34.0 * t) + 0.3 * sin(2 * pi * 136.0 * t);
        
        // 18Hz tremolo modulation for raspy, low animal throat rattle
        double growlMod = 1.0 + 0.75 * sin(2 * pi * 18.0 * t);
        
        // Deep low-pass textured rumble (noise element)
        double rumble = (random.nextDouble() - 0.5) * 0.22;
        
        double roar = (carrier * growlMod * 0.45 + rumble * 0.15) * env * 0.95;
        return roar;
      },
    );
  }

  /// Synthesizes a tranquil deep night breeze and low drone sound (Draw)
  static Future<File> _generateCricketDraw() {
    final random = Random(404);
    return _generateWavFile(
      durationSeconds: 2.2, // increased duration for slow tranquil fade-out
      sampleRate: 22050,
      waveform: (double t) {
        // Tranquil deep night in the jungle: deep night breeze and a low-frequency tribal drone (G2 drone at 98Hz)
        double env = sin(t * pi / 2.2).clamp(0.0, 1.0);
        
        // Deep, soothing bamboo flute drone (98Hz) representing natural serenity
        double drone = sin(2 * pi * 98.0 * t) + 0.3 * sin(2 * pi * 196.0 * t);
        
        // Soothing rustling night wind noise
        double wind = (random.nextDouble() - 0.5) * 0.12 * sin(t * pi / 2.2);
        
        // Ultra-low, slow pitch cricket chirp (modulated at 450Hz instead of 1800Hz)
        double tMod = t % 0.18;
        double cricketEnv = sin(tMod * pi / 0.18);
        double cricket = sin(2 * pi * 450.0 * tMod) * cricketEnv * 0.05;
        
        return (drone * 0.18 + wind * 0.45 + cricket) * env;
      },
    );
  }

  /// Synthesizes a 3-second exotic Toucan call sequence (screeches, chirps and clacks)
  static Future<File> _generateToucanPeek() {
    final random = Random(601);
    return _generateWavFile(
      durationSeconds: 3.0,
      sampleRate: 22050,
      waveform: (double t) {
        double sound = 0.0;
        // 5 fast bird chirps spaced across 3 seconds
        final List<double> chirpTimes = [0.1, 0.6, 1.2, 1.8, 2.4];
        for (final chirp in chirpTimes) {
          if (t >= chirp && t < chirp + 0.45) {
            double st = t - chirp;
            double env = sin(st * pi / 0.45);
            // Sliding bird pitch with fast vibrato
            double freq = 950.0 + st * 1800.0 + sin(2 * pi * 28.0 * st) * 150.0;
            sound += sin(2 * pi * freq * st) * env * 0.35;
          }
        }
        // Hollow beak wood clacks
        final List<double> clackTimes = [0.35, 0.45, 1.45, 1.55, 2.05, 2.15];
        for (final clack in clackTimes) {
          if (t >= clack && t < clack + 0.08) {
            double st = t - clack;
            double env = exp(-st * 68.0);
            sound += sin(2 * pi * 320.0 * st) * env * 0.22;
          }
        }
        // Soft background foliage breeze
        double wind = (random.nextDouble() - 0.5) * 0.08 * sin(t * pi / 3.0);
        return (sound + wind).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a 3-second realistic Snake hissed rattle and soft foliage rustles
  static Future<File> _generateSnakePeek() {
    final random = Random(602);
    return _generateWavFile(
      durationSeconds: 3.0,
      sampleRate: 22050,
      waveform: (double t) {
        // Soft swishing foliage/leaves background
        double rustle = (random.nextDouble() - 0.5) * (0.07 + 0.08 * sin(t * pi * 2.0));
        
        // Two long emerald boa breathy hisses
        double hiss = 0.0;
        final List<List<double>> hissIntervals = [[0.2, 1.1], [1.6, 2.6]];
        for (final interval in hissIntervals) {
          double start = interval[0];
          double end = interval[1];
          if (t >= start && t < end) {
            double duration = end - start;
            double st = t - start;
            double env = sin(st * pi / duration);
            
            // High frequency snake hiss centered at 7200Hz
            double noise = (random.nextDouble() - 0.5) * 0.32;
            double filterHiss = noise * sin(2 * pi * 7200.0 * st);
            hiss += filterHiss * env;
          }
        }
        
        // Tongue flicking clicks
        double tongue = 0.0;
        final List<double> tongueTicks = [0.8, 0.9, 2.2, 2.3];
        for (final tick in tongueTicks) {
          if (t >= tick && t < tick + 0.04) {
            double st = t - tick;
            double env = exp(-st * 120.0);
            tongue += (random.nextDouble() - 0.5) * env * 0.18;
          }
        }

        return (rustle + hiss + tongue).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a 3-second realistic croaking Tree Frog ("Ribbit, ribbit!")
  static Future<File> _generateFrogPeek() {
    final random = Random(603);
    return _generateWavFile(
      durationSeconds: 3.0,
      sampleRate: 22050,
      waveform: (double t) {
        double frog = 0.0;
        
        // Three croak sequences spaced across 3 seconds
        final List<double> croakTimes = [0.2, 1.0, 2.0];
        for (final croak in croakTimes) {
          // Double "rib-bit" croak
          if (t >= croak && t < croak + 0.65) {
            double st = t - croak;
            
            // Partition into "rib" (0.0 to 0.28) and "bit" (0.33 to 0.60)
            double subEnv = 0.0;
            double subT = 0.0;
            if (st < 0.28) {
              subEnv = sin(st * pi / 0.28);
              subT = st;
            } else if (st >= 0.33 && st < 0.60) {
              subEnv = sin((st - 0.33) * pi / 0.27) * 0.85;
              subT = st - 0.33;
            }
            
            if (subEnv > 0.0) {
              // Deep frog pitch (148Hz) with strong vocal tremolo throat ripple (36Hz)
              double pitch = 148.0 + sin(subT * 25.0) * 12.0;
              double tremolo = 1.0 + 0.85 * sin(2 * pi * 36.0 * subT);
              double vocal = sin(2 * pi * pitch * subT) + 0.35 * sin(2 * pi * pitch * 3.0 * subT);
              
              // Soft skin rub sound
              double rasp = (random.nextDouble() - 0.5) * 0.12;
              
              frog += (vocal * tremolo * 0.42 + rasp) * subEnv;
            }
          }
        }
        
        return frog.clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a 3-second low guttural growl and throat warning chuffs of a Tiger
  static Future<File> _generateTigerPeek() {
    final random = Random(604);
    return _generateWavFile(
      durationSeconds: 3.0,
      sampleRate: 22050,
      waveform: (double t) {
        // Deep warning throat growl from 0.1s to 1.6s
        double growl = 0.0;
        if (t >= 0.1 && t < 1.6) {
          double env = sin((t - 0.1) * pi / 1.5);
          // Guttural low-pitched throat rumble (64Hz with sub-bass at 32Hz)
          double carrier = sin(2 * pi * 64.0 * t) + 0.72 * sin(2 * pi * 32.0 * t) + 0.35 * sin(2 * pi * 128.0 * t);
          // Powerful throat vibrato (15Hz tremolo modulation)
          double vibrato = 1.0 + 0.8 * sin(2 * pi * 15.0 * t);
          
          // Low filtered wind/rumble
          double rumble = (random.nextDouble() - 0.5) * 0.35;
          growl = (carrier * vibrato * 0.48 + rumble * 0.18) * env * 0.80;
        }

        // Two soft breath chuffs from 1.8s to 2.8s
        double chuff = 0.0;
        final List<double> chuffTimes = [1.8, 2.3];
        for (final strike in chuffTimes) {
          if (t >= strike && t < strike + 0.35) {
            double st = t - strike;
            double env = sin(st * pi / 0.35);
            // Huffing breath noise (throat puff)
            double huff = (random.nextDouble() - 0.5) * (0.24 + sin(st * 40.0) * 0.08);
            chuff += huff * env * 0.55;
          }
        }

        return (growl + chuff).clamp(-1.0, 1.0);
      },
    );
  }

  /// Synthesizes a majestic 3-second Lion roar (sweeping rumble to vocal growl)
  static Future<File> _generateLionPeek() {
    final random = Random(605);
    return _generateWavFile(
      durationSeconds: 3.0,
      sampleRate: 22050,
      waveform: (double t) {
        double roar = 0.0;
        // Majestic Lion roar from 0.15s to 2.3s
        if (t >= 0.15 && t < 2.3) {
          double env = sin((t - 0.15) * pi / 2.15);
          
          // Lion growl carrier (starts very low at 58Hz and swells to 110Hz, then drops)
          double timeRatio = (t - 0.15) / 2.15;
          double currentFreq = 58.0 + sin(timeRatio * pi) * 52.0;
          
          double carrier = sin(2 * pi * currentFreq * t) 
                         + 0.55 * sin(2 * pi * currentFreq * 2.0 * t)
                         + 0.28 * sin(2 * pi * currentFreq * 3.0 * t);
          
          // Throat tremor vibration at 20Hz
          double tremolo = 1.0 + 0.85 * sin(2 * pi * 20.0 * t);
          
          // Heavy rasp/rumble noise (vocal gravel)
          double rasp = (random.nextDouble() - 0.5) * 0.45 * sin(timeRatio * pi);
          
          roar = (carrier * tremolo * 0.45 + rasp * 0.26) * env * 0.90;
        }

        // Low tail rumble at the end
        double tail = 0.0;
        if (t >= 2.0 && t < 3.0) {
          double env = sin((3.0 - t) * pi / 1.0);
          double rumble = sin(2 * pi * 32.0 * t) * (random.nextDouble() - 0.5) * 0.12;
          tail = rumble * env;
        }

        return (roar + tail).clamp(-1.0, 1.0);
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
