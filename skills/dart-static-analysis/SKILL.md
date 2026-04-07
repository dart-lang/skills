---
name: dart-static-analysis
description: Configure and resolve static analysis warnings to maintain project health.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:17:26 GMT
---
# Analyzing and Linting Dart Code

## Contents
- [Configuring Analysis Options](#configuring-analysis-options)
- [Managing Linter Rules](#managing-linter-rules)
- [Resolving Type Promotion Failures](#resolving-type-promotion-failures)
- [Workflow: Static Analysis Setup and Execution](#workflow-static-analysis-setup-and-execution)
- [Workflow: Fixing Type Promotion](#workflow-fixing-type-promotion)
- [Examples](#examples)

## Configuring Analysis Options

Control static analysis by placing an `analysis_options.yaml` file at the root of your package. 

*   **Enforce Strict Type Checks:** Always enable `strict-casts`, `strict-inference`, and `strict-raw-types` in the `analyzer` section to catch implicit dynamic casts and un-inferred types at compile time.
*   **Configure Formatting:** Define `dart format` rules within the `formatter` section (e.g., `page_width` and `trailing_commas`).
*   **Exclude Generated Code:** Use the `exclude` key to ignore generated files (e.g., `**/*.g.dart`, `**/*.freezed.dart`) to prevent false positives.

## Managing Linter Rules

Rely on community-standard rule sets rather than maintaining a bespoke list of rules.

*   **Use Standard Packages:** Include `package:lints/recommended.yaml` for pure Dart projects or `package:flutter_lints/flutter.yaml` for Flutter projects.
*   **Avoid Manual Ignores:** AVOID ignoring lints manually (e.g., `// ignore: ...`) unless absolutely necessary. Prefer fixing the root cause of the lint.
*   **Bulk Fixes:** DO use `dart fix --apply` to automatically resolve common lint violations and migration issues across the entire codebase.
*   **Customize Severity:** If a specific rule is too noisy but still valuable, change its severity in the `errors` map (e.g., `todo: info`) rather than disabling it entirely.

## Resolving Type Promotion Failures

Type promotion occurs when flow analysis confirms a nullable variable is not null. Promotion fails when the compiler cannot guarantee that a value remains stable between the check and the usage. 

Common causes for promotion failures include:
1.  **Public or Non-Final Fields:** External libraries could override public fields, and non-final fields can be mutated.
2.  **Getters:** The compiler cannot guarantee a getter returns the same value on subsequent calls.
3.  **Write Captures:** A variable is modified inside a closure or function expression, invalidating previous checks.

**The Solution:** DO resolve "non-promotion" reasons by assigning the field, getter, or captured variable to a **local `final` variable** before performing the null or type check. Local variables are guaranteed to be stable, allowing the compiler to safely promote the type.

## Workflow: Static Analysis Setup and Execution

Use this checklist to initialize and enforce static analysis in a Dart project.

- [ ] **Task Progress: Setup Analysis**
  - [ ] Run `dart pub add --dev lints` (or `flutter_lints`).
  - [ ] Create `analysis_options.yaml` at the project root.
  - [ ] Include the recommended rule set (`include: package:lints/recommended.yaml`).
  - [ ] Enable strict language modes (`strict-casts`, `strict-inference`, `strict-raw-types`).
- [ ] **Task Progress: Execution & Remediation**
  - [ ] Run `dart analyze` to catch potential bugs and style violations early.
  - [ ] Run `dart fix --apply` to automatically resolve mechanical lint issues.
  - [ ] Review remaining errors manually. Run validator -> review errors -> fix root causes without using `// ignore`.

## Workflow: Fixing Type Promotion

When `dart analyze` reports that a property or field cannot be promoted:

- [ ] **Task Progress: Fix Promotion**
  - [ ] Identify the failing variable (e.g., a public field, getter, or write-captured variable).
  - [ ] Declare a local `final` variable immediately before the conditional check.
  - [ ] Assign the un-promotable field/getter to the new local variable.
  - [ ] Perform the `!= null` or `is Type` check on the *local* variable.
  - [ ] Update all references inside the conditional block to use the local variable.
  - [ ] Run `dart analyze` to verify the promotion failure is resolved.

## Examples

### High-Fidelity `analysis_options.yaml`

```yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    todo: info
    invalid_assignment: error

formatter:
  page_width: 80
  trailing_commas: preserve

linter:
  rules:
    # Disable specific rules if they conflict with project architecture
    avoid_classes_with_only_static_members: false
    # Enable additional strict rules
    always_declare_return_types: true
    cancel_subscriptions: true
```

### Fixing Type Promotion via Local Variables

**Anti-Pattern:** Checking a getter or public field directly. The compiler throws an error because `_value` is a getter and might return a different result on the second call.

```dart
abstract class Example {
  int? get _value => Random().nextBool() ? 123 : null;
}

void printParity(Example x) {
  if (x._value != null) {
    // ERROR: '_value' refers to a getter so it couldn't be promoted.
    print(x._value.isEven); 
  }
}
```

**Best Practice:** Assign to a local `final` variable to ensure stability.

```dart
abstract class Example {
  int? get _value => Random().nextBool() ? 123 : null;
}

void printParity(Example x) {
  final localValue = x._value; // 1. Assign to local final variable
  
  if (localValue != null) {    // 2. Check the local variable
    print(localValue.isEven);  // 3. Use the promoted local variable (OK)
  }
}
```

---
*Related Skills: `dart-effective-style`, `dart-api-design`*
