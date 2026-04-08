---
name: dart-testing
description: Ensure code correctness with comprehensive unit and integration tests.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:20:13 GMT
---
# Testing Dart Applications

## Contents
- [Core Testing Principles](#core-testing-principles)
- [Test Implementation Guidelines](#test-implementation-guidelines)
- [Mocking and Isolation](#mocking-and-isolation)
- [Running Tests](#running-tests)
- [Workflows](#workflows)
- [Examples](#examples)
- [Related Skills](#related-skills)

## Core Testing Principles

Apply the appropriate testing strategy based on the target environment and scope:

- **Unit Tests:** Verify the smallest piece of testable software (functions, methods, classes). Maximize coverage here.
- **Component/Widget Tests:** Verify that a component (multiple classes or Flutter Widgets) behaves as expected. Use mock objects to mimic user actions and events.
- **Integration/End-to-End Tests:** Verify the behavior of an entire app or large subsystem on a simulated/real device or browser.

**Conditional Logic for Test Environments:**
- **If testing a pure Dart package or server app:** Use `package:test`.
- **If testing a Flutter app:** Use `flutter_test` (built on `package:test`) for unit/widget tests, and `integration_test` or `flutter_driver` for end-to-end tests.

## Test Implementation Guidelines

Structure and write tests using the `test` package conventions.

- **Descriptive Naming:** Use `group()` to categorize related tests and `test()` for individual cases. Provide clear, descriptive names that explain the expected behavior.
- **Assertions:** Always use `expect(actual, matcher)` for assertions.
- **Async Matchers:** Use `completion()` to verify Future resolutions and `throwsA()` to verify exceptions.
- **Annotations:** Use `@TestOn('browser')` or `@TestOn('vm')` to restrict tests to specific environments. Use `@Tag('name')` to categorize tests for custom configurations.

## Mocking and Isolation

Isolate the system under test (SUT) to ensure deterministic and fast execution.

- **Prefer Mocks and Fakes:** Do not use real network calls, databases, or complex external dependencies in unit tests.
- **Use `package:mockito`:** Generate mock classes for complex dependencies. Define fixed scenarios and verify that the SUT interacts with the mock object in expected ways.
- **Code Generation:** Use `build_runner` to generate mock implementations (see `dart-code-generation`).

## Running Tests

Execute tests via the command line using targeted flags to optimize the feedback loop.

- **Run all tests:** `dart test` (or `flutter test`)
- **Run specific directories:** `dart test test/unit/` or `dart test test/integration/`
- **Run specific files:** `dart test test/services/auth_test.dart`
- **Filter by tags:** `dart test --tags="integration"` or `dart test --exclude-tags="slow"`
- **Filter by name:** `dart test --name="AuthService"`

## Workflows

### Workflow: Implementing a Unit Test Suite

Copy and track this checklist when implementing new tests:

- [ ] 1. Identify the class/function to test and its external dependencies.
- [ ] 2. Create a corresponding `_test.dart` file in the `test/` directory.
- [ ] 3. Define mock objects for all external dependencies using `package:mockito` or manual fakes.
- [ ] 4. Set up the test `group()` with a descriptive name.
- [ ] 5. Initialize the SUT and mocks within a `setUp()` block.
- [ ] 6. Write individual `test()` cases covering success, failure, and edge cases.
- [ ] 7. Use `expect()` with appropriate matchers (`completion`, `throwsA`, etc.).
- [ ] 8. **Feedback Loop:** Run `dart test path/to/test.dart` -> Review failures -> Fix implementation or test logic -> Repeat until passing.

## Examples

### High-Fidelity Unit Test Example

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Assume these are defined in your application code
import 'package:my_app/auth_service.dart';
import 'package:my_app/api_client.dart';

// Generate mocks using build_runner
@GenerateMocks([ApiClient])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      authService = AuthService(apiClient: mockApiClient);
    });

    test('login successfully returns a user token', () async {
      // Arrange
      when(mockApiClient.post('/login', any))
          .thenAnswer((_) async => {'token': 'abc-123'});

      // Act
      final result = authService.login('user', 'password');

      // Assert
      await expectLater(result, completion(equals('abc-123')));
      verify(mockApiClient.post('/login', any)).called(1);
    });

    test('login throws AuthException on invalid credentials', () async {
      // Arrange
      when(mockApiClient.post('/login', any))
          .thenThrow(Exception('Unauthorized'));

      // Act
      final result = authService.login('user', 'wrong_password');

      // Assert
      await expectLater(result, throwsA(isA<AuthException>()));
    });
  });
}
```

## Related Skills
- `dart-static-analysis`: For configuring linting rules that enforce test quality.
- `dart-code-generation`: For generating mock objects via `build_runner` and `mockito`.
