import 'package:flutter/foundation.dart';
import 'package:closecart/services/location_service.dart';
import 'package:closecart/models/shop_model.dart';

class Geofence {
  final double latitude;
  final double longitude;
  double radiusInMeters;
  String name;

  Geofence({
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.name,
  });
}

class GeofenceService extends ChangeNotifier {
  Geofence? _currentGeofence;

  Geofence? get currentGeofence => _currentGeofence;

  /// Create a geofence around the given location
  Future<void> createGeofence(
      UserLocation location, double radiusInMeters) async {
    _currentGeofence = Geofence(
      latitude: location.latitude,
      longitude: location.longitude,
      radiusInMeters: radiusInMeters,
      name: location.placeName,
    );
    notifyListeners();
  }

  /// Update the radius of the current geofence
  void updateGeofenceRadius(double newRadiusInMeters) {
    if (_currentGeofence != null) {
      _currentGeofence!.radiusInMeters = newRadiusInMeters;
      notifyListeners();
    }
  }

  /// Check if a location is within the current geofence
  bool isLocationInCurrentGeofence(double latitude, double longitude) {
    if (_currentGeofence == null) return false;

    return LocationService.isLocationInGeofence(
      centerLatitude: _currentGeofence!.latitude,
      centerLongitude: _currentGeofence!.longitude,
      pointLatitude: latitude,
      pointLongitude: longitude,
      radiusInMeters: _currentGeofence!.radiusInMeters,
    );
  }

  /// Check if a shop is within the current geofence
  bool isShopInCurrentGeofence(Shop shop) {
    if (_currentGeofence == null) return false;

    final latitude = shop.location.latitude;
    final longitude = shop.location.longitude;

    return isLocationInCurrentGeofence(latitude, longitude);
  }

  /// Clear the current geofence
  void clearGeofence() {
    _currentGeofence = null;
    notifyListeners();
  }
}
