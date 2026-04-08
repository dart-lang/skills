---
name: dart-effective-style
description: Maintain code consistency by following official Dart style and naming conventions.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:16:30 GMT
---
# Styling Dart Code

## Contents
- [Naming Conventions](#naming-conventions)
- [Ordering Directives](#ordering-directives)
- [Formatting Rules](#formatting-rules)
- [Workflows](#workflows)

## Naming Conventions

Apply the following naming conventions strictly to maintain consistency across the Dart ecosystem. 

- **Types:** Name classes, enum types, typedefs, extensions, and type parameters using `UpperCamelCase`.
- **Variables & Members:** Name class members, top-level definitions, variables, parameters, and named parameters using `lowerCamelCase`.
- **Constants:** Prefer `lowerCamelCase` for constant variables, including enum values. 
  - *Conditional:* If editing existing code that uses `SCREAMING_CAPS` or working with generated code (e.g., protobufs), maintain consistency with the existing style.
- **Files & Directories:** Name packages, directories, and source files using `lowercase_with_underscores`.
- **Import Prefixes:** Name import prefixes using `lowercase_with_underscores`.
- **Acronyms:** Capitalize acronyms and abbreviations longer than two letters like regular words (e.g., `Http`, `Uri`). Keep two-letter acronyms fully capitalized (e.g., `ID`, `UI`). If an abbreviation begins a `lowerCamelCase` identifier, make it entirely lowercase (e.g., `httpConnection`).
- **Privacy:** Use a leading underscore `_` for members and top-level declarations to indicate library privacy. Do not use leading underscores for local variables, parameters, local functions, or library prefixes.
- **Unused Parameters:** Prefer using wildcards (`_`, `__`, etc.) for unused callback parameters to explicitly signal intent.
- **Prefixes:** Do not use prefix letters (e.g., Hungarian notation like `kDefaultTimeout`).
- **Libraries:** Do not explicitly name libraries (e.g., avoid `library my_library;`).

### Examples

```dart
// GOOD
class SliderMenu {}
typedef Predicate<T> = bool Function(T value);
const defaultTimeout = 1000;
var httpConnection = connect();

futureOfVoid.then((_) {
  print('Operation complete.');
});

// BAD
class slider_menu {}
const DEFAULT_TIMEOUT = 1000;
var HTTPConnection = connect();
const kDefaultTimeout = 1000;
```

## Ordering Directives

Organize file preambles using the following strict order. Separate each section with a blank line and sort directives alphabetically within each section.

1. Place `dart:` imports first.
2. Place `package:` imports second.
3. Place relative imports third.
   - *Best Practice:* Prefer relative imports for files located inside the `lib` directory of the same package.
4. Specify `export` directives in a separate section after all imports.

### Example

```dart
// GOOD
import 'dart:async';
import 'dart:collection';

import 'package:bar/bar.dart';
import 'package:foo/foo.dart';

import 'src/util.dart';

export 'src/error.dart';
```

## Formatting Rules

- **Mandatory Formatting:** Run `dart format` as a mandatory step before committing any code. The official whitespace-handling rules for Dart are defined entirely by what `dart format` produces.
- **Line Length:** Prefer lines of 80 characters or fewer. Reorganize deeply nested expressions or extract variables if `dart format` produces unreadable output due to line length constraints.
- **Flow Control:** Use curly braces for all flow control statements to avoid the dangling else problem.
  - *Exception:* You may omit braces for an `if` statement with no `else` clause if the entire statement fits on a single line.

### Example

```dart
// GOOD
if (isWeekDay) {
  print('Bike to work!');
} else {
  print('Go dancing or read a book!');
}

if (arg == null) return defaultValue;

// BAD
if (overflowChars != other.overflowChars)
  return overflowChars < other.overflowChars;
```

## Workflows

### Pre-Commit Formatting & Linting Workflow

Execute this workflow before finalizing any Dart code modifications to ensure style compliance.

- [ ] **Task Progress**
  - [ ] 1. Review code against naming conventions (e.g., `UpperCamelCase` for types, `lowerCamelCase` for variables).
  - [ ] 2. Verify import ordering (`dart:` -> `package:` -> relative -> exports).
  - [ ] 3. Run `dart format .` on the modified files.
  - [ ] 4. Run `dart analyze` to catch static analysis and linting errors.
  - [ ] 5. Run validator -> review errors -> fix any issues reported by the analyzer.
