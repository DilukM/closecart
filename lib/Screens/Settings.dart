import 'package:closecart/Screens/edit_profile.dart';
import 'package:closecart/services/authService.dart';
import 'package:closecart/services/notificationService.dart';
import 'package:closecart/services/preferences_service.dart';
import 'package:closecart/services/settings_cache_service.dart';
import 'package:closecart/widgets/category_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  bool _locationTrackingEnabled = true;
  double _geofenceRadius = 1.0; // Will be updated from cache (in kilometers)
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];
  final AuthService _authService = AuthService();
  Map<dynamic, dynamic>? _profileData;
  bool _notificationsLoading = false;
  bool _categoriesLoading = false;
  bool _isSavingCategories = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSettings();
    _loadCategories();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Safe setState that checks if the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _loadSettings() async {
    // Initialize settings cache
    await SettingsCacheService.init();

    // Load geofence radius (convert from meters to km for display)
    double radiusInMeters = SettingsCacheService.getGeofenceRadius();

    if (mounted) {
      setState(() {
        _geofenceRadius = SettingsCacheService.metersToKm(radiusInMeters);
      });
    }
  }

  Future<void> _loadProfileData() async {
    var box = Hive.box('authBox');
    var profileData = box.get('profileData');

    if (profileData == null) {
      // Fetch profile data from the backend
      profileData = await _authService.fetchProfileData();
    }
    print("Profile data loaded: $profileData");
    if (mounted) {
      setState(() {
        _profileData = profileData!;
      });
    }
  }

  Future<void> _loadCategories() async {
    _safeSetState(() {
      _categoriesLoading = true;
    });

    try {
      // Load all available categories
      final allCategories = await PreferencesService.getAllCategories();

      // Load user's selected categories
      final userCategories = await PreferencesService.getUserCategories();

      // Update state
      if (mounted) {
        setState(() {
          _allCategories = allCategories;
          _selectedCategories = userCategories;
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _categoriesLoading = false;
          // Use defaults if there's an error - fixed by using public methods
          _allCategories = PreferencesService.getDefaultCategories();
          _selectedCategories =
              PreferencesService.getDefaultSelectedCategories();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildSectionHeader(context, 'Profile'),
              const SizedBox(height: 16),
              _buildProfileCard(context),
              const SizedBox(height: 24),

              // Location Settings
              _buildSectionHeader(context, 'Location Settings'),
              const SizedBox(height: 16),
              _buildSettingsCard(
                context,
                [
                  _buildSwitchTile(
                    context,
                    'Location Tracking',
                    Icons.location_on_outlined,
                    _locationTrackingEnabled,
                    (value) {
                      setState(() {
                        _locationTrackingEnabled = value;
                      });
                    },
                  ),
                  _buildDivider(context),
                  _buildGeofenceRadiusSlider(context),
                ],
              ),
              const SizedBox(height: 24),
              // Preferences
              _buildSectionHeader(context, 'Preferences'),
              const SizedBox(height: 16),
              _buildSettingsCard(
                context,
                [
                  Consumer<NotificationPermissionProvider>(
                    builder: (context, provider, child) {
                      return _buildSwitchTile(
                        context,
                        'Push Notifications',
                        Icons.notifications_outlined,
                        provider.permissionGranted,
                        (value) async {
                          if (_notificationsLoading) return;

                          if (value) {
                            // If trying to enable notifications
                            setState(() => _notificationsLoading = true);
                            final granted = await NotificationService
                                .requestNotificationPermissions();
                            setState(() => _notificationsLoading = false);

                            if (!granted) {
                              // If permission request was denied, show settings dialog
                              _showNotificationSettingsDialog(context);
                            } else {
                              // Update the provider with new permission status
                              Provider.of<NotificationPermissionProvider>(
                                      context,
                                      listen: false)
                                  .permissionGranted = granted;
                            }
                          } else {
                            // If turning off, show settings dialog to guide user
                            _showNotificationSettingsDialog(context);
                          }
                        },
                        isLoading: _notificationsLoading,
                      );
                    },
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    'Preferred Categories',
                    Icons.category_outlined,
                    showTrailing: true,
                    onTap: () => _showCategoriesDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // Account Settings
              _buildSectionHeader(context, 'Account Settings'),
              const SizedBox(height: 16),
              _buildSettingsCard(
                context,
                [
                  _buildSettingsTile(
                    context,
                    'Change Password',
                    Icons.lock_outline,
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    'Logout',
                    Icons.logout,
                    iconColor: Theme.of(context).colorScheme.primary,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    'Delete Account',
                    Icons.delete_outline,
                    iconColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.error,
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),
                ],
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    if (_profileData == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                _profileData!['imageUrl'] != null
                    ? Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              _profileData!['imageUrl'],
                            ),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                const SizedBox(width: 20),
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileData!['name'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileData!['email'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_profileData!['phone']}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to edit profile page
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return EditProfilePage(profileData: _profileData);
                  }));
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  'EDIT PROFILE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    List<Widget> children,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    bool showTrailing = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ??
            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
      ),
      trailing: showTrailing
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool isLoading = false,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildGeofenceRadiusSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'Geofence Radius',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      value: _geofenceRadius,
                      min: 0.1,
                      max: 5.0,
                      divisions: 49,
                      label: "${_geofenceRadius.toStringAsFixed(1)} km",
                      onChanged: (value) {
                        setState(() {
                          _geofenceRadius = value;
                        });

                        // Save the new radius to local storage (convert to meters)
                        SettingsCacheService.saveGeofenceRadius(
                            SettingsCacheService.kmToMeters(_geofenceRadius));
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0.1 km',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          Text(
                            '2.5 km',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          Text(
                            '5.0 km',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      height: 1,
      indent: MediaQuery.of(context).size.width * 0.05,
      endIndent: MediaQuery.of(context).size.width * 0.05,
    );
  }

  // Dialog methods
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    void disposeControllers() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await _authService.changePassword(
                    _profileData!['email'],
                    currentPasswordController.text,
                    newPasswordController.text);
                print(response.statusCode);
                if (response.statusCode == 200) {
                  toastification.show(
                      autoCloseDuration: Duration(seconds: 3),
                      context: context,
                      title: Text(response.body),
                      type: ToastificationType.success);
                } else {
                  toastification.show(
                      autoCloseDuration: Duration(seconds: 3),
                      context: context,
                      title: Text(response.body),
                      type: ToastificationType.error);
                }
              } catch (err) {
                toastification.show(
                    autoCloseDuration: Duration(seconds: 3),
                    context: context,
                    title: Text('Failed to update password'),
                    description: Text(err.toString()),
                    type: ToastificationType.error);
              }

              disposeControllers();
              Navigator.of(context).pop();
              // Show success message
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Call the logout function to clear authentication data
              await _authService.logout();
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final passwordController = TextEditingController();

    void disposeController() {
      passwordController.dispose();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Text('Enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              disposeController();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement account deletion logic
              disposeController();
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    CategorySelectionDialog.show(
      context: context,
      allCategories: _allCategories,
      selectedCategories: _selectedCategories,
      isLoading: _categoriesLoading,
      onSave: (List<String> tempSelectedCategories) async {
        // Update categories via API
        final success = await PreferencesService.updateUserCategories(
            tempSelectedCategories);

        // Update local state
        if (mounted) {
          setState(() {
            _selectedCategories.clear();
            _selectedCategories.addAll(tempSelectedCategories);
          });
        }

        // Show confirmation
        if (context.mounted) {
          toastification.show(
            context: context,
            type:
                success ? ToastificationType.success : ToastificationType.info,
            title: Text(
                success ? 'Categories updated' : 'Categories saved locally'),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }

        return success;
      },
    );
  }

  // Show dialog when notification permissions need to be modified from device settings
  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notification Permissions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: const Text(
          'To change notification permissions, you need to update them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open device notification settings
              await NotificationService.openNotificationSettings();

              // Check permission status again after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              final permissionStatus =
                  await NotificationService.checkCurrentPermissionStatus();
              if (context.mounted) {
                Provider.of<NotificationPermissionProvider>(context,
                        listen: false)
                    .permissionGranted = permissionStatus;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
