import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent feedback messages. Usage: AppSnackbar.success(context, 'Saved');
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext c, String m) =>
      _show(c, m, AppColors.success, Icons.check_circle_rounded);
  static void error(BuildContext c, String m) =>
      _show(c, m, AppColors.error, Icons.error_rounded);
  static void info(BuildContext c, String m) =>
      _show(c, m, AppColors.primaryDark, Icons.info_rounded);

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
