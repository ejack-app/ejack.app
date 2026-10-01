import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/common/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: UI shouldn't block on notification init.
  unawaited(NotificationService.instance.init());
  runApp(const ProviderScope(child: EjackApp()));
}

class EjackApp extends ConsumerWidget {
  const EjackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ejack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).bootstrap();
      if (mounted) setState(() => _booted = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_booted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = ref.watch(authControllerProvider).user;
    return user == null ? const LoginPage() : const DashboardShell();
  }
}
