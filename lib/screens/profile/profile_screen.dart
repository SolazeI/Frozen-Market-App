import 'package:flutter/material.dart';

import 'profile_view.dart';

/// Standalone wrapper around [ProfileView] (pushed route until the shells exist).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const ProfileView(),
      );
}
