import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import '../auth/auth_ui.dart';

/// Profile content shared by customers and sellers. Used as the Profile tab
/// body in the customer/seller shells (Phases 5 and 9).
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForAuthErrors(context, ref);
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingView();

    final location = [user.barangay, user.city, user.province]
        .where((s) => s.isNotEmpty)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.ice,
                  backgroundImage: user.profileImage == null
                      ? null
                      : CachedNetworkImageProvider(user.profileImage!),
                  child: user.profileImage == null
                      ? Text(_initials(user.fullName),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary))
                      : null,
                ),
                const SizedBox(height: 14),
                Text(user.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(
                      user.isSeller
                          ? Icons.storefront_outlined
                          : Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppColors.primary),
                  label: Text(user.isSeller ? 'Seller' : 'Customer'),
                  backgroundColor: AppColors.ice,
                  side: BorderSide.none,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(location,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.editProfile),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Change password'),
                subtitle: const Text("We'll email you a reset link"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final ok = await showConfirmDialog(context,
                      title: 'Reset password?',
                      message: 'A reset link will be sent to ${user.email}.',
                      confirmLabel: 'Send link');
                  if (!ok) return;
                  final sent = await ref
                      .read(authControllerProvider.notifier)
                      .sendPasswordReset(user.email);
                  if (sent && context.mounted) {
                    AppSnackbar.success(context, 'Reset link sent.');
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Log out',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  final ok = await showConfirmDialog(context,
                      title: 'Log out?',
                      message: 'You will need to log in again.',
                      confirmLabel: 'Log out',
                      isDestructive: true);
                  if (ok) ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
