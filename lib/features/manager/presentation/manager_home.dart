import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/detail_sheet.dart';
import '../../../widgets/role_scaffold.dart';

class ManagerHome extends ConsumerWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    return RoleScaffold(
      title: 'لوحة الإدارة',
      subtitle: 'مرحباً ${user.fullName}',
      tabs: [
        const RoleTab(
          icon: Icons.dashboard_outlined,
          label: 'ملخص',
          endpoint: '/dashboard/summary/',
        ),
        RoleTab(
          icon: Icons.list_alt,
          label: 'الطلبات',
          endpoint: '/orders/',
          detailActions: const [
            DetailAction(label: 'إسناد لسائق', actionKey: 'assign', icon: Icons.person_add_alt),
            DetailAction(label: 'إلغاء الطلب', actionKey: 'cancel', icon: Icons.cancel_outlined, destructive: true),
          ],
          actionEndpointBuilder: (r, k) => '/orders/${r["id"]}/$k/',
        ),
        RoleTab(
          icon: Icons.local_shipping_outlined,
          label: 'السائقون',
          endpoint: '/drivers/',
          detailActions: const [
            DetailAction(label: 'تفعيل', actionKey: 'activate', icon: Icons.toggle_on),
            DetailAction(label: 'إيقاف', actionKey: 'suspend', icon: Icons.block, destructive: true),
          ],
          actionEndpointBuilder: (r, k) => '/drivers/${r["id"]}/$k/',
        ),
        const RoleTab(
          icon: Icons.people_outline,
          label: 'العملاء',
          endpoint: '/customers/',
        ),
        const RoleTab(
          icon: Icons.person_outline,
          label: 'حسابي',
          endpoint: '/auth/me/',
        ),
      ],
    );
  }
}
