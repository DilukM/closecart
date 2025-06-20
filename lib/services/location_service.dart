import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async'; // Add this import

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
  static StreamController<UserLocation>? _locationController;

  /// Get a stream of user location updates
  static Stream<UserLocation> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // minimum distance (meters) before updates
    Duration? timeInterval,
  }) {
    // Create a stream controller if it doesn't exist
    _locationController ??= StreamController<UserLocation>.broadcast();

    // Listen to the Geolocator position stream
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: timeInterval,
      ),
    ).listen(
      (Position position) async {
        _lastKnownPosition = position;

        try {
          // Convert position to UserLocation with address info
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          Placemark place =
              placemarks.isNotEmpty ? placemarks.first : Placemark();

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

          // Add the UserLocation to the stream
          _locationController?.add(
            UserLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              address: address,
              placeName: placeName,
            ),
          );
        } catch (e) {
          print('Error in location stream: $e');
          // Even if geocoding fails, we still want to emit location coords
          _locationController?.add(
            UserLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              address: "Unknown address",
              placeName: "Unknown location",
            ),
          );
        }
      },
      onError: (error) {
        print('Location stream error: $error');
        _locationController?.addError(error);
      },
    );

    return _locationController!.stream;
  }

  /// Dispose of the location stream resources
  static void dispose() {
    _locationController?.close();
    _locationController = null;
  }

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
