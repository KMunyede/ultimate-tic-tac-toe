import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../../settings/logic/settings_controller.dart';

class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthService>().user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          _lastUserId = null;
          return const AuthScreen();
        }

        // Only trigger settings load if the user identity has actually changed
        // to prevent build/flicker loops.
        if (user.uid != _lastUserId) {
          _lastUserId = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<SettingsController>().loadSettings(
                    isGuest: user.isAnonymous,
                  );
            }
          });
        }

        return widget.child;
      },
    );
  }
}
