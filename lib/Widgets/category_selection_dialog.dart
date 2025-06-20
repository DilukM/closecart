import 'package:closecart/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CategorySelectionDialog extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selectedCategories;
  final Function(List<String>) onSave;
  final bool isLoading;

  const CategorySelectionDialog({
    Key? key,
    required this.allCategories,
    required this.selectedCategories,
    required this.onSave,
    this.isLoading = false,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required List<String> allCategories,
    required List<String> selectedCategories,
    required Function(List<String>) onSave,
    bool isLoading = false,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => CategorySelectionDialog(
        allCategories: allCategories,
        selectedCategories: selectedCategories,
        onSave: onSave,
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  late List<String> _tempSelectedCategories;
  bool _isSavingCategories = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedCategories = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Select Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),

            SizedBox(height: 4),

            Text(
              'Choose your preferred shopping categories',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),

            SizedBox(height: 24),

            // Categories content
            widget.isLoading || widget.allCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading categories...'),
                      ],
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: widget.allCategories.length,
                      itemBuilder: (context, index) {
                        final category = widget.allCategories[index];
                        final isSelected =
                            _tempSelectedCategories.contains(category);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildCategoryCard(category, isSelected, () {
                            setState(() {
                              if (isSelected) {
                                _tempSelectedCategories.remove(category);
                              } else {
                                _tempSelectedCategories.add(category);
                              }
                            });
                          }),
                        );
                      },
                    ),
                  ),

            SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                _isSavingCategories
                    ? Container(
                        margin: EdgeInsets.only(right: 8),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (_tempSelectedCategories.isEmpty) {
                            toastification.show(
                              context: context,
                              title:
                                  Text('Please select at least one category'),
                              type: ToastificationType.error,
                            );
                            return;
                          }

                          // Show saving indicator
                          setState(() {
                            _isSavingCategories = true;
                          });

                          try {
                            // Call the save callback
                            await widget.onSave(_tempSelectedCategories);

                            if (mounted) {
                              // Close dialog
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            // Error handling is done by the caller
                            print('Error in category dialog: $e');
                            setState(() {
                              _isSavingCategories = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          elevation: 1,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Save',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String category, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Category name
            Text(
              category,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
