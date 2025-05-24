import 'package:closecart/Widgets/offerTile.dart';
import 'package:closecart/model/offerModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:closecart/services/location_service.dart';
import 'package:closecart/services/geofence_service.dart';
import 'package:closecart/services/recommendationService.dart';
import 'package:closecart/services/shop_cache_service.dart';
import 'package:closecart/model/shopModel.dart';

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
  UserLocation? _userLocation;
  MapController _mapController = MapController();
  double _geofenceRadius = 1000.0; // Default radius in meters
  List<CircleMarker> _circles = [];
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initialize();
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

  void _updateMapCircle() {
    final geofenceService =
        Provider.of<GeofenceService>(context, listen: false);
    final geofence = geofenceService.currentGeofence;

    if (geofence != null && _userLocation != null) {
      _circles = [
        CircleMarker(
          point: LatLng(geofence.latitude, geofence.longitude),
          color: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderStrokeWidth: 2.0,
          radius: geofence.radiusInMeters,
        ),
      ];

      setState(() {});
    }
  }

  Future<void> _loadOffersInGeofence() async {
    try {
      final geofenceService =
          Provider.of<GeofenceService>(context, listen: false);
      final result = await RecommendationService.getOffersInGeofence(
        geofenceService: geofenceService,
        forceRefresh: false,
      );

      if (result['success'] == true) {
        final cachedResult = result['recommendations'];
        List<Offer> offers = (cachedResult as List)
            .map((offerJson) => Offer.fromJson(offerJson))
            .toList();

        setState(() {
          _offers = offers;
        });
        // Add markers for each offer
        _markers = [];

        // Add user marker first
        if (_userLocation != null) {
          _markers.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
              builder: (ctx) => const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30.0,
              ),
            ),
          );
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

  void _showOfferInfo(dynamic offer) {
    String title = offer['title']?.toString() ?? 'No Title';
    String shopId = offer['shop']?.toString() ?? '';

    String storeName = ShopCacheService.getShopNameById(shopId,
        fallback: offer['name']?.toString() ?? 'Unknown Store');

    // Get shop object for additional details if available
    Shop? shop =
        shopId.isNotEmpty ? ShopCacheService.getShopById(shopId) : null;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
              onPressed: () {
                Navigator.pop(context);
                // Navigate to offer details if needed
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
            icon: const Icon(Icons.refresh),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: LatLng(
                                  _userLocation!.latitude,
                                  _userLocation!.longitude,
                                ),
                                zoom: 14.0,
                                minZoom: 10.0,
                                maxZoom: 18.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.closecart.app',
                                ),
                                CircleLayer(circles: _circles),
                                MarkerLayer(markers: _markers),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geofence Radius: ${(_geofenceRadius / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value: _geofenceRadius,
                            min: 100,
                            max: 5000,
                            divisions: 49,
                            label:
                                '${(_geofenceRadius / 1000).toStringAsFixed(1)} km',
                            onChanged: (value) {
                              _updateGeofenceRadius(value);
                            },
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
                                print("Offer at end $_offers");
                                return OfferTile(offer: offer);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
