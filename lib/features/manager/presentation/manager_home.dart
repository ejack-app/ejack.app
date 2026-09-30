import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/role_scaffold.dart';

class ManagerHome extends ConsumerWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    return RoleScaffold(
      title: 'لوحة الإدارة',
      subtitle: 'مرحباً ${user.fullName}',
      tabs: const [
        RoleTab(
          icon: Icons.dashboard_outlined,
          label: 'ملخص',
          endpoint: '/dashboard/summary/',
        ),
        RoleTab(
          icon: Icons.list_alt,
          label: 'الطلبات',
          endpoint: '/orders/',
        ),
        RoleTab(
          icon: Icons.local_shipping_outlined,
          label: 'السائقون',
          endpoint: '/drivers/',
        ),
        RoleTab(
          icon: Icons.people_outline,
          label: 'العملاء',
          endpoint: '/customers/',
        ),
        RoleTab(
          icon: Icons.person_outline,
          label: 'حسابي',
          endpoint: '/auth/me/',
        ),
      ],
    );
  }
}
