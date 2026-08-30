---
name: dart-use-pattern-matching
description: Use switch expressions and pattern matching where appropriate
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sun, 30 Aug 2026 05:08:00 GMT
---
# Implementing Dart Patterns

## Contents
- [Pattern Selection Strategy](#pattern-selection-strategy)
- [Switch Statements vs. Expressions](#switch-statements-vs-expressions)
- [Core Pattern Implementations](#core-pattern-implementations)
- [Pragmatic Balance & Anti-Patterns](#pragmatic-balance--anti-patterns)
- [Workflows](#workflows)
- [Examples](#examples)

## Pattern Selection Strategy

Apply specific pattern types based on the data structure and desired outcome. Follow these conditional guidelines:

*   **If validating and extracting from deserialized data (e.g., JSON):** Use Map, List, and Object patterns to validate schema structure and destructure properties in a single step.
*   **If handling polymorphic payloads or responses:** Use `switch` expressions over map discriminant keys to deserialize into `sealed` class hierarchies.
*   **If handling multiple return values:** Use Record patterns to destructure fields directly into local variables.
*   **If executing type-specific behavior (Algebraic Data Types):** Use Object patterns combined with `sealed` classes to ensure exhaustiveness.
*   **If matching numeric ranges or conditions:** Use Relational (`>=`, `<=`) and Logical-and (`&&`) patterns within switch arms.
*   **If multiple cases share logic:** Use Logical-or (`||`) patterns to share a single case body or guard clause.
*   **If ignoring specific values:** Use the Wildcard pattern (`_`) or a non-matching Rest element (`...`) in collections.

## Switch Statements vs. Expressions

Select the appropriate switch construct based on the execution context:

*   **If producing a value:** Use a **switch expression**.
    *   Syntax: `switch (value) { pattern => expression, }`
    *   Rule: Each case must be a single expression. No implicit fallthrough. Must be exhaustive.
*   **If executing statements or side effects:** Use a **switch statement**.
    *   Syntax: `switch (value) { case pattern: statements; }`
    *   Rule: Empty cases fall through to the next case. Non-empty cases implicitly break (no `break` keyword required).

## Core Pattern Implementations

Implement patterns using the following syntax and rules:

*   **Logical-or (`||`):** `pattern1 || pattern2`. Both branches must define the exact same set of variables.
*   **Logical-and (`&&`):** `pattern1 && pattern2`. Branches must *not* define overlapping variables.
*   **Relational:** `==`, `!=`, `<`, `>`, `<=`, `>=` followed by a constant expression.
*   **Cast (`as`):** `pattern as Type`. Throws if the value does not match the type. Use to forcibly assert types during destructuring.
*   **Null-check (`?`):** `pattern?`. Fails the match if the value is null. Binds the variable to the non-nullable base type.
*   **Null-assert (`!`):** `pattern!`. Throws if the value is null.
*   **Variable:** `var name` or `Type name`. Binds the matched value to a new local variable.
*   **Wildcard (`_`):** Matches any value and discards it.
*   **List:** `[pattern1, pattern2]`. Matches lists of exact length unless a Rest element (`...` or `...var rest`) is used.
*   **Map:** `{"key": pattern}`. Matches maps containing the specified keys. Ignores unmatched keys.
*   **Record:** `(pattern1, named: pattern2)`. Matches records of the exact shape. Use `:var name` to infer the getter name.
*   **Object:** `ClassName(field: pattern)`. Matches instances of `ClassName`. Use `:var field` to infer the getter name.

## Pragmatic Balance & Anti-Patterns

Pattern matching and switch expressions should simplify code, not add syntactic overhead. Observe the following boundaries:

### 1. Prefer `is` Type Promotion over `if-case` for Single Promotable Variables
When checking or promoting a single variable, use standard `is` checks instead of `if-case` patterns that introduce shadow aliases.

*   **Avoid:**
    ```dart
    // ❌ Anti-pattern: Introduces unnecessary alias variable `k`
    for (final MapEntry(:key, :value) in map.entries) {
      if (key case final String k when value != null) {
        process(k, value);
      }
    }
    ```
*   **Prefer:**
    ```dart
    // ✅ Promotes `key` directly in-place without extra variables
    for (final MapEntry(:key, :value) in map.entries) {
      if (key is String && value != null) {
        process(key, value);
      }
    }
    ```

### 2. Consolidate Nullable Types in Switch Arms
When mapping or returning values where both `null` and a type `T` are valid and handled identically, match the nullable type `T?` directly rather than creating redundant `null` arms.

*   **Avoid:**
    ```dart
    // ❌ Redundant separate null arm
    switch (value) {
      final String s => s,
      null => null,
      _ => throw FormatException('Invalid value: $value'),
    }
    ```
*   **Prefer:**
    ```dart
    // ✅ Clean nullable pattern match
    switch (value) {
      final String? s => s,
      _ => throw FormatException('Invalid value: $value'),
    }
    ```

### 3. Preserve Fast-Fail Validation (Do Not Silently Drop Data)
Do not use `if-case` in loops or deserialization to filter elements if malformed data should trigger an error or diagnostic warning.

*   **Avoid:**
    ```dart
    // ❌ Silently ignores malformed items
    for (final raw in rawTasks) {
      if (raw case final Map<String, dynamic> taskMap) {
        _applyTask(taskMap);
      }
    }
    ```
*   **Prefer:**
    ```dart
    // ✅ Fast-fail with explicit diagnostic error
    for (final raw in rawTasks) {
      if (raw is! Map<String, dynamic>) {
        throw FormatException('Expected Map item, got ${raw.runtimeType}: $raw');
      }
      _applyTask(raw);
    }
    ```

### 4. Avoid Single-Case or Boolean Switches
*   Use `if (x is T)` instead of a `switch` statement with only 1 case and `default: break;`.
*   Use standard conditional ternary operators (`condition ? a : b`) instead of `switch (condition) { true => a, false => b }`.

### 5. Avoid Gratuitous Object Destructuring
Use standard property access (`user.name`) rather than object pattern destructuring (`final User(:name) = user;`) when reading a single property on a known non-null instance.

### 6. Avoid `if-case` for Standalone Scalar Comparisons
Use standard boolean operators (`if (code >= 200 && code < 300)`) instead of `if (code case >= 200 && < 300)` for standalone conditions. Reserve relational patterns for multi-arm `switch` tables.

## Workflows

### Task Progress: Implementing Pattern Matching
Copy this checklist to track progress when implementing complex pattern matching logic:

- [ ] Identify the data structure being evaluated (JSON, Record, Class, Enum).
- [ ] Select the appropriate switch construct (Expression for values, Statement for side-effects).
- [ ] Define the required patterns (Object, Map, List, Record).
- [ ] Extract required data using Variable patterns (`var x`, `:var y`).
- [ ] Apply Guard clauses (`when condition`) for logic that cannot be expressed via patterns.
- [ ] Handle unmatched cases using a Wildcard (`_`) or `default` clause (if not using a sealed class).
- [ ] Run static analyzer for exhaustiveness and dead code (`dart analyze`).
- [ ] Write unit tests verifying both happy paths and malformed/error edge cases (`dart test`).

### Feedback Loop 1: Exhaustiveness Checking (Static Verification)
When switching over `sealed` classes or enums, ensure all subtypes are handled at compile time:

1. **Run analyzer:** Execute `dart analyze`.
2. **Review errors:** Look for "The type 'X' is not exhaustively matched by the switch cases" or unreachable pattern arm warnings.
3. **Fix:** Add the missing Object patterns for unhandled subtypes, or add an explicit wildcard (`_`) arm if a default fallback or error is acceptable.

### Feedback Loop 2: Runtime Edge Case & Fast-Fail Verification (Empirical Testing)
When implementing deserialization or complex multi-case switches, verify runtime behavior across edge cases:

1. **Test Happy Path**: Assert that valid structures match and bind variables correctly.
2. **Test Optional / Nullable Variants**: Verify that payloads with missing or `null` optional fields do not fail matching.
3. **Test Fast-Fail & Malformed Inputs**: Verify that unexpected types or missing required fields throw descriptive `FormatException`s rather than unhandled `StateError` or silent data drops.
4. **Run test suite**: Execute `dart test` to confirm all validation paths and error handling behave as expected.

## Examples

### Polymorphic JSON Deserialization (Discriminated Unions)
Use Map patterns with switch expressions to validate tagged JSON payloads and construct `sealed` class hierarchies:

```dart
sealed class ApiResponse {}

class SuccessResponse implements ApiResponse {
  final Map<String, dynamic> data;
  SuccessResponse(this.data);
}

class ErrorResponse implements ApiResponse {
  final String message;
  final int code;
  ErrorResponse(this.message, this.code);
}

ApiResponse parseApiResponse(Map<String, dynamic> json) => switch (json) {
  {'status': 'ok', 'data': Map<String, dynamic> data} => SuccessResponse(data),
  {'status': 'error', 'message': String msg, 'code': int code} =>
    ErrorResponse(msg, code),
  _ => throw FormatException('Invalid or unrecognized API response: $json'),
};
```

### Nested JSON Validation and Optional Fields
Use nested Map and List patterns to validate schema structure, extract collections, and handle optional/nullable fields in a single step:

```dart
void processUserPayload(Map<String, dynamic> json) {
  if (json case {
    'id': String id,
    'profile': {
      'name': String name,
      'email': String email,
      'avatarUrl': String? avatarUrl, // Nullable / optional field
    },
    'tags': [String primaryTag, ...],  // Matches at least 1 element, ignores rest
  }) {
    print('User $name ($id, $email) - Primary tag: $primaryTag');
  } else {
    throw FormatException('Malformed user payload structure: $json');
  }
}
```

### Algebraic Data Types (Sealed Classes)
Use Object patterns with switch expressions to handle family types exhaustively.

```dart
sealed class Shape {}

class Square implements Shape {
  final double length;
  Square(this.length);
}

class Circle implements Shape {
  final double radius;
  Circle(this.radius);
}

// Switch expression guarantees exhaustiveness due to `sealed` modifier.
double calculateArea(Shape shape) => switch (shape) {
  Square(length: var l) => l * l,
  Circle(:var radius)   => math.pi * radius * radius,
};
```

### Variable Swapping and Destructuring
Use variable assignment patterns to swap values or extract record fields without temporary variables.

```dart
var (a, b) = ('left', 'right');
(b, a) = (a, b); // Swap values

// Destructuring a function return
var (name, age) = getUserInfo();
```

### Guard Clauses and Logical-or
Use `when` to evaluate arbitrary conditions after a pattern matches.

```dart
switch (shape) {
  case Square(size: var s) || Circle(size: var s) when s > 0:
    print('Valid symmetric shape with size $s');
  case Square() || Circle():
    print('Invalid or empty shape');
  default:
    print('Unknown shape');
}
```
