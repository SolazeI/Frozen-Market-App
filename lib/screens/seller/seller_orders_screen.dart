import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Orders tab. Empty state only until order management lands in Phase 12.
class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: "You don't have any orders yet.",
          message: 'Incoming orders will appear here.',
        ),
      );
}
