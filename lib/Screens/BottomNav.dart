import 'package:closecart/Screens/Favourite.dart';
import 'package:closecart/Screens/Search.dart';
import 'package:closecart/Screens/Settings.dart';
import 'package:closecart/Screens/home.dart';
import 'package:closecart/Util/colors.dart';
import 'package:closecart/Widgets/sidebar.dart';
import 'package:closecart/main.dart';
import 'package:closecart/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  static List<Widget> _pages = <Widget>[
    Home(),
    FavouritePage(),
    SearchPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Delay location fetch slightly to avoid issues during app startup
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _fetchUserLocation();
    });
  }

  @override
  void dispose() {
    // Ensure we're properly cleaning up any location resources
    super.dispose();
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

      Future.delayed(Duration(seconds: 5), () {
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
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
                  // Handle notification button press
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
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
