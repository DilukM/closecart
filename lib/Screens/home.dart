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

class _HomeState extends State<Home> with TickerProviderStateMixin {
  bool _isInitialLoading = true; // For initial loading state
  bool _isBackgroundLoading = false; // For background refresh
  String? _currentCity;
  List<Offer> _recommendedOffers = [];
  String _errorMessage = '';
  bool _isFromCache = false;
  PageController _heroController = PageController();
  int _currentHeroIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    // Start auto-sliding immediately with promotional content
    _startAutoSlide();

    // Load cached data and fetch fresh data in background
    _loadCachedRecommendations().then((_) {
      _loadRecommendations(backgroundRefresh: true);
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    // Always start auto-slide with promotional content (5 slides)
    Future.delayed(Duration(seconds: 4), () {
      if (mounted && _heroController.hasClients) {
        int nextIndex = (_currentHeroIndex + 1) % 5; // 5 promotional slides
        _heroController.animateToPage(
          nextIndex,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startAutoSlide(); // Continue the loop
      }
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

  Widget _buildHeroSection() {
    // Promotional slides for the platform
    List<Map<String, dynamic>> promoSlides = [
      {
        'title': 'Discover Local Deals',
        'subtitle': 'Find amazing offers near you',
        'icon': Icons.location_on,
        'gradient': [Colors.blue.shade400, Colors.purple.shade400],
        'imageUrl':
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'description':
            'Explore exclusive deals from local businesses around your area'
      },
      {
        'title': 'Save More, Spend Less',
        'subtitle': 'Up to 70% off on your favorites',
        'icon': Icons.savings,
        'gradient': [Colors.green.shade400, Colors.teal.shade400],
        'imageUrl':
            'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'description': 'Unbeatable discounts on food, fashion, tech and more'
      },
      {
        'title': 'Quick & Easy Shopping',
        'subtitle': 'Shop with just a few taps',
        'icon': Icons.flash_on,
        'gradient': [Colors.orange.shade400, Colors.red.shade400],
        'imageUrl':
            'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'description':
            'Browse, compare and buy from your favorite stores instantly'
      },
      {
        'title': 'Personalized for You',
        'subtitle': 'Curated deals based on your preferences',
        'icon': Icons.favorite,
        'gradient': [Colors.pink.shade400, Colors.purple.shade400],
        'imageUrl':
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'description': 'AI-powered recommendations just for your taste'
      },
      {
        'title': 'Join CloseCart Today',
        'subtitle': 'Start your smart shopping journey',
        'icon': Icons.star,
        'gradient': [Colors.indigo.shade400, Colors.blue.shade400],
        'imageUrl':
            'https://images.unsplash.com/photo-1472851294608-062f824d29cc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'description': 'Experience the future of local shopping with CloseCart'
      },
    ];

    return Container(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroController,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
            },
            itemCount: promoSlides.length,
            itemBuilder: (context, index) {
              final slide = promoSlides[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image with fallback gradient
                      Image.network(
                        slide['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: slide['gradient'],
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: slide['gradient'],
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    slide['icon'],
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    slide['title'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              slide['subtitle'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              slide['description'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Action button/indicator
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Enhanced page indicators
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promoSlides.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: _currentHeroIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentHeroIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                _buildHeroSection(),
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
