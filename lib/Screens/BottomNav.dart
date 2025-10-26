import 'package:closecart/Screens/Favourite.dart';
import 'package:closecart/Screens/notification_page.dart';
import 'package:closecart/Screens/Search.dart';
import 'package:closecart/Screens/Settings.dart';
import 'package:closecart/Screens/geofence_offers_screen.dart';
import 'package:closecart/Screens/home.dart';
import 'package:closecart/Util/colors.dart';
import 'package:closecart/Widgets/sidebar.dart';
import 'package:closecart/main.dart';
import 'package:closecart/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Global key that can be accessed from anywhere in the app
final GlobalKey<_BottomNavState> bottomNavKey = GlobalKey<_BottomNavState>();

class BottomNav extends StatefulWidget {
  final int initialIndex;
  const BottomNav({super.key, this.initialIndex = 0});

  BottomNav.withIndex({super.key, required this.initialIndex});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _selectedIndex;
  String locationName = 'Fetching location...';
  bool isLoadingLocation = true;
  String? profileImageUrl;

  static final List<Widget> _pages = <Widget>[
    const Home(),
    const GeofenceOffersScreen(),
    const FavouritePage(),
    const SearchPage(),
    const SettingsPage(),
  ];

  // Method to change the selected index from outside
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
    _selectedIndex = widget.initialIndex;
    // Delay location fetch slightly to avoid issues during app startup
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fetchUserLocation();
    });
  }

  @override
  void dispose() {
    // Ensure we're properly cleaning up any location resources
    super.dispose();
  }

  Future<void> _getProfile() async {
    var box = Hive.box('authBox');
    var profile = box.get('profileData');
    profileImageUrl = profile != null
        ? profile['imageUrl']
        : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvj3m7aqQbQp6jX0EGDRWLGNok8H47-XZnfQ&s';
  }

  Future<void> _fetchUserLocation() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoadingLocation = true;
      });

      final userLocation = await LocationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        locationName = userLocation.placeName;
        isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        locationName = 'Location unavailable';
        isLoadingLocation = false;
      });

      print('Error fetching location: $e');

      // Optional: Add a retry mechanism after a delay

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && locationName == 'Location unavailable') {
          _fetchUserLocation();
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      drawer: ThemeDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isLoadingLocation ? 'Fetching location...' : 'Your Location',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Text(
                textAlign: TextAlign.center,
                isLoadingLocation ? '...' : locationName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
                onTap: () => setState(() {
                      _selectedIndex = 4;
                    }),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    profileImageUrl!,
                  ),
                )),
          ),
          // builder: (context) => IconButton(
          //   icon: const Icon(Icons.menu),

          //   onPressed: () => Scaffold.of(context).openDrawer(),
          // ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.primaryLight))),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: 20,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.location_pin,
                size: 20,
              ),
              label: 'Geofence',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.favorite,
                size: 20,
              ),
              label: 'Favourite',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                size: 20,
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings,
                size: 20,
              ),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_selectedIndex],
      ),
    );
  }
}
