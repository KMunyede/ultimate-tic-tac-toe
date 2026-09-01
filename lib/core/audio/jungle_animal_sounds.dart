// lib/core/audio/jungle_animal_sounds.dart
import 'dart:math';

class JungleAnimalSounds {
  static double generateToucanChirp(double t, Random random) {
    double crack = 0.0;
    if (t < 0.035) {
      crack = (random.nextDouble() - 0.5) * exp(-t * 150.0) * 0.95;
    }
    double resonance = sin(2 * pi * 150.0 * t) * exp(-t * 26.0) * 0.45;
    return crack + resonance;
  }

  static double generateMonkeyChatter(double t, Random random) {
    double tMod = t % 0.14;
    double click = sin(2 * pi * 110.0 * tMod) * exp(-tMod * 48.0) * 0.52;
    double rustle = (random.nextDouble() - 0.5) * sin(t * pi / 0.28) * 0.16;
    return click + rustle;
  }

  static double generateLionRoar(double t, Random random) {
    double noise = (random.nextDouble() - 0.5) * 0.4;
    double growl = sin(2 * pi * 65.0 * t + 4 * sin(2 * pi * 12.0 * t));
    double env = exp(-t * 4.0) * (1.0 - exp(-t * 20.0));
    return (growl + noise) * env * 0.6;
  }

  static double generateFrogCroak(double t, Random random) {
    double base = sin(2 * pi * 180.0 * t) * (0.5 + 0.5 * sin(2 * pi * 45.0 * t));
    return base * exp(-t * 8.0) * 0.4;
  }
}
