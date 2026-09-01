// lib/features/game/widgets/game_over_overlay.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../models/player.dart';
import '../../../widgets/profile_stats_dialog.dart';
import '../../../widgets/board/clay_bevel_painter.dart';
import '../logic/end_game_hooks.dart';
import '../../../widgets/animations/ocean_float.dart';

class GameOverOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const GameOverOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: OceanFloat(
                drift: 4.0,
                swell: 6.0,
                rotation: 0.015,
                child: Hero(
                  tag: 'game_over_card',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: theme.boardBg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: theme.mainColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25.0,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: theme.name == 'Rushing Wind'
                        ? ClayBevelPainter(
                            borderRadius: 28.0,
                            baseColor: theme.boardBg,
                            themeName: theme.name,
                          )
                        : null,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24.0, 36.0, 24.0, 24.0),
                          child: Builder(
                            builder: (context) {
                              final hook = EndGameHooks.getHook(game.matchWinner, game.isMatchDraw, game.matchId);
                              
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: theme.mainColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      game.matchWinner == Player.X
                                          ? Icons.emoji_events_rounded
                                          : (game.matchWinner == Player.O
                                              ? Icons.emoji_events_rounded
                                              : (game.isMatchDraw
                                                  ? Icons.handshake_rounded
                                                  : Icons.refresh_rounded)),
                                      size: 64.0,
                                      color: game.matchWinner == Player.X
                                          ? theme.mainColor
                                          : (game.matchWinner == Player.O
                                              ? theme.accentGlow
                                              : theme.textColor),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    hook.title,
                                    style: GoogleFonts.righteous(
                                      color: theme.textColor,
                                      fontSize: 22.0,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: theme.mainColor.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    hook.description,
                                    style: TextStyle(
                                      color: theme.textColor.withValues(alpha: 0.8),
                                      fontSize: 13.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  Container(
                                    height: 1.0,
                                    color: theme.textColor.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildMetricItem("SECTOR WINS", "${game.boardsWonX} - ${game.boardsWonO}", theme),
                                      Container(
                                        width: 1.0,
                                        height: 36.0,
                                        color: theme.textColor.withValues(alpha: 0.15),
                                      ),
                                      _buildMetricItem(
                                        "XP REWARD",
                                        settings.isGuest ? "🔒 SIGN UP" : "+100 XP",
                                        theme,
                                        isHighlight: !settings.isGuest,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            context.read<SoundManager>().playMoveSound();
                                            context.read<GameController>().resetGame();
                                            onDismiss();
                                          },
                                          icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                                          label: Text(
                                            "BATTLE AGAIN",
                                            style: GoogleFonts.righteous(fontSize: 14.0, letterSpacing: 1.0),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.mainColor,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size.fromHeight(48.0),
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            elevation: 4.0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        flex: 1,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            context.read<SoundManager>().playMoveSound();
                                            showDialog(
                                              context: context,
                                              builder: (context) => const ProfileStatsDialog(),
                                            );
                                          },
                                          icon: Icon(Icons.person_outline, color: theme.textColor, size: 18),
                                          label: Text(
                                            "STATS",
                                            style: GoogleFonts.righteous(
                                              color: theme.textColor,
                                              fontSize: 13.0,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
                                            minimumSize: const Size.fromHeight(48.0),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.textColor.withValues(alpha: 0.6),
                                  size: 22.0,
                                ),
                                onPressed: () {
                                  context.read<SoundManager>().playMoveSound();
                                  onDismiss();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMetricItem(String label, String value, AppTheme theme, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withValues(alpha: 0.6),
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? theme.accentGlow : theme.textColor,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
