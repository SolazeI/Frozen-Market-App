import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Orders tab. Empty state only until order tracking is built (Phase 13).
class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: "You don't have any orders yet.",
          message: 'Your orders will show up here.',
        ),
      );
}
