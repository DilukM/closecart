import 'package:flutter_test/flutter_test.dart';
import 'package:closecart/models/user_model.dart';

void main() {
  group('UserModel', () {
    late UserModel testUser;

    setUp(() {
      testUser = UserModel(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: 1234567890,
        gender: 'Male',
        birthday: DateTime(1990, 1, 1),
        favoriteShops: ['shop1', 'shop2'],
        likedShops: ['shop3'],
        likedOffers: ['offer1'],
        interestedCategories: ['electronics', 'clothing'],
        interestedTags: ['tech', 'fashion'],
        locationHistory: ['location1'],
        imageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime(2023, 1, 1),
      );
    });

    test('should create a UserModel instance', () {
      expect(testUser, isA<UserModel>());
      expect(testUser.id, '123');
      expect(testUser.name, 'John Doe');
      expect(testUser.email, 'john@example.com');
      expect(testUser.phone, 1234567890);
      expect(testUser.gender, 'Male');
      expect(testUser.favoriteShops, ['shop1', 'shop2']);
    });

    test('should create UserModel from JSON', () {
      final json = {
        '_id': '123',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': 9876543210,
        'gender': 'Female',
        'birthday': '1995-05-15T00:00:00.000Z',
        'favoriteShops': ['shop1'],
        'likedShops': [],
        'likedOffers': [],
        'interestedCategories': ['food'],
        'interestedTags': ['healthy'],
        'locationHistory': [],
        'imageUrl': 'https://example.com/jane.jpg',
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(user.phone, 9876543210);
      expect(user.gender, 'Female');
      expect(user.birthday, DateTime.parse('1995-05-15T00:00:00.000Z'));
      expect(user.favoriteShops, ['shop1']);
      expect(user.interestedCategories, ['food']);
    });

    test('should convert UserModel to JSON', () {
      final json = testUser.toJson();

      expect(json['_id'], '123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['phone'], 1234567890);
      expect(json['gender'], 'Male');
      expect(json['favoriteShops'], ['shop1', 'shop2']);
      expect(json['interestedCategories'], ['electronics', 'clothing']);
    });

    test('should create a copy with updated values', () {
      final updatedUser = testUser.copyWith(
        name: 'John Smith',
        email: 'johnsmith@example.com',
      );

      expect(updatedUser.name, 'John Smith');
      expect(updatedUser.email, 'johnsmith@example.com');
      expect(updatedUser.id, '123'); // unchanged
      expect(updatedUser.phone, 1234567890); // unchanged
    });

    test('should get user preferences', () {
      final preferences = testUser.getPreferences();

      expect(preferences['interestedCategories'], ['electronics', 'clothing']);
      expect(preferences['interestedTags'], ['tech', 'fashion']);
    });

    test('should check if user has complete profile', () {
      expect(testUser.hasCompleteProfile(), true);

      final incompleteUser = UserModel(
        id: '456',
        name: '',
        email: 'test@example.com',
        favoriteShops: [],
        likedShops: [],
        likedOffers: [],
        interestedCategories: [],
        interestedTags: [],
        locationHistory: [],
        createdAt: DateTime.now(),
      );

      expect(incompleteUser.hasCompleteProfile(), false);
    });

    test('should handle null values in fromJson', () {
      final json = {
        '_id': '789',
        'name': 'Test User',
        'email': 'test@example.com',
        // phone is null
        // birthday is null
        // other fields are null or empty
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '789');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.phone, null);
      expect(user.birthday, null);
      expect(user.gender, 'Other'); // default value
      expect(user.favoriteShops, []);
      expect(user.likedShops, []);
    });

    test('should convert list to string list correctly', () {
      final json = {
        '_id': '789',
        'name': 'Test User',
        'email': 'test@example.com',
        'favoriteShops': [
          'shop1',
          {'_id': 'shop2', 'name': 'Shop 2'},
          123,
        ],
        'likedShops': [],
        'likedOffers': [],
        'interestedCategories': [],
        'interestedTags': [],
        'locationHistory': [],
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.favoriteShops, ['shop1', 'shop2', '123']);
    });

    test('should convert to map for Hive storage', () {
      final map = testUser.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['_id'], '123');
      expect(map['name'], 'John Doe');
    });

    test('should create user from map', () {
      final map = testUser.toMap();
      final user = UserModel.fromMap(map);

      expect(user.id, testUser.id);
      expect(user.name, testUser.name);
      expect(user.email, testUser.email);
    });

    test('should have proper toString representation', () {
      final stringRep = testUser.toString();
      expect(stringRep, contains('UserModel'));
      expect(stringRep, contains('123'));
      expect(stringRep, contains('John Doe'));
      expect(stringRep, contains('john@example.com'));
    });
  });

  group('UserGenderExtension', () {
    test('should convert enum to string value', () {
      expect(UserGender.male.value, 'Male');
      expect(UserGender.female.value, 'Female');
      expect(UserGender.other.value, 'Other');
    });

    test('should convert string to enum', () {
      expect(UserGenderExtension.fromString('male'), UserGender.male);
      expect(UserGenderExtension.fromString('female'), UserGender.female);
      expect(UserGenderExtension.fromString('other'), UserGender.other);
      expect(UserGenderExtension.fromString('unknown'), UserGender.other);
    });

    test('should handle case insensitive string conversion', () {
      expect(UserGenderExtension.fromString('MALE'), UserGender.male);
      expect(UserGenderExtension.fromString('Female'), UserGender.female);
      expect(UserGenderExtension.fromString('OTHER'), UserGender.other);
    });
  });
}
