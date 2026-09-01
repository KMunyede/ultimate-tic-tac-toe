// lib/widgets/profile/onboarding_tabs.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GuestUnlockTab extends StatelessWidget {
  final AppTheme theme;
  const GuestUnlockTab({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(Icons.lock_person_rounded, size: 68, color: theme.accentGlow),
          const SizedBox(height: 10),
          Text('Stats Tracking is Locked 🔒', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
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
          _buildBenefitRow(Icons.insights_rounded, 'No Win/Loss Preservation', 'Any games you play as a guest are discarded.', theme),
          const SizedBox(height: 10),
          _buildBenefitRow(Icons.military_tech_rounded, 'Locked XP & Level badges', 'Level progression is restricted to profiles.', theme),
          const SizedBox(height: 10),
          _buildBenefitRow(Icons.cloud_sync_rounded, 'Missing Cloud Sync', 'Registered users can log in on any device.', theme),
          const SizedBox(height: 24),
          Text('Ready to save your progress?', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 8),
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
                Text('Switch to the "Register" tab above!', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.mainColor)),
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
}

class GuestRegisterTab extends StatelessWidget {
  final AppTheme theme;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSavingAccount;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onRegister;
  final VoidCallback onDiscardSession;

  const GuestRegisterTab({
    super.key,
    required this.theme,
    required this.registerFormKey,
    required this.emailController,
    required this.passwordController,
    required this.isSavingAccount,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onRegister,
    required this.onDiscardSession,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            _buildRegistrationSection(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onDiscardSession,
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

  Widget _buildRegistrationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 4),
            Text('Upgrade to a permanent profile to sync stats.', style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            _buildTextField(
              controller: emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscure: obscurePassword,
              onToggleObscure: onToggleObscure,
              validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSavingAccount ? null : onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSavingAccount
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Register & Merge Stats', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: theme.textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: theme.mainColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: theme.textColor.withValues(alpha: 0.4)),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: theme.boardBg.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
