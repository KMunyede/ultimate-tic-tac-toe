// lib/widgets/profile/stats_tab_view.dart
import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../core/theme/app_theme.dart';

class StatsTabView extends StatelessWidget {
  final PlayerStats stats;
  final AppTheme theme;
  final bool isSmallWidth;

  const StatsTabView({
    super.key,
    required this.stats,
    required this.theme,
    required this.isSmallWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildXpProgressCard(stats, theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  label: 'Current Streak',
                  value: '${stats.currentStreak} wins',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orange.shade700,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  label: 'Max Streak',
                  value: '${stats.maxStreak} wins',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFCCA67C),
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallWidth ? 2 : 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildStatCell('Total Wins', stats.totalWins.toString(), Colors.green, theme),
              _buildStatCell('Total Losses', stats.totalLosses.toString(), Colors.red, theme),
              _buildStatCell('Total Draws', stats.totalDraws.toString(), Colors.orange, theme),
              _buildStatCell('Matches', stats.totalGames.toString(), theme.mainColor, theme),
              _buildStatCell(
                'Win Ratio',
                '${stats.totalGames > 0 ? ((stats.totalWins / stats.totalGames) * 100).toStringAsFixed(1) : "0.0"}%',
                Colors.teal,
                theme,
              ),
              _buildStatCell('Total XP', stats.totalXp.toString(), Colors.purple, theme),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Detailed Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor),
            ),
          ),
          const SizedBox(height: 6),
          _buildDetailSectionTitle('Pass & Play PvP', theme),
          const SizedBox(height: 4),
          _buildDetailRow('Wins (X)', stats.winsLocalPvp.toString(), Colors.green, theme),
          _buildDetailRow('Wins (O)', stats.lossesLocalPvp.toString(), Colors.blue, theme),
          _buildDetailRow('Draws', stats.drawsLocalPvp.toString(), Colors.orange, theme),
          const SizedBox(height: 10),
          _buildDetailSectionTitle('Vs Intelligent AI', theme),
          const SizedBox(height: 4),
          _buildAiRowStats('Easy AI', stats.winsVsAiEasy, stats.lossesVsAiEasy, stats.drawsVsAiEasy, theme),
          const SizedBox(height: 6),
          _buildAiRowStats('Med AI', stats.winsVsAiMedium, stats.lossesVsAiMedium, stats.drawsVsAiMedium, theme),
          const SizedBox(height: 6),
          _buildAiRowStats('Hard AI', stats.winsVsAiHard, stats.lossesVsAiHard, stats.drawsVsAiHard, theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildXpProgressCard(PlayerStats stats, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Progress',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textColor),
              ),
              Text(
                '${stats.xpProgress} / 500 XP',
                style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: theme.boardBg,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth * stats.xpProgressPercent,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.mainColor, theme.accentGlow]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required AppTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color, AppTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: theme.textColor.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.mainColor, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textColor)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAiRowStats(String label, int w, int l, int d, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 12, color: theme.textColor))),
          Expanded(child: Text('W:$w', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(child: Text('L:$l', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
          Expanded(child: Text('D:$d', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
        ],
      ),
    );
  }
}
