import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:closecart/model/shopModel.dart';
import 'package:closecart/services/favoriteShopService.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class ShopView extends StatefulWidget {
  final String shopId;

  const ShopView({
    Key? key,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView>
    with SingleTickerProviderStateMixin {
  Shop? _shop;
  bool _isLoading = true;
  bool _isLikeLoading = false;
  bool _isFavorite = false;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkFavoriteStatus();

    // Initialize data loading without depending on Dio
    _fetchShopDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkFavoriteStatus() {
    setState(() {
      _isFavorite = FavoriteShopService.isFavorite(widget.shopId);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isLikeLoading) return;

    setState(() {
      _isLikeLoading = true;
    });

    try {
      final result = await FavoriteShopService.toggleFavorite(widget.shopId);

      if (result['success']) {
        setState(() {
          _isFavorite = result['isFavorite'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } finally {
      setState(() {
        _isLikeLoading = false;
      });
    }
  }

  Future<void> _fetchShopDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Use http package directly instead of Dio
      final url = Uri.parse(
          'https://closecart-backend.vercel.app/api/v1/shops/${widget.shopId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          final shopData = responseData['data'];

          setState(() {
            _shop = Shop.fromJson(shopData);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load shop details';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMap() async {
    if (_shop == null) return;

    final url =
        'https://www.google.com/maps/search/?api=1&query=${_shop!.location.latitude},${_shop!.location.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map')),
      );
    }
  }

  Future<void> _launchSocialMedia(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for cover image
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surface,
            highlightColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            child: Container(
              width: double.infinity,
              height: 200,
              color: Colors.white,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer for shop stats card
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Shimmer for shop header with logo
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Shop name and category
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Shimmer for description
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 24,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Shimmer for address card
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Shimmer for business hours card
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(color: Colors.red)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchShopDetails,
            child: Text('Try Again'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: _buildLoadingView());
    }

    if (_errorMessage.isNotEmpty || _shop == null) {
      return Scaffold(body: _buildErrorView());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: _isLikeLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                onPressed: _toggleFavorite,
                tooltip:
                    _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share functionality coming soon!')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _shop!.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _shop!.coverImage.isNotEmpty
                        ? _shop!.coverImage
                        : 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(Icons.store, size: 50),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop stats row
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.remove_red_eye,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(height: 4),
                            Text(
                              '${_shop!.visits}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Visits',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: 4),
                            Text(
                              _isFavorite ? 'Liked' : 'Like',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Shop',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.share,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(height: 4),
                            Text(
                              'Share',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Shop',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Shop header with logo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _shop!.logo.isNotEmpty
                            ? CachedNetworkImageProvider(_shop!.logo)
                            : null,
                        child: _shop!.logo.isEmpty
                            ? Text(
                                _shop!.name.isNotEmpty
                                    ? _shop!.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontSize: 24),
                              )
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shop!.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _shop!.isOpenNow
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _shop!.openingStatusText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Shop description
                  if (_shop!.description.isNotEmpty) ...[
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _shop!.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 16),
                  ],

                  // Address and location
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _shop!.address,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _launchMap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              child: Text('View on Map'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Business hours
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Hours',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          _buildBusinessHourRow(
                              'Monday', _shop!.businessHours.monday),
                          _buildBusinessHourRow(
                              'Tuesday', _shop!.businessHours.tuesday),
                          _buildBusinessHourRow(
                              'Wednesday', _shop!.businessHours.wednesday),
                          _buildBusinessHourRow(
                              'Thursday', _shop!.businessHours.thursday),
                          _buildBusinessHourRow(
                              'Friday', _shop!.businessHours.friday),
                          _buildBusinessHourRow(
                              'Saturday', _shop!.businessHours.saturday),
                          _buildBusinessHourRow(
                              'Sunday', _shop!.businessHours.sunday),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Social media links
                  if (_shop!.socialMediaLinks.isNotEmpty) ...[
                    Text(
                      'Follow Us',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (var entry in _shop!.socialMediaLinks.entries)
                          IconButton(
                            onPressed: () => _launchSocialMedia(entry.value),
                            icon: _getSocialMediaIcon(entry.key),
                            tooltip: entry.key,
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],

                  // Shop metrics
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetricColumn('Clicks', _shop!.clicks.toString(),
                              Icons.touch_app),
                          _buildMetricColumn('Visits', _shop!.visits.toString(),
                              Icons.visibility),
                          _buildMetricColumn(
                            'Since',
                            DateFormat('MMM yyyy').format(_shop!.createdAt),
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement contact functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.message),
                      label: Text('Contact Shop'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHourRow(String day, BusinessHours hours) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final isToday = day == dayOfWeek;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          Text(
            hours.isOpen ? '${hours.open} - ${hours.close}' : 'Closed',
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Icon _getSocialMediaIcon(String platform) {
    platform = platform.toLowerCase();

    if (platform.contains('facebook')) return Icon(Icons.facebook);
    if (platform.contains('instagram')) return Icon(Icons.camera_alt);
    if (platform.contains('twitter') || platform.contains('x.com'))
      return Icon(Icons.whatshot);
    if (platform.contains('linkedin')) return Icon(Icons.work);
    if (platform.contains('youtube')) return Icon(Icons.play_arrow);
    if (platform.contains('tiktok')) return Icon(Icons.music_note);
    if (platform.contains('website')) return Icon(Icons.language);

    return Icon(Icons.link);
  }
}
