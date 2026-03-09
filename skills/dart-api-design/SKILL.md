---
name: "dart-api-design"
description: "Apply design principles to create intuitive and robust library interfaces."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:35:35 GMT"

---
# Dart Effective Design

## Goal
Analyzes and refactors Dart code to enforce idiomatic API design, strict type safety, and robust object-oriented hierarchies. Applies Dart 3 class modifiers to control extension and implementation boundaries, ensures proper encapsulation through getters and setters, and standardizes naming conventions for predictable, maintainable libraries.

## Instructions

1.  **Apply Naming Conventions**
    *   Use noun phrases for non-boolean properties/variables (e.g., `list.length`).
    *   Use non-imperative verb phrases for boolean properties (e.g., `isEmpty`, `canClose`).
    *   Use imperative verbs for methods with side effects (e.g., `list.add()`).
    *   Use `to___()` for methods that copy state to a new object (e.g., `list.toSet()`).
    *   Use `as___()` for methods returning a different representation backed by the original object (e.g., `map.asMap()`).
    *   Follow standard generic type parameter mnemonics: `E` (elements), `K`/`V` (key/value), `R` (return type), `T`/`S`/`U` (general).

2.  **Determine Class Modifiers (Decision Logic)**
    Evaluate every class declaration against the intended API boundary.
    *   *Does the class require a full, concrete implementation of its interface?*
        *   **No:** Use `abstract class`.
    *   *Should external libraries be allowed to implement the class interface, but NOT inherit its implementation?*
        *   **Yes:** Use `interface class` (or `abstract interface class` for pure interfaces).
    *   *Should external libraries be allowed to inherit the implementation, but NOT implement the interface?*
        *   **Yes:** Use `base class`. (Note: Subclasses must be marked `base`, `final`, or `sealed`).
    *   *Is the class part of a closed, enumerable set of subtypes for exhaustive switching?*
        *   **Yes:** Use `sealed class`.
    *   *Should the class be completely locked from external extension and implementation?*
        *   **Yes:** Use `final class`.
    *   *Does the class contain only a single abstract method (e.g., `call`)?*
        *   **Yes:** Convert to a `typedef` function type.
    *   *Does the class contain only static members?*
        *   **Yes:** Move members to top-level library declarations.
    *   **STOP AND ASK THE USER:** If the extension/implementation intent of a public class is ambiguous, pause and ask the user to clarify the intended API boundary before applying modifiers.

3.  **Enforce Parameter Rules**
    *   Prefer named parameters for functions with more than two arguments.
    *   Avoid positional boolean parameters.
    *   Omit the verb (`is`, `can`, `has`) for named boolean parameters.
    *   Use inclusive start and exclusive end parameters for ranges.
    
    ```dart
    // GOOD
    void configure(String name, {bool paused = false, bool growable = true}) {}
    var sub = items.sublist(0, 3); 
    
    // BAD
    void configure(String name, bool isPaused, bool canGrow) {}
    ```

4.  **Manage State and Encapsulation**
    *   Prefer `final` for fields and top-level variables.
    *   Avoid public fields; use getters and setters for encapsulation.
    *   Do not define a setter without a corresponding getter.
    *   Avoid public `late final` fields without initializers (this implicitly exposes a setter).
    *   Use getters for operations that conceptually access properties (no arguments, returns a result, idempotent, no user-visible side effects).

    ```dart
    // GOOD
    class Rectangle {
      double _width;
      Rectangle(this._width);
      
      double get width => _width;
      set width(double value) => _width = value;
      
      double get area => _width * _width; // Idempotent, no side effects
    }
    ```

5.  **Apply Strict Type Annotations**
    *   Annotate variables without initializers.
    *   Annotate fields and top-level variables if the type isn't obvious.
    *   Annotate return types and parameter types on non-local function declarations.
    *   Do NOT redundantly annotate initialized local variables.
    *   Do NOT annotate inferred parameter types on function expressions (closures).
    *   Do NOT type annotate initializing formals (`this.x`).
    *   Use inline function types over legacy typedefs.
    *   Use `Future<void>` (not `void` or `Future<Null>`) for async members that do not produce values.
    *   Avoid `FutureOr<T>` as a return type; return `Future<T>` instead.

    ```dart
    // GOOD
    typedef Comparison<T> = int Function(T a, T b);
    
    class FilteredObservable {
      final bool Function(Event) _predicate; // Inline function type
      FilteredObservable(this._predicate);
    }
    ```

6.  **Implement Equality Safely**
    *   If overriding `==`, you MUST override `hashCode`.
    *   Ensure `==` is reflexive, symmetric, and transitive.
    *   Avoid defining custom equality for mutable classes.
    *   Do not make the parameter to `==` nullable (`Object` instead of `Object?`).

    ```dart
    // GOOD
    class Person {
      final String name;
      Person(this.name);

      @override
      bool operator ==(Object other) => other is Person && name == other.name;

      @override
      int get hashCode => name.hashCode;
    }
    ```

## Constraints
*   **No Positional Booleans:** Never generate function signatures with positional boolean arguments.
*   **No Legacy Typedefs:** Never use the `typedef name(args)` syntax. Always use `typedef Name = ReturnType Function(args)`.
*   **No Faked Overloading:** Do not use runtime type tests (`is`) to fake method overloading. Create distinctly named methods instead.
*   **No Nullable Collections:** Avoid returning nullable `Future`, `Stream`, or collection types. Return empty collections instead.
*   **No Fluent `this`:** Avoid returning `this` from methods just to enable a fluent interface; rely on Dart's cascade operator (`..`) instead.
*   **No Raw Types:** Never write incomplete generic types (e.g., `List numbers = []`). Always specify type arguments or rely on complete inference.
*   **Related Skills:** `dart-effective-style`, `dart-package-management`.
