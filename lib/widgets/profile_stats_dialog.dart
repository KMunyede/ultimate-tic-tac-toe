import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stats_service.dart';
import '../models/player_stats.dart';
import '../core/theme/app_theme.dart';

class ProfileStatsDialog extends StatelessWidget {
  const ProfileStatsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final statsService = context.watch<StatsService>();
    final stats = statsService.stats;

    final media = MediaQuery.of(context);
    final isSmallWidth = media.size.width < 400;

    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: media.size.width * 0.9,
          height: media.size.height * 0.75,
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Player Profile',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Level and XP Section
              _buildXpSection(context, stats, theme),
              const SizedBox(height: 16),
              
              // Tabs Header
              TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'General & PvP'),
                  Tab(text: 'H2H vs AI'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGeneralTab(stats, theme, textTheme, isSmallWidth),
                    _buildAiTab(stats, theme, textTheme, isSmallWidth),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpSection(BuildContext context, PlayerStats stats, ThemeData theme) {
    final bg = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: NeumorphicColors.getDarkShadow(bg), offset: const Offset(4, 4), blurRadius: 8),
          BoxShadow(color: NeumorphicColors.getLightShadow(bg), offset: const Offset(-4, -4), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
                child: Text(
                  'Level ${stats.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              
              // XP counter
              Text(
                '${stats.xpProgress} / 500 XP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // XP Progress Bar
          Stack(
            children: [
              // Background track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: NeumorphicColors.getDarkShadow(bg),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Glowing Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                width: (MediaQuery.of(context).size.width * 0.73).clamp(0.0, 480.0) * stats.xpProgressPercent,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.45),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(PlayerStats stats, ThemeData theme, TextTheme textTheme, bool isSmallWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Aggregate Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallWidth ? 2 : 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Wins', stats.totalWins.toString(), theme, Colors.green),
              _buildStatCard('Total Losses', stats.totalLosses.toString(), theme, Colors.red),
              _buildStatCard('Total Draws', stats.totalDraws.toString(), theme, Colors.orange),
              _buildStatCard('Matches Played', stats.totalGames.toString(), theme, theme.colorScheme.primary),
              _buildStatCard('Win Ratio', '${stats.totalGames > 0 ? ((stats.totalWins / stats.totalGames) * 100).toStringAsFixed(1) : "0.0"}%', theme, Colors.teal),
              _buildStatCard('Total XP', stats.totalXp.toString(), theme, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          
          // PvP Details Card
          _buildDetailSectionTitle('Local Pass & Play PvP', textTheme, theme),
          const SizedBox(height: 8),
          _buildRowStatItem('Wins (Player X)', stats.winsLocalPvp.toString(), Colors.green, theme),
          _buildRowStatItem('Wins (Player O)', stats.lossesLocalPvp.toString(), Colors.blue, theme),
          _buildRowStatItem('Draws', stats.drawsLocalPvp.toString(), Colors.orange, theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAiTab(PlayerStats stats, ThemeData theme, TextTheme textTheme, bool isSmallWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Easy AI
          _buildDetailSectionTitle('Easy AI Battles', textTheme, theme),
          const SizedBox(height: 8),
          _buildAiRowStats(stats.winsVsAiEasy, stats.lossesVsAiEasy, stats.drawsVsAiEasy, theme),
          const SizedBox(height: 16),
          
          // Medium AI
          _buildDetailSectionTitle('Medium AI Battles', textTheme, theme),
          const SizedBox(height: 8),
          _buildAiRowStats(stats.winsVsAiMedium, stats.lossesVsAiMedium, stats.drawsVsAiMedium, theme),
          const SizedBox(height: 16),
          
          // Hard AI
          _buildDetailSectionTitle('Hard AI Battles', textTheme, theme),
          const SizedBox(height: 8),
          _buildAiRowStats(stats.winsVsAiHard, stats.lossesVsAiHard, stats.drawsVsAiHard, theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, ThemeData theme, Color accentColor) {
    final bg = theme.colorScheme.surface;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: NeumorphicColors.getDarkShadow(bg), offset: const Offset(3, 3), blurRadius: 6),
          BoxShadow(color: NeumorphicColors.getLightShadow(bg), offset: const Offset(-3, -3), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, TextTheme textTheme, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.only(left: 6, bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRowStatItem(String label, String value, Color color, ThemeData theme) {
    final bg = theme.colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: NeumorphicColors.getDarkShadow(bg), offset: const Offset(2, 2), blurRadius: 4),
            BoxShadow(color: NeumorphicColors.getLightShadow(bg), offset: const Offset(-2, -2), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRowStats(int wins, int losses, int draws, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildAiStatCell('Wins', wins.toString(), Colors.green, theme)),
        const SizedBox(width: 8),
        Expanded(child: _buildAiStatCell('Losses', losses.toString(), Colors.red, theme)),
        const SizedBox(width: 8),
        Expanded(child: _buildAiStatCell('Draws', draws.toString(), Colors.orange, theme)),
      ],
    );
  }

  Widget _buildAiStatCell(String label, String value, Color color, ThemeData theme) {
    final bg = theme.colorScheme.surface;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: NeumorphicColors.getDarkShadow(bg), offset: const Offset(2, 2), blurRadius: 4),
          BoxShadow(color: NeumorphicColors.getLightShadow(bg), offset: const Offset(-2, -2), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
