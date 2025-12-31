import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  
  @override
  void initState() {
    super.initState();
    // Automatically sign in anonymously when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().signInAnonymously();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ultimate Tic-Tac-Toe',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            if (authController.isLoading)
              const CircularProgressIndicator()
            else if (authController.errorMessage != null)
               // In case of error, we might want to show a retry button
               // so the user isn't stuck if the auto-signin fails.
               Column(
                 children: [
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      authController.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<AuthController>().signInAnonymously(),
                    child: const Text('Retry'),
                  ),
                 ],
               )
            else
              const Text("Signing in..."),
          ],
        ),
      ),
    );
  }
}
