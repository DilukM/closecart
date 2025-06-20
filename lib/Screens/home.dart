import 'package:closecart/Widgets/categoryItem.dart';
import 'package:closecart/Widgets/offerCard.dart';
import 'package:closecart/Widgets/sectionTile.dart';
import 'package:closecart/models/offer_model.dart';
import 'package:closecart/services/recommendationService.dart';
import 'package:closecart/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isInitialLoading = true; // For initial loading state
  bool _isBackgroundLoading = false; // For background refresh
  String? _currentCity;
  List<Offer> _recommendedOffers = [];
  String _errorMessage = '';
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    // Immediately load cached data
    _loadCachedRecommendations().then((_) {
      // Then fetch fresh data in background
      _loadRecommendations(backgroundRefresh: true);
    });
  }

  /// Load cached recommendations for immediate display
  Future<void> _loadCachedRecommendations() async {
    try {
      // Try to get cached location first
      var box = Hive.box('authBox');
      final cachedCity = box.get('lastKnownCity');
      if (cachedCity != null && mounted) {
        setState(() {
          _currentCity = cachedCity;
        });
      }

      // Try to get cached recommendations
      final cachedResult =
          RecommendationService.getCachedRecommendations(city: _currentCity);

      if (cachedResult['success'] == true && mounted) {
        // Convert raw JSON data to Offer objects
        List<Offer> offers = (cachedResult['recommendations'] as List)
            .map((offerJson) => Offer.fromJson(offerJson))
            .toList();

        setState(() {
          _recommendedOffers = offers;
          _isFromCache = true;
          _isInitialLoading = false; // No longer in initial loading state
        });
        print("Loaded ${_recommendedOffers.length} cached recommendations");
      } else {
        print("No cached recommendations found: ${cachedResult['message']}");
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _loadRecommendations(
      {bool forceRefresh = false, bool backgroundRefresh = false}) async {
    if (!mounted) return; // Don't proceed if widget is no longer in the tree

    try {
      if (backgroundRefresh && mounted) {
        setState(() {
          _isBackgroundLoading = true;
        });
      } else if (_recommendedOffers.isEmpty && mounted) {
        // Only show loading indicator if we have no data to display
        setState(() {
          _isInitialLoading = true;
        });
      }

      // Get the user's current city using the existing location service
      UserLocation location = await LocationService.getCurrentLocation();
      String currentCity = location.placeName;

      // Save city to cache for future use
      var box = Hive.box('authBox');
      box.put('lastKnownCity', currentCity);

      if (!mounted) return; // Check again before setState

      setState(() {
        _currentCity = currentCity;
      });

      print('Current city: $_currentCity');

      // Get recommendations based on the user's city
      final result = await RecommendationService.getRecommendations(
        city: _currentCity,
        forceRefresh: forceRefresh,
        backgroundRefresh: backgroundRefresh,
      );

      if (!mounted) return; // Check again before final setState

      setState(() {
        if (result['success'] == true) {
          // Convert raw JSON data to Offer objects
          _recommendedOffers = (result['recommendations'] as List)
              .map((offerJson) => Offer.fromJson(offerJson))
              .toList();

          _isFromCache = result['fromCache'] ?? false;
        } else if (!backgroundRefresh) {
          // Only show error messages for foreground refreshes
          _errorMessage = result['message'] ?? 'Failed to load recommendations';
        }
        _isInitialLoading = false;
        _isBackgroundLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Check before setState in catch block

      setState(() {
        if (!backgroundRefresh) {
          // Only show error messages for foreground refreshes
          _errorMessage = 'An error occurred: $e';
        }
        _isInitialLoading = false;
        _isBackgroundLoading = false;
      });
      print("Error loading recommendations: $e");
    }
  }

  Widget _buildFeaturedOffers() {
    if (_isInitialLoading && _recommendedOffers.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty && _recommendedOffers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRecommendations(forceRefresh: true),
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_recommendedOffers.isEmpty) {
      return Center(
        child: Text('No recommendations available'),
      );
    }

    // Remove container with fixed height and use GridView with shrinkWrap
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(), // Disable grid scrolling
      shrinkWrap: true, // Allow grid to size based on content
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 items per row
        childAspectRatio: 0.9, // Aspect ratio for each item
        crossAxisSpacing: 10, // Horizontal spacing
        mainAxisSpacing: 10, // Vertical spacing
      ),
      itemCount: _recommendedOffers.length,
      itemBuilder: (context, index) {
        final offer = _recommendedOffers[index];
        return OfferCard(offer: offer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: RefreshIndicator(
          onRefresh: () => _loadRecommendations(forceRefresh: true),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "What would you like to take a look at?",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: Icon(Icons.search,
                              color: Theme.of(context).colorScheme.onSurface),
                          hintText: 'Find for shops and offers...',
                          hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.tune,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              CategoryItem(
                                  label: 'Food',
                                  icon: Icons.fastfood,
                                  isSelected: true),
                              CategoryItem(label: 'Beauty', icon: Icons.brush),
                              CategoryItem(
                                  label: 'Fashion', icon: Icons.checkroom),
                              CategoryItem(label: 'Shoes', icon: Icons.style),
                              CategoryItem(label: 'Tech', icon: Icons.devices),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                SectionTitle(
                  title: 'Featured Offers',
                  onViewAll: () => _loadRecommendations(forceRefresh: true),
                ),
                SizedBox(height: 16),
                _buildFeaturedOffers(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
