---
name: "dart-idiomatic-usage"
description: "Apply Effective Dart usage patterns for cleaner and more efficient code."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:40:33 GMT"

---
# Effective Dart Usage Refactoring

## Goal
Analyzes and refactors Dart code to strictly adhere to the "Effective Dart: Usage" guidelines. It optimizes code for readability, performance, and idiomatic Dart patterns, specifically targeting collections, strings, null safety, and asynchronous operations. Assumes the target environment supports Dart 3.0+ and sound null safety.

## Decision Logic

When evaluating Dart code, apply the following decision tree to determine the correct refactoring path:

*   **Strings:**
    *   If concatenating string literals -> Use adjacent strings.
    *   If composing strings with variables -> Use string interpolation (`$variable` or `${expression}`).
    *   If interpolating a simple identifier -> Omit curly braces (`$variable` instead of `${variable}`).
*   **Collections:**
    *   If instantiating a List, Map, or Set -> Use collection literals (`[]`, `<String, dynamic>{}`).
    *   If checking if a collection has elements -> Use `.isEmpty` or `.isNotEmpty` (never `.length == 0`).
    *   If iterating to apply a function -> Use a `for-in` loop (avoid `Iterable.forEach` with function literals).
    *   If filtering a collection by type -> Use `.whereType<T>()` (never `.where((e) => e is T)`).
    *   If changing the type of an iterable -> Use `List<T>.from()` or `.map<T>()` (avoid `.cast<T>()`).
*   **Nullability & Variables:**
    *   If initializing a nullable variable -> Omit explicit `= null`.
    *   If checking boolean equality -> Use `if (condition)` or `if (!condition)` (never `== true` or `== false`).
    *   If checking initialization state -> Avoid `late` variables; use nullable types and check for `null`.

## Instructions

1. **Analyze the Source Code:** Review the provided Dart code against the "Effective Dart: Usage" guidelines. Identify violations related to strings, collections, variables, and asynchrony.
2. **Refactor Strings:**
   Replace manual concatenation with adjacent strings or interpolation.
   ```dart
   // BAD
   var bad = 'Hello, ' + name + '!';
   var badAdjacent = 'Long ' + 'string';
   var badBraces = 'Hi, ${name}!';

   // GOOD
   var good = 'Hello, $name!';
   var goodAdjacent = 'Long '
       'string';
   var goodBraces = 'Hi, $name!';
   ```
3. **Refactor Collections:**
   Convert constructors to literals, utilize spread operators, and replace length checks.
   ```dart
   // BAD
   var addresses = Map<String, Address>();
   if (lunchBox.length == 0) return;
   var ints = objects.where((e) => e is int).cast<int>();
   var copy = stuff.toList().cast<int>();

   // GOOD
   var addresses = <String, Address>{};
   if (lunchBox.isEmpty) return;
   var ints = objects.whereType<int>();
   var copy = List<int>.from(stuff);
   
   // Dynamic lists using spread and collection-if
   var arguments = [
     ...options,
     if (modeFlags != null) ...modeFlags,
   ];
   ```
4. **Refactor Nulls and Variables:**
   Remove redundant null initializations and boolean checks.
   ```dart
   // BAD
   Item? bestItem = null;
   if (isValid == true) {}

   // GOOD
   Item? bestItem;
   if (isValid) {}
   ```
5. **STOP AND ASK THE USER:** 
   **"Do you want me to also apply structural refactorings for Asynchrony (e.g., replacing raw Futures with async/await) and Error Handling (e.g., adding `on` clauses to `catch` blocks)?"**
   *Wait for the user's confirmation before proceeding to step 6.*
6. **Refactor Asynchrony & Error Handling (If Approved):**
   ```dart
   // BAD
   Future<int> count() {
     return download().then((data) => data.length);
   }
   try { ... } catch (e) { ... } // Pokemon catching

   // GOOD
   Future<int> count() async {
     var data = await download();
     return data.length;
   }
   try { ... } on FormatException catch (e) { ... }
   ```
7. **Validate-and-Fix:** 
   Review the refactored code. Verify that no `.cast()` methods remain unless absolutely necessary, that all collection length checks use `.isEmpty`/`.isNotEmpty`, and that no explicit `= null` initializations exist. If any violations are found, fix them before outputting the final code.

## Constraints

*   **DO NOT** use `Iterable.forEach()` with function literals; always use `for-in` loops.
*   **DO NOT** use `.length == 0` or `.length > 0` for collections. Strictly use `.isEmpty` and `.isNotEmpty`.
*   **DO NOT** use `.cast()` to change collection types. Prefer `List.from()`, `Map.from()`, or `.whereType<T>()`.
*   **DO NOT** explicitly initialize variables or optional parameters to `null`.
*   **DO NOT** use `new` to instantiate objects.
*   **DO NOT** use `this.` unless necessary to avoid variable shadowing or redirecting to a named constructor.
*   **DO** use collection literals (`[]`, `{}`) instead of constructors (`List()`, `Map()`, `Set()`).
*   **DO** use string interpolation (`$variable`) instead of concatenation (`+`).
*   **DO** use the spread operator (`...`) and collection-if/for for dynamic lists instead of `.addAll()`.
