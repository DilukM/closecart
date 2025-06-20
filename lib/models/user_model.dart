class UserModel {
  final String id;
  final String name;
  final String email;
  final int? phone;
  final String? googleId;
  final String gender;
  final DateTime? birthday;
  final List<String> favoriteShops;
  final List<String> likedShops;
  final List<String> likedOffers;
  final List<String> interestedCategories;
  final List<String> interestedTags;
  final List<String> locationHistory;
  final String? imageUrl;
  final DateTime createdAt;

  // Constructor
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.googleId,
    this.gender = 'Other',
    this.birthday,
    required this.favoriteShops,
    required this.likedShops,
    required this.likedOffers,
    required this.interestedCategories,
    required this.interestedTags,
    required this.locationHistory,
    this.imageUrl,
    required this.createdAt,
  });

  // Create a copy of the user with updated values
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? phone,
    String? googleId,
    String? gender,
    DateTime? birthday,
    List<String>? favoriteShops,
    List<String>? likedShops,
    List<String>? likedOffers,
    List<String>? interestedCategories,
    List<String>? interestedTags,
    List<String>? locationHistory,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      googleId: googleId ?? this.googleId,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      favoriteShops: favoriteShops ?? this.favoriteShops,
      likedShops: likedShops ?? this.likedShops,
      likedOffers: likedOffers ?? this.likedOffers,
      interestedCategories: interestedCategories ?? this.interestedCategories,
      interestedTags: interestedTags ?? this.interestedTags,
      locationHistory: locationHistory ?? this.locationHistory,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert a JSON object into a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      googleId: json['googleId'],
      gender: json['gender'] ?? 'Other',
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      favoriteShops: _convertListToStringList(json['favoriteShops'] ?? []),
      likedShops: _convertListToStringList(json['likedShops'] ?? []),
      likedOffers: _convertListToStringList(json['likedOffers'] ?? []),
      interestedCategories:
          _convertListToStringList(json['interestedCategories'] ?? []),
      interestedTags: _convertListToStringList(json['interestedTags'] ?? []),
      locationHistory: _convertListToStringList(json['locationHistory'] ?? []),
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Helper method to convert a list of dynamic objects to strings
  static List<String> _convertListToStringList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return item;
      } else if (item is Map) {
        return item['_id']?.toString() ?? '';
      }
      return item.toString();
    }).toList();
  }

  // Convert a UserModel into a JSON object
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'googleId': googleId,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'favoriteShops': favoriteShops,
      'likedShops': likedShops,
      'likedOffers': likedOffers,
      'interestedCategories': interestedCategories,
      'interestedTags': interestedTags,
      'locationHistory': locationHistory,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Get user preferences as a map for API requests
  Map<String, dynamic> getPreferences() {
    return {
      'interestedCategories': interestedCategories,
      'interestedTags': interestedTags,
    };
  }

  // Check if user has completed their profile
  bool hasCompleteProfile() {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        phone != null &&
        interestedCategories.isNotEmpty;
  }

  // Convert to map for Hive storage
  Map<String, dynamic> toMap() => toJson();

  // Create user from Hive storage map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email)';
  }
}

// User gender enum for type safety
enum UserGender { male, female, other }

// Extension for converting enum to string and back
extension UserGenderExtension on UserGender {
  String get value {
    switch (this) {
      case UserGender.male:
        return 'Male';
      case UserGender.female:
        return 'Female';
      case UserGender.other:
        return 'Other';
    }
  }

  static UserGender fromString(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return UserGender.other;
    }
  }
}
