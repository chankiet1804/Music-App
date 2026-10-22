import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:music_app/shared/widgets/toast/app_toast.dart';
import 'package:music_app/shared/widgets/toast/toast_item.dart';
import 'package:music_app/shared/widgets/toast/toast_spec.dart';

/// Hosts the app-wide toast stack above [child]. Mount once, above the
/// Navigator (via `ShadApp.builder`), then show toasts through [AppToast].
///
/// Collapsed, toasts stack with a small offset and shrinking scale; tapping
/// one expands the stack into a list. Swipe a toast to dismiss it.
class AppToaster extends StatefulWidget {
  const AppToaster({
    super.key,
    required this.child,
    this.position = AppToastPosition.top,
  });

  final Widget child;
  final AppToastPosition position;

  /// The mounted toaster [AppToast] talks to, if any.
  static AppToasterState? get current => _current;
  static AppToasterState? _current;

  @override
  State<AppToaster> createState() => AppToasterState();
}

class _Entry {
  _Entry(this.data);

  final key = UniqueKey();
  AppToastData data;
  bool dismissing = false;
  double? height;
}

class AppToasterState extends State<AppToaster> {
  /// Newest first; dismissing entries stay until their exit animation ends.
  final _entries = <_Entry>[];
  bool _expanded = false;

  Iterable<_Entry> get _live => _entries.where((e) => !e.dismissing);

  @override
  void initState() {
    super.initState();
    AppToaster._current = this;
  }

  @override
  void dispose() {
    if (identical(AppToaster._current, this)) AppToaster._current = null;
    super.dispose();
  }

  /// Shows [data], or replaces the live toast with the same id.
  void upsert(AppToastData data) {
    if (!mounted) return;
    final existing = _find(data.id);
    setState(() {
      if (existing != null) {
        existing.data = data;
      } else {
        _entries.insert(0, _Entry(data));
      }
    });
  }

  void update(Object id, AppToastData Function(AppToastData data) change) {
    final entry = _find(id);
    if (!mounted || entry == null) return;
    setState(() => entry.data = change(entry.data));
  }

  void dismiss(Object id) {
    final entry = _find(id);
    if (entry != null) _dismiss(entry);
  }

  void dismissAll() {
    if (!mounted) return;
    setState(() {
      for (final entry in _entries) {
        entry.dismissing = true;
      }
      _expanded = false;
    });
  }

  _Entry? _find(Object id) => _live.where((e) => e.data.id == id).firstOrNull;

  void _dismiss(_Entry entry) {
    if (!mounted || entry.dismissing) return;
    setState(() {
      entry.dismissing = true;
      if (_live.length <= 1) _expanded = false;
    });
  }

  void _remove(_Entry entry) => setState(() => _entries.remove(entry));

  void _setHeight(_Entry entry, double height) {
    if (entry.height == height) return;
    setState(() => entry.height = height);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded && _live.length > 1);
  }

  Map<_Entry, ToastTarget> _layout() {
    final targets = <_Entry, ToastTarget>{};
    final live = _live.toList();
    final frontHeight = live.firstOrNull?.height;
    var stacked = 0.0;
    for (final (i, entry) in live.indexed) {
      targets[entry] = ToastTarget(
        y: _expanded
            ? stacked + i * ToastSpec.gap
            : i * ToastSpec.collapseOffset,
        scale: _expanded
            ? 1
            : math.max(
                ToastSpec.minScale,
                1 - i * ToastSpec.collapseScaleStep,
              ),
        opacity: i < ToastSpec.visible ? 1 : 0,
        clipHeight: _expanded || i == 0 ? null : frontHeight,
      );
      stacked += entry.height ?? ToastSpec.fallbackHeight;
    }
    return targets;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final top = widget.position == AppToastPosition.top;
    final edgeInset =
        (top ? padding.top : padding.bottom) + ToastSpec.viewportOffset;
    final width = math.max(
      0.0,
      math.min(
        screen.width - 2 * ToastSpec.viewportOffset,
        ToastSpec.maxWidth,
      ),
    );
    final left = (screen.width - width) / 2;
    final targets = _layout();

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Tapping anywhere outside the expanded stack collapses it.
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpanded,
            ),
          ),
        // Oldest first so the newest paints on top.
        for (final entry in _entries.reversed)
          ToastItem(
            key: entry.key,
            data: entry.data,
            // Exiting toasts ignore their target, any value will do.
            target: targets[entry] ?? _exitingTarget,
            position: widget.position,
            left: left,
            width: width,
            edgeInset: edgeInset,
            // Hidden toasts wait their turn instead of expiring unseen.
            paused: _expanded || (targets[entry]?.opacity ?? 1) == 0,
            dismissing: entry.dismissing,
            onHeight: (height) => _setHeight(entry, height),
            onTap: _toggleExpanded,
            onDismiss: () => _dismiss(entry),
            onRemoved: () => _remove(entry),
          ),
      ],
    );
  }
}

const _exitingTarget = ToastTarget(y: 0, scale: 1, opacity: 1);
