import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/api_client.dart';

/// Streams the driver's GPS and POSTs each sample to the Django backend.
///
/// Server contract (adjust in your DRF view):
///   POST /drivers/me/location/
///   body: { "lat": 24.71, "lng": 46.67, "speed": 12.5, "heading": 180, "ts": "ISO-8601" }
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _sub;
  bool get isTracking => _sub != null;

  /// Returns `true` if background tracking actually started.
  Future<bool> start({
    String endpoint = '/drivers/me/location/',
    int distanceFilterMeters = 25,
  }) async {
    if (_sub != null) return true;

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return false;
    }

    final perm = await Permission.locationWhenInUse.request();
    if (!perm.isGranted) return false;

    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen((pos) async {
      try {
        await ApiClient.instance.dio.post(endpoint, data: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speed': pos.speed,
          'heading': pos.heading,
          'ts': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        // Swallow — the stream keeps pushing; a dropped sample is fine.
      }
    });
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<Position?> currentOnce() async {
    final perm = await Permission.locationWhenInUse.request();
    if (!perm.isGranted) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
