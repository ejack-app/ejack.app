import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/role_scaffold.dart';

class DriverHome extends ConsumerWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    return RoleScaffold(
      title: 'مرحباً ${user.fullName}',
      subtitle: 'واجهة السائق',
      tabs: const [
        RoleTab(
          icon: Icons.map_outlined,
          label: 'رحلاتي',
          endpoint: '/trips/?assigned_to_me=true',
        ),
        RoleTab(
          icon: Icons.assignment_outlined,
          label: 'الطلبات',
          endpoint: '/orders/?status=assigned',
        ),
        RoleTab(
          icon: Icons.attach_money,
          label: 'الأرباح',
          endpoint: '/drivers/me/earnings/',
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
