// lib/widgets/profile/account_settings_tab.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AccountSettingsTab extends StatelessWidget {
  final AppTheme theme;
  final GlobalKey<FormState> passwordFormKey;
  final TextEditingController newPasswordController;
  final bool isSavingAccount;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onChangePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignOut;

  const AccountSettingsTab({
    super.key,
    required this.theme,
    required this.passwordFormKey,
    required this.newPasswordController,
    required this.isSavingAccount,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onChangePassword,
    required this.onForgotPassword,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPasswordChangeSection(),
          const SizedBox(height: 24),
          _buildAuthManagementSection(),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_reset_rounded, size: 20, color: theme.mainColor),
                const SizedBox(width: 8),
                Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              obscureText: obscurePassword,
              validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              style: TextStyle(color: theme.textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 13),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: theme.textColor.withValues(alpha: 0.4)),
                  onPressed: onToggleObscure,
                ),
                filled: true,
                fillColor: theme.boardBg.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSavingAccount ? null : onChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSavingAccount
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(onPressed: onForgotPassword, child: Text('Forgot Password?', style: TextStyle(color: theme.mainColor, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthManagementSection() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onSignOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size.fromHeight(44),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
