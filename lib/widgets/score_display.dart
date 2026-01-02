import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/settings_controller.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScoreCard(context, 'You (X)', settings.scoreX, const Color(0xFFD32F2F)),
        _buildScoreCard(
            context,
            settings.gameMode == GameMode.playerVsAi ? 'AI (O)' : 'Player O',
            settings.scoreO, const Color(0xFF388E3C)),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, String label, int score, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(blurRadius: 2.0, color: color.withAlpha(128), offset: const Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }
}
