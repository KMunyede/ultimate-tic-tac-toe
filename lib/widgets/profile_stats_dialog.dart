import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stats_service.dart';
import '../models/player_stats.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/services/auth_service.dart';
import '../features/settings/logic/settings_controller.dart';

class ProfileStatsDialog extends StatefulWidget {
  const ProfileStatsDialog({super.key});

  @override
  State<ProfileStatsDialog> createState() => _ProfileStatsDialogState();
}

class _ProfileStatsDialogState extends State<ProfileStatsDialog> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _registerFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _isSavingAccount = false;
  bool _obscurePassword = true;

  // Administrative simulation flags
  bool _isSimulatedAdmin = false;
  bool _mockDoubleXp = false;
  bool _mockDevLogs = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayNameController.text = user?.displayName ?? 'Gamer';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  bool _isSuperAdmin(User user) {
    if (user.isAnonymous) return false;
    final email = user.email?.toLowerCase() ?? '';
    return email == 'admin@ultimatictactoe.com' ||
        email == 'superadmin@gmail.com' ||
        _isSimulatedAdmin;
  }

  Future<void> _updateDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _displayNameController.text.trim().isEmpty) return;

    setState(() {
      _isSavingName = true;
    });

    try {
      final newName = _displayNameController.text.trim();
      await user.updateDisplayName(newName);
      
      // Update Firestore user document (only if not anonymous guest)
      if (!user.isAnonymous) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': newName,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display name updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating name: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  Future<void> _linkGuestAccount() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingAccount = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final authService = context.read<AuthService>();
      final statsService = context.read<StatsService>();
      final oldUid = authService.currentUser?.uid;

      final credential = await authService.linkEmailPassword(email, password);
      
      if (credential != null && oldUid != null) {
        // Merge stats
        await statsService.mergeAnonymousStats(oldUid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account successfully registered! All stats migrated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAccount = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingAccount = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text);
        if (mounted) {
          _newPasswordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAccount = false;
        });
      }
    }
  }

  Future<void> _sendForgotPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await context.read<AuthService>().sendPasswordResetEmail(user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;
    final statsService = context.watch<StatsService>();
    final stats = statsService.stats;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Dialog(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final isSmallWidth = media.size.width < 400;

    final bool isGuest = user.isAnonymous;
    final bool isAdmin = _isSuperAdmin(user);

    // Dynamically calculate tabs list based on role
    final List<String> tabTitles = [];
    if (isGuest) {
      tabTitles.addAll(['🔒 Unlock Profile', '✍️ Register']);
    } else if (isAdmin) {
      tabTitles.addAll(['📊 Stats & Streaks', '⚙️ Security', '🛠️ Admin Console']);
    } else {
      tabTitles.addAll(['📊 Stats & Streaks', '⚙️ Security']);
    }

    return DefaultTabController(
      length: tabTitles.length,
      child: Dialog(
        backgroundColor: theme.boardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: media.size.width * 0.9,
            height: media.size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isGuest ? 'Guest Session' : (isAdmin ? 'Admin Portal' : 'Player Profile'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dynamic Identity Header Card
                _buildIdentityCard(user, stats, theme, isAdmin),
                const SizedBox(height: 12),

                // Dynamic Tab Header
                TabBar(
                  labelColor: theme.mainColor,
                  unselectedLabelColor: theme.textColor.withValues(alpha: 0.55),
                  indicatorColor: theme.mainColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                  tabs: tabTitles.map((title) => Tab(text: title)).toList(),
                ),
                const SizedBox(height: 12),

                // Dynamic Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      if (isGuest) ...[
                        _buildGuestUnlockTab(theme),
                        _buildGuestRegisterTab(user, theme),
                      ] else ...[
                        _buildStatsTab(stats, theme, isSmallWidth),
                        _buildAccountTab(user, theme),
                        if (isAdmin) _buildAdminConsoleTab(statsService, theme),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(User user, PlayerStats stats, AppTheme theme, bool isAdmin) {
    final isGuest = user.isAnonymous;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: NeumorphicColors.getDarkShadow(theme.boardBg).withValues(alpha: 0.3),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: NeumorphicColors.getLightShadow(theme.boardBg),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Avatar with Level Badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAdmin
                        ? [const Color(0xFFFFB300), const Color(0xFFFF6F00)] // Glowing admin gold
                        : [theme.mainColor, theme.accentGlow],
                  ),
                  shape: BoxShape.circle,
                  border: isAdmin
                      ? Border.all(color: const Color(0xFFFFE082), width: 2.0)
                      : null,
                ),
                child: Center(
                  child: isAdmin
                      ? const Icon(Icons.stars_rounded, color: Colors.white, size: 28)
                      : Text(
                          isGuest
                              ? 'G'
                              : ((user.displayName?.isNotEmpty == true)
                                  ? user.displayName![0].toUpperCase()
                                  : 'U'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isAdmin ? const Color(0xFFFF8F00) : theme.accentGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.scaffoldBg, width: 1.5),
                ),
                child: Text(
                  isGuest ? 'Lvl 1' : 'Lvl ${stats.level}',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? Colors.white : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Display Name Editor & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingName)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _displayNameController,
                            style: TextStyle(color: theme.textColor, fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              isDense: true,
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.mainColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _isSavingName
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                              onPressed: _updateDisplayName,
                            ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _displayNameController.text = user.displayName ?? 'Gamer';
                            _isEditingName = false;
                          });
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isGuest ? 'Guest Player' : (user.displayName ?? 'Registered Gamer'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isGuest)
                        IconButton(
                          icon: Icon(Icons.edit_rounded, size: 16, color: theme.mainColor),
                          onPressed: () {
                            setState(() {
                              _isEditingName = true;
                            });
                          },
                        ),
                    ],
                  ),
                Row(
                  children: [
                    if (isAdmin) ...[
                      const Icon(Icons.shield_rounded, size: 12, color: Color(0xFFFF8F00)),
                      const SizedBox(width: 4),
                      const Text(
                        'SuperAdmin • ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        isGuest ? 'Temporary Offline Session' : (user.email ?? 'Verified Account'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.textColor.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB VIEW 1: GUEST UNLOCK ONBOARDING ---
  Widget _buildGuestUnlockTab(AppTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(Icons.lock_person_rounded, size: 68, color: theme.accentGlow),
          const SizedBox(height: 10),
          Text(
            'Stats Tracking is Locked 🔒',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Unregistered/Guest players play in temporary sandbox mode. Sign up to unlock permanent tracking!',
              style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.75)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Benefit checkmarks list
          _buildBenefitRow(Icons.insights_rounded, 'No Win/Loss Preservation', 'Any games you play as a guest are discarded and do not update statistics.', theme),
          const SizedBox(height: 10),
          _buildBenefitRow(Icons.military_tech_rounded, 'Locked XP & Level badges', 'Level progression and XP achievements are restricted to signed up profiles.', theme),
          const SizedBox(height: 10),
          _buildBenefitRow(Icons.cloud_sync_rounded, 'Missing Cloud Sync', 'Registered users can log in on any device and access their win streaks safely.', theme),
          
          const SizedBox(height: 24),
          Text(
            'Ready to save your progress?',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.textColor),
          ),
          const SizedBox(height: 8),
          
          // Secondary register helper card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.mainColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.mainColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward_rounded, color: theme.mainColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Switch to the "Register" tab above to create an account!',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.mainColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB VIEW 2: GUEST REGISTER FORM ---
  Widget _buildGuestRegisterTab(User user, AppTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            _buildRegistrationSection(theme),
            const SizedBox(height: 24),
            
            // Discard dialog
            ElevatedButton.icon(
              onPressed: () async {
                final authService = context.read<AuthService>();
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Lose Temporary Progress?'),
                    content: const Text(
                      'Warning! Exiting this guest session will discard all current board configurations. We highly recommend registering first.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Discard Session'),
                      ),
                    ],
                  ),
                );
                if (proceed != true) return;

                await authService.signOut();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Discard Guest Session', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB VIEW 3: REGISTERED STATS VIEWER ---
  Widget _buildStatsTab(PlayerStats stats, AppTheme theme, bool isSmallWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // XP Progress Bar
          _buildXpProgressCard(stats, theme),
          const SizedBox(height: 12),

          // Streaks Display Row
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

          // Win/Loss grid stats
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

          // H2H detailed stats breakdown
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 440 * stats.xpProgressPercent,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.mainColor, theme.accentGlow]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: theme.textColor.withValues(alpha: 0.65)),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
              ],
            ),
          ),
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
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: theme.textColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.textColor.withValues(alpha: 0.12), width: 1)),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.mainColor),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textColor)),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAiRowStats(String difficulty, int wins, int losses, int draws, AppTheme theme) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            difficulty,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textColor),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('W: $wins', style: const TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.bold)),
              Text('L: $losses', style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.bold)),
              Text('D: $draws', style: const TextStyle(fontSize: 11.5, color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB VIEW 4: REGISTERED ACCOUNT SECURITY VIEW ---
  Widget _buildAccountTab(User user, AppTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRegisteredManagementSection(user, theme),
            const SizedBox(height: 24),

            // Sign Out Button
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthService>().signOut();
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Sign Out Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationSection(AppTheme theme) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.mainColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.mainColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: theme.mainColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Become a Champion!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor, fontSize: 13.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Register today to save your streaks, level up permanently, and secure your in-progress games in the cloud.',
                  style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: _emailController,
            style: TextStyle(color: theme.textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.7)),
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.mainColor)),
              prefixIcon: Icon(Icons.email_outlined, color: theme.textColor.withValues(alpha: 0.5)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: theme.textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Create Password',
              labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.7)),
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.mainColor)),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.textColor.withValues(alpha: 0.5)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.textColor.withValues(alpha: 0.5)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Register Button
          _isSavingAccount
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _linkGuestAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Register & Link Stats',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
          const SizedBox(height: 12),

          // Simulation Admin Trigger inside Registration tab for Guest demonstration
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isSimulatedAdmin = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulated SuperAdmin Role Enabled! Profile reloaded.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFFF8F00),
                ),
              );
            },
            icon: const Icon(Icons.shield_rounded, color: Color(0xFFFF8F00)),
            label: const Text('Simulate Admin Center (Demo)', style: TextStyle(color: Color(0xFFFF8F00))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF8F00)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredManagementSection(User user, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Security & Password Self-Service',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: theme.textColor),
        ),
        const SizedBox(height: 12),

        // Change Password Form
        Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                style: TextStyle(color: theme.textColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.7)),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.mainColor)),
                  prefixIcon: Icon(Icons.lock_reset_rounded, color: theme.textColor.withValues(alpha: 0.5)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _isSavingAccount
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Forgot/Reset Password row
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lost your password?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textColor),
                  ),
                  Text(
                    'We will email you a secure link to reset it.',
                    style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _sendForgotPassword,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.mainColor,
                side: BorderSide(color: theme.mainColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB VIEW 5: SUPERADMIN OPERATIONS CONSOLE ---
  Widget _buildAdminConsoleTab(StatsService statsService, AppTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Admin Status Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Operational Control Center',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time database triggers, mock telemetry displays, and statistics injector overrides.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Operational Telemetry Monitor
          Text(
            'System Telemetry',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTelemetryRow('Server Latency', '24ms (Excellent)', Colors.green),
                const Divider(height: 10),
                _buildTelemetryRow('Firestore Write Queue', '0 / 100 (Idle)', Colors.green),
                const Divider(height: 10),
                _buildTelemetryRow('Mock Online Users', '1,482 active', Colors.blue),
                const Divider(height: 10),
                _buildTelemetryRow('API Connection State', '100% Operational', Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mock Data Injector (Interacts directly with StatsService)
          Text(
            'Interactive Statistics Injector',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              // Inject +500 XP
              _buildInjectorButton(
                icon: Icons.bolt_rounded,
                label: 'Inject +500 XP',
                color: Colors.purple.shade700,
                onPressed: () async {
                  final s = statsService.stats;
                  await statsService.updateCustomStats(s.copyWith(totalXp: s.totalXp + 500));
                  _showAdminFeedback('Injected +500 XP successfully!');
                },
              ),
              // Inject Win Streak
              _buildInjectorButton(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak +5 wins',
                color: Colors.orange.shade800,
                onPressed: () async {
                  final s = statsService.stats;
                  final nextStreak = s.currentStreak + 5;
                  final nextMax = s.maxStreak < nextStreak ? nextStreak : s.maxStreak;
                  await statsService.updateCustomStats(s.copyWith(
                    currentStreak: nextStreak,
                    maxStreak: nextMax,
                  ));
                  _showAdminFeedback('Streak set to $nextStreak wins!');
                },
              ),
              // Inject AI Wins
              _buildInjectorButton(
                icon: Icons.smart_toy_rounded,
                label: 'Mock AI Wins (+3)',
                color: Colors.teal.shade800,
                onPressed: () async {
                  final s = statsService.stats;
                  await statsService.updateCustomStats(s.copyWith(
                    winsVsAiMedium: s.winsVsAiMedium + 3,
                    winsVsAiHard: s.winsVsAiHard + 3,
                  ));
                  _showAdminFeedback('Injected +6 total AI Wins!');
                },
              ),
              // Reset Stats
              _buildInjectorButton(
                icon: Icons.refresh_rounded,
                label: 'Reset Stats to 0',
                color: Colors.red.shade900,
                onPressed: () async {
                  await statsService.updateCustomStats(const PlayerStats());
                  _showAdminFeedback('All statistics reset to clean zeroed slate.');
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mock Feature Switches
          Text(
            'System State Simulation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _mockDoubleXp,
                  onChanged: (val) {
                    setState(() {
                      _mockDoubleXp = val;
                    });
                    _showAdminFeedback(val ? 'Server-wide Double XP Boost ACTIVATED!' : 'Double XP Boost deactivated.');
                  },
                  title: const Text('Simulate Double XP Boost', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _mockDevLogs,
                  onChanged: (val) {
                    setState(() {
                      _mockDevLogs = val;
                    });
                    _showAdminFeedback(val ? 'Developer Trace Console output forced.' : 'Developer Logs muted.');
                  },
                  title: const Text('Simulate Developer Logs', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
                const Divider(height: 1),
                // simulated admin role toggle to return to normal
                SwitchListTile(
                  value: _isSimulatedAdmin,
                  onChanged: (val) {
                    setState(() {
                      _isSimulatedAdmin = val;
                    });
                    _showAdminFeedback(val ? 'Simulated Admin Mode Active.' : 'Returned to normal Registered User.');
                  },
                  title: const Text('Simulation Mode (Admin Active)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String key, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 11.5)),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInjectorButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showAdminFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFFFFB300), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F0F12),
      ),
    );
  }
}
