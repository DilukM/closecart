import 'package:cached_network_image/cached_network_image.dart';
import 'package:closecart/Screens/OfferView.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OfferCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final double rating;

  const OfferCard(
      {required this.imageUrl, required this.title, required this.rating});

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  @override
  Widget build(BuildContext context) {
    bool isFavourite = false;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OfferView(
              // imageUrl: imageUrl,
              // title: title,
              // rating: rating,
              ),
        ));
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor:
                      Theme.of(context).colorScheme.primary.withAlpha(10),
                  highlightColor: Theme.of(context).colorScheme.surface,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    height: 150,
                    width: double.infinity,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.rating} ★',
                          style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Theme.of(context).colorScheme.primary),
                      )
                    ],
                  ),
                  Text(widget.title,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
