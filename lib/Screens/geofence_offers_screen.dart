import 'package:closecart/Screens/OfferView.dart';
import 'package:closecart/Widgets/offerTile.dart';
import 'package:closecart/models/offer_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:closecart/services/location_service.dart';
import 'package:closecart/services/geofence_service.dart';
import 'package:closecart/services/recommendationService.dart';
import 'package:closecart/services/shop_cache_service.dart';
import 'package:closecart/services/settings_cache_service.dart';
import 'package:closecart/models/shop_model.dart';
import 'package:closecart/services/notificationService.dart';
import 'package:closecart/models/notification_model.dart';
import 'package:closecart/services/audio_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive/hive.dart';
import 'dart:async';

class GeofenceOffersScreen extends StatefulWidget {
  const GeofenceOffersScreen({Key? key}) : super(key: key);

  @override
  _GeofenceOffersScreenState createState() => _GeofenceOffersScreenState();
}

class _GeofenceOffersScreenState extends State<GeofenceOffersScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _offers = [];
  Set<String> _previousOfferIds = {};
  UserLocation? _userLocation;
  MapController _mapController = MapController();
  double _geofenceRadius =
      1000.0; // Default value, will be overridden from settings
  List<CircleMarker> _circles = [];
  List<Marker> _markers = [];

  // Add stream subscriptions for real-time updates
  StreamSubscription<UserLocation>? _locationSubscription;
  Timer? _offersRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitialize();

    // Set up periodic refresh for offers (every 30 seconds)
    _offersRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOffersInGeofence(forceRefresh: true);
    });
  }

  Future<void> _loadSettingsAndInitialize() async {
    // Initialize settings cache
    await SettingsCacheService.init();

    // Load saved geofence radius from settings
    setState(() {
      _geofenceRadius = SettingsCacheService.getGeofenceRadius();
    });

    // Continue with initialization
    _initialize();
  }

  @override
  void dispose() {
    // Cancel subscriptions when widget is disposed
    _locationSubscription?.cancel();
    _offersRefreshTimer?.cancel();
    AudioService.stopAlarm(); // Stop any playing alarm sounds
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get user's current location
      _userLocation = await LocationService.getCurrentLocation();

      // Create geofence around current location
      final geofenceService =
          Provider.of<GeofenceService>(context, listen: false);
      await geofenceService.createGeofence(_userLocation!, _geofenceRadius);

      // Update map
      _updateMapCircle();

      // Get offers within geofence
      await _loadOffersInGeofence();

      // Subscribe to location changes
      _subscribeToLocationUpdates();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToLocationUpdates() {
    // Cancel existing subscription if any
    _locationSubscription?.cancel();

    // Subscribe to location updates
    _locationSubscription =
        LocationService.getLocationStream().listen((newLocation) {
      if (_userLocation != null &&
          (_userLocation!.latitude != newLocation.latitude ||
              _userLocation!.longitude != newLocation.longitude)) {
        setState(() {
          _userLocation = newLocation;
        });

        // Update geofence based on new location
        final geofenceService =
            Provider.of<GeofenceService>(context, listen: false);
        geofenceService
            .createGeofence(_userLocation!, _geofenceRadius)
            .then((_) {
          _updateMapCircle();
          _loadOffersInGeofence();
        });

        // Center map on new location
        _mapController.move(LatLng(newLocation.latitude, newLocation.longitude),
            _mapController.zoom);
      }
    }, onError: (e) {
      print('Location stream error: $e');
    });
  }

  void _updateMapCircle() {
    final geofenceService =
        Provider.of<GeofenceService>(context, listen: false);
    final geofence = geofenceService.currentGeofence;

    if (geofence != null && _userLocation != null) {
      // Convert meters to map units for proper circle sizing
      // This conversion factor is approximate and may need adjustment
      final metersToPixels = 1.0; // Adjust this value if needed

      _circles = [
        // Main geofence circle
        CircleMarker(
          point: LatLng(geofence.latitude, geofence.longitude),
          color: Colors.yellow.withOpacity(0.1),
          borderColor: Colors.yellow.shade700,
          borderStrokeWidth: 3.0,
          radius: _geofenceRadius, // Use the radius value directly
          useRadiusInMeter:
              true, // This is important - tells the map to use meters!
        ),
        // Secondary circle for visual effect (optional)
        CircleMarker(
          point: LatLng(geofence.latitude, geofence.longitude),
          color: Colors.transparent,
          borderColor: Colors.yellow.withOpacity(0.3),
          borderStrokeWidth: 1.5,
          radius: _geofenceRadius * 0.98,
          useRadiusInMeter: true, // Use meters for radius
        ),
        // Center point indicator
        CircleMarker(
          point: LatLng(geofence.latitude, geofence.longitude),
          color: Colors.yellow.shade700.withOpacity(0.7),
          borderColor: Colors.white,
          borderStrokeWidth: 2.0,
          radius: 10.0, // Small fixed radius for center point (in pixels)
          useRadiusInMeter: false, // Don't use meters for this small indicator
        ),
      ];

      setState(() {});
    }
  }

  // Add a new method to animate to the geofence bounds
  void _fitGeofenceBounds() {
    if (_userLocation != null) {
      final geofenceService =
          Provider.of<GeofenceService>(context, listen: false);
      final geofence = geofenceService.currentGeofence;

      if (geofence != null) {
        // Calculate the bounds that would include the entire geofence circle
        final centerLat = geofence.latitude;
        final centerLng = geofence.longitude;
        final radiusInDegrees =
            geofence.radiusInMeters / 111000; // Rough conversion to degrees

        final southwest =
            LatLng(centerLat - radiusInDegrees, centerLng - radiusInDegrees);
        final northeast =
            LatLng(centerLat + radiusInDegrees, centerLng + radiusInDegrees);

        // Get the map bounds
        final bounds = LatLngBounds(southwest, northeast);

        // Set the map camera position to show the entire geofence
        final centerPoint = LatLng(centerLat, centerLng);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(
            padding: EdgeInsets.all(50.0),
            maxZoom: 17.0,
          ),
        );
      }
    }
  }

  Future<void> _loadOffersInGeofence({bool forceRefresh = false}) async {
    try {
      final geofenceService =
          Provider.of<GeofenceService>(context, listen: false);
      final result = await RecommendationService.getOffersInGeofence(
        geofenceService: geofenceService,
        forceRefresh: forceRefresh,
      );

      if (result['success'] == true) {
        final cachedResult = result['recommendations'];
        List<Offer> offers = (cachedResult as List)
            .map((offerJson) => Offer.fromJson(offerJson))
            .toList();

        // Check for new offers
        Set<String> currentOfferIds = offers.map((offer) => offer.id).toSet();
        Set<String> newOfferIds = currentOfferIds.difference(_previousOfferIds);

        print('DEBUG: Current offers: ${currentOfferIds.length}');
        print('DEBUG: Previous offers: ${_previousOfferIds.length}');
        print('DEBUG: New offers detected: ${newOfferIds.length}');

        // If there are new offers and we've already initialized
        if (newOfferIds.isNotEmpty && _previousOfferIds.isNotEmpty) {
          // Find the new offers
          List<Offer> newOffers =
              offers.where((offer) => newOfferIds.contains(offer.id)).toList();

          print(
              'DEBUG: New offers list: ${newOffers.map((o) => o.title).toList()}');

          // Create notifications for new offers
          _createNewOffersNotifications(newOffers);
        } else if (_previousOfferIds.isEmpty) {
          print('DEBUG: First load - not creating notifications');
        } else {
          print('DEBUG: No new offers to notify about');
        }

        // Update previous offers for next comparison
        _previousOfferIds = currentOfferIds;

        setState(() {
          _offers = offers;
        });

        // Add markers for each offer
        _markers = [];

        // Add user marker first

        // Add shop markers for each offer
        for (var offer in _offers) {
          if (offer.shop["location"]["coordinates"][0] != null &&
              offer.shop["location"]["coordinates"][1] != null) {
            _markers.add(
              Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(offer.shop["location"]["coordinates"][1],
                    offer.shop["location"]["coordinates"][0]),
                builder: (ctx) => GestureDetector(
                  onTap: () => _showOfferInfo(offer),
                  child: Image.asset('assets/images/shopLocationPin.png',
                      width: 30, height: 30),
                  // const Icon(
                  //   Icons.location_pin,
                  //   color: Colors.red,
                  //   size: 30.0,
                  // ),
                ),
              ),
            );
          }
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to get offers';
        });
      }

      setState(() {});
    } catch (e) {
      print('Error loading offers: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Method to create notifications for new offers
  void _createNewOffersNotifications(List<Offer> newOffers) async {
    if (newOffers.isEmpty) return;

    print('DEBUG: Creating notifications for ${newOffers.length} new offers');

    // Check if user is authenticated
    try {
      final box = Hive.box('authBox');
      final jwtToken = box.get('jwtToken');
      print('DEBUG: JWT Token exists: ${jwtToken != null}');

      if (jwtToken != null) {
        print(
            'DEBUG: JWT Token (first 20 chars): ${jwtToken.toString().substring(0, jwtToken.toString().length > 20 ? 20 : jwtToken.toString().length)}...');
      }

      // Check notification permissions
      final permissionGranted =
          await NotificationService.checkCurrentPermissionStatus();
      print('DEBUG: Notification permission granted: $permissionGranted');
    } catch (e) {
      print('DEBUG: Error checking JWT token or permissions: $e');
    }

    try {
      // For single offer notification
      if (newOffers.length == 1) {
        Offer offer = newOffers.first;
        String shopName = ShopCacheService.getShopNameById(offer.shopId,
            fallback: offer.shop!["name"] ?? 'Unknown Store');

        print(
            'DEBUG: Creating notification for offer: ${offer.title} at $shopName');

        // Use the notification service to create a notification via API
        bool success = await NotificationService.createNotification(
          title: 'New Offer Available',
          message: '${offer.title} at $shopName',
          type: NotificationType.offer,
          link: '/offers/${offer.id}',
          resourceId: offer.id, // Use offer ID as the resource ID
        );

        print('DEBUG: Notification creation result: $success');

        if (success) {
          // Play alarm sound for new offer notification
          await AudioService.playAlarm();
          print('DEBUG: Alarm sound played');
        } else {
          print('DEBUG: Failed to create notification');
        }
      }
      // For multiple offers notification
      else if (newOffers.length > 1) {
        print(
            'DEBUG: Creating notification for ${newOffers.length} multiple offers');

        bool success = await NotificationService.createNotification(
          title: 'New Offers Available',
          message: '${newOffers.length} new offers found in your area',
          type: NotificationType.offer,
          link: '/nearby-offers',
        );

        print('DEBUG: Multiple offers notification result: $success');

        if (success) {
          // Play alarm sound for multiple new offers
          await AudioService.playAlarm();
          print('DEBUG: Alarm sound played for multiple offers');
        } else {
          print('DEBUG: Failed to create notification for multiple offers');
        }
      }
    } catch (e) {
      print('Error creating notifications for new offers: $e');
    }
  }

  void _showOfferInfo(dynamic offer) {
    print('Showing info for offer: ${offer}');
    String title = offer.title?.toString() ?? 'No Title';
    String shopId = offer.shop['_id']?.toString() ?? '';

    String storeName = ShopCacheService.getShopNameById(shopId,
        fallback: offer.shop['name']?.toString() ?? 'Unknown Store');

    // Get shop object for additional details if available
    Shop? shop =
        shopId.isNotEmpty ? ShopCacheService.getShopById(shopId) : null;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              textAlign: TextAlign.center,
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Store: $storeName'),
            if (shop != null) ...[
              const SizedBox(height: 4),
              Text(shop.openingStatusText,
                  style: TextStyle(
                    color: shop.isOpenNow ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text(shop.address),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.of(context).size.width, 40),
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OfferView(offer: offer),
                  ),
                );
              },
              child: const Text('View Details'),
            )
          ],
        ),
      ),
    );
  }

  void _updateGeofenceRadius(double newRadius) async {
    final geofenceService =
        Provider.of<GeofenceService>(context, listen: false);
    geofenceService.updateGeofenceRadius(newRadius);
    _geofenceRadius = newRadius;

    // Save the new radius to local storage
    await SettingsCacheService.saveGeofenceRadius(newRadius);

    _updateMapCircle();
    await _loadOffersInGeofence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () async {
              // Force test new offer notification
              if (_offers.isNotEmpty) {
                print('DEBUG: Forcing new offer notification test...');
                final testOffer = _offers.first as Offer;
                _createNewOffersNotifications([testOffer]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Forced new offer notification test')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No offers available to test')),
                );
              }
            },
            tooltip: 'Test New Offer Notification',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitGeofenceBounds,
            tooltip: 'Show full geofence',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _userLocation == null
                          ? const Center(child: Text('Location not available'))
                          : Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    center: LatLng(
                                      _userLocation!.latitude,
                                      _userLocation!.longitude,
                                    ),
                                    zoom: 14.0,
                                    minZoom: 10.0,
                                    maxZoom: 18.0,
                                    // Add interactive flags for better user experience
                                    interactiveFlags: InteractiveFlag.all,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      subdomains: const ['a', 'b', 'c'],
                                      userAgentPackageName: 'com.closecart.app',
                                    ),
                                    // Use circle layer with correct radius values
                                    CircleLayer(circles: _circles),
                                    MarkerLayer(markers: _markers),
                                  ],
                                ),
                                // Add a debug overlay to show the current radius
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Radius: ${(_geofenceRadius / 1000).toStringAsFixed(1)} km',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geofence Radius: ${SettingsCacheService.metersToKm(_geofenceRadius).toStringAsFixed(1)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value: _geofenceRadius,
                            min: 100, // 0.1 km
                            max: 5000, // 5 km
                            divisions: 49,
                            label:
                                '${SettingsCacheService.metersToKm(_geofenceRadius).toStringAsFixed(1)} km',
                            onChanged: (value) {
                              _updateGeofenceRadius(value);
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            secondaryActiveColor: Colors.transparent,
                            inactiveColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _offers.isEmpty
                          ? const Center(
                              child: Text(
                                'No offers found within this radius.\nTry expanding your search area.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _offers.length,
                              itemBuilder: (context, index) {
                                final offer = _offers[index];

                                return OfferTile(offer: offer);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  // Add shimmer loading effect widget
  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Shimmer effect for map area
        Expanded(
          flex: 1,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        ),

        // Shimmer effect for slider area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 180,
                  height: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Shimmer effect for offer list area
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: 5, // Show a few placeholder items
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 150,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
