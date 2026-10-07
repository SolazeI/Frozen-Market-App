import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_providers.dart';
import 'state_views.dart';

/// UI-level defense in depth: shows [child] only to users with [role].
/// (The router guard and Firestore rules are the real enforcement.)
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.role,
    required this.child,
    this.fallback,
  });

  final String role;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(userRoleProvider) == role) return child;
    return fallback ??
        const EmptyState(
          icon: Icons.lock_outline,
          title: 'Access restricted',
          message: "You don't have permission to view this page.",
        );
  }
}
