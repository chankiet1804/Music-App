import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/auth/auth_controller.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/theme/theme.dart';
import 'package:music_app/ui/login/forgot_password_sheet.dart';
import 'package:music_app/ui/login/loading_button.dart';
import 'package:music_app/ui/login/pill_input.dart';
import 'package:music_app/ui/login/starfield_background.dart';
import 'package:music_app/ui/login/validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Sign in and sign up on one screen, laid out after Native Bloom's "Clover
/// sign in": brand on top, fields in the middle, actions pinned to the
/// bottom, all directly on the sky. On success the router redirects away, so
/// this page never navigates by itself.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _liftOff = Duration(milliseconds: 600);
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
      AppToast.dismissAll();
      AppToast.error(message);
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;

    // Brand gives way to the fields while typing.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Starfield sits outside the Scaffold so the keyboard never resizes it.
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: cs.background,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
              child: StarfieldBackground(
                color: cs.foreground.withValues(alpha: 0.7),
                boosted: isLoading,
              ),
            ),
          ),
        ),
        Positioned.fill(child: _scrim(cs)),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            // Fills the screen to pin actions to the bottom; scrolls once the
            // keyboard leaves too little room. No intrinsics: the shad inputs
            // under-report their height.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.xl,
                  AppSpacing.screenH,
                  AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (constraints.maxHeight - AppSpacing.xl - AppSpacing.lg)
                            .clamp(0, double.infinity),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: keyboardUp
                                ? const SizedBox(width: double.infinity)
                                : _brand(theme),
                          ),
                          _reveal(2, _fields(isLoading, theme)),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                      _reveal(3, _actions(isLoading, theme)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Darkens the sky towards the bottom, where most of the content sits, so
  /// stars never compete with text. Plain background colour, so it only ever
  /// darkens, and two stops, since a mid stop shows up as a visible band.
  Widget _scrim(ShadColorScheme cs) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0, -0.3),
            end: Alignment.bottomCenter,
            colors: [
              cs.background.withValues(alpha: 0),
              cs.background.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brand(ShadThemeData theme) {
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.huge,
      ),
      child: Column(
        children: [
          _reveal(0, _logo(theme.colorScheme)),
          const SizedBox(height: AppSpacing.lg),
          _reveal(1, Text('Mysic App', style: textTheme.h2)),
          const SizedBox(height: AppSpacing.xs),
          _reveal(1, Text('Your music, your universe', style: textTheme.muted)),
        ],
      ),
    );
  }

  Widget _logo(ShadColorScheme cs) {
    // The asset carries its own rounded corners and drop shadow; 96 keeps
    // the 288 px export sharp up to 3x screens.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.5),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Image.asset('assets/app_logo.png', width: 96, height: 96),
    );
  }

  /// Heading and inputs. Rises slightly while signing in, a softer take on
  /// Clover's lift-off. The form lives in here, below the entrance animation,
  /// so the key swap on mode toggle does not replay it.
  Widget _fields(bool isLoading, ShadThemeData theme) {
    final textTheme = theme.textTheme;
    final lockIcon = _obscure ? LucideIcons.lock : LucideIcons.lockOpen;

    return AnimatedSlide(
      offset: isLoading ? const Offset(0, -0.04) : Offset.zero,
      duration: _liftOff,
      curve: Curves.easeInOut,
      child: ShadForm(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: textTheme.h4,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isSignUp
                    ? 'Create an account to start listening'
                    : 'Sign in to continue listening',
                style: textTheme.muted,
              ),
              const SizedBox(height: AppSpacing.xl),
              PillInput(
                key: const Key('login.email'),
                id: 'email',
                controller: _email,
                placeholder: 'Email',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              PillInput(
                key: const Key('login.password'),
                id: 'password',
                controller: _password,
                placeholder: 'Password',
                obscureText: _obscure,
                revealed: !_obscure,
                icon: lockIcon,
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
                PillInput(
                  key: const Key('login.confirm'),
                  id: 'confirm',
                  controller: _confirm,
                  placeholder: 'Confirm password',
                  obscureText: _obscure,
                  revealed: !_obscure,
                  icon: lockIcon,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(bool isLoading, ShadThemeData theme) {
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingButton(
          key: const Key('login.submit'),
          width: double.infinity,
          isLoading: isLoading,
          onPressed: _submit,
          loadingLabel: Text(
            _isSignUp ? 'Creating account...' : 'Signing in...',
          ),
          child: Text(_isSignUp ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(child: ShadSeparator.horizontal()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or', style: textTheme.muted),
            ),
            const Expanded(child: ShadSeparator.horizontal()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ShadButton.outline(
          width: double.infinity,
          height: 50,
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.8),
          decoration: const ShadDecoration(
            border: ShadBorder(
              radius: BorderRadius.all(Radius.circular(AppRadius.full)),
            ),
            secondaryFocusedBorder: ShadBorder(
              radius: BorderRadius.all(Radius.circular(AppRadius.full + 2)),
            ),
          ),
          // TODO: implement Google sign-in
          onPressed: () => AppToast.info('Coming soon'),
          leading: const Icon(LucideIcons.logIn, size: 16),
          child: const Text('Continue with Google'),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Wrap so the link drops to a new line under large text scales.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Already have an account?' : "Don't have an account?",
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
    );
  }

  /// Fade + rise entrance, staggered by [step]. Ported from Native Bloom's
  /// "Staggered reveal welcome screen". Uses effect delays, not Animate.delay,
  /// so no timer outlives the widget. Skipped when motion is reduced.
  Widget _reveal(int step, Widget child, {double rise = 50}) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    const curve = Curves.easeOutCubic;
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + step * 80),
          duration: const Duration(milliseconds: 500),
          curve: curve,
        )
        .moveY(begin: rise, end: 0, curve: curve);
  }

  Widget _obscureToggle() {
    final cs = ShadTheme.of(context).colorScheme;
    // Revealed fields fill with primary, so the icon must not be primary.
    final color = _obscure ? cs.mutedForeground : cs.primaryForeground;

    return SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        maxWidth: 28,
        maxHeight: 28,
        child: ShadIconButton.ghost(
          iconSize: 18,
          padding: const EdgeInsets.all(2),
          foregroundColor: color,
          hoverForegroundColor: color,
          icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
