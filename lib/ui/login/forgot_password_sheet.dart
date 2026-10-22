import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/auth/auth_controller.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/ui/login/validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Asks for an email and sends a password reset link. Errors are surfaced by
/// the [LoginPage] listener on [authControllerProvider].
class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key, this.initialEmail = ''});

  final String initialEmail;

  static Future<void> show(BuildContext context, {String initialEmail = ''}) {
    return showShadSheet<void>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<ShadFormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    await controller.resetPassword(_email.text);
    if (!mounted || ref.read(authControllerProvider).hasError) return;
    Navigator.of(context).pop();
    // Neutral wording: the response never reveals whether the email exists.
    AppToast.success(
      'If an account exists for that email, a reset link has been sent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    // Lift the sheet above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ShadSheet(
        title: const Text('Reset password'),
        description: const Text(
          "Enter your email and we'll send you a link to reset your password.",
        ),
        actions: [
          ShadButton.outline(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: isLoading ? null : _submit,
            child: const Text('Send link'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ShadForm(
            key: _formKey,
            child: ShadInputFormField(
              id: 'email',
              controller: _email,
              autofocus: true,
              placeholder: const Text('Email'),
              leading: const Icon(LucideIcons.mail, size: 16),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: validateEmail,
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
      ),
    );
  }
}
