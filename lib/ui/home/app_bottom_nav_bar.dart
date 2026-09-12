import 'package:flutter/material.dart';
import 'package:music_app/theme/theme.dart';

/// Bottom nav matching the Figma design: floating, rounded top corners and a
/// soft upward shadow. Replaces CupertinoTabBar, which exposes no decoration.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppNavBar.inset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.full),
          ),
          boxShadow: [tokens.navBarShadow],
        ),
        child: SizedBox(
          height: AppNavBar.height,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavBarItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavigationBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final color = selected ? theme.colorScheme.primary : tokens.navInactive;
    final label = item.label;

    return Expanded(
      // GestureDetector rather than InkWell: there is no Material ancestor
      // inside CupertinoPageScaffold.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: AppIconSize.sm),
              child: item.icon,
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
