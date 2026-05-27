class PlayerStats {
  final int totalXp;

  final int winsVsAiEasy;
  final int lossesVsAiEasy;
  final int drawsVsAiEasy;

  final int winsVsAiMedium;
  final int lossesVsAiMedium;
  final int drawsVsAiMedium;

  final int winsVsAiHard;
  final int lossesVsAiHard;
  final int drawsVsAiHard;

  final int winsLocalPvp;
  final int lossesLocalPvp;
  final int drawsLocalPvp;

  const PlayerStats({
    this.totalXp = 0,
    this.winsVsAiEasy = 0,
    this.lossesVsAiEasy = 0,
    this.drawsVsAiEasy = 0,
    this.winsVsAiMedium = 0,
    this.lossesVsAiMedium = 0,
    this.drawsVsAiMedium = 0,
    this.winsVsAiHard = 0,
    this.lossesVsAiHard = 0,
    this.drawsVsAiHard = 0,
    this.winsLocalPvp = 0,
    this.lossesLocalPvp = 0,
    this.drawsLocalPvp = 0,
  });

  /// Level calculation: each level requires exactly 500 XP
  int get level => (totalXp / 500).floor() + 1;

  /// XP progressed inside the current level
  int get xpProgress => totalXp % 500;

  /// Progress percentage towards the next level (0.0 to 1.0)
  double get xpProgressPercent => (totalXp % 500) / 500.0;

  /// Calculated totals
  int get totalWins => winsVsAiEasy + winsVsAiMedium + winsVsAiHard + winsLocalPvp;
  int get totalLosses => lossesVsAiEasy + lossesVsAiMedium + lossesVsAiHard + lossesLocalPvp;
  int get totalDraws => drawsVsAiEasy + drawsVsAiMedium + drawsVsAiHard + drawsLocalPvp;
  int get totalGames => totalWins + totalLosses + totalDraws;

  PlayerStats copyWith({
    int? totalXp,
    int? winsVsAiEasy,
    int? lossesVsAiEasy,
    int? drawsVsAiEasy,
    int? winsVsAiMedium,
    int? lossesVsAiMedium,
    int? drawsVsAiMedium,
    int? winsVsAiHard,
    int? lossesVsAiHard,
    int? drawsVsAiHard,
    int? winsLocalPvp,
    int? lossesLocalPvp,
    int? drawsLocalPvp,
  }) {
    return PlayerStats(
      totalXp: totalXp ?? this.totalXp,
      winsVsAiEasy: winsVsAiEasy ?? this.winsVsAiEasy,
      lossesVsAiEasy: lossesVsAiEasy ?? this.lossesVsAiEasy,
      drawsVsAiEasy: drawsVsAiEasy ?? this.drawsVsAiEasy,
      winsVsAiMedium: winsVsAiMedium ?? this.winsVsAiMedium,
      lossesVsAiMedium: lossesVsAiMedium ?? this.lossesVsAiMedium,
      drawsVsAiMedium: drawsVsAiMedium ?? this.drawsVsAiMedium,
      winsVsAiHard: winsVsAiHard ?? this.winsVsAiHard,
      lossesVsAiHard: lossesVsAiHard ?? this.lossesVsAiHard,
      drawsVsAiHard: drawsVsAiHard ?? this.drawsVsAiHard,
      winsLocalPvp: winsLocalPvp ?? this.winsLocalPvp,
      lossesLocalPvp: lossesLocalPvp ?? this.lossesLocalPvp,
      drawsLocalPvp: drawsLocalPvp ?? this.drawsLocalPvp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'winsVsAiEasy': winsVsAiEasy,
      'lossesVsAiEasy': lossesVsAiEasy,
      'drawsVsAiEasy': drawsVsAiEasy,
      'winsVsAiMedium': winsVsAiMedium,
      'lossesVsAiMedium': lossesVsAiMedium,
      'drawsVsAiMedium': drawsVsAiMedium,
      'winsVsAiHard': winsVsAiHard,
      'lossesVsAiHard': lossesVsAiHard,
      'drawsVsAiHard': drawsVsAiHard,
      'winsLocalPvp': winsLocalPvp,
      'lossesLocalPvp': lossesLocalPvp,
      'drawsLocalPvp': drawsLocalPvp,
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      totalXp: json['totalXp'] ?? 0,
      winsVsAiEasy: json['winsVsAiEasy'] ?? 0,
      lossesVsAiEasy: json['lossesVsAiEasy'] ?? 0,
      drawsVsAiEasy: json['drawsVsAiEasy'] ?? 0,
      winsVsAiMedium: json['winsVsAiMedium'] ?? 0,
      lossesVsAiMedium: json['lossesVsAiMedium'] ?? 0,
      drawsVsAiMedium: json['drawsVsAiMedium'] ?? 0,
      winsVsAiHard: json['winsVsAiHard'] ?? 0,
      lossesVsAiHard: json['lossesVsAiHard'] ?? 0,
      drawsVsAiHard: json['drawsVsAiHard'] ?? 0,
      winsLocalPvp: json['winsLocalPvp'] ?? 0,
      lossesLocalPvp: json['lossesLocalPvp'] ?? 0,
      drawsLocalPvp: json['drawsLocalPvp'] ?? 0,
    );
  }
}
