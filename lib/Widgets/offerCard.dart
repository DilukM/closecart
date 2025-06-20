import 'package:cached_network_image/cached_network_image.dart';
import 'package:closecart/Screens/OfferView.dart';
import 'package:closecart/models/offer_model.dart';
import 'package:closecart/models/shop_model.dart';
import 'package:closecart/services/shop_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OfferCard extends StatefulWidget {
  final Offer offer;

  const OfferCard({
    Key? key,
    required this.offer,
  }) : super(key: key);

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  Shop? _shopDetails;
  bool _isLoadingShop = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    if (widget.offer.shopId != null) {
      String? shopId;
      if (widget.offer.shopId is String) {
        shopId = widget.offer.shopId;
      } else if (widget.offer.shop is Map &&
          widget.offer.shop!['_id'] != null) {
        shopId = widget.offer.shop!['_id'];
      }

      if (shopId != null && shopId.isNotEmpty) {
        setState(() {
          _isLoadingShop = true;
        });

        try {
          final Shop? shop = await ShopCacheService.fetchShopById(shopId);
          if (mounted) {
            setState(() {
              _shopDetails = shop;
              _isLoadingShop = false;
            });
          }
        } catch (e) {
          print('Error loading shop details: $e');
          if (mounted) {
            setState(() {
              _isLoadingShop = false;
            });
          }
        }
      }
    }
  }

  /// Get shop details from cache or state
  Shop? getShopDetails() {
    // Return the shop if already loaded
    if (_shopDetails != null) {
      return _shopDetails;
    }

    // Try synchronous cache lookup as fallback
    if (widget.offer.shopId != null) {
      String? shopId;
      if (widget.offer.shopId is String) {
        shopId = widget.offer.shopId;
      } else if (widget.offer.shop is Map &&
          widget.offer.shop!['_id'] != null) {
        shopId = widget.offer.shop!['_id'];
      }

      if (shopId != null && shopId.isNotEmpty) {
        return ShopCacheService.getShopById(shopId);
      }
    }

    return null;
  }

  /// Get shop name with fallback
  String getShopName() {
    final Shop? shop = getShopDetails();

    if (shop != null) {
      return shop.name;
    }

    // If we have shop data in the offer
    if (widget.offer.shop != null) {
      if (widget.offer.shop is String) {
        return ShopCacheService.getShopNameById(widget.offer.shop as String,
            fallback: 'Unknown Shop');
      } else if (widget.offer.shop is Map &&
          widget.offer.shop!['name'] != null) {
        return widget.offer.shop!['name'].toString();
      }
    }

    return 'Unknown Shop name 2';
  }

  /// Check if shop is open now
  bool isShopOpen() {
    final shop = getShopDetails();
    return shop?.isOpenNow ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Get shop information
    final shopName = getShopName();
    final shop = getShopDetails();
    final isOpen = shop?.isOpenNow ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferView(offer: widget.offer),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Offer image
                AspectRatio(
                  aspectRatio: 1.5,
                  child: CachedNetworkImage(
                    imageUrl: widget.offer.imageUrl,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                // Discount badge if applicable
                if (widget.offer.discount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 202, 19, 6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.offer.discount}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Shop open status badge if available
                if (shop != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOpen ? 'Open' : 'Closed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.offer.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _isLoadingShop
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 14,
                                  width: 100,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                shopName,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 2),
                          Text(
                            widget.offer.rating.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
