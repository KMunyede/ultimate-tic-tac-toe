import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings_controller.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Player X: ${settings.scoreX}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Player O: ${settings.scoreO}',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
