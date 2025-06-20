import 'package:hive_flutter/hive_flutter.dart';

class SettingsCacheService {
  static const String _boxName = 'settings';
  static const String _geofenceRadiusKey = 'geofence_radius';
  static const double _defaultGeofenceRadius = 1000.0; // Default 1km in meters

  static Box<dynamic>? _box;

  /// Initialize Hive and open the settings box
  static Future<void> init() async {
    if (_box != null) return; // Already initialized

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>(_boxName);
      print('Settings cache initialized');
    } catch (e) {
      print('Error initializing settings cache: $e');
    }
  }

  /// Save geofence radius to local storage (in meters)
  static Future<void> saveGeofenceRadius(double radiusInMeters) async {
    try {
      await _ensureInitialized();
      await _box!.put(_geofenceRadiusKey, radiusInMeters);
      print('Geofence radius saved: $radiusInMeters meters');
    } catch (e) {
      print('Error saving geofence radius: $e');
    }
  }

  /// Get geofence radius from local storage (in meters)
  static double getGeofenceRadius() {
    try {
      _ensureInitialized();
      return _box?.get(_geofenceRadiusKey,
              defaultValue: _defaultGeofenceRadius) ??
          _defaultGeofenceRadius;
    } catch (e) {
      print('Error retrieving geofence radius: $e');
      return _defaultGeofenceRadius;
    }
  }

  /// Convert kilometers to meters
  static double kmToMeters(double km) {
    return km * 1000;
  }

  /// Convert meters to kilometers
  static double metersToKm(double meters) {
    return meters / 1000;
  }

  /// Make sure the box is initialized before using it
  static Future<void> _ensureInitialized() async {
    if (_box == null || !(_box!.isOpen)) {
      await init();
    }
  }

  /// Clear all settings
  static Future<void> clearSettings() async {
    try {
      await _ensureInitialized();
      await _box!.clear();
      print('Settings cleared');
    } catch (e) {
      print('Error clearing settings: $e');
    }
  }
}
