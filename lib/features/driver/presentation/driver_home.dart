import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/detail_sheet.dart';
import '../../../widgets/role_scaffold.dart';

class DriverHome extends ConsumerWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    return RoleScaffold(
      title: 'مرحباً ${user.fullName}',
      subtitle: 'واجهة السائق',
      tabs: [
        RoleTab(
          icon: Icons.map_outlined,
          label: 'رحلاتي',
          endpoint: '/trips/?assigned_to_me=true',
          detailActions: const [
            DetailAction(label: 'ابدأ الرحلة', actionKey: 'start', icon: Icons.play_arrow),
            DetailAction(label: 'في الطريق', actionKey: 'on_the_way', icon: Icons.local_shipping_outlined),
            DetailAction(label: 'تم التسليم', actionKey: 'complete', icon: Icons.check_circle_outline),
          ],
          actionEndpointBuilder: (r, k) => '/trips/${r["id"]}/$k/',
        ),
        RoleTab(
          icon: Icons.assignment_outlined,
          label: 'الطلبات',
          endpoint: '/orders/?status=assigned',
          detailActions: const [
            DetailAction(label: 'قبول', actionKey: 'accept', icon: Icons.check),
            DetailAction(label: 'رفض', actionKey: 'reject', icon: Icons.close, destructive: true),
          ],
          actionEndpointBuilder: (r, k) => '/orders/${r["id"]}/$k/',
        ),
        const RoleTab(
          icon: Icons.attach_money,
          label: 'الأرباح',
          endpoint: '/drivers/me/earnings/',
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
