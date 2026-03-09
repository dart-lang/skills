---
name: "dart-api-design"
description: "Apply design principles to create intuitive and robust library interfaces."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:45:09 GMT"

---
# Dart API Design and Class Modifiers

## Goal
Enforces idiomatic Dart API design principles, strict naming conventions, and precise access control using class modifiers. Analyzes Dart codebases to refactor classes, members, and types for optimal maintainability, encapsulation, and static safety, assuming a modern Dart 3.0+ environment.

## Instructions

1. **Analyze the Target Code**
   Review the provided Dart code for structural integrity, naming conventions, and type safety. Identify areas lacking encapsulation, missing class modifiers, or using outdated Dart paradigms.

2. **Apply Naming and Type Conventions**
   Refactor identifiers and type annotations to match idiomatic Dart:
   * Use noun phrases for non-boolean properties (`pageCount`) and non-imperative verb phrases for booleans (`isEmpty`, `canClose`).
   * Use imperative verbs for side-effect methods (`list.add()`).
   * Use `to___()` for copying state to a new object, and `as___()` for returning a different representation backed by the original object.
   * Explicitly annotate return types, parameters, and uninitialized variables. Use `dynamic` explicitly if type inference should be disabled.
   * Replace legacy typedefs with inline function types or modern typedefs.

   ```dart
   // BAD
   typedef int Comparison<T>(T a, T b);
   getBreakfastOrder() { ... }
   
   // GOOD
   typedef Comparison<T> = int Function(T a, T b);
   Order get breakfastOrder => ...
   ```

3. **Refactor Parameters and Encapsulation**
   * Convert functions with more than two arguments to use named parameters.
   * Eliminate positional boolean parameters.
   * Replace public fields with private fields exposed via getters and setters.

   ```dart
   // BAD
   class Configuration {
     bool isEnabled;
     void setup(String name, int retries, bool force) { ... }
   }

   // GOOD
   class Configuration {
     bool _isEnabled = false;
     
     bool get isEnabled => _isEnabled;
     set isEnabled(bool value) => _isEnabled = value;

     void setup({
       required String name,
       int retries = 3,
       bool force = false,
     }) { ... }
   }
   ```

4. **Determine Class Modifiers (Decision Logic)**
   Apply the correct class modifiers to control external library access. Use the following decision tree:
   * **Does the class represent an enumerable set of subtypes for exhaustive switching?**
     * YES: Use `sealed class`.
   * **Should external libraries be completely prevented from extending OR implementing the class?**
     * YES: Use `final class`.
   * **Should external libraries be allowed to implement the interface, but NOT extend the implementation?**
     * YES: Use `interface class`.
   * **Should external libraries be allowed to extend the class, but NOT implement its interface (to guarantee base implementation)?**
     * YES: Use `base class`.
   * **Should the class prevent direct instantiation?**
     * YES: Prepend `abstract` (e.g., `abstract interface class`).

   ```dart
   // Example: Pure interface
   abstract interface class Vehicle {
     void moveForward(int meters);
   }

   // Example: Exhaustive subtypes
   sealed class NetworkResult {}
   class Success extends NetworkResult {}
   class Failure extends NetworkResult {}
   ```

5. **Interactive Checkpoint**
   **STOP AND ASK THE USER:** "Please provide the Dart code you would like me to refactor. Are there any specific external libraries that need to extend or implement these classes, which would affect the choice of class modifiers?"

6. **Validate-and-Fix**
   After generating the refactored code, verify the following:
   * Are there any 1-member abstract classes? If so, convert them to `typedef` or inline function types.
   * Are there any classes containing only static members? If so, extract them to top-level functions/variables.
   * Do all overridden `==` operators also override `hashCode`?
   * Fix any violations found during this validation step before presenting the final code.

## Constraints
* DO NOT use public fields; strictly use getters and setters for encapsulation.
* DO NOT use positional boolean parameters.
* DO NOT define a setter without a corresponding getter.
* DO NOT use runtime type tests (`is`) to fake method overloading; use distinct method names.
* DO NOT return `this` from methods just to enable a fluent interface; use Dart's cascade operator (`..`) instead.
* DO NOT use the legacy typedef syntax.
* DO NOT type annotate initializing formals (`this.x`) or inferred closure parameters.
* ALWAYS prefer named parameters for functions with more than two arguments.
* ALWAYS use inclusive start and exclusive end parameters for ranges.
