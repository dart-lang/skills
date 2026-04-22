---
name: dart-fix-static-analysis-errors
description: Workflow for identifying and fixing static analysis errors. Use this after modifying code or if `dart analyze` fails.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 20:54:44 GMT
---
# Resolving Dart Static Analysis Errors

## Contents
- [Configuring Static Analysis](#configuring-static-analysis)
- [Enforcing Type Safety and Null Safety](#enforcing-type-safety-and-null-safety)
- [Suppressing Diagnostics](#suppressing-diagnostics)
- [Workflow: Standard Analysis and Fix Loop](#workflow-standard-analysis-and-fix-loop)
- [Workflow: Migrating to Sound Null Safety](#workflow-migrating-to-sound-null-safety)
- [Examples](#examples)

## Configuring Static Analysis

Configure the Dart analyzer using `analysis_options.yaml` at the package root. Enforce strict type checking to prevent implicit downcasts and un-inferred dynamic types.

Include standard rule sets (`lints/recommended.yaml` or `flutter_lints/recommended.yaml`) and enable strict language modes.

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_assignment: warning
    missing_return: error

linter:
  rules:
    - always_declare_return_types
    - cancel_subscriptions
    - close_sinks
```

## Enforcing Type Safety and Null Safety

Address static analysis errors by explicitly managing nullability and types.

*   **Null Safety Modifiers:** Use `?` for nullable types, `!` to cast away nullability (use sparingly), `required` for mandatory named parameters, and `late` for variables initialized after declaration but before use.
*   **Type Annotations:** Add explicit type annotations to generic classes (`List<T>`, `Map<K, V>`). Never use a `dynamic` list as a typed list.
*   **Explicit Downcasts:** If implicit downcasts are disallowed (e.g., assigning `List<Animal>` to `List<Cat>`), use an explicit cast (`as List<Cat>`).
*   **Flow Analysis:** Use `== null` or `!= null` checks to promote nullable local variables to non-nullable types within the guarded scope. Note: Flow-based type promotion only applies to local variables, parameters, and private final fields.
*   **Late Initialization:** Use `late` to defer initialization of non-nullable fields. Combine `late final` for variables assigned exactly once at runtime.
*   **Never Type:** Use the `Never` type for functions that unconditionally throw exceptions or abort execution, extending Dart's reachability analysis.

## Suppressing Diagnostics

When a diagnostic is a known false positive or originates from generated code, suppress it using specific comments.

*   **File-level:** Add `// ignore_for_file: <rule_name>` at the top of the file.
*   **Line-level:** Add `// ignore: <rule_name>` directly above or appended to the offending line.
*   **Pubspec:** Add `# ignore: <rule_name>` above the offending line in `pubspec.yaml`.

## Workflow: Standard Analysis and Fix Loop

Use this workflow to identify, automatically fix, and manually resolve static analysis errors.

**Task Progress:**
- [ ] Run `dart analyze` to identify static errors across the project.
- [ ] Run `dart fix --apply` to automatically resolve standard linting and formatting issues.
- [ ] Review remaining errors from the analyzer output.
- [ ] **Conditional:** If the error is a null safety issue, apply `?`, `!`, `late`, or `required`.
- [ ] **Conditional:** If the error is an implicit downcast, add an explicit `as T` cast or correct the generic type annotation.
- [ ] **Conditional:** If the error is an un-promoted class field, copy the field to a local variable, check for null, and use the local variable.
- [ ] **Feedback Loop:** Run `dart analyze` -> review errors -> fix -> repeat until the analyzer reports 0 issues.
- [ ] Run tests (`dart test` or `flutter test`) to ensure explicit casts or `late` variables have not introduced runtime exceptions.

## Workflow: Migrating to Sound Null Safety

Use this workflow when dealing with legacy codebases or mixed-version programs.

**Task Progress:**
- [ ] Update `pubspec.yaml` SDK constraints to `>=2.12.0 <4.0.0` (or higher).
- [ ] Run `dart pub get` to regenerate the package configuration.
- [ ] **Conditional:** If migrating incrementally, add `// @dart=2.9` to the top of files you wish to opt-out of sound null safety temporarily.
- [ ] Run `dart analyze` and resolve static errors file-by-file.
- [ ] **Conditional:** If running or testing a mixed-version program (containing both null-safe and legacy code), execute using the `--no-sound-null-safety` flag (e.g., `dart run --no-sound-null-safety`).
- [ ] Remove all `// @dart=2.9` comments once all files are migrated.
- [ ] **Feedback Loop:** Run `dart analyze` -> fix remaining soundness issues -> verify with `dart test`.

## Examples

### Example: Fixing Un-promoted Fields
Public or non-final fields cannot be type-promoted via null checks. Copy to a local variable first.

**Input (Fails Analysis):**
```dart
class Coffee {
  String? temperature;
  void serve() {
    if (temperature != null) {
      print(temperature.length); // ERROR: Property 'length' cannot be accessed on 'String?'
    }
  }
}
```

**Output (Passes Analysis):**
```dart
class Coffee {
  String? temperature;
  void serve() {
    final temp = temperature; // Copy to local variable
    if (temp != null) {
      print(temp.length); // OK: 'temp' is promoted to non-nullable 'String'
    }
  }
}
```

### Example: Using `late` for Deferred Initialization
Avoid making fields nullable if they are guaranteed to be initialized before use.

**Input (Fails Analysis or requires unsafe `!`):**
```dart
class Weather {
  String? _temperature; // Implies null is a valid state
  void update() { _temperature = 'hot'; }
  String getTemp() => _temperature!; // Requires runtime assertion
}
```

**Output (Passes Analysis):**
```dart
class Weather {
  late String _temperature; // Non-nullable, deferred initialization
  void update() { _temperature = 'hot'; }
  String getTemp() => _temperature; // Safe access, checked at runtime
}
```
