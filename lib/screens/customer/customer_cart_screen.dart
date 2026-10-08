import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/routes.dart';
import '../../widgets/widgets.dart';

/// Cart tab. Empty state only until the cart is built in Phase 10.
class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My cart')),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty.',
          message: 'Browse frozen goods and add them to your cart.',
          actionLabel: 'Browse products',
          onAction: () => context.go(Routes.customerHome),
        ),
      );
}
