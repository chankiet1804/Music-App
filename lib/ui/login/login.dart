import 'package:flutter/material.dart';
import 'package:music_app/theme/theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Image.asset(
                  'assets/ITunes_logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Mysic App', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to continue listening',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  // TODO: implement sign-in
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon'))),
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
