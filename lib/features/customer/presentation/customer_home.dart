import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/role_scaffold.dart';

class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    return RoleScaffold(
      title: 'مرحباً ${user.fullName}',
      subtitle: 'حسابك كعميل',
      tabs: const [
        RoleTab(
          icon: Icons.shopping_bag_outlined,
          label: 'طلباتي',
          endpoint: '/orders/?mine=true',
        ),
        RoleTab(
          icon: Icons.add_circle_outline,
          label: 'طلب جديد',
          endpoint: '/orders/quote/',
        ),
        RoleTab(
          icon: Icons.receipt_long_outlined,
          label: 'الفواتير',
          endpoint: '/customers/me/invoices/',
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
