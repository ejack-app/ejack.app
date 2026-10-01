import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/api_client.dart';

/// Live map that polls `endpoint` every [refreshSeconds] seconds for a payload
/// shaped `{lat, lng}` (or `{latitude, longitude}`) and recenters the marker.
///
/// Driver uses it to see their own tracked path.
/// Customer passes `/orders/<id>/driver_location/` and watches the driver.
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({
    super.key,
    required this.title,
    required this.endpoint,
    this.refreshSeconds = 10,
  });

  final String title;
  final String endpoint;
  final int refreshSeconds;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final _mapController = MapController();
  Timer? _timer;
  LatLng? _point;
  String? _error;
  DateTime? _lastUpdate;

  // Riyadh as a fallback center so the map renders even before first poll.
  static const _fallback = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(
      Duration(seconds: widget.refreshSeconds),
      (_) => _poll(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final r = await ApiClient.instance.dio.get<Map<String, dynamic>>(widget.endpoint);
      final d = r.data ?? const <String, dynamic>{};
      final lat = (d['lat'] ?? d['latitude']) as num?;
      final lng = (d['lng'] ?? d['longitude']) as num?;
      if (lat != null && lng != null && mounted) {
        setState(() {
          _point = LatLng(lat.toDouble(), lng.toDouble());
          _lastUpdate = DateTime.now();
          _error = null;
        });
        _mapController.move(_point!, 15);
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = 'لا يوجد موقع بعد (${e.response?.statusCode ?? "offline"})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _point ?? _fallback;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _poll,
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ejack.ejack',
                ),
                if (_point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point!,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.local_shipping, size: 36, color: Colors.redAccent),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Material(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _point == null ? Icons.gps_off : Icons.gps_fixed,
                        color: _point == null ? Colors.grey : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error ??
                              (_point == null
                                  ? 'في انتظار أول قراءة...'
                                  : 'آخر تحديث: ${_fmt(_lastUpdate!)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return 'منذ $s ث';
    return 'منذ ${s ~/ 60}د';
  }
}
