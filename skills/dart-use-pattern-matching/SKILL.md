---
name: dart-use-pattern-matching
description: Use switch expressions and pattern matching where appropriate
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 19:41:06 GMT
---
# Implementing Dart Patterns

## Contents
- [Decision Matrix: Switch Statements vs. Expressions](#decision-matrix-switch-statements-vs-expressions)
- [Applying Pattern Types](#applying-pattern-types)
- [Workflow: Implementing Algebraic Data Types (ADTs)](#workflow-implementing-algebraic-data-types-adts)
- [Workflow: Validating and Destructuring JSON](#workflow-validating-and-destructuring-json)
- [Examples](#examples)

## Decision Matrix: Switch Statements vs. Expressions

Apply the correct switch construct based on the execution context:

*   **If producing a value:** Use a **Switch Expression**. Use `=>` to separate cases from single-expression bodies. Do not use `default`; use the wildcard `_` for unmatched cases.
*   **If executing side-effects or statements:** Use a **Switch Statement**. Use `:` to separate cases from statement bodies. Allow empty cases to fall through to share a body. Use `break` to prevent fall-through in empty cases.
*   **If testing a single value against a single pattern:** Use an **If-Case Statement** (`if (value case pattern) { ... }`).

## Applying Pattern Types

Implement specific pattern types to handle complex matching and destructuring operations:

*   **Logical-or (`||`):** Share a body or guard across multiple cases. Ensure both branches define the exact same set of variables.
*   **Logical-and (`&&`):** Match multiple conditions simultaneously. Ensure variables defined in each branch do not overlap.
*   **Relational (`>=`, `<=`, `==`):** Match numeric ranges or specific constant comparisons.
*   **Record (`(x: var a, y: var b)`):** Destructure record fields. Omit the field name to infer it from the variable pattern (e.g., `(:var x, :var y)`).
*   **List (`[a, b, ...rest]`):** Destructure arrays. Use the rest element (`...`) to capture remaining elements into a new list.
*   **Map (`{"key": var value}`):** Destructure key-value pairs. Map patterns ignore unmatched keys automatically.
*   **Object (`ClassName(field: var x)`):** Destructure class instances using their getters.
*   **Wildcard (`_`):** Ignore parts of a matched value.
*   **Null-check (`?`):** Match only if the value is non-null, binding the variable to the non-nullable base type.
*   **Null-assert (`!`):** Force a match on non-null values, throwing an exception if the value is null.
*   **Cast (`as`):** Forcibly assert the expected type of a destructured value during the match.

## Workflow: Implementing Algebraic Data Types (ADTs)

Use this workflow to model and process families of related types using exhaustive pattern matching.

**Task Progress:**
- [ ] 1. Define a `sealed` base class to enable compiler exhaustiveness checking.
- [ ] 2. Define subclasses extending or implementing the `sealed` base class.
- [ ] 3. Implement a Switch Expression that takes the base class as input.
- [ ] 4. Write an Object Pattern case for every subclass, destructuring necessary properties.
- [ ] 5. Run validator -> review exhaustiveness errors -> fix missing subclass cases.

## Workflow: Validating and Destructuring JSON

Use this workflow to safely parse dynamic or untyped data structures.

**Task Progress:**
- [ ] 1. Implement an If-Case Statement to evaluate the incoming dynamic data.
- [ ] 2. Define a Map Pattern matching the expected JSON schema.
- [ ] 3. Nest List, Record, or Object patterns within the Map Pattern to validate deep structures.
- [ ] 4. Bind extracted values to strongly-typed local variables within the pattern.
- [ ] 5. Implement an `else` block to handle validation failures.
- [ ] 6. Run validator -> review type cast/match errors -> fix schema mismatches.

## Examples

### High-Fidelity JSON Validation
Validate and destructure a complex JSON payload in a single statement.

```dart
void processPayload(dynamic json) {
  if (json case {'user': [String name, int age]} when age >= 18) {
    // 'name' and 'age' are strongly typed and guaranteed valid.
    print('Authorized adult user: $name ($age)');
  } else {
    throw FormatException('Invalid payload or unauthorized user.');
  }
}
```

### Exhaustive ADT Switch Expression
Model shapes and calculate area using a `sealed` class and Object Patterns.

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

double calculateArea(Shape shape) => switch (shape) {
  Square(length: var l) => l * l,
  Circle(radius: var r) => math.pi * r * r,
};
```

### Variable Swapping via Destructuring
Swap variables in-place using a variable assignment pattern.

```dart
void swapCoordinates() {
  var (x, y) = ('left', 'right');
  (y, x) = (x, y); 
}
```

### Guard Clauses and Logical-Or
Combine patterns and guards to handle complex shared logic.

```dart
void evaluateShape(Shape shape) {
  switch (shape) {
    case Square(length: var s) || Circle(radius: var s) when s > 0:
      print('Valid symmetric shape with size $s');
    case Square() || Circle():
      print('Empty shape');
  }
}
```
