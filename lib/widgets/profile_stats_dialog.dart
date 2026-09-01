// lib/widgets/profile_stats_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stats_service.dart';
import '../features/auth/services/auth_service.dart';
import '../features/settings/logic/settings_controller.dart';
import 'animations/ocean_float.dart';

import 'profile/profile_header.dart';
import 'profile/stats_tab_view.dart';
import 'profile/onboarding_tabs.dart';
import 'profile/account_settings_tab.dart';
import 'profile/admin_debug_tab.dart';

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
    return email == 'admin@ultimatictactoe.com' || email == 'superadmin@gmail.com' || _isSimulatedAdmin;
  }

  Future<void> _updateDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _displayNameController.text.trim().isEmpty) return;
    setState(() => _isSavingName = true);
    try {
      final newName = _displayNameController.text.trim();
      await user.updateDisplayName(newName);
      if (!user.isAnonymous) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': newName,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (mounted) {
        setState(() => _isEditingName = false);
        _showSnackbar('Display name updated successfully!');
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error updating name: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _linkGuestAccount() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isSavingAccount = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final authService = context.read<AuthService>();
      final statsService = context.read<StatsService>();
      final oldUid = authService.currentUser?.uid;
      final credential = await authService.linkEmailPassword(email, password);
      if (credential != null && oldUid != null) await statsService.mergeAnonymousStats(oldUid);
      if (mounted) _showSnackbar('Account successfully registered! All stats migrated.');
    } catch (e) {
      if (mounted) _showSnackbar('Registration Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingAccount = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingAccount = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text);
        if (mounted) {
          _newPasswordController.clear();
          _showSnackbar('Password updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error updating password: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingAccount = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: isError ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final statsService = context.watch<StatsService>();
    final theme = settings.currentTheme;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isGuest = user.isAnonymous;
    final isAdmin = _isSuperAdmin(user);
    final stats = statsService.stats;
    final isSmallWidth = MediaQuery.of(context).size.width < 400;

    return OceanFloat(
      drift: 4.0,
      swell: 7.0,
      rotation: 0.015,
      child: Dialog(
        backgroundColor: theme.scaffoldBg, // Standardized background
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black, width: 3.0), // Cartoon border
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
          decoration: BoxDecoration(
            color: theme.scaffoldBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 0)],
          ),
          padding: const EdgeInsets.all(20),
          child: DefaultTabController(
            length: isGuest ? 2 : (isAdmin ? 3 : 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileHeader(
                  user: user,
                  isGuest: isGuest,
                  isAdmin: isAdmin,
                  theme: theme,
                  isEditingName: _isEditingName,
                  isSavingName: _isSavingName,
                  displayNameController: _displayNameController,
                  onEditName: () => setState(() => _isEditingName = true),
                  onUpdateName: _updateDisplayName,
                  onCancelEdit: () => setState(() {
                    _displayNameController.text = user.displayName ?? 'Gamer';
                    _isEditingName = false;
                  }),
                ),
                const SizedBox(height: 16),
                TabBar(
                  labelColor: theme.mainColor,
                  unselectedLabelColor: theme.textColor.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  indicatorColor: theme.mainColor,
                  indicatorWeight: 4,
                  dividerColor: Colors.black.withValues(alpha: 0.1),
                  tabs: [
                    if (isGuest) ...[
                      const Tab(text: 'UNLOCK'),
                      const Tab(text: 'REGISTER'),
                    ] else ...[
                      const Tab(text: 'STATS'),
                      const Tab(text: 'ACCOUNT'),
                      if (isAdmin) const Tab(text: 'ADMIN'),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      if (isGuest) ...[
                        GuestUnlockTab(theme: theme),
                        GuestRegisterTab(
                          theme: theme,
                          registerFormKey: _registerFormKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isSavingAccount: _isSavingAccount,
                          obscurePassword: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          onRegister: _linkGuestAccount,
                          onDiscardSession: () async {
                            final auth = context.read<AuthService>();
                            final navigator = Navigator.of(context);
                            await auth.signOut();
                            if (mounted) navigator.pop();
                          },
                        ),
                      ] else ...[
                        StatsTabView(stats: stats, theme: theme, isSmallWidth: isSmallWidth),
                        AccountSettingsTab(
                          theme: theme,
                          passwordFormKey: _passwordFormKey,
                          newPasswordController: _newPasswordController,
                          isSavingAccount: _isSavingAccount,
                          obscurePassword: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          onChangePassword: _changePassword,
                          onForgotPassword: () async {
                            if (user.email != null) {
                              final auth = context.read<AuthService>();
                              await auth.sendPasswordResetEmail(user.email!);
                              if (mounted) _showSnackbar('Reset email sent!');
                            }
                          },
                          onSignOut: () async {
                            final auth = context.read<AuthService>();
                            final navigator = Navigator.of(context);
                            await auth.signOut();
                            if (mounted) navigator.pop();
                          },
                        ),
                        if (isAdmin)
                          AdminDebugTab(
                            statsService: statsService,
                            theme: theme,
                            isSimulatedAdmin: _isSimulatedAdmin,
                            mockDoubleXp: _mockDoubleXp,
                            mockDevLogs: _mockDevLogs,
                            onSimulatedAdminChanged: (v) => setState(() => _isSimulatedAdmin = v),
                            onMockDoubleXpChanged: (v) => setState(() => _mockDoubleXp = v),
                            onMockDevLogsChanged: (v) => setState(() => _mockDevLogs = v),
                            showFeedback: (m) => _showSnackbar(m),
                          ),
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
}
