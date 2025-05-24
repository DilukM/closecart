import 'package:cached_network_image/cached_network_image.dart';
import 'package:closecart/Screens/OfferView.dart';
import 'package:closecart/model/offerModel.dart';
import 'package:closecart/model/shopModel.dart';
import 'package:closecart/services/shop_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;

  const OfferCard({
    Key? key,
    required this.offer,
  }) : super(key: key);

  /// Get shop details from cache service or from the offer
  Shop? getShopDetails() {
    // First try to get shop details from the cache if we have a shop ID
    if (offer.shopId != null) {
      String? shopId;
      if (offer.shopId is String) {
        shopId = offer.shopId;
      } else if (offer.shop is Map && offer.shop!['_id'] != null) {
        shopId = offer.shop!['_id'];
      }

      if (shopId != null && shopId.isNotEmpty) {
        final Shop? cachedShop = ShopCacheService.getShopById(shopId);
        if (cachedShop != null) {
          return cachedShop;
        }
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
    if (offer.shop != null) {
      if (offer.shop is String) {
        return ShopCacheService.getShopNameById(offer.shop as String,
            fallback: 'Unknown Shop');
      } else if (offer.shop is Map && offer.shop!['name'] != null) {
        return offer.shop!['name'].toString();
      }
    }

    return 'Unknown Shop';
  }

  /// Check if shop is open now
  bool isShopOpen() {
    final shop = getShopDetails();
    return shop?.isOpenNow ?? false;
  }

  @override
  Widget build(BuildContext context) {
    print("Recieved Offer: ${offer}");
    // Get shop information
    final shopName = getShopName();
    final shop = getShopDetails();
    final isOpen = shop?.isOpenNow ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferView(offer: offer),
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
                    imageUrl: offer.imageUrl,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.surface,
                      highlightColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                // Discount badge if applicable
                if (offer.discount > 0)
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
                        '${offer.discount}% OFF',
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
                    offer.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
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
                            offer.rating.toString(),
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
