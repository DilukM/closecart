import 'package:closecart/Widgets/categoryItem.dart';
import 'package:closecart/Widgets/offerCard.dart';
import 'package:closecart/Widgets/sectionTile.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
              SectionTitle(title: 'Featured Offers', onViewAll: () {}),
              SizedBox(height: 16),
              Container(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    OfferCard(
                        imageUrl:
                            'https://www.foodiesfeed.com/wp-content/uploads/2023/06/burger-with-melted-cheese.jpg',
                        title: 'McDonald\'s',
                        rating: 4.5),
                    OfferCard(
                        imageUrl:
                            'https://www.foodiesfeed.com/wp-content/uploads/2023/06/burger-with-melted-cheese.jpg',
                        title: 'Starbucks',
                        rating: 4.7),
                    OfferCard(
                        imageUrl:
                            'https://www.foodiesfeed.com/wp-content/uploads/2023/06/burger-with-melted-cheese.jpg',
                        title: 'Starbucks',
                        rating: 4.7),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
