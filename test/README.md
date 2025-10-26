# Test Suite for CloseCart Flutter App

This directory contains comprehensive tests for the CloseCart Flutter application.

## Test Structure

```
test/
├── models/
│   ├── user_model_test.dart          # Tests for UserModel class
│   └── shop_model_test.dart          # Tests for ShopModel and related classes
├── services/
│   ├── cache_service_test.dart       # Tests for CacheService
│   ├── auth_service_test.dart        # Tests for AuthService
│   └── notification_service_test.dart # Tests for NotificationService
├── widgets/
│   └── notification_permission_handler_test.dart # Widget tests
├── main_test.dart                    # Tests for main app functionality
└── test_runner.dart                  # Test runner for all tests
```

## Test Coverage

### Models

- **UserModel**: Tests for user data model including JSON serialization/deserialization, validation, and error handling
- **ShopModel**: Tests for shop-related models including BusinessHours and WeeklyBusinessHours

### Services

- **CacheService**: Tests for caching functionality, data persistence, expiration handling
- **AuthService**: Tests for authentication operations, local storage, and error handling
- **NotificationService**: Tests for notification permission handling and provider state management

### Widgets

- **NotificationPermissionHandler**: Widget tests for permission handling UI component

### Main App

- **ThemeProvider**: Tests for theme management and state changes
- **App Configuration**: Tests for app initialization and routing

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/models/user_model_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Run Tests in a Specific Directory

```bash
flutter test test/models/
```

## Test Types

### Unit Tests

- Model classes
- Service classes
- Utility functions

### Widget Tests

- UI components
- State management
- User interactions

### Integration Tests

- Provider integration
- Service integration
- End-to-end workflows

## Best Practices

1. **Test Structure**: Each test file follows the AAA pattern (Arrange, Act, Assert)
2. **Mocking**: Uses minimal mocking to focus on actual functionality
3. **Edge Cases**: Tests handle null values, empty data, and error conditions
4. **Performance**: Includes performance tests for critical operations
5. **State Management**: Tests provider state changes and listener management

## Test Data

Tests use realistic test data that mirrors the actual app data structure:

- User models with complete profile information
- Shop models with business hours and location data
- Cache data with expiration timestamps
- Authentication tokens and user sessions

## Error Handling

Tests verify proper error handling for:

- Network failures
- Invalid data formats
- Permission denied scenarios
- Cache expiration
- Authentication failures

## Dependencies

The tests use the following packages:

- `flutter_test`: Core testing framework
- `hive_flutter`: For local storage testing
- `provider`: For state management testing
- Standard Flutter testing utilities

## Adding New Tests

When adding new tests:

1. Place them in the appropriate directory (models/, services/, widgets/)
2. Follow the existing naming convention (`*_test.dart`)
3. Include comprehensive test coverage for happy path and error scenarios
4. Add the test import to `test_runner.dart` if needed
5. Update this README if adding new test categories

## Test Maintenance

- Keep tests updated with code changes
- Run tests frequently during development
- Review test coverage reports
- Update test data when models change
- Maintain consistent testing patterns across the codebase
