---
name: "dart-migration-versioning"
description: "Manage language versioning and perform large-scale codebase upgrades."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:44:39 GMT"

---
# dart-version-migration

## Goal
Analyzes Dart projects to manage language versioning, apply per-file version overrides, and resolve breaking changes across SDK upgrades. Evaluates `pubspec.yaml` constraints, implements targeted fixes for deprecated APIs (such as migrating legacy web libraries to `package:web`), and ensures compatibility with sound null safety and modern WebAssembly (Wasm) compilation requirements.

## Instructions

### Decision Logic
When tasked with upgrading a Dart project or resolving versioning conflicts, follow this evaluation path:
*   **Is the target SDK >= 3.0.0?**
    *   *Yes:* Sound null safety is strictly required. Legacy `dart:html` and `dart:js` are deprecated. Proceed to Wasm/Web migration checks.
    *   *No:* Sound null safety is optional but recommended.
*   **Does the code compile to WebAssembly (Wasm)?**
    *   *Yes:* `dart:js_util` and `package:js` will cause compilation errors. Migrate to `dart:js_interop`.
*   **Can the entire project be migrated simultaneously?**
    *   *Yes:* Update `pubspec.yaml` SDK constraints and refactor all files.
    *   *No:* Update `pubspec.yaml` but use `@dart = <version>` overrides on unmigrated files.

### Execution Steps

1. **Analyze Current Version Requirements:**
   Inspect the `pubspec.yaml` file to determine the default language version, which is defined by the lower bound of the SDK constraint.
   ```yaml
   environment:
     sdk: '>=2.18.0 <3.0.0' # Default language version is 2.18
   ```

2. **Consult Breaking Change Logs:**
   Before performing major dependency upgrades, evaluate the target version against known breaking changes (e.g., Dart 3.0.0 enforcing sound null safety, Dart 3.11.0 removing `dart:js_util` for Wasm).

3. **Interactive Checkpoint:**
   **STOP AND ASK THE USER:** "Which specific files or directories should be migrated to the new language version immediately, and which should be temporarily pinned to their older language version?"

4. **Apply Per-Library Version Overrides:**
   For files that are not ready for the breaking changes of the new SDK constraint, pin them to an older version. The `@dart` string must be in a `//` comment and appear before any Dart code.
   ```dart
   // @dart = 2.19
   import 'dart:math';
   
   // Legacy non-null-safe or pre-Dart 3 code here
   void legacyFunction() {
     int? x = null;
   }
   ```

5. **Execute Code Migrations (Web & JS Interop):**
   If the project targets Dart 3.3+ or Wasm, strictly replace legacy JS interop and HTML libraries.
   *Legacy Code (Do Not Use for Wasm):*
   ```dart
   import 'dart:html';
   import 'dart:js_util';
   
   void main() {
     var el = document.getElementById('app');
     setProperty(el, 'innerText', 'Hello');
   }
   ```
   *Migrated Code (Required for Wasm/Modern Web):*
   ```dart
   import 'package:web/web.dart';
   import 'dart:js_interop';
   
   void main() {
     final el = document.getElementById('app') as HTMLElement?;
     el?.innerText = 'Hello'.toJS;
   }
   ```

6. **Validate-and-Fix:**
   Run static analysis to verify the migration and catch newly introduced diagnostics (e.g., `unnecessary_non_null_assertion` due to improved type promotion).
   ```bash
   dart analyze
   dart fix --apply
   ```
   If `dart analyze` returns errors related to type promotion or reachability, automatically remove the dead code or unnecessary casts and re-run the analysis until clean.

## Constraints
*   **Never** use `///` or `/* */` for language version overrides. It must strictly be `// @dart = <major>.<minor>`.
*   **Never** place the `@dart` override comment after any Dart code (including imports). It must precede all code.
*   **Never** use `dart:js_util`, `package:js`, or `dart:html` when compiling to WebAssembly (`dart compile wasm`). Always enforce `dart:js_interop` and `package:web`.
*   **Do not** attempt to use unsound null safety in Dart 3.0.0 or higher; the VM no longer supports it.
*   **Do not** implement `JSAny` or `JSObject` using user-defined `@staticInterop` classes in Dart 3.3+; use extension types instead.
