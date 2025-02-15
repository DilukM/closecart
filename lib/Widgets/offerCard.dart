import 'package:closecart/Screens/OfferView.dart';
import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double rating;

  const OfferCard(
      {required this.imageUrl, required this.title, required this.rating});

  @override
  Widget build(BuildContext context) {
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
              child: Image.network(imageUrl,
                  height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$rating ★',
                          style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.favorite_border,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
