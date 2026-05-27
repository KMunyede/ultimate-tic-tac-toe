import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/game/logic/game_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/player.dart';
import '../models/game_enums.dart';

class PowerUpHandWidget extends StatelessWidget {
  const PowerUpHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final bg = Theme.of(context).colorScheme.surface;
    final active = controller.activePowerUp;

    // Card counts
    final shieldCount = controller.currentPlayer == Player.X ? controller.shieldCardsX : controller.shieldCardsO;
    final eraserCount = controller.currentPlayer == Player.X ? controller.eraserCardsX : controller.eraserCardsO;
    final hackerCount = controller.currentPlayer == Player.X ? controller.hackerCardsX : controller.hackerCardsO;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Power-Up Cards',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCard(
                    context: context,
                    type: PowerUpType.shield,
                    label: 'Shield',
                    count: shieldCount,
                    icon: Icons.shield_outlined,
                    glowColor: const Color(0xFFFFD700),
                    active: active == PowerUpType.shield,
                    bg: bg,
                    onTap: () => controller.selectPowerUp(PowerUpType.shield),
                  ),
                  const SizedBox(width: 20),
                  _buildCard(
                    context: context,
                    type: PowerUpType.eraser,
                    label: 'Eraser',
                    count: eraserCount,
                    icon: Icons.auto_fix_normal_outlined,
                    glowColor: const Color(0xFF00E5FF),
                    active: active == PowerUpType.eraser,
                    bg: bg,
                    onTap: () => controller.selectPowerUp(PowerUpType.eraser),
                  ),
                  const SizedBox(width: 20),
                  _buildCard(
                    context: context,
                    type: PowerUpType.hacker,
                    label: 'Hacker',
                    count: hackerCount,
                    icon: Icons.bolt_outlined,
                    glowColor: const Color(0xFFFF2A2A),
                    active: active == PowerUpType.hacker,
                    bg: bg,
                    onTap: () => controller.selectPowerUp(PowerUpType.hacker),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required PowerUpType type,
    required String label,
    required int count,
    required IconData icon,
    required Color glowColor,
    required bool active,
    required Color bg,
    required VoidCallback onTap,
  }) {
    final double cardWidth = 85;
    final double cardHeight = 100;

    return GestureDetector(
      onTap: count > 0 ? onTap : null,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: active ? 1.0 : 0.0),
        builder: (context, value, child) {
          // Floating offset animation
          final double translateOffset = value * -12.0;
          final double scale = 1.0 + (value * 0.08);
          
          return Transform.translate(
            offset: Offset(0, translateOffset),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: count > 0 ? bg : bg.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? glowColor : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: NeumorphicColors.getDarkShadow(bg),
                      offset: Offset(4 - (value * 2), 4 - (value * 2)),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: NeumorphicColors.getLightShadow(bg),
                      offset: Offset(-4 + (value * 2), -4 + (value * 2)),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Card Contents
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 26,
                            color: count > 0 ? glowColor : Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: count > 0 
                                  ? Theme.of(context).textTheme.bodyMedium?.color 
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inventory Badge
                    Positioned(
                      top: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: count > 0 ? glowColor : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (count > 0)
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
