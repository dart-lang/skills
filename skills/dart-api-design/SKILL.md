---
name: dart-api-design
description: Apply design principles to create intuitive and robust library interfaces.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:22:40 GMT
---
# Designing Effective Dart APIs

## Contents
- [Naming Conventions](#naming-conventions)
- [Class Modifiers & Architecture](#class-modifiers--architecture)
- [Members & Encapsulation](#members--encapsulation)
- [Types & Signatures](#types--signatures)
- [Parameters](#parameters)
- [Workflows](#workflows)

## Naming Conventions

Enforce consistent, descriptive naming to leverage existing domain and core library knowledge.

- **Properties & Variables**: 
  - Use noun phrases for non-boolean properties (e.g., `pageCount`, `context.lineWidth`).
  - Use non-imperative verb phrases for boolean properties (e.g., `isEmpty`, `canClose`). Prefer the "positive" name (e.g., `isConnected` over `isNotDisconnected`).
- **Methods & Functions**:
  - Use imperative verb phrases for side-effect-heavy operations (e.g., `list.add()`, `window.refresh()`).
  - Use noun phrases or non-imperative verb phrases if returning a value is the primary purpose (e.g., `list.elementAt(3)`).
  - **AVOID** starting method names with `get`. Use a getter or a descriptive verb (e.g., `downloadData()`).
  - Name methods `to___()` if they copy state to a new object (e.g., `list.toSet()`).
  - Name methods `as___()` if they return a different representation backed by the original object (e.g., `table.asMap()`).
- **Type Parameters**: Follow standard mnemonics: `E` (elements), `K`/`V` (key/value), `R` (return type), or `T`/`S`/`U` (single types).

## Class Modifiers & Architecture

Design for extension and encapsulate implementations using Dart 3 class modifiers. Apply modifiers to control external library access.

- **`abstract`**: Use to define a class that requires concrete implementation of its interface. Cannot be instantiated.
- **`base`**: Use to enforce inheritance of a class's implementation. Disallows `implements` outside its own library. Guarantees the base class constructor is called.
- **`interface`**: Use to define a pure interface. Allows `implements` but disallows `extends` outside its library. Reduces the fragile base class problem.
- **`final`**: Use to close the type hierarchy. Disallows both `extends` and `implements` outside the library. Guarantees safe incremental API changes.
- **`sealed`**: Use to create a known, enumerable set of subtypes. Enables exhaustive `switch` statements over subtypes. Implicitly abstract.

*Note: Combine modifiers where appropriate (e.g., `abstract interface class` for a pure interface).*

## Members & Encapsulation

- **Encapsulation**: AVOID public fields; use getters and setters for encapsulation to control state access and modification.
- **Getters**: Use getters for operations that conceptually access properties. The operation must take no arguments, return a result, have no user-visible side effects, and be idempotent.
- **Setters**: Use setters for operations that conceptually change properties. The operation must take a single argument, change state, and be idempotent.
  - **DON'T** define a setter without a corresponding getter.
  - **DON'T** specify a return type for a setter (they inherently return `void`).
- **Method Cascades**: AVOID returning `this` from methods just to enable a fluent interface. Use Dart's cascade operator (`..`) instead.
- **Equality**: 
  - DO override `hashCode` if you override `==`.
  - AVOID defining custom equality for mutable classes.
  - DON'T make the parameter to `==` nullable (the language handles `null` checks automatically).

## Types & Signatures

- **Type Aliases**: DO use type aliases (`typedef`) to simplify complex function signatures. Use the modern syntax: `typedef Comparison<T> = int Function(T a, T b);`.
- **Inline Functions**: PREFER inline function types over typedefs for simple, one-off callbacks (e.g., `void Function(Event) callback`).
- **Type Annotations**: 
  - DO type annotate variables without initializers.
  - DO annotate return types and parameter types on non-local function declarations.
  - DON'T redundantly type annotate initialized local variables or inferred closure parameters.
- **Generics**: Write complete generic types. AVOID incomplete generic types (e.g., use `Completer<Map<String, int>>()` instead of `Completer<Map>()`).
- **Dynamic vs. Object**: AVOID using `dynamic` unless you explicitly want to disable static checking. Use `Object?` to accept any value safely.
- **Async Returns**: DO use `Future<void>` as the return type of asynchronous members that do not produce values. AVOID using `FutureOr<T>` as a return type (it forces callers to check the type).

## Parameters

- **Named Parameters**: PREFER named parameters for functions with more than two arguments to improve call-site readability.
- **Boolean Parameters**: AVOID positional boolean parameters. Use named parameters instead.
  - CONSIDER omitting the 'is/can/has' prefix from named boolean parameters (e.g., use `Isolate.spawn(..., paused: true)` instead of `isPaused: true`).
- **Optional Positional Parameters**: AVOID optional positional parameters if the user may want to omit earlier parameters. Use named parameters instead.
- **Ranges**: DO use inclusive `start` and exclusive `end` parameters to accept a range (e.g., `substring(1, 3)`).

## Workflows

### Task Progress: API Design & Implementation
Copy this checklist to track progress when designing a new Dart class or library API.

- [ ] **Define Class Modifiers**:
  - [ ] If defining a contract without implementation -> `abstract interface class`.
  - [ ] If providing implementation that must be inherited -> `base class`.
  - [ ] If closing the hierarchy to external extension/implementation -> `final class`.
  - [ ] If defining an enumerable set of states for exhaustive switching -> `sealed class`.
- [ ] **Encapsulate State**:
  - [ ] Make internal fields private (`_fieldName`).
  - [ ] Expose state via getters.
  - [ ] Expose mutations via setters (ensure a corresponding getter exists).
- [ ] **Refine Signatures**:
  - [ ] Convert positional parameters to named parameters if > 2 arguments.
  - [ ] Convert positional booleans to named booleans (strip `is/can/has` prefixes).
  - [ ] Extract complex function parameters into `typedef` aliases.
- [ ] **Verify Types**:
  - [ ] Ensure no implicit `dynamic` types exist in public signatures.
  - [ ] Replace `FutureOr<T>` return types with `Future<T>`.
  - [ ] Ensure async void methods return `Future<void>`.
- [ ] **Run Validator -> Review Errors -> Fix**:
  - Run `dart analyze` to catch missing annotations, unhandled sealed class switch cases, and linter violations. Fix all warnings before finalizing the API.
