import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../widgets/role_scaffold.dart';
import 'create_order_page.dart';

class CustomerHome extends ConsumerStatefulWidget {
  const CustomerHome({super.key});

  @override
  ConsumerState<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends ConsumerState<CustomerHome> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user!;
    return Stack(
      children: [
        RoleScaffold(
          title: 'مرحباً ${user.fullName}',
          subtitle: 'حسابك كعميل',
          tabs: const [
            RoleTab(
              icon: Icons.shopping_bag_outlined,
              label: 'طلباتي',
              endpoint: '/orders/?mine=true',
            ),
            RoleTab(
              icon: Icons.receipt_long_outlined,
              label: 'الفواتير',
              endpoint: '/customers/me/invoices/',
            ),
            RoleTab(
              icon: Icons.local_shipping_outlined,
              label: 'التتبّع',
              endpoint: '/orders/?mine=true&status=in_progress',
            ),
            RoleTab(
              icon: Icons.person_outline,
              label: 'حسابي',
              endpoint: '/auth/me/',
            ),
          ],
        ),
        Positioned(
          bottom: 90,
          right: 16,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateOrderPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد'),
            ),
          ),
        ),
      ],
    );
  }
}
