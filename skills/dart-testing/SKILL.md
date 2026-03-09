---
name: "dart-testing"
description: "Ensure code correctness with comprehensive unit and integration tests."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:42:31 GMT"

---
# Dart Testing Automation

## Goal
Generates, configures, and executes robust test suites for Dart and Flutter applications. Evaluates the target codebase to determine the appropriate testing strategy (unit, component, or integration), implements isolated tests using `package:test` and `package:mockito`, and validates system behavior using precise matchers and mock objects.

## Decision Logic

Evaluate the target application and testing requirements to determine the correct testing path:

1. **Is the target a pure Dart application or package?**
   * *Yes:* Use `package:test` for unit and integration tests. Execute via `dart test`.
2. **Is the target a Flutter application?**
   * *Yes (UI/Component):* Use `flutter_test` for widget testing. Execute via `flutter test`.
   * *Yes (E2E/Integration):* Use `integration_test` or `flutter_driver` for real-device testing.
3. **Does the System Under Test (SUT) have external dependencies (e.g., APIs, databases)?**
   * *Yes:* Use `package:mockito` to generate mock objects and isolate the SUT.

## Instructions

1. **Determine Test Scope and Environment**
   Analyze the provided source code to identify the classes, methods, and dependencies that require testing.
   **STOP AND ASK THE USER:** "Which specific directory or file should I target for testing, and do you require unit, widget, or integration tests?"

2. **Configure Dependencies**
   Ensure the required testing packages are present in the `pubspec.yaml` under `dev_dependencies`.
   ```yaml
   dev_dependencies:
     test: ^1.24.0
     mockito: ^5.4.4
     build_runner: ^2.4.8
   ```

3. **Generate Mock Objects**
   If the SUT relies on external services, define the mock annotations and generate the mock files.
   Create a file named `[target]_test.dart` and add the `@GenerateMocks` annotation.
   ```dart
   import 'package:mockito/annotations.dart';
   import 'package:my_app/api_client.dart';

   @GenerateMocks([ApiClient])
   void main() {}
   ```
   Execute the build runner to generate the mocks:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Implement the Test Suite**
   Write the tests using the `test` package. Group related tests using `group()` and use descriptive names for both groups and individual tests. Use `expect()` with appropriate matchers (`completion`, `throwsA`, `equals`, etc.).

   ```dart
   import 'package:test/test.dart';
   import 'package:mockito/mockito.dart';
   import 'package:my_app/data_service.dart';
   
   // Import the generated mock file
   import 'data_service_test.mocks.dart';

   void main() {
     late DataService dataService;
     late MockApiClient mockApiClient;

     setUp(() {
       mockApiClient = MockApiClient();
       // Isolate the SUT by injecting the mock
       dataService = DataService(apiClient: mockApiClient);
     });

     group('DataService - Fetch Operations', () {
       test('returns parsed data when API call is successful', () async {
         // Arrange
         when(mockApiClient.fetchData(any))
             .thenAnswer((_) async => '{"status": "ok"}');

         // Act & Assert
         expect(
           dataService.fetchAndParse('endpoint'),
           completion(equals({'status': 'ok'})),
         );
         verify(mockApiClient.fetchData('endpoint')).called(1);
       });

       test('throws FormatException when API returns invalid JSON', () async {
         // Arrange
         when(mockApiClient.fetchData(any))
             .thenAnswer((_) async => 'invalid json');

         // Act & Assert
         expect(
           () => dataService.fetchAndParse('endpoint'),
           throwsA(isA<FormatException>()),
         );
       });
     }, tags: ['unit', 'fast']);
   }
   ```

5. **Execute Tests**
   Run the tests using the Dart CLI. Apply flags to target specific directories or tags.
   ```bash
   # Run all tests in a specific directory
   dart test test/unit/

   # Run only tests with a specific tag
   dart test --tags "fast"

   # Run tests with a custom configuration file
   dart test --concurrency=1 --reporter=expanded
   ```

6. **Validate and Fix**
   Review the test execution output. If tests fail:
   * Verify that mock expectations (`when`) exactly match the arguments passed during execution.
   * Ensure asynchronous operations are properly awaited or evaluated using the `completion()` matcher.
   * Adjust the SUT or test logic, re-run the tests, and confirm passing status.

## Constraints

* **Strict Isolation:** Always isolate the System Under Test (SUT). Never make real network requests, database writes, or file system changes in unit tests. Use fakes or `mockito` mocks exclusively.
* **Descriptive Naming:** Test names must describe the expected behavior and the condition (e.g., `returns [X] when [Y] occurs`).
* **Matcher Usage:** Always use specific matchers in `expect()` statements. Avoid generic `expect(result == true, isTrue)` when `expect(result, isTrue)` or `expect(result, equals(expected))` is applicable.
* **Async Handling:** Asynchronous tests must either use `async`/`await` or return a `Future`. Unhandled futures will cause flaky tests.
* **File Naming:** Test files must strictly end with `_test.dart` to be recognized by the test runner.
