import 'package:closecart/Widgets/offerCard.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:path_provider/path_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> offers = [];
  List<dynamic> filteredOffers = [];
  late Dio dio;
  String searchQuery = '';
  String sortOption = 'None';

  @override
  void initState() {
    super.initState();
    initializeDioAndFetchOffers();
  }

  Future<void> initializeDioAndFetchOffers() async {
    await initializeDio();
    await fetchOffers();
  }

  Future<void> initializeDio() async {
    final dir = await getApplicationDocumentsDirectory();
    dio = Dio()
      ..interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: HiveCacheStore(dir.path),
            policy: CachePolicy.refreshForceCache,
            maxStale: const Duration(days: 7),
            priority: CachePriority.high,
          ),
        ),
      );
  }

  Future<void> fetchOffers() async {
    try {
      final response = await dio.get(
        'https://closecart-backend.vercel.app/api/v1/offers/all',
        options: Options(extra: {'refresh': false}),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody != null && responseBody['data'] != null) {
          setState(() {
            offers = responseBody['data'];
            filteredOffers = offers;
          });
        } else {
          throw Exception('Offers data is null or missing');
        }
      } else {
        throw Exception('Failed to load offers');
      }
    } catch (e) {
      print('Error fetching offers: $e');
    }
  }

  void filterOffers(String query) {
    setState(() {
      searchQuery = query;
      filteredOffers = offers.where((offer) {
        final title = offer['title'].toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  void sortOffers(String option) {
    setState(() {
      sortOption = option;
      if (option == 'Discount') {
        filteredOffers.sort((a, b) => double.parse(b['discount'].toString())
            .compareTo(double.parse(a['discount'].toString())));
      } else if (option == 'Alphabetical') {
        filteredOffers.sort((a, b) => a['title'].compareTo(b['title']));
      }
    });
  }

  void showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sort by Discount'),
                onTap: () {
                  sortOffers('Discount');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Sort Alphabetically'),
                onTap: () {
                  sortOffers('Alphabetical');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    child: TextField(
                      onChanged: filterOffers,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        prefixIcon: Icon(Icons.search,
                            color: Theme.of(context).colorScheme.onSurface),
                        hintText: 'Find shops and offers...',
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
                  GestureDetector(
                    onTap: showFilterOptions,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.tune,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              filteredOffers.isEmpty
                  ? Shimmer.fromColors(
                      baseColor:
                          Theme.of(context).colorScheme.surface.withAlpha(20),
                      highlightColor: Theme.of(context).colorScheme.surface,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            height: 150,
                            width: double.infinity,
                          );
                        },
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 0.9,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredOffers.length,
                      itemBuilder: (context, index) {
                        final offer = filteredOffers[index];
                        return OfferCard(
                            imageUrl: offer['imageUrl'],
                            title: offer['title'],
                            rating: double.parse(offer['discount'].toString()));
                      },
                    ),
            ],
          ),
        )),
      ),
    );
  }
}
