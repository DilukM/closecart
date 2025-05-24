import 'package:cached_network_image/cached_network_image.dart';
import 'package:closecart/Screens/OfferView.dart';
import 'package:closecart/model/offerModel.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OfferTile extends StatelessWidget {
  final Offer offer;

  const OfferTile({
    Key? key,
    required this.offer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfferView(offer: offer),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section (left)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 120,
                height: 110,
                child: Stack(
                  children: [
                    // Offer image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: offer.imageUrl ?? '',
                        fit: BoxFit.cover,
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
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                    // Discount badge
                    if (offer.discount > 0)
                      Positioned(
                        top: 8,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 202, 19, 6),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${offer.discount.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content section (right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      offer.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Shop name
                    Text(
                      offer.shop != null && offer.shop!['name'] != null
                          ? offer.shop!['name']
                          : offer.shopId ?? 'Unknown Shop',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              offer.rating?.toString() ?? '0',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
