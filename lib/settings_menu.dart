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

    // UI UPDATE: Increased menu width to prevent text wrapping.
    const double menuWidth = 400.0;

    // We will use MediaQuery to get the padding (status bar) + kToolbarHeight.
    // final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // UI UPDATE: Attached the menu to the top of the window title bar (y=0) as requested.
      // The settings icon is in the AppBar, but if the intention is to "attach to the top",
      // starting at 0 allows it to overlay everything including the status bar area if needed,
      // or just align with the very top of the window.
      top: 0, 
      bottom: 0,
      // UI UPDATE: The drawer now expands to the left (by moving right: 0) when open
      // and retracts to the right (right: -menuWidth) when closed.
      // This is standard drawer behavior coming from the right side.
      right: isOpen ? 0 : -menuWidth,
      width: menuWidth,
      child: Material(
        elevation: 16,
        color: theme.scaffoldBackgroundColor.withOpacity(0.95),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding( // Removed SafeArea because we are already accounting for top padding
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add a SizedBox to account for the status bar height + some padding
                  // since we are now starting at top: 0
                  SizedBox(height: MediaQuery.of(context).padding.top), 
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
                  // --- ARCHITECTURAL ADDITION: Premium Features UI ---
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.view_quilt_outlined),
                    title: const Text('Board Layout'),
                    trailing: DropdownButton<BoardLayout>(
                      value: settings.boardLayout,
                      underline: const SizedBox.shrink(),
                      items: BoardLayout.values.map((BoardLayout layout) {
                        final bool isPremiumFeature = layout != BoardLayout.single;
                        final bool isEnabled = settings.isPremium || !isPremiumFeature;
                        return DropdownMenuItem<BoardLayout>(
                          value: layout,
                          enabled: isEnabled,
                          child: Row(
                            children: [
                              Text(layout.name, style: TextStyle(color: isEnabled ? null : theme.disabledColor)),
                              if (isPremiumFeature)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.star, size: 14, color: isEnabled ? Colors.amber : theme.disabledColor),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (BoardLayout? newLayout) {
                        if (newLayout != null) {
                          settings.setBoardLayout(newLayout);
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
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Premium Subscription'),
                      subtitle: Text(settings.isPremium ? 'Active' : 'Inactive'),
                      value: settings.isPremium,
                      onChanged: (_) => settings.togglePremium(), // Simulates purchase
                      secondary: const Icon(Icons.star, color: Colors.amber),
                    ),
                  const Divider(),
                  // --- End Premium Features UI ---
                  ListTile(
                    contentPadding: EdgeInsets.zero,
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
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound'),
                    value: settings.isSoundOn,
                    onChanged: (_) => settings.toggleSound(),
                    secondary: const Icon(Icons.volume_up),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Play against AI'),
                    value: settings.gameMode == GameMode.playerVsAi,
                    onChanged: (isAi) {
                      settings.setGameMode(isAi ? GameMode.playerVsAi : GameMode.playerVsPlayer);
                    },
                    secondary: const Icon(Icons.computer),
                  ),
                  if (settings.gameMode == GameMode.playerVsAi)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
                  const Spacer(),
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
                        closeMenu();
                        context.read<AuthController>().signOut();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // UI UPDATE: Added an arrow button on the left edge of the drawer.
            // This button points to the right (Icons.arrow_forward_ios) and closes the drawer when tapped.
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top + 10, // Vertically aligned near the title
              child: InkWell(
                onTap: closeMenu,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    // UI CHANGE: Removed explicit card color background to blend with the menu.
                    // If you want it completely seamless, remove the color property or set it to transparent.
                    // However, to make it "blend in" but still be visible as part of the menu structure,
                    // we can just remove the decoration entirely or match the menu's background if it wasn't already.
                    // The menu background is theme.scaffoldBackgroundColor.withOpacity(0.95).
                    // Let's make the button background transparent so it just shows the icon on top of the menu/or empty space.
                    // Wait, this Positioned widget is INSIDE the Material widget which has the background color.
                    // So if we remove the decoration, it will show the Material's background.
                    // But if it's "on the left side", it is visually on top of the menu content.
                    
                    // Actually, the request "blend in with the menu theme and UI color" implies
                    // the icon color should match the theme's icon color, and the background shouldn't stand out.
                    // Removing the Container decoration achieves this blending.
                    // color: theme.cardColor.withOpacity(0.8), // REMOVED
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios, // Arrow pointing right
                    size: 20,
                    // Ensure icon color matches the theme
                    color: theme.iconTheme.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
