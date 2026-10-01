import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/common/settings_page.dart';
import 'detail_sheet.dart';
import 'endpoint_list_view.dart';

class RoleTab {
  const RoleTab({
    required this.icon,
    required this.label,
    required this.endpoint,
    this.detailActions = const [],
    this.actionEndpointBuilder,
  });

  final IconData icon;
  final String label;
  final String endpoint;
  final List<DetailAction> detailActions;
  final String Function(Map<String, dynamic> record, String action)?
      actionEndpointBuilder;
}

/// Bottom-nav scaffold shared by driver / customer / manager screens.
/// Each tab renders the same [EndpointListView] pointing to a Django REST URL.
class RoleScaffold extends ConsumerStatefulWidget {
  const RoleScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tabs,
  });

  final String title;
  final String subtitle;
  final List<RoleTab> tabs;

  @override
  ConsumerState<RoleScaffold> createState() => _RoleScaffoldState();
}

class _RoleScaffoldState extends ConsumerState<RoleScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(widget.subtitle,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
        ),
        body: EndpointListView(
          key: ValueKey('${tab.label}#${tab.endpoint}'),
          title: tab.label,
          endpoint: tab.endpoint,
          detailActions: tab.detailActions,
          actionEndpointBuilder: tab.actionEndpointBuilder,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in widget.tabs)
              NavigationDestination(icon: Icon(t.icon), label: t.label),
          ],
        ),
      ),
    );
  }
}
