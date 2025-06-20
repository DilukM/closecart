import 'package:closecart/Widgets/offerCard.dart';
import 'package:closecart/models/offer_model.dart';
import 'package:closecart/services/favoriteOfferService.dart';
import 'package:flutter/material.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  List<Offer> _favoriteOffers = [];
  bool _isLoading = true;
  bool _isBackgroundLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Load cached data immediately
    _loadCachedFavorites();
    // Then fetch fresh data in the background
    _fetchFavorites(backgroundRefresh: true);
  }

  /// Load cached favorites data
  void _loadCachedFavorites() {
    final cachedData = FavoriteOfferService
        .getCachedFavoriteOffers(); // Convert the cached map data to Offer objects
    List<Offer> offers =
        cachedData.map((offerJson) => Offer.fromJson(offerJson)).toList();

    if (mounted) {
      setState(() {
        _favoriteOffers = offers;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavorites({bool backgroundRefresh = false}) async {
    if (!mounted) return;

    if (backgroundRefresh) {
      setState(() {
        _isBackgroundLoading = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Get favorite offer data from service
      final favoriteOffersData = await FavoriteOfferService.fetchFavoriteOffers(
          backgroundRefresh: backgroundRefresh);

      // Convert the map data to Offer objects
      List<Offer> offers = favoriteOffersData;

      if (mounted) {
        setState(() {
          _favoriteOffers = offers;
          _isLoading = false;
          _isBackgroundLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBackgroundLoading = false;
          _errorMessage =
              backgroundRefresh ? '' : 'Failed to load favorites: $e';
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Items you favorite will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home or categories
              Navigator.of(context).pushNamed('/');
            },
            child: Text('Browse Offers'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteGrid() {
    if (_favoriteOffers.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _favoriteOffers.length,
      itemBuilder: (context, index) {
        // Pass the Offer object to the OfferCard
        return OfferCard(offer: _favoriteOffers[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchFavorites(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  )
                else if (_errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  _buildFavoriteGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
