// lib/features/game/widgets/pause_overlay.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/animations/ocean_float.dart';

class PauseOverlay extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onResume;

  const PauseOverlay({super.key, required this.theme, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6), // Darker overlay for focus
        child: Center(
          child: OceanFloat(
            drift: 5.0,
            swell: 8.0,
            rotation: 0.02,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onResume,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.mainColor, // High contrast button color
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(6, 6),
                          blurRadius: 0, // Sharp cartoon shadow
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded, 
                      size: 80, 
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'GAME PAUSED',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white, // Max contrast on dark overlay
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the play button to resume',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
