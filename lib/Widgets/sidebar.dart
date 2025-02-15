import 'package:closecart/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Theme Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: themeProvider.currentTheme == "System Default"
                ? Icon(Icons.brightness_auto)
                : themeProvider.currentTheme == "Light Theme"
                    ? Icon(Icons.light_mode)
                    : Icon(Icons.dark_mode),
            title: Text(themeProvider.currentTheme),
            onTap: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
