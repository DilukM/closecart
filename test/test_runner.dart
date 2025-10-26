import 'package:flutter_test/flutter_test.dart';

// Import all test files directly to run them
import 'models/user_model_test.dart';
import 'models/shop_model_test.dart';
import 'services/cache_service_test.dart';
import 'services/auth_service_test.dart';
import 'services/notification_service_test.dart';
import 'widgets/notification_permission_handler_test.dart';
import 'main_test.dart';

void main() {
  // When this file is run with flutter test, it will automatically execute
  // all the imported test files. No need to explicitly call main() on each.
  // This is how Flutter's test runner works - it discovers and runs all tests
  // in imported files automatically.
}
