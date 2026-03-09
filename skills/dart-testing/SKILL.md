---
name: "dart-testing"
description: "Ensure code correctness with comprehensive unit and integration tests."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:32:51 GMT"

---
# Dart Testing Automation

## Goal
Analyzes Dart and Flutter codebases to architect, implement, and execute robust test suites. Generates unit, component, and integration tests utilizing `package:test` and `package:mockito`. Configures mock objects, structures test groups, and executes validation loops using `dart test` or `flutter test` to ensure code reliability and prevent regressions.

## Decision Logic
Evaluate the target repository to determine the appropriate testing strategy:
*   **Project Type:**
    *   If `pubspec.yaml` contains `sdk: flutter`: Use `flutter_test` and execute via `flutter test`.
    *   If pure Dart (Server/CLI/Web): Use `package:test` and execute via `dart test`.
*   **Test Scope:**
    *   *Isolated Logic (Functions/Classes):* Implement **Unit Tests**. Isolate the system under test using `package:mockito`.
    *   *UI/Multi-class interactions:* Implement **Component/Widget Tests**. Use `flutter_test` for widget pumping or standard component instantiation.
    *   *Full Application Flow:* Implement **Integration Tests**. Use `flutter_driver` or `integration_test` package.

## Instructions

1. **Analyze Context and Configure Dependencies**
   Inspect `pubspec.yaml`. Ensure the required testing and mocking packages are present under `dev_dependencies`.
   ```yaml
   dev_dependencies:
     test: ^1.24.0 # Use flutter_test for Flutter projects
     mockito: ^5.4.4
     build_runner: ^2.4.8
   ```

2. **Generate Mock Objects**
   Identify external dependencies (e.g., API clients, database repositories) of the system under test. Create a test file and use the `@GenerateMocks` annotation.
   ```dart
   import 'package:mockito/annotations.dart';
   import 'package:my_app/api_client.dart';

   @GenerateMocks([ApiClient])
   void main() {}
   ```
   Execute the build runner to generate the mock files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   **STOP AND ASK THE USER:** If you do not have execution capabilities in the current environment, provide the `build_runner` command to the user and wait for them to confirm successful generation before proceeding.

3. **Implement the Test Suite**
   Write tests using the `test` package. Group related tests and use descriptive names. Utilize `expect()` with appropriate matchers.
   ```dart
   import 'package:test/test.dart';
   import 'package:mockito/mockito.dart';
   import 'package:my_app/data_service.dart';
   import 'api_client.mocks.dart'; // Generated mock file

   void main() {
     group('DataService -', () {
       late DataService dataService;
       late MockApiClient mockApiClient;

       setUp(() {
         mockApiClient = MockApiClient();
         dataService = DataService(apiClient: mockApiClient);
       });

       test('fetchData returns parsed data on successful API call', () async {
         // Arrange
         when(mockApiClient.get('/data')).thenAnswer((_) async => '{"status": "ok"}');

         // Act
         final result = await dataService.fetchData();

         // Assert
         expect(result, equals({'status': 'ok'}));
         verify(mockApiClient.get('/data')).called(1);
       });

       test('fetchData throws Exception on API failure', () async {
         // Arrange
         when(mockApiClient.get('/data')).thenThrow(Exception('Network Error'));

         // Act & Assert
         expect(
           () => dataService.fetchData(),
           throwsA(isA<Exception>()),
         );
       });
     });
   }
   ```

4. **Execute Tests and Validate**
   Run the test suite using the appropriate CLI command. Use flags to target specific directories or tags if necessary.
   ```bash
   # For pure Dart projects
   dart test test/data_service_test.dart

   # For Flutter projects
   flutter test test/data_service_test.dart
   ```

5. **Validate-and-Fix Loop**
   Parse the output of the test execution. 
   *   If tests **pass**, proceed to the next task or finalize the implementation.
   *   If tests **fail**, analyze the stack trace, identify the mismatch between expected and actual values, modify the source code or the test assertions accordingly, and re-run the tests until they pass.

6. **Configure Continuous Integration (Optional)**
   If requested, generate a GitHub Actions workflow to automate test execution.
   ```yaml
   name: Dart CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: dart-lang/setup-dart@v1
         - run: dart pub get
         - run: dart test
   ```

## Constraints
*   DO write tests using the `test` package with descriptive `group` and `test` names.
*   DO use `expect()` with appropriate matchers (e.g., `completion`, `throwsA`, `isA`).
*   DO run tests via `dart test` (or `flutter test`) and use flags for specific directories or tags when applicable.
*   PREFER mock objects or fakes (via `package:mockito`) to isolate the system under test. Never make real HTTP requests or database mutations in unit tests.
*   DO NOT write monolithic test functions; strictly separate Arrange, Act, and Assert phases.
*   DO NOT leave unresolved type promotion failures in test files; ensure sound null safety is respected.
*   Related Skills: `dart-static-analysis`, `dart-code-generation`.
