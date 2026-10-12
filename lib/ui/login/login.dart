import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/auth/auth_controller.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/login/forgot_password_dialog.dart';
import 'package:music_app/ui/login/validators.dart';

/// Sign in and sign up on one screen. On success the router redirects away,
/// so this page never navigates by itself.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  var _formKey = GlobalKey<FormState>();
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
      // New key rebuilds the Form to drop stale errors; text lives in the
      // controllers so it survives. FormState.reset() would revert it.
      _formKey = GlobalKey<FormState>();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.xxl,
          ),
          child: Form(
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
                  Text('Mysic App', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isSignUp
                        ? 'Create an account to start listening'
                        : 'Sign in to continue listening',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextFormField(
                    key: const Key('login.email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: _decoration(context, 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: const Key('login.password'),
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: _isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: [
                      _isSignUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: _decoration(context, 'Password').copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: validatePassword,
                    onFieldSubmitted: _isSignUp ? null : (_) => _submit(),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const Key('login.confirm'),
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: _decoration(context, 'Confirm password'),
                      validator: (value) =>
                          validateConfirmPassword(value, _password.text),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => ForgotPasswordDialog.show(
                                context,
                                initialEmail: _email.text.trim(),
                              ),
                        child: const Text('Forgot password?'),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.lg),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('login.submit'),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Create account' : 'Sign in'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Expanded(child: Divider(indent: 0, endIndent: 0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text('or', style: textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider(indent: 0, endIndent: 0)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      // TODO: implement Google sign-in
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          ),
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: textTheme.bodySmall,
                      ),
                      TextButton(
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

  InputDecoration _decoration(BuildContext context, String label) {
    final tokens = AppTokens.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: tokens.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
    );
  }
}
