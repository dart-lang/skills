---
name: dart-language-syntax
description: Master core and advanced language syntax for expressive and type-safe code.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:18:04 GMT
---
# Writing Idiomatic Dart

## Contents
- [Variables and State Management](#variables-and-state-management)
- [Functions and Closures](#functions-and-closures)
- [Records and Pattern Matching](#records-and-pattern-matching)
- [Generics and Type Safety](#generics-and-type-safety)
- [Workflow: Refactoring to Idiomatic Dart](#workflow-refactoring-to-idiomatic-dart)
- [Examples](#examples)

## Variables and State Management
Manage state and variable declarations using strict mutability and type inference rules.

- **Prefer `var`:** Use `var` for local variables when the assigned type is obvious (e.g., `var name = 'Bob';`). Use explicit types when the type is not immediately clear from the initializer.
- **Enforce Immutability:** Use `final` for variables that should not be reassigned after initialization. Use `const` for compile-time constants and to create canonicalized, immutable object instances.
- **Leverage `late`:** Use the `late` modifier to defer initialization of non-nullable variables until their first use, especially for expensive computations or when initialization requires access to `this`.
- **Implement Wildcards:** Use the wildcard variable `_` (requires Dart 3.7+) to discard unused values in local declarations, closures, or pattern matching without triggering unused variable warnings.

## Functions and Closures
Structure functions for maximum composability and minimal boilerplate.

- **Use Arrow Syntax:** Condense single-expression functions using the `=>` operator.
- **Prefer Tear-offs:** Pass function references directly (tear-offs) instead of wrapping them in redundant anonymous closures (e.g., use `list.forEach(print)` instead of `list.forEach((e) => print(e))`).
- **Implement Generators:** Use `sync*` to lazily generate `Iterable` sequences and `async*` to generate `Stream` sequences. Yield values using `yield` or delegate to other generators using `yield*`.
- **Define Named Parameters:** Use named parameters `({required Type name})` for functions with boolean flags or multiple arguments to improve call-site readability.

## Records and Pattern Matching
Eliminate boilerplate data classes and complex conditional logic using records and patterns.

- **Return Multiple Values:** Use records `(Type, Type)` to return multiple values from a function without defining a dedicated class.
- **Destructure Assignments:** Master pattern matching to destructure records, lists, and objects directly into local variables.
- **Use Switch Expressions:** Replace complex `if-else` chains with switch expressions. Leverage logical-or patterns (`||`) and guard clauses (`when`) to share logic across cases.
- **Validate JSON Declaratively:** Use map and list patterns to simultaneously validate structure, check types, and extract data from dynamic JSON payloads.

## Generics and Type Safety
Ensure type safety and reusability across collections and custom components.

- **Implement Generics:** Use `<T>` to parameterize classes, methods, and collections.
- **Restrict Type Parameters:** Use `extends` to bound generic types (e.g., `<T extends Object>` to enforce non-nullability, or `<T extends BaseWidget>`).
- **Use F-Bounds:** Implement self-referential type constraints when a class must interact with instances of its own exact type (e.g., `class Node<T extends Node<T>>`).
- **Extend Functionality:** Use extension methods and extension types to add utility functions to existing generic or concrete classes without subclassing.

## Workflow: Refactoring to Idiomatic Dart

Use this checklist to upgrade legacy Dart code to modern, idiomatic Dart 3+ standards.

- [ ] **Task Progress: Variable Modernization**
  - [ ] Replace explicit types with `var` for obvious local assignments.
  - [ ] Convert mutable `var` declarations to `final` if they are never reassigned.
  - [ ] Replace `__` or `___` unused parameters with the standard `_` wildcard.
- [ ] **Task Progress: Control Flow & Returns**
  - [ ] Replace custom "Tuple" or "Pair" classes with native Records `(T1, T2)`.
  - [ ] Refactor redundant closures into function/method tear-offs.
  - [ ] Convert single-statement function bodies to arrow `=>` syntax.
- [ ] **Task Progress: Pattern Matching Integration**
  - [ ] If extracting multiple fields from an object, use object destructuring: `var User(:name, :age) = user;`.
  - [ ] If validating nested JSON, replace `is` checks and manual casting with map/list patterns.
  - [ ] If switching over an algebraic data type (sealed class), convert `switch` statements to exhaustive `switch` expressions.
- [ ] **Run Validator -> Review Errors -> Fix:** Run `dart analyze` and `dart format`. Resolve any linting errors related to type promotion or exhaustiveness.

## Examples

### Destructuring Multiple Returns (Records)
**Input (Legacy):**
```dart
class UserInfo {
  final String name;
  final int age;
  UserInfo(this.name, this.age);
}

UserInfo fetchUser() => UserInfo('Dash', 10);
final info = fetchUser();
print(info.name);
```

**Output (Idiomatic):**
```dart
(String, int) fetchUser() => ('Dash', 10);

// Destructure directly into final variables
final (name, age) = fetchUser();
print(name);
```

### Declarative JSON Validation (Patterns)
**Input (Legacy):**
```dart
if (json is Map<String, Object?> && json.containsKey('user')) {
  var user = json['user'];
  if (user is List<Object> && user.length == 2 && user[0] is String && user[1] is int) {
    var name = user[0] as String;
    var age = user[1] as int;
    print('User $name is $age');
  }
}
```

**Output (Idiomatic):**
```dart
if (json case {'user': [String name, int age]}) {
  print('User $name is $age');
}
```

### Switch Expressions and Guard Clauses
**Implementation:**
```dart
sealed class Shape {}
class Square implements Shape { final double length; Square(this.length); }
class Circle implements Shape { final double radius; Circle(this.radius); }

double calculateArea(Shape shape) => switch (shape) {
  Square(length: var l) when l > 0 => l * l,
  Circle(:var radius) when radius > 0 => 3.14159 * radius * radius,
  _ => 0.0, // Fallback for invalid dimensions
};
```

### Extension Methods with Generics
**Implementation:**
```dart
extension IterableExtensions<T> on Iterable<T> {
  /// Returns the first element matching the predicate, or null.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
```
