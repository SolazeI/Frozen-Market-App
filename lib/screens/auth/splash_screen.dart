import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final loggedIn = ref.watch(authStateProvider).valueOrNull != null;

    if (loggedIn && profile.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('FrostMart')),
        body: Column(
          children: [
            Expanded(
              child: ErrorState(
                message:
                    "We couldn't load your account. Check your connection and try again.",
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrostLogo(size: 104, onDark: true, showTagline: true),
            SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.6, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
