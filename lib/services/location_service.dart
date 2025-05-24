import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// A model class to store location data
class UserLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String placeName;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.placeName,
  });
}

class LocationService {
  static Position? _lastKnownPosition;

  /// Get the user's current location including coordinates, address and place name
  static Future<UserLocation> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    try {
      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _lastKnownPosition = position;

      // Get address information through reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: "Unknown address",
          placeName: "Unknown location",
        );
      }

      Placemark place = placemarks.first;

      // Format the address
      List<String> addressParts = [
        place.street,
        place.subLocality,
        place.locality,
        place.postalCode,
        place.country,
      ]
          .where((part) => part != null && part.isNotEmpty)
          .map((part) => part!)
          .toList();

      String address = addressParts.join(", ");

      // Use the name of the place or a nearby POI
      String placeName = place.name ??
          place.locality ??
          place.subLocality ??
          'Unknown location';
      if (placeName.isEmpty) placeName = 'Unknown location';

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        placeName: placeName,
      );
    } catch (e) {
      print("Error getting location: $e");

      // If we have a last known position, try using that
      if (_lastKnownPosition != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _lastKnownPosition!.latitude,
            _lastKnownPosition!.longitude,
          );

          Placemark place = placemarks.first;
          String address =
              '${place.street ?? ""}, ${place.locality ?? ""}, ${place.country ?? ""}';
          String placeName =
              place.name ?? place.locality ?? 'Last known location';

          return UserLocation(
            latitude: _lastKnownPosition!.latitude,
            longitude: _lastKnownPosition!.longitude,
            address: address,
            placeName: placeName,
          );
        } catch (_) {
          // Fall through to the exception below
        }
      }

      throw Exception('Failed to get location: $e');
    }
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if a location is within the specified geofence radius
  static bool isLocationInGeofence({
    required double centerLatitude,
    required double centerLongitude,
    required double pointLatitude,
    required double pointLongitude,
    required double radiusInMeters,
  }) {
    double distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      pointLatitude,
      pointLongitude,
    );

    return distance <= radiusInMeters;
  }
}
