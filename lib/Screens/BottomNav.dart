import 'package:closecart/Screens/Favourite.dart';
import 'package:closecart/Screens/Search.dart';
import 'package:closecart/Screens/Settings.dart';
import 'package:closecart/Screens/home.dart';
import 'package:closecart/Util/colors.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;
  const BottomNav({super.key, this.initialIndex = 0});

  BottomNav.withIndex({super.key, required this.initialIndex});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _selectedIndex;

  static List<Widget> _pages = <Widget>[
    Home(),
    SearchPage(),
    FavouritePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              label: 'Program',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                size: 20,
              ),
              label: 'Ai',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 20,
              ),
              label: 'Stats',
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
