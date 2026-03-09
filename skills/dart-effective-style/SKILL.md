---
name: "dart-effective-style"
description: "Maintain code consistency by following official Dart style and naming conventions."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:33:15 GMT"

---
# Dart Style and Formatting

## Goal
Analyzes, refactors, and formats Dart source code to strictly adhere to the official Effective Dart style guidelines. It enforces consistent identifier naming, directive ordering, and structural formatting, ensuring the codebase is idiomatic, readable, and fully compatible with standard Dart tooling.

## Decision Logic

When evaluating identifiers and directives, apply the following decision trees:

**Identifier Naming Flow:**
1. Is it a Class, Enum, Typedef, Type Parameter, or Extension? -> Use `UpperCamelCase`.
2. Is it a Package, Directory, Source File, or Import Prefix? -> Use `lowercase_with_underscores`.
3. Is it a Variable, Constant, Parameter, Named Parameter, or Method? -> Use `lowerCamelCase`.
4. Is it an unused callback parameter? -> Use `_` (wildcard).
5. Does the name contain an acronym?
   - > 2 letters (e.g., HTTP)? -> Capitalize like a word (`Http`).
   - 2 letters (e.g., ID, TV)? -> Keep capitalized if capitalized in English (`ID`, `TV`).

**Directive Ordering Flow:**
1. Is it a `dart:` import? -> Place in Section 1.
2. Is it a `package:` import? -> Place in Section 2.
3. Is it a relative import (inside `lib`)? -> Place in Section 3.
4. Is it an `export`? -> Place in Section 4 (after all imports).
5. Sort each section alphabetically.

## Instructions

1. **Analyze the Source Code**
   Review the provided Dart code for naming, ordering, and formatting violations based on the decision logic above.

2. **Apply Identifier Naming Rules**
   Refactor all identifiers to match their required casing.
   *   **Types and Extensions:**
       ```dart
       class SliderMenu {}
       typedef Predicate<T> = bool Function(T value);
       extension SmartIterable<T> on Iterable<T> {}
       ```
   *   **Variables, Constants, and Methods:**
       ```dart
       const defaultTimeout = 1000; // Prefer lowerCamelCase for constants
       var count = 3;
       void align(bool clearItems) {}
       ```
   *   **Acronyms:**
       ```dart
       var httpConnection = connect(); // >2 letters, treat as word
       var tvSet = Television();       // 2 letters, keep caps
       ```
   *   **Unused Callbacks:**
       ```dart
       futureOfVoid.then((_) {
         print('Operation complete.');
       });
       ```

3. **Handle Legacy Constants**
   **STOP AND ASK THE USER:** If the file currently uses `SCREAMING_CAPS` for constants or is generated from protobufs, ask: *"This file uses legacy SCREAMING_CAPS for constants. Should I convert them to lowerCamelCase (Dart 3+ preference) or maintain SCREAMING_CAPS for consistency?"*

4. **Apply Directive Ordering**
   Reorder all imports and exports. Separate each section with a single blank line. Sort alphabetically within sections. Prefer relative imports for files located inside the `lib` directory of the same package.
   ```dart
   import 'dart:async';
   import 'dart:collection';

   import 'package:bar/bar.dart';
   import 'package:foo/foo.dart';

   import 'util.dart';

   export 'src/error.dart';
   ```

5. **Enforce Structural Formatting**
   *   Ensure all flow control statements use curly braces to prevent dangling else issues.
       ```dart
       if (isWeekDay) {
         print('Bike to work!');
       } else {
         print('Go dancing!');
       }
       ```
       *Exception:* Single-line `if` statements without an `else` may omit braces if they fit on one line: `if (arg == null) return defaultValue;`
   *   Manually wrap long string literals if they exceed 80 characters (the formatter will not do this automatically).

6. **Execute Mandatory Formatting**
   Run the official Dart formatter on the refactored code.
   ```bash
   dart format .
   ```

7. **Validate and Fix**
   Verify the output against the constraints. If any `package:` imports are mixed with `dart:` imports, or if any types use `lowerCamelCase`, immediately correct the output before presenting it to the user.

## Constraints

*   **DO NOT** use a leading underscore for identifiers that aren't private (e.g., local variables, parameters).
*   **DO NOT** use prefix letters (Hungarian notation) like `kDefaultTimeout`.
*   **DO NOT** explicitly name libraries (e.g., `library my_library;`). Use `library;` with annotations if necessary.
*   **DO NOT** exceed 80 characters per line, except for URIs/file paths in strings or multi-line strings where newlines are significant.
*   **ALWAYS** run `dart format` as the final step before committing or returning code.
*   **ALWAYS** use relative imports for files within the same package's `lib` directory.
