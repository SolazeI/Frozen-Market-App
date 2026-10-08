import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Centered spinner for loading screens.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      );
}

/// Fades + slides its child up slightly on first build. Used by the state
/// views so empty / error / data content never "pops" in.
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.offset = 12,
  });
  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, (1 - t) * offset), child: child),
        ),
        child: child,
      );
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FadeIn(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: t.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(180, 48)),
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state, e.g. "Your cart is empty."
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.ac_unit_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _MessageView(
        icon: icon,
        iconColor: AppColors.primary,
        iconBg: AppColors.ice,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

/// Friendly error state with retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _MessageView(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.error,
        iconBg: AppColors.errorBg,
        title: title,
        message: message,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
}

/// Renders loading / error / data for any Riverpod AsyncValue so screens
/// don't repeat the same switch. Pass [isEmpty] + [empty] for empty lists.
///
/// Pass [loading] (e.g. `SkeletonProductGrid()` or `SkeletonList()`) to show
/// a skeleton shaped like the final content instead of a spinner. Switching
/// between loading, empty, error and data cross-fades.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.errorMessage,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String Function(Object error)? errorMessage;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final Widget child = value.when(
      loading: () => KeyedSubtree(
          key: const ValueKey('loading'), child: loading ?? const LoadingView()),
      error: (e, _) => KeyedSubtree(
        key: const ValueKey('error'),
        child: ErrorState(
          message: errorMessage?.call(e) ??
              "We couldn't load this. Check your connection and try again.",
          onRetry: onRetry,
        ),
      ),
      data: (d) {
        if (isEmpty != null && empty != null && isEmpty!(d)) {
          return KeyedSubtree(key: const ValueKey('empty'), child: empty!);
        }
        return KeyedSubtree(key: const ValueKey('data'), child: data(d));
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
