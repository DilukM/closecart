# CloseCart 🛍️

A mobile application that helps users discover nearby shops and exclusive offers based on their location. Built with Flutter, CloseCart provides a seamless shopping experience with real-time location-based notifications, favorites management, and personalized recommendations.

## 📱 Features

### Core Features
- **Location-Based Discovery**: Find nearby shops and offers using GPS and geofencing technology
- **Real-Time Notifications**: Get notified when you're near shops with active offers
- **Offer Management**: Browse, search, and view detailed information about exclusive deals
- **Shop Information**: Access comprehensive shop details including location, contact info, and available offers
- **Favorites System**: Save your favorite offers and shops for quick access
- **Smart Search**: Quickly find specific shops or offers
- **Personalized Recommendations**: Get tailored suggestions based on your preferences

### Technical Features
- **Geofencing Service**: Automatic detection when entering shop proximity
- **Offline Caching**: Browse cached content even without internet connection
- **Image Caching**: Optimized image loading for better performance
- **Dark Mode Support**: System-adaptive theme with manual override
- **Audio Notifications**: Custom notification sounds for alerts
- **Error Tracking**: Integrated Sentry for crash reporting and monitoring

## 🛠️ Tech Stack

- **Framework**: Flutter 3.4.1+
- **State Management**: Provider
- **Local Storage**: Hive
- **Networking**: Dio with cache interceptor
- **Maps**: Flutter Map with LatLong2
- **Location Services**: Geolocator & Geocoding
- **Notifications**: Flutter Local Notifications
- **UI Components**: 
  - Cached Network Image
  - Shimmer loading effects
  - Lottie animations
  - Auto Size Text
  - Toastification
- **Error Tracking**: Sentry Flutter
- **Authentication**: JWT (Dart JSON Web Token)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (>=3.4.1 <4.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/DilukM/closecart.git
   cd closecart
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Android (if targeting Android)**
   - Update `android/key.properties` with your signing configuration
   - Ensure `android/local.properties` points to your Android SDK

4. **Configure iOS (if targeting iOS)**
   - Navigate to the `ios` folder
   - Run `pod install`

## ⚙️ Configuration

### 1. Sentry Configuration
Update the Sentry DSN in `lib/main.dart`:
```dart
options.dsn = 'your-sentry-dsn-here';
```

Or configure via `sentry.properties`:
```properties
defaults.project=your-project-name
defaults.org=your-org-name
```

### 2. API Configuration
Configure your backend API endpoints in the appropriate service files under `lib/services/`.

### 3. Location Permissions
Ensure location permissions are properly configured:
- **Android**: Check `android/app/src/main/AndroidManifest.xml`
- **iOS**: Check `ios/Runner/Info.plist`

## 🏃 Running the App

### Development Mode
```bash
flutter run
```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── Screens/                  # UI screens
│   ├── Auth/                # Authentication screens
│   ├── home.dart            # Home screen
│   ├── ShopView.dart        # Shop details
│   ├── OfferView.dart       # Offer details
│   ├── Favourite.dart       # Favorites screen
│   ├── Search.dart          # Search functionality
│   ├── Settings.dart        # App settings
│   └── notification_page.dart
├── services/                 # Business logic services
│   ├── authService.dart
│   ├── geofence_service.dart
│   ├── location_service.dart
│   ├── notificationService.dart
│   ├── cache_service.dart
│   ├── favoriteOfferService.dart
│   └── recommendationService.dart
├── Util/                     # Utilities and helpers
│   └── theme.dart
└── Widgets/                  # Reusable widgets
```

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `hive_flutter` | Local database |
| `dio` | HTTP client |
| `geolocator` | Location tracking |
| `flutter_map` | Map integration |
| `flutter_local_notifications` | Push notifications |
| `cached_network_image` | Image caching |
| `sentry_flutter` | Error tracking |
| `lottie` | Animations |
| `shimmer` | Loading effects |

## 🧪 Testing

Run tests using:
```bash
flutter test
```

Test files are located in the `test/` directory.

## 🔒 Security

- Uses JWT for secure authentication
- Implements secure token storage with Hive
- Network requests are cached securely
- Location data is handled according to privacy best practices

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS


*Note: Full functionality is optimized for mobile platforms (Android & iOS)*

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is private and proprietary. All rights reserved.

## 👥 Authors

**Your Team Name**

## 📞 Support

For support, please contact [dilukedu@gmail.com]

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All open-source contributors whose packages made this project possible

---

**Version**: 1.5.2  
**Last Updated**: February 2026
