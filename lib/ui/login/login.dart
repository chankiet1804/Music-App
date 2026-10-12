import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/auth/auth_controller.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/login/forgot_password_sheet.dart';
import 'package:music_app/ui/login/validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Sign in and sign up on one screen. On success the router redirects away,
/// so this page never navigates by itself.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  var _formKey = GlobalKey<ShadFormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _confirm.clear();
    setState(() {
      _isSignUp = !_isSignUp;
      // New key rebuilds the form to drop stale errors; text lives in the
      // controllers so it survives. Resetting the form would revert it.
      _formKey = GlobalKey<ShadFormState>();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.saveAndValidate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await controller.signUp(_email.text, _password.text);
    } else {
      await controller.signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      if (next is! AsyncError) return;
      final error = next.error;
      final message = error is AuthFailure
          ? error.message
          : const AuthFailure('unknown').message;
      ShadToaster.of(context)
        ..hide()
        ..show(ShadToast.destructive(description: Text(message)));
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = ShadTheme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.xxl,
          ),
          child: ShadForm(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Image.asset(
                      'assets/ITunes_logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Mysic App', style: textTheme.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isSignUp
                        ? 'Create an account to start listening'
                        : 'Sign in to continue listening',
                    style: textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ShadInputFormField(
                    key: const Key('login.email'),
                    id: 'email',
                    controller: _email,
                    placeholder: const Text('Email'),
                    leading: const Icon(LucideIcons.mail, size: 16),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ShadInputFormField(
                    key: const Key('login.password'),
                    id: 'password',
                    controller: _password,
                    placeholder: const Text('Password'),
                    obscureText: _obscure,
                    leading: const Icon(LucideIcons.lock, size: 16),
                    trailing: _obscureToggle(),
                    textInputAction: _isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: [
                      _isSignUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    validator: validatePassword,
                    onSubmitted: _isSignUp ? null : (_) => _submit(),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ShadInputFormField(
                      key: const Key('login.confirm'),
                      id: 'confirm',
                      controller: _confirm,
                      placeholder: const Text('Confirm password'),
                      obscureText: _obscure,
                      leading: const Icon(LucideIcons.lock, size: 16),
                      textInputAction: TextInputAction.done,
                      validator: (value) =>
                          validateConfirmPassword(value, _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ShadButton.link(
                        onPressed: isLoading
                            ? null
                            : () => ForgotPasswordSheet.show(
                                context,
                                initialEmail: _email.text.trim(),
                              ),
                        child: const Text('Forgot password?'),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.lg),
                  const SizedBox(height: AppSpacing.sm),
                  ShadButton(
                    key: const Key('login.submit'),
                    width: double.infinity,
                    onPressed: isLoading ? null : _submit,
                    leading: isLoading
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primaryForeground,
                            ),
                          )
                        : null,
                    child: Text(_isSignUp ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Expanded(child: ShadSeparator.horizontal()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text('or', style: textTheme.muted),
                      ),
                      const Expanded(child: ShadSeparator.horizontal()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ShadButton.outline(
                    width: double.infinity,
                    // TODO: implement Google sign-in
                    onPressed: () => ShadToaster.of(context).show(
                      const ShadToast(description: Text('Coming soon')),
                    ),
                    leading: const Icon(LucideIcons.logIn, size: 16),
                    child: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: textTheme.muted,
                      ),
                      ShadButton.link(
                        key: const Key('login.toggle'),
                        onPressed: isLoading ? null : _toggleMode,
                        child: Text(_isSignUp ? 'Sign in' : 'Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _obscureToggle() {
    return SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        maxWidth: 28,
        maxHeight: 28,
        child: ShadIconButton.ghost(
          iconSize: 18,
          padding: const EdgeInsets.all(2),
          icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
