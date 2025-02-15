import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const CategoryItem({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.15,
        height: MediaQuery.of(context).size.width * 0.25,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  isSelected ? EdgeInsets.only(top: 8.0) : EdgeInsets.all(0),
              child: CircleAvatar(
                radius: isSelected
                    ? MediaQuery.of(context).size.width * 0.06
                    : MediaQuery.of(context).size.width * 0.07,
                backgroundColor: Colors.white,
                child: Icon(icon, color: Colors.black),
              ),
            ),
            SizedBox(height: 8),
            AutoSizeText(
              maxFontSize: 16,
              minFontSize: 8,
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
