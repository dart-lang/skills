---
name: "dart-language-syntax"
description: "Master core and advanced language syntax for expressive and type-safe code."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:30:03 GMT"

---
# dart-advanced-syntax-and-patterns

## Goal
Implements idiomatic Dart code leveraging advanced syntax, including pattern matching, records, generics, and sound null safety, to produce robust, type-safe, and concise applications. This skill assumes a Dart 3.0+ environment and focuses on applying modern language features to optimize data structures, control flow, and API design.

## Instructions

1. **Variable Declaration and Null Safety**
   Apply sound null safety and strict mutability rules when declaring variables.
   * Use `var` for local variables with obvious types.
   * Use `final` for variables that should not be reassigned.
   * Use `const` for compile-time constants.
   * Use `late` only when control flow analysis fails to detect initialization, or for expensive lazy initialization.
   * Use wildcard variables `_` for non-binding placeholders (requires Dart 3.7+).
   ```dart
   final name = 'Bob'; // Immutable
   var count = 0; // Obvious type
   late final String expensiveResult = computeExpensiveValue();
   
   // Wildcard usage
   for (var _ in list) {
     print('Iterating without binding');
   }
   ```

2. **Function Design and Tear-offs**
   Structure functions using named parameters, optional positional parameters, and tear-offs for concise callbacks.
   * Use `required` for mandatory named parameters.
   * Prefer tear-offs over lambdas when passing functions directly.
   ```dart
   // Named parameters with required and default values
   void configure({required String id, bool verbose = false}) { ... }

   // Tear-offs
   final charCodes = [68, 97, 114, 116];
   final buffer = StringBuffer();
   charCodes.forEach(buffer.write); // Method tear-off
   ```

3. **Implementing Records for Multiple Returns**
   Use records `(...)` to return multiple values without defining a dedicated class.
   ```dart
   // Returning a record
   (String, int) fetchUserInfo(Map<String, dynamic> json) {
     return (json['name'] as String, json['age'] as int);
   }

   // Returning a record with named fields
   ({String name, int age}) fetchNamedUserInfo() {
     return (name: 'Dash', age: 10);
   }
   ```

4. **Pattern Matching and Destructuring (Decision Logic)**
   Master pattern matching in assignments, switch statements, and JSON validation. Follow this decision logic when handling complex data:
   * *If extracting values from a record or collection:* Use variable assignment/declaration patterns.
   * *If branching logic based on object shape or type:* Use `switch` expressions with pattern matching and guard clauses (`when`).
   * *If validating external data (e.g., JSON):* Use `if-case` statements with map/list patterns.
   
   ```dart
   // Destructuring a record
   var (name, age) = fetchUserInfo(json);

   // Switch expression with algebraic data types and guards
   double calculateArea(Shape shape) => switch (shape) {
     Square(length: final l) when l > 0 => l * l,
     Circle(radius: final r) => math.pi * r * r,
     _ => throw ArgumentError('Invalid shape'),
   };

   // JSON Validation using if-case
   if (json case {'user': [String name, int age]}) {
     print('User $name is $age years old.');
   } else {
     // Handle invalid JSON structure
   }
   ```

5. **Generics and Type Safety**
   Implement generics `<T>` to ensure type safety in reusable components. Apply bounds (`extends`) to restrict parameterized types.
   ```dart
   // Restricting to non-nullable types
   class Cache<T extends Object> {
     final Map<String, T> _storage = {};
     
     T? getByKey(String key) => _storage[key];
     void setByKey(String key, T value) => _storage[key] = value;
   }

   // Generic method
   T first<T>(List<T> items) {
     if (items.isEmpty) throw StateError('No elements');
     return items[0];
   }
   ```

6. **Extension Methods and Types**
   Use extension methods and types to add functionality to existing classes or to create zero-cost abstractions over records/types.
   ```dart
   extension type ButtonItem._(({String label, void Function() onPressed}) _) {
     ButtonItem({required String label, required void Function() onPressed})
         : this._((label: label, onPressed: onPressed));
         
     String get label => _.label;
     void Function() get onPressed => _.onPressed;
   }
   ```

7. **Validate and Fix**
   After generating Dart code, verify that:
   * No null dereference errors are possible.
   * Records are used instead of custom classes for simple data tuples.
   * Pattern matching is used for JSON validation instead of verbose `is` checks.
   * **STOP AND ASK THE USER:** If the data structure shape for pattern matching is ambiguous or not provided, pause and ask the user for the expected JSON/Object schema before writing the destructuring logic.

## Constraints
* DO NOT use `var` if the assigned type is not immediately obvious to the reader; use explicit types instead.
* DO NOT use `dynamic` unless explicitly interacting with untyped external APIs (and immediately cast/validate it using patterns).
* DO NOT define a class just to return multiple values from a function; strictly use records.
* DO NOT use multiple underscores (`__`, `___`) for unused variables; use the single wildcard `_`.
* DO NOT wrap tear-offs in anonymous functions (e.g., avoid `list.forEach((e) => print(e))`; use `list.forEach(print)`).
* DO NOT use `is` checks and manual casting for JSON validation; strictly use `if-case` pattern matching.
* Related Skills: `dart-idiomatic-usage`.
