import 'package:flutter/material.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pill-shaped form field: translucent fill and no border at rest, a primary
/// border that fades in on focus, and a placeholder whose characters rise in
/// one by one (Native Bloom's "Text input with animated placeholder").
/// When [revealed], primary floods in from the trailing edge (Native Bloom's
/// "Password reveal animation").
class PillInput extends StatefulWidget {
  const PillInput({
    super.key,
    required this.id,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.trailing,
    this.obscureText = false,
    this.revealed = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
  });

  final String id;
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final Widget? trailing;
  final bool obscureText;
  final bool revealed;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PillInput> createState() => _PillInputState();
}

class _PillInputState extends State<PillInput> {
  static const _radius = BorderRadius.all(Radius.circular(AppRadius.full));
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _focusNode.hasFocus ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, focus, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: widget.revealed ? 1 : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        builder: (context, reveal, _) {
          final iconColor = Color.lerp(
            Color.lerp(cs.mutedForeground, cs.primary, focus),
            cs.primaryForeground,
            reveal,
          );
          return ShadInputFormField(
            id: widget.id,
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: _decoration(cs, focus, reveal),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg + 2,
              vertical: AppSpacing.md + 2,
            ),
            // Shad clips the placeholder to one line of this style; the extra
            // height over the placeholder's 1.4 keeps per-char descenders in.
            style: theme.textTheme.muted.copyWith(
              fontSize: 15,
              height: 1.6,
              color: cs.foreground,
            ),
            placeholderAlignment: AlignmentDirectional.centerStart,
            placeholderStyle: theme.textTheme.muted.copyWith(
              fontSize: 15,
              color: Color.lerp(
                cs.mutedForeground,
                cs.primaryForeground.withValues(alpha: 0.7),
                reveal,
              ),
            ),
            placeholder: _RisingText(widget.placeholder),
            leading: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(widget.icon, size: 18, color: iconColor),
            ),
            trailing: widget.trailing,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
            onSubmitted: widget.onSubmitted,
          );
        },
      ),
    );
  }

  ShadDecoration _decoration(ShadColorScheme cs, double focus, double reveal) {
    // Opaque: the starfield races while signing in and would flicker through.
    final fill = cs.secondary;
    // Soft edge, so the sweep does not alias into a hard line.
    final edge = 1 - reveal;

    return ShadDecoration(
      color: fill,
      gradient: reveal == 0
          ? null
          : LinearGradient(
              colors: [fill, fill, cs.primary, cs.primary],
              stops: [0, (edge - 0.03).clamp(0, 1), edge, 1],
            ),
      border: ShadBorder.all(
        width: 1.5,
        color: cs.primary.withValues(alpha: focus),
        radius: _radius,
      ),
      errorBorder: ShadBorder.all(
        width: 1.5,
        color: cs.destructive,
        radius: _radius,
      ),
      disableSecondaryBorder: true,
    );
  }
}

/// Placeholder whose characters fade, rise and grow in with a 30 ms stagger.
/// Shad remounts the placeholder whenever the field empties, which replays it.
class _RisingText extends StatelessWidget {
  const _RisingText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Text(text);
    final chars = text.characters.toList();

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chars.length; i++)
              // Effect delay, not Animate.delay, so no timer outlives it.
              Text(chars[i])
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: i * 30),
                    duration: const Duration(milliseconds: 300),
                  )
                  .moveY(
                    begin: 15,
                    end: 0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                  )
                  .scaleXY(
                    begin: 0.5,
                    end: 1,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                  ),
          ],
        ),
      ),
    );
  }
}
