import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart' as pkg;

import '../auth/presentation/auth_controller.dart';
import '../auth/presentation/profile_edit_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          children: [
            if (user != null)
              ListTile(
                leading: CircleAvatar(child: Text(user.fullName.characters.first)),
                title: Text(user.fullName),
                subtitle: Text(user.email),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                ),
              ),
            const Divider(),
            const _SectionLabel('التطبيق'),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('الوضع الليلي'),
              subtitle: const Text('يتبع إعداد الجهاز تلقائياً'),
              value: MediaQuery.of(context).platformBrightness == Brightness.dark,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يتبع التطبيق إعداد الجهاز')),
                );
              },
            ),
            const ListTile(
              leading: Icon(Icons.language),
              title: Text('اللغة'),
              subtitle: Text('العربية'),
            ),
            const Divider(),
            const _SectionLabel('الحساب'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل تريد الخروج من حسابك؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
            const Divider(),
            FutureBuilder<pkg.PackageInfo>(
              future: pkg.PackageInfo.fromPlatform(),
              builder: (_, snap) {
                final v = snap.data == null
                    ? '...'
                    : '${snap.data!.version}+${snap.data!.buildNumber}';
                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('إصدار التطبيق'),
                  subtitle: Text(v),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
