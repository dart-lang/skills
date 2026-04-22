---
name: dart-add-unit-test
description: Write and organize unit tests for functions, methods, and classes using `package:test`. Use when creating new logic or fixing bugs to ensure code remains correct and regression-free.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 19:35:39 GMT
---
# Testing Dart Applications

## Contents
- [Test Organization](#test-organization)
- [Writing Tests](#writing-tests)
- [Running Tests](#running-tests)
- [Workflows](#workflows)
- [Examples](#examples)

## Test Organization

Structure your test files to mirror the `lib` directory structure, ensuring predictable discovery by the test runner.

*   Place all unit and component test code in the `test` directory at the root of the package.
*   Place end-to-end or integration tests in the `integration_test` directory.
*   Append `_test.dart` to the end of all test file names (e.g., `string_helpers_test.dart`).

## Writing Tests

Utilize `package:test` as the standard library for writing Dart tests. 

*   **Test Cases & Grouping:** Use `test()` to define individual test cases. Group related test cases using `group()`.
*   **Assertions:** Use `expect()` provided by `package:matcher` to validate outcomes.
*   **Setup & Teardown:** Use `setUp()` and `tearDown()` to initialize and clean up shared state between tests in a group or suite. `tearDown()` executes even if a test fails.
*   **Asynchronous Testing:** Write asynchronous tests using standard `async`/`await` syntax. Ensure all futures have error handlers before they complete as an error to avoid uncaught async errors failing the test suite unpredictably.
*   **Mocking:** Use `package:mockito` alongside `package:test` when testing code that relies on dependency injection. Generate mock objects, configure them for fixed scenarios, and verify interactions.
*   **Annotations:** 
    *   Use `@TestOn('platform_selector')` to restrict tests to specific platforms (e.g., `@TestOn('vm')` or `@TestOn('browser && !chrome')`).
    *   Use `@Skip('reason')` to temporarily bypass failing tests.
    *   Use `@Timeout(Duration(...))` to override the default 30-second timeout for slow tests.

## Running Tests

Execute tests using the Dart or Flutter CLI depending on the project environment.

*   **Standard Dart Projects:** Run `dart test` to execute all tests in the `test` directory.
*   **Flutter Projects:** Run `flutter test` instead of `dart test`.
*   **Integration Tests:** Explicitly target the integration directory, as it is ignored by default: `dart test integration_test`.
*   **Targeting Specific Tests:** 
    *   Run a specific file: `dart test path/to/file_test.dart`.
    *   Filter by name (regex): `dart test -n "test name"`.
    *   Filter by tags: `dart test --tags "browser"`.
*   **Performance & CI:**
    *   Control concurrency: `dart test --concurrency=4`.
    *   Shard tests across CI nodes: `dart test --total-shards 3 --shard-index 0`.
    *   Collect coverage: `dart test --coverage-path=./coverage/lcov.info`.

## Workflows

### Workflow: Implementing a New Test Suite

Use this checklist to track progress when creating and verifying a new test suite.

```markdown
- [ ] 1. Create the test file in the `test/` directory ending with `_test.dart`.
- [ ] 2. Import `package:test/test.dart` and the target library.
- [ ] 3. Define the `main()` function.
- [ ] 4. Initialize dependencies (use `package:mockito` if DI is required).
- [ ] 5. Write `setUp()` and `tearDown()` blocks for shared state.
- [ ] 6. Implement `group()` blocks for logical feature sets.
- [ ] 7. Implement `test()` cases using `expect()` assertions.
- [ ] 8. Run validator -> review errors -> fix.
```

**Conditional Execution Logic:**
*   **If testing a Flutter package:** Use `flutter test` for the validation step.
*   **If testing a pure Dart package:** Use `dart test` for the validation step.
*   **If testing integration flows:** Place the file in `integration_test/` and run `dart test integration_test`.

**Feedback Loop: Run validator -> review errors -> fix**
1. Execute the targeted test command (e.g., `dart test test/my_feature_test.dart`).
2. Analyze the stack trace for failed `expect()` calls or uncaught async errors.
3. Adjust the test logic or the underlying implementation.
4. Repeat until the test suite passes.

## Examples

### High-Fidelity Test Suite Example

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Assume ApiClient is a class in the lib directory
import 'package:my_app/api_client.dart'; 
import 'package:my_app/data_service.dart';

// Generate mocks using build_runner: dart run build_runner build
@GenerateMocks([ApiClient])
import 'data_service_test.mocks.dart';

void main() {
  group('DataService', () {
    late MockApiClient mockApiClient;
    late DataService dataService;

    setUp(() {
      // Initialize mock and inject it into the service
      mockApiClient = MockApiClient();
      dataService = DataService(apiClient: mockApiClient);
    });

    tearDown(() {
      // Clean up resources if necessary
      dataService.dispose();
    });

    test('fetchData returns parsed list on success', () async {
      // Arrange
      when(mockApiClient.get('/data')).thenAnswer(
        (_) async => '["item1", "item2"]',
      );

      // Act
      final result = await dataService.fetchData();

      // Assert
      expect(result, isA<List<String>>());
      expect(result, equals(['item1', 'item2']));
      verify(mockApiClient.get('/data')).called(1);
    });

    test('fetchData throws Exception on API failure', () async {
      // Arrange
      when(mockApiClient.get('/data')).thenThrow(Exception('API Error'));

      // Act & Assert
      expect(
        () => dataService.fetchData(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```
