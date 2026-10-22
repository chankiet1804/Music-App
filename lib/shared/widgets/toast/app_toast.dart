import 'package:flutter/foundation.dart';
import 'package:music_app/shared/widgets/toast/app_toaster.dart';

enum AppToastType { normal, success, error, info, warning, loading }

enum AppToastPosition { top, bottom }

class AppToastAction {
  const AppToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

@immutable
class AppToastData {
  const AppToastData({
    required this.id,
    required this.title,
    this.type = AppToastType.normal,
    this.description,
    this.action,
    this.duration,
  });

  final Object id;
  final String title;
  final AppToastType type;
  final String? description;
  final AppToastAction? action;

  /// Falls back to [ToastSpec.lifetime]. Ignored while [type] is loading.
  final Duration? duration;

  AppToastData copyWith({
    String? title,
    AppToastType? type,
    String? description,
    AppToastAction? action,
    Duration? duration,
  }) {
    return AppToastData(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      action: action ?? this.action,
      duration: duration ?? this.duration,
    );
  }
}

/// Context-free toast API. Calls are no-ops until an [AppToaster] is mounted.
abstract final class AppToast {
  static int _nextId = 0;

  static Object show(
    String title, {
    AppToastType type = AppToastType.normal,
    String? description,
    AppToastAction? action,
    Duration? duration,
    Object? id,
  }) {
    final effectiveId = id ?? _nextId++;
    AppToaster.current?.upsert(
      AppToastData(
        id: effectiveId,
        title: title,
        type: type,
        description: description,
        action: action,
        duration: duration,
      ),
    );
    return effectiveId;
  }

  static Object success(
    String title, {
    String? description,
    AppToastAction? action,
    Duration? duration,
    Object? id,
  }) => show(
    title,
    type: AppToastType.success,
    description: description,
    action: action,
    duration: duration,
    id: id,
  );

  static Object error(
    String title, {
    String? description,
    AppToastAction? action,
    Duration? duration,
    Object? id,
  }) => show(
    title,
    type: AppToastType.error,
    description: description,
    action: action,
    duration: duration,
    id: id,
  );

  static Object info(
    String title, {
    String? description,
    AppToastAction? action,
    Duration? duration,
    Object? id,
  }) => show(
    title,
    type: AppToastType.info,
    description: description,
    action: action,
    duration: duration,
    id: id,
  );

  static Object warning(
    String title, {
    String? description,
    AppToastAction? action,
    Duration? duration,
    Object? id,
  }) => show(
    title,
    type: AppToastType.warning,
    description: description,
    action: action,
    duration: duration,
    id: id,
  );

  /// Stays until updated or dismissed.
  static Object loading(String title, {String? description, Object? id}) =>
      show(
        title,
        type: AppToastType.loading,
        description: description,
        id: id,
      );

  /// Merges the given fields into a live toast; restarts its timer.
  static void update(
    Object id, {
    String? title,
    AppToastType? type,
    String? description,
    AppToastAction? action,
    Duration? duration,
  }) {
    AppToaster.current?.update(
      id,
      (data) => data.copyWith(
        title: title,
        type: type,
        description: description,
        action: action,
        duration: duration,
      ),
    );
  }

  /// Shows a loading toast that turns into success/error when [future]
  /// settles, or is dismissed if the matching builder is null.
  static Object promise<T>(
    Future<T> future, {
    required String loading,
    String Function(T value)? success,
    String Function(Object error)? error,
  }) {
    final id = AppToast.loading(loading);
    future.then(
      (value) => success == null
          ? dismiss(id)
          : update(id, type: AppToastType.success, title: success(value)),
      onError: (Object e) => error == null
          ? dismiss(id)
          : update(id, type: AppToastType.error, title: error(e)),
    );
    return id;
  }

  static void dismiss(Object id) => AppToaster.current?.dismiss(id);

  static void dismissAll() => AppToaster.current?.dismissAll();
}
