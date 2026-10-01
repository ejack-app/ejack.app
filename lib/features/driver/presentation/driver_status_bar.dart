import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_service.dart';

/// Toggleable "online / offline" chip the driver pins at the top of their
/// screen. Starts/stops the GPS pinger.
class DriverStatusBar extends ConsumerStatefulWidget {
  const DriverStatusBar({super.key});

  @override
  ConsumerState<DriverStatusBar> createState() => _DriverStatusBarState();
}

class _DriverStatusBarState extends ConsumerState<DriverStatusBar> {
  bool _online = false;
  bool _busy = false;
  String? _hint;

  Future<void> _toggle(bool v) async {
    setState(() {
      _busy = true;
      _hint = null;
    });
    try {
      if (v) {
        final ok = await LocationService.instance.start();
        if (!ok) {
          setState(() {
            _busy = false;
            _hint = 'لم يتم منح إذن الموقع';
          });
          return;
        }
      } else {
        await LocationService.instance.stop();
      }
      setState(() {
        _online = v;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _hint = 'تعذر تغيير الحالة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _online ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = _online ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(_online ? Icons.gps_fixed : Icons.gps_off, color: fg, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _hint ?? (_online ? 'متصل — جاري بث الموقع' : 'غير متصل'),
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
            Switch(
              value: _online,
              onChanged: _busy ? null : _toggle,
            ),
          ],
        ),
      ),
    );
  }
}
