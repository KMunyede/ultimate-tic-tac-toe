import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tictactoe/app_theme.dart';
import 'auth_controller.dart';
import 'settings_controller.dart';
import 'firebase_service.dart';

class SettingsMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback closeMenu;

  const SettingsMenu({
    super.key,
    required this.isOpen,
    required this.closeMenu,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final firebaseService = context.read<FirebaseService>();
    final User? user = firebaseService.currentUser;
    final theme = Theme.of(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: isOpen ? 0 : -300,
      width: 300,
      child: Material(
        elevation: 16,
        color: theme.scaffoldBackgroundColor.withOpacity(0.95),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Settings', style: theme.textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: closeMenu,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('Theme'),
                  trailing: DropdownButton<AppTheme>(
                    value: settings.currentTheme,
                    underline: const SizedBox.shrink(),
                    items: appThemes.map((AppTheme theme) {
                      return DropdownMenuItem<AppTheme>(
                        value: theme,
                        child: Text(theme.name),
                      );
                    }).toList(),
                    onChanged: (AppTheme? newTheme) {
                      if (newTheme != null) {
                        settings.changeTheme(newTheme);
                      }
                    },
                    style: theme.textTheme.bodyMedium,
                    dropdownColor: theme.cardColor,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Sound'),
                  value: settings.isSoundOn,
                  onChanged: (_) => settings.toggleSound(),
                  secondary: const Icon(Icons.volume_up),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Play against AI'),
                  value: settings.gameMode == GameMode.playerVsAi,
                  onChanged: (isAi) {
                    settings.setGameMode(isAi ? GameMode.playerVsAi : GameMode.playerVsPlayer);
                  },
                  secondary: const Icon(Icons.computer),
                ),
                if (settings.gameMode == GameMode.playerVsAi)
                  ListTile(
                    leading: const Icon(Icons.psychology_alt),
                    title: const Text('AI Difficulty'),
                    trailing: DropdownButton<AiDifficulty>(
                      value: settings.aiDifficulty,
                      underline: const SizedBox.shrink(),
                      items: AiDifficulty.values.map((AiDifficulty difficulty) {
                        return DropdownMenuItem<AiDifficulty>(
                          value: difficulty,
                          child: Text(difficulty.name),
                        );
                      }).toList(),
                      onChanged: (AiDifficulty? newDifficulty) {
                        if (newDifficulty != null) {
                          settings.setAiDifficulty(newDifficulty);
                        }
                      },
                      style: theme.textTheme.bodyMedium,
                      dropdownColor: theme.cardColor,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Scores'),
                    onPressed: () {
                      // Show a confirmation dialog before resetting
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Reset'),
                            content: const Text('Are you sure you want to reset all scores?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text('Reset'),
                                onPressed: () {
                                  settings.resetGameAndScores();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const Spacer(), // Pushes the sign out button to the bottom
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      user.isAnonymous
                          ? 'Signed in as Guest'
                          : user.email ?? 'Signed In',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    onPressed: () {
                      // Close the menu first to avoid UI glitches
                      closeMenu();
                      // Use context.read inside a callback
                      context.read<AuthController>().signOut();
                    },
                  ),
                ),
                const SizedBox(height: 16), // Some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}