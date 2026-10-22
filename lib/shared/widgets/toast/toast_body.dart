import 'package:flutter/material.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/shared/widgets/toast/toast_spec.dart';
import 'package:music_app/theme/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The toast card: status icon, title/description and an optional action.
class ToastBody extends StatelessWidget {
  const ToastBody({super.key, required this.data});

  final AppToastData data;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final icon = _icon(cs);
    final action = data.action;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.popover,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.border, width: AppBorders.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000), // black @ 45%
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox.square(dimension: ToastSpec.iconSize, child: icon),
              const SizedBox(width: ToastSpec.iconGap),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: theme.textTheme.small),
                  if (data.description != null)
                    Text(data.description!, style: theme.textTheme.caption),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ShadButton.secondary(
                size: ShadButtonSize.sm,
                onPressed: action.onPressed,
                child: Text(action.label),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _icon(ShadColorScheme cs) {
    return switch (data.type) {
      AppToastType.normal => null,
      AppToastType.success => Icon(
        LucideIcons.circleCheck,
        size: ToastSpec.iconSize,
        color: cs.success,
      ),
      AppToastType.error => Icon(
        LucideIcons.circleX,
        size: ToastSpec.iconSize,
        color: cs.destructive,
      ),
      AppToastType.info => Icon(
        LucideIcons.info,
        size: ToastSpec.iconSize,
        color: cs.info,
      ),
      AppToastType.warning => Icon(
        LucideIcons.triangleAlert,
        size: ToastSpec.iconSize,
        color: cs.warning,
      ),
      AppToastType.loading => Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.mutedForeground,
        ),
      ),
    };
  }
}
