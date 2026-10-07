import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/widgets.dart';

/// Call from build(): shows a friendly snackbar when an auth action fails.
void listenForAuthErrors(BuildContext context, WidgetRef ref) {
  ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
    if (!next.hasError || next.isLoading) return;
    final e = next.error!;
    if (e is CancelledException) return;
    AppSnackbar.error(context, friendlyError(e));
  });
}
