---
name: "dart-language-syntax"
description: "Master core and advanced language syntax for expressive and type-safe code."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:40:04 GMT"

---
# dart-modern-syntax-mastery

Analyzes, refactors, and generates modern Dart code utilizing advanced language features such as pattern matching, records, sound null safety, generics, and functional programming paradigms. Applies strict typing rules, destructuring, and concise control flow to build robust, type-safe, and maintainable Dart applications.

## Goal
Generate idiomatic, highly optimized Dart 3+ code that leverages modern syntax (records, patterns, advanced generics, and null safety) while adhering to strict style guidelines. Assume the environment supports Dart 3.11+ and sound null safety.

## Instructions

1. **Variable Declaration and Null Safety**
   Apply sound null safety and strict mutability rules.
   * Use `var` for local variables where the type is obvious.
   * Use `final` for variables that will not be reassigned.
   * Use `const` for compile-time constants, but avoid redundant `const` keywords.
   * Use the wildcard `_` for non-binding placeholders.
   ```dart
   // Good
   var name = 'Bob'; 
   final String nickname = 'Bobby';
   const bar = 1000000;
   
   // Null safety and late initialization
   int? lineCount;
   late String temperature = readThermometer(); // Lazily initialized
   
   // Wildcards
   var _ = 1;
   for (var _ in list) {}
   ```

2. **Function Design and Tear-offs**
   Implement concise functions using arrow syntax, named parameters, and tear-offs.
   * Use `=>` for single-expression functions.
   * Prefer named parameters with `required` or default values for clarity.
   * Use tear-offs instead of lambdas when passing methods directly.
   ```dart
   // Named and optional parameters
   void enableFlags({required Widget child, bool bold = false, bool? hidden}) { ... }
   
   // Tear-offs
   var charCodes = [68, 97, 114, 116];
   charCodes.forEach(print); // Instead of (code) => print(code)
   ```

3. **Returning Multiple Values (Records)**
   Use records `(...)` to return multiple values without defining a dedicated class.
   * Destructure records immediately upon return.
   * Use named fields `({ ... })` for complex records to improve readability.
   ```dart
   // Definition
   (String, int) userInfo(Map<String, dynamic> json) {
     return (json['name'] as String, json['age'] as int);
   }
   
   // Destructuring
   final (name, age) = userInfo(json);
   
   // Named fields
   ({String name, int age}) detailedUserInfo() => (name: 'Dash', age: 10);
   final (:name, :age) = detailedUserInfo();
   ```

4. **Pattern Matching and Destructuring (Decision Logic)**
   Apply pattern matching to simplify control flow, validate data, and destructure objects. Follow this decision logic when handling complex data:
   * **If validating external/JSON data:** Use Map/List patterns in an `if-case`.
   * **If handling Algebraic Data Types (ADTs):** Use `switch` expressions with object patterns.
   * **If extracting data from collections:** Use pattern matching in `for-in` loops.
   
   *JSON Validation Example:*
   ```dart
   if (data case {'user': [String name, int age]}) {
     print('User $name is $age years old.');
   }
   ```
   
   *ADT / Switch Expression Example:*
   ```dart
   sealed class Shape {}
   class Square implements Shape { final double length; Square(this.length); }
   class Circle implements Shape { final double radius; Circle(this.radius); }
   
   double calculateArea(Shape shape) => switch (shape) {
     Square(length: var l) => l * l,
     Circle(radius: var r) => math.pi * r * r,
   };
   ```
   
   *For-in Loop Destructuring Example:*
   ```dart
   Map<String, int> hist = {'a': 23, 'b': 100};
   for (var MapEntry(:key, value: count) in hist.entries) {
     print('$key occurred $count times');
   }
   ```

5. **Generics and Type Safety**
   Implement generics `<T>` to ensure type safety in reusable components. Use `extends` to restrict parameterized types (bounds).
   ```dart
   // Restricting types
   class Cache<T extends Object> {
     T getByKey(String key) => ...;
     void setByKey(String key, T value) { ... }
   }
   
   // Generic methods
   T first<T>(List<T> ts) {
     T tmp = ts[0];
     return tmp;
   }
   
   // F-bounds (Self-referential)
   int compareAndOffset<T extends Comparable<T>>(T t1, T t2) => t1.compareTo(t2) + 1;
   ```

6. **Extension Methods and Types**
   Use extensions to add functionality to existing classes without subclassing.
   ```dart
   extension type ButtonItem._(({String label, Icon icon, void Function()? onPressed}) _) {
     String get label => _.label;
     Icon get icon => _.icon;
     void Function()? get onPressed => _.onPressed;
     
     ButtonItem({required String label, required Icon icon, void Function()? onPressed})
         : this._((label: label, icon: icon, onPressed: onPressed));
         
     bool get hasOnPressed => _.onPressed != null;
   }
   ```

7. **Validation Checkpoint**
   **STOP AND ASK THE USER:** If the provided data structure or architectural requirement is ambiguous (e.g., choosing between a Record, a Class, or an Extension Type for a specific data model), pause and ask the user for their preference regarding mutability and abstraction level before generating the implementation.

## Constraints
* Do NOT use `var` if the type is not immediately obvious from the right-hand side of the assignment.
* Do NOT reassign variables declared with `final`.
* Do NOT use multiple underscores (e.g., `__`, `___`) for unused variables; strictly use the single wildcard `_`.
* Do NOT use redundant `const` keywords inside a collection that is already marked as `const`.
* Do NOT create single-use classes just to return multiple values; strictly use Records.
* Do NOT use `if/else` chains for type checking if a `switch` expression with pattern matching can be used.
* Ensure all generic type parameters are explicitly bounded if they must be non-nullable (e.g., `<T extends Object>`).
