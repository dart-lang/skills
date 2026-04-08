---
name: dart-migration-versioning
description: Manage language versioning and perform large-scale codebase upgrades.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:22:14 GMT
---
# Managing Dart Language Versions

## Contents
- [Core Guidelines](#core-guidelines)
- [Configuration & Overrides](#configuration--overrides)
- [Workflows](#workflows)
- [Examples](#examples)
- [Breaking Changes Reference](#breaking-changes-reference)
- [Related Skills](#related-skills)

## Core Guidelines

- **Check current language version requirements** in `pubspec.yaml` before initiating any migration or refactoring.
- **Consult breaking change logs** before performing major dependency or SDK upgrades.
- **Use `@dart = <version>`** to pin specific files to older versions during gradual migrations (e.g., migrating a large project to a new language feature like sound null safety).
- **Understand Version Derivation**: The default language version for a package is strictly determined by the **lower bound** of the SDK constraint in `pubspec.yaml`. Patch versions do not introduce new language features.

## Configuration & Overrides

### Global Package Versioning
Set the default language version for the entire package by modifying the `environment.sdk` constraint in `pubspec.yaml`. 

### Per-Library Version Selection
Override the package-wide language version for individual files using a specific comment syntax.
- Place the `@dart` string inside a `//` comment (do not use `///` or `/*`).
- Ensure the comment appears **before** any Dart code in the file.
- Use this mechanism to maintain legacy code compatibility while upgrading the rest of the package.

## Workflows

### Task Progress: Gradual Language Version Migration
Use this workflow when upgrading a project to a new Dart major/minor version that contains breaking changes.

- [ ] **Analyze Current State**: Run `dart analyze` on the current version to ensure a clean baseline.
- [ ] **Check Constraints**: Inspect `pubspec.yaml` to identify the current lower-bound SDK constraint.
- [ ] **Review Breaking Changes**: Consult the [Breaking Changes Reference](#breaking-changes-reference) for the target version.
- [ ] **Update SDK Constraint**: Modify the `environment.sdk` lower bound in `pubspec.yaml` to the target version.
- [ ] **Run Dependency Resolution**: Execute `dart pub get`.
- [ ] **Identify Breakages**: Run `dart analyze`.
- [ ] **Apply Conditional Logic for Fixes**:
  - *If the file is small or easily refactored*: Fix the breaking changes immediately to comply with the new language version.
  - *If the file is complex or part of a large legacy module*: Insert `// @dart = <previous_version>` at the top of the file to defer migration.
- [ ] **Run Validator**: Execute `dart test` and `dart analyze` -> review errors -> fix remaining issues.

## Examples

### Setting the Package Language Version
```yaml
# pubspec.yaml
name: my_package
environment:
  # This sets the default language version to Dart 3.3
  sdk: '>=3.3.0 <4.0.0'
```

### Applying a Per-Library Override
```dart
// @dart = 2.19
// The above comment pins this specific file to Dart 2.19, 
// even if the pubspec.yaml specifies Dart 3.0+.

import 'dart:math';

void legacyFunction() {
  // Legacy code implementation
}
```

## Breaking Changes Reference

<details>
<summary>Expand for Critical Dart Breaking Changes (Versions 2.12 - 3.11)</summary>

### Dart 3.11.0
- **Wasm Compilation**: Code importing `dart:js_util` or `package:js` results in a compilation error. Migrate to `dart:js_interop`.
- **Analyzer**: Deprecated `avoid_null_checks_in_equality_operators`, `prefer_final_parameters`, and `use_if_null_to_convert_nulls_to_bools` lint rules.

### Dart 3.10.0
- **SDK**: The `dart` CLI and Dart VM are now separate executables (`dartvm`). IA32 platform support removed.
- **Wasm Compilation**: `dartify` converts JS `Promise` objects to Dart `Future` objects instead of `JSValue`.

### Dart 3.7.0
- **Language**: Local variables and parameters named `_` are non-binding and cannot be accessed.
- **Libraries**: Legacy web libraries (`dart:html`, `dart:js`, etc.) are officially deprecated. Migrate to `package:web` and `dart:js_interop`.

### Dart 3.5.0
- **Runtime**: The Dart VM no longer supports unsound null safety. `--no-sound-null-safety` CLI option removed.

### Dart 3.0.0 (Major Breaking Changes)
- **Language**: Null safety is strictly enforced. Switch cases are now interpreted as patterns.
- **Mixins**: Class declarations from Dart 3.0+ libraries can no longer be used as mixins by default.
- **Core**: `Iterable`, `ListMixin`, `SetMixin`, and `MapMixin` are now mixin classes.

### Dart 2.12.0
- **Language**: Sound null safety enabled by default.

</details>

## Related Skills
- `dart-web-development`
- `dart-static-analysis`
