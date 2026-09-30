import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/user.dart';
import '../auth/presentation/auth_controller.dart';
import '../driver/presentation/driver_home.dart';
import '../customer/presentation/customer_home.dart';
import '../manager/presentation/manager_home.dart';

/// Root shell that switches the whole app based on the user's role.
/// One APK, three (or more) app experiences.
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    switch (user.role) {
      case UserRole.driver:
        return const DriverHome();
      case UserRole.customer:
        return const CustomerHome();
      case UserRole.manager:
      case UserRole.admin:
        return const ManagerHome();
      case UserRole.unknown:
        return const _UnknownRole();
    }
  }
}

class _UnknownRole extends ConsumerWidget {
  const _UnknownRole();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ejack')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'دورك غير معرّف على السيرفر.\nتواصل مع المشرف.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
