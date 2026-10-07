import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/location_providers.dart';
import '../../providers/user_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// TEMPORARY landing screen. Replaced by the customer shell + marketplace in Phase 9.
/// Shows the active delivery location so Phase 7 can be tested.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final location = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FrostMart'),
        actions: [
          IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(Routes.profile)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: Text(location?.shortLabel ?? 'Choose delivery location'),
                subtitle: Text(location == null
                    ? 'Needed to see products you can order'
                    : 'Delivering to ${location.province.isEmpty ? location.region : location.province}'),
                trailing: const Text('Change'),
                onTap: () => context.push(Routes.locationSelect),
              ),
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Hi, ${user?.fullName ?? 'Customer'}!',
              message:
                  'The marketplace arrives in Phase 9.',
            ),
          ),
        ],
      ),
    );
  }
}
