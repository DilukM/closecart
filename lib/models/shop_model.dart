import 'package:flutter/foundation.dart';

class BusinessHours {
  final String open;
  final String close;
  final bool isOpen;

  const BusinessHours({
    this.open = '09:00',
    this.close = '17:00',
    this.isOpen = true,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      open: json['open'] ?? '09:00',
      close: json['close'] ?? '17:00',
      isOpen: json['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'isOpen': isOpen,
    };
  }

  @override
  String toString() =>
      'BusinessHours(open: $open, close: $close, isOpen: $isOpen)';
}

class WeeklyBusinessHours {
  final BusinessHours monday;
  final BusinessHours tuesday;
  final BusinessHours wednesday;
  final BusinessHours thursday;
  final BusinessHours friday;
  final BusinessHours saturday;
  final BusinessHours sunday;

  const WeeklyBusinessHours({
    this.monday = const BusinessHours(),
    this.tuesday = const BusinessHours(),
    this.wednesday = const BusinessHours(),
    this.thursday = const BusinessHours(),
    this.friday = const BusinessHours(),
    this.saturday = const BusinessHours(open: '10:00', close: '15:00'),
    this.sunday =
        const BusinessHours(open: '10:00', close: '15:00', isOpen: false),
  });

  factory WeeklyBusinessHours.fromJson(Map<String, dynamic> json) {
    return WeeklyBusinessHours(
      monday: json['monday'] != null
          ? BusinessHours.fromJson(json['monday'])
          : BusinessHours(),
      tuesday: json['tuesday'] != null
          ? BusinessHours.fromJson(json['tuesday'])
          : BusinessHours(),
      wednesday: json['wednesday'] != null
          ? BusinessHours.fromJson(json['wednesday'])
          : BusinessHours(),
      thursday: json['thursday'] != null
          ? BusinessHours.fromJson(json['thursday'])
          : BusinessHours(),
      friday: json['friday'] != null
          ? BusinessHours.fromJson(json['friday'])
          : BusinessHours(),
      saturday: json['saturday'] != null
          ? BusinessHours.fromJson(json['saturday'])
          : BusinessHours(open: '10:00', close: '15:00'),
      sunday: json['sunday'] != null
          ? BusinessHours.fromJson(json['sunday'])
          : BusinessHours(open: '10:00', close: '15:00', isOpen: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }

  BusinessHours getForDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return monday;
    }
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  const Location({
    this.type = 'Point',
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] ?? [0.0, 0.0];
    return Location(
      type: json['type'] ?? 'Point',
      coordinates: coords is List
          ? List<double>.from(coords.map((x) => x.toDouble()))
          : [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
  double get longitude => coordinates.length > 0 ? coordinates[0] : 0.0;

  @override
  String toString() => 'Location(type: $type, coordinates: $coordinates)';
}

class Shop {
  final String id;
  final String name;
  final String description;
  final String address;
  final String category;
  final Location location;
  final Map<String, String> socialMediaLinks;
  final String coverImage;
  final String logo;
  final WeeklyBusinessHours businessHours;
  final int clicks;
  final int visits;
  final DateTime createdAt;

  static const List<String> validCategories = [
    "Food",
    "Retail",
    "Hotels & Accommodation",
    "Travel & Transport",
    "Banks",
    "Online",
    "Services",
    "Entertainment",
    "Health",
    "Beauty",
    "Electronics",
    "Fashion",
    "Other",
  ];

  Shop({
    required this.id,
    required this.name,
    this.description = '',
    required this.address,
    required this.category,
    required this.location,
    this.socialMediaLinks = const {},
    this.coverImage = '',
    this.logo = '',
    this.businessHours = const WeeklyBusinessHours(),
    this.clicks = 0,
    this.visits = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Shop.fromJson(Map<String, dynamic> json) {
    Map<String, String> socialLinks = {};

    if (json['socialMediaLinks'] != null) {
      final links = json['socialMediaLinks'];
      if (links is Map) {
        links.forEach((key, value) {
          socialLinks[key.toString()] = value.toString();
        });
      }
    }

    return Shop(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Shop',
      description: json['description'] ?? '',
      address: json['address'] ?? 'No address provided',
      category: json['category'] ?? 'Other',
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : Location(coordinates: [0.0, 0.0]),
      socialMediaLinks: socialLinks,
      coverImage: json['coverImage'] ?? '',
      logo: json['logo'] ?? '',
      businessHours: json['businessHours'] != null
          ? WeeklyBusinessHours.fromJson(json['businessHours'])
          : WeeklyBusinessHours(),
      clicks: json['clicks'] ?? 0,
      visits: json['visits'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'address': address,
      'category': category,
      'location': location.toJson(),
      'socialMediaLinks': socialMediaLinks,
      'coverImage': coverImage,
      'logo': logo,
      'businessHours': businessHours.toJson(),
      'clicks': clicks,
      'visits': visits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isOpenNow {
    final now = DateTime.now();
    final today = businessHours.getForDay(now.weekday);

    if (!today.isOpen) return false;

    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(today.open) >= 0 &&
        currentTime.compareTo(today.close) < 0;
  }

  String get openingStatusText {
    if (isOpenNow) {
      return 'Open Now';
    } else {
      final now = DateTime.now();
      final today = businessHours.getForDay(now.weekday);

      if (!today.isOpen) {
        // Find the next open day
        int checkDay = now.weekday + 1;
        bool foundOpenDay = false;
        BusinessHours nextOpenDay = today;

        for (int i = 0; i < 7; i++) {
          if (checkDay > 7) checkDay = 1; // Wrap around to Monday
          final dayToCheck = businessHours.getForDay(checkDay);

          if (dayToCheck.isOpen) {
            nextOpenDay = dayToCheck;
            foundOpenDay = true;
            break;
          }
          checkDay++;
        }

        if (foundOpenDay) {
          final dayNames = [
            '',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ];
          return 'Closed today, opens ${dayNames[checkDay]} at ${nextOpenDay.open}';
        } else {
          return 'Temporarily closed';
        }
      } else {
        // Today is open but currently closed
        final currentTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        if (currentTime.compareTo(today.open) < 0) {
          return 'Opens today at ${today.open}';
        } else {
          return 'Closed, opens tomorrow at ${businessHours.getForDay(now.weekday == 7 ? 1 : now.weekday + 1).open}';
        }
      }
    }
  }

  @override
  String toString() => 'Shop(id: $id, name: $name, category: $category)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
