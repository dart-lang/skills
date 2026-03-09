---
name: "dart-effective-style"
description: "Maintain code consistency by following official Dart style and naming conventions."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:28:16 GMT"

---
# dart-style-guide

## Goal
Applies idiomatic Dart styling, naming conventions, and formatting rules to ensure consistent, readable, and maintainable code across Dart and Flutter projects. Assumes a standard Dart SDK environment where the `dart` CLI is available.

## Instructions

1. **Apply Naming Conventions**
   Ensure all identifiers match Dart's official style guidelines. Use the Decision Logic section below to determine the correct casing for any given identifier.

2. **Order Directives**
   Organize all imports and exports at the top of the file in the following strict order, separated by blank lines, and sorted alphabetically within each group:
   * `dart:` imports.
   * `package:` imports.
   * Relative imports.
   * `export` directives.

   ```dart
   import 'dart:async';
   import 'dart:collection';

   import 'package:bar/bar.dart';
   import 'package:foo/foo.dart';

   import 'util.dart';

   export 'src/error.dart';
   ```

3. **Format Code**
   Always format the code using the official Dart formatter. If the formatter produces hard-to-read code, refactor the code (e.g., extract variables) to be more formatter-friendly.
   ```bash
   dart format .
   ```

4. **Enforce Flow Control Braces**
   Always use curly braces for flow control statements to prevent the dangling else problem.
   ```dart
   // GOOD
   if (isWeekDay) {
     print('Bike to work!');
   } else {
     print('Go dancing or read a book!');
   }

   // ACCEPTABLE (Single line, no else)
   if (arg == null) return defaultValue;
   ```

5. **Handle Unused Callback Parameters**
   Use wildcards (`_`) for unused callback parameters to signal intent.
   ```dart
   futureOfVoid.then((_) {
     print('Operation complete.');
   });

   // Multiple unused parameters
   .onError((_, __) {
     print('Operation failed.');
   });
   ```

## Decision Logic

When creating or renaming an identifier, follow this flowchart logic:

* **Is it a Class, Enum, Typedef, Extension, or Type Parameter?**
  * **Yes:** Use `UpperCamelCase`.
    ```dart
    class SliderMenu {}
    typedef Predicate<T> = bool Function(T value);
    extension SmartIterable<T> on Iterable<T> {}
    ```
* **Is it a Package, Directory, Source File, or Import Prefix?**
  * **Yes:** Use `lowercase_with_underscores`.
    ```dart
    import 'dart:math' as math;
    import 'package:js/js.dart' as js;
    // File: slider_menu.dart
    ```
* **Is it a Constant Variable or Enum Value?**
  * **Yes:** Use `lowerCamelCase` (Do NOT use `SCREAMING_CAPS` unless matching legacy code).
    ```dart
    const pi = 3.14;
    const defaultTimeout = 1000;
    ```
* **Is it a Variable, Parameter, Named Parameter, Class Member, or Top-Level Definition?**
  * **Yes:** Use `lowerCamelCase`.
    ```dart
    var count = 3;
    HttpRequest httpRequest;
    ```
* **Does the name contain an Acronym or Abbreviation?**
  * **Is it longer than two letters?** Capitalize it like a normal word (e.g., `Http`, `Uri`).
  * **Is it exactly two letters?** Keep both capitalized (e.g., `ID`, `TV`) *unless* it is the start of a `lowerCamelCase` identifier, in which case both are lowercase (e.g., `idToken`, `tvSet`).
* **Is the member or top-level declaration meant to be private to its library?**
  * **Yes:** Prefix it with a leading underscore `_`.
  * **No:** Do NOT use a leading underscore. (Never use leading underscores for local variables or parameters).

## Constraints

* **Mandatory Formatting:** DO run `dart format` as a mandatory step before committing or finalizing any code changes.
* **Import Preferences:** PREFER relative imports for files located inside the `lib` directory of the same package.
* **No Prefix Letters:** DON'T use prefix letters (like Hungarian notation). Use `defaultTimeout`, not `kDefaultTimeout`.
* **No Explicit Library Names:** DON'T explicitly name libraries (e.g., avoid `library my_library;`). Use `library;` if a directive is needed for annotations.
* **Line Length:** PREFER lines 80 characters or fewer. **STOP AND ASK THE USER:** if a specific string or configuration requires exceeding the 80-character limit and cannot be reasonably refactored.
* **Related Skills:** `dart-static-analysis`, `dart-api-design`.
