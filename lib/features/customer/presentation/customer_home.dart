import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../common/live_tracking_page.dart';
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'customer-map',
                  tooltip: 'تتبّع آخر طلب',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LiveTrackingPage(
                        title: 'تتبّع الطلب',
                        endpoint: '/orders/active/driver_location/',
                      ),
                    ),
                  ),
                  child: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'customer-new',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateOrderPage()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('طلب جديد'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
