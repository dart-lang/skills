---
name: "dart-idiomatic-usage"
description: "Apply Effective Dart usage patterns for cleaner and more efficient code."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:30:31 GMT"

---
# Dart Effective Strings and Collections

## Goal
Analyzes and refactors Dart code to comply with the official "Effective Dart: Usage" guidelines specifically targeting string manipulation and collection handling. It enforces idiomatic syntax, optimizes performance by eliminating anti-patterns (like `.length` checks or `.cast()`), and ensures type-safe collection transformations. Assumes a modern Dart environment with null safety enabled.

## Instructions

1. **String Concatenation and Interpolation**
   * Scan the code for string concatenations using the `+` operator.
   * Replace adjacent string literal concatenations with adjacent strings (no operator).
   * Replace variable concatenations with string interpolation.
   * Remove unnecessary curly braces in interpolations where the identifier is not followed by alphanumeric text.
   ```dart
   // BAD
   var s1 = 'Hello ' + name + '!';
   var s2 = 'Hi, ${name}!';
   var s3 = 'Part 1 ' + 
            'Part 2';

   // GOOD
   var s1 = 'Hello $name!';
   var s2 = 'Hi, $name!';
   var s3 = 'Part 1 '
            'Part 2';
   ```

2. **Collection Initialization**
   * Replace unnamed constructor calls for `Map`, `Set`, and `List` with collection literals.
   * Utilize the spread operator (`...`, `...?`) and collection `if`/`for` for dynamic collection building instead of `.add()` or `.addAll()`.
   ```dart
   // BAD
   var addresses = Map<String, Address>();
   var counts = Set<int>();
   var args = <String>[];
   args.addAll(options);
   if (flag != null) args.add(flag);

   // GOOD
   var addresses = <String, Address>{};
   var counts = <int>{};
   var args = [
     ...options,
     if (flag != null) flag,
   ];
   ```

3. **Collection Emptiness Checks**
   * Identify any collection checks comparing `.length` to `0`.
   * Replace them with `.isEmpty` or `.isNotEmpty`.
   ```dart
   // BAD
   if (items.length == 0) return;
   if (items.length > 0) process(items);

   // GOOD
   if (items.isEmpty) return;
   if (items.isNotEmpty) process(items);
   ```

4. **Iteration Logic (Decision Tree)**
   Evaluate how iterables are being processed and apply the following logic:
   * **IF** iterating over a `Map` -> **THEN** `map.forEach((k, v) { ... })` is acceptable.
   * **IF** applying an existing function (tear-off) to an `Iterable` -> **THEN** use `iterable.forEach(functionName)`.
   * **IF** executing a function literal/block on an `Iterable` -> **THEN** use a `for-in` loop.
   ```dart
   // BAD
   people.forEach((person) {
     person.greet();
   });

   // GOOD
   for (final person in people) {
     person.greet();
   }

   // GOOD (Tear-off)
   people.forEach(print);
   ```

5. **Type Filtering and Casting (Decision Tree)**
   Evaluate how collections are transformed or filtered by type:
   * **IF** filtering an iterable to a specific type -> **THEN** use `.whereType<T>()`. Do NOT use `.where((e) => e is T)`.
   * **IF** copying an iterable while preserving its original type -> **THEN** use `.toList()`.
   * **IF** copying an iterable and changing its type -> **THEN** use `List<T>.from(iterable)`.
   * **IF** `.cast<T>()` is used -> **THEN** refactor to avoid it. Prefer creating the collection with the correct type, casting elements on access, or eagerly casting with `List<T>.from()`.
   ```dart
   // BAD
   var ints = objects.where((e) => e is int).cast<int>();
   var copy = List.from(iterable); // when type change isn't needed
   var casted = objects.cast<int>();

   // GOOD
   var ints = objects.whereType<int>();
   var copy = iterable.toList();
   var casted = List<int>.from(objects); // Eager cast
   ```

6. **Validate-and-Fix Loop**
   * Review the refactored code.
   * Verify that no `+` operators remain for string concatenation.
   * Verify that `.cast()` is completely eliminated unless explicitly justified by lazy-evaluation requirements.
   * **STOP AND ASK THE USER:** If the original code relies heavily on lazy evaluation via `.cast()` and converting to `List.from()` might cause performance regressions on massive datasets, pause and ask: *"Refactoring `.cast()` to `List.from()` forces eager evaluation. Is this collection large enough that we need to preserve lazy evaluation, or is eager instantiation acceptable?"*

## Constraints

* DO NOT use `Map()`, `Set()`, or `List()` unnamed constructors.
* DO NOT use `.length == 0` or `.length > 0` for iterables.
* DO NOT use `Iterable.forEach()` with a function literal.
* DO NOT use `.cast()` when a nearby operation (like `List.from()` or `.map<T>()`) will suffice.
* DO NOT use `where((e) => e is T)`; strictly enforce `whereType<T>()`.
* DO NOT use `+` for string concatenation of literals or variables.
* PREFER string interpolation (`$variable`) over concatenation.
* PREFER the spread operator (`...`) and collection-if/for over imperative `.add()`/`.addAll()` mutations.
* AVOID curly braces in string interpolation unless required for expression evaluation or disambiguation.
