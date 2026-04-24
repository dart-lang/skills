---
name: dart-migrate-to-checks-package
description: Replace the usage of `expect` and similar functions from `package:matcher` to `package:checks` equivalents.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Fri, 24 Apr 2026 15:15:22 GMT
---
# Migrating Dart Tests to Package Checks

## Contents
- [Dependency Management](#dependency-management)
- [Syntax Migration Guidelines](#syntax-migration-guidelines)
- [Utilizing Dart MCP Tools](#utilizing-dart-mcp-tools)
- [Migration Workflow](#migration-workflow)
- [Examples](#examples)

## Dependency Management
Manage dependencies using the Dart Tooling MCP Server `pub` tool or standard CLI commands. 

- Add `package:checks` as a `dev_dependency` using `dart pub add dev:checks`.
- Remove `package:matcher` if it is explicitly listed in the `pubspec.yaml` (note: it is often transitively included by `package:test`, which is fine).
- Import `package:checks/checks.dart` in all test files undergoing migration.

## Syntax Migration Guidelines
Transition test assertions from the `package:matcher` syntax to the literate API provided by `package:checks`.

- **Basic Equality:** Replace `expect(actual, equals(expected))` or `expect(actual, expected)` with `check(actual).equals(expected)`.
- **Type Checking:** Replace `expect(actual, isA<Type>())` with `check(actual).isA<Type>()`.
- **Property Extraction:** Replace `expect(actual.property, expected)` with `check(actual).has((a) => a.property, 'property name').equals(expected)`.
- **Cascades for Multiple Checks:** Use Dart's cascade operator (`..`) to chain multiple expectations on a single subject.
- **Asynchronous Expectations:** 
  - If checking a `Future`, `await` the `check` call: `await check(someFuture).completes((r) => r.equals(expected));`.
  - If checking a `Stream`, wrap it in a `StreamQueue` for multiple checks, or use `.withQueue` for single/broadcast checks.

## Utilizing Dart MCP Tools
Leverage the Dart MCP Server tools to automate and validate the migration process.

- Use `pub` to run `dart pub get` or `dart pub add`.
- Use `analyze_files` to run static analysis on the project or specific paths.
- Use `run_tests` to execute Dart or Flutter tests with an agent-centric UX. ALWAYS use this instead of shell commands like `dart test`.
- Use `dart_fix` to apply automated fixes if applicable.

## Migration Workflow

Copy and use the following checklist to track progress when migrating a test suite:

- [ ] **Task Progress**
  - [ ] Add `package:checks` as a dev dependency.
  - [ ] Identify all test files using `package:matcher` (`expect` calls).
  - [ ] Import `package:checks/checks.dart` in target test files.
  - [ ] Rewrite all `expect(...)` statements to `check(...)` statements.
  - [ ] Run static analyzer (`analyze_files`).
  - [ ] Run tests (`run_tests`).

### Feedback Loop: Static Analysis
1. Run the `analyze_files` tool on the modified test directories.
2. Review any static analysis warnings or errors (e.g., missing imports, incorrect generic types on `isA`, unawaited futures).
3. Fix the warnings.
4. Repeat until the analyzer returns zero issues.

### Feedback Loop: Test Validation
1. Run the `run_tests` tool.
2. If tests fail, review the failure output. `package:checks` provides detailed context (e.g., `Which: has length of <2>`).
3. Adjust the `check()` expectations or the underlying code to resolve the failure.
4. Repeat until all tests pass.

## Examples

### Basic Assertions
**Input (`matcher`):**
```dart
expect(someList.length, 1);
expect(someString, startsWith('a'));
expect(someObject, isA<Map>());
```

**Output (`checks`):**
```dart
check(someList).length.equals(1);
check(someString).startsWith('a');
check(someObject).isA<Map>();
```

### Composed Expectations
**Input (`matcher`):**
```dart
expect('foo,bar,baz', allOf([
  contains('foo'),
  isNot(startsWith('bar')),
  endsWith('baz')
]));
```

**Output (`checks`):**
```dart
check('foo,bar,baz')
  ..contains('foo')
  ..not((s) => s.startsWith('bar'))
  ..endsWith('baz');
```

### Asynchronous Futures
**Input (`matcher`):**
```dart
expect(Future.value(10), completion(equals(10)));
expect(Future.error('oh no'), throwsA(equals('oh no')));
```

**Output (`checks`):**
```dart
await check(Future.value(10)).completes((it) => it.equals(10));
await check(Future.error('oh no')).throws<String>().equals('oh no');
```

### Asynchronous Streams
**Input (`matcher`):**
```dart
var stdout = StreamQueue(Stream.fromIterable(['Ready', 'Go']));
await expectLater(stdout, emitsThrough('Ready'));
```

**Output (`checks`):**
```dart
var stdout = StreamQueue(Stream.fromIterable(['Ready', 'Go']));
await check(stdout).emitsThrough((it) => it.equals('Ready'));
```
