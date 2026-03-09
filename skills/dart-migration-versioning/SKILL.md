---
name: "dart-migration-versioning"
description: "Manage language versioning and perform large-scale codebase upgrades."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:35:09 GMT"

---
# Dart Version Management and Migration

## Goal
Manages Dart language versioning, resolves breaking changes during SDK upgrades, and applies per-library version overrides to facilitate gradual migrations. Assumes a standard Dart or Flutter environment with access to `pubspec.yaml` and source files. Related Skills: `dart-web-development`, `dart-static-analysis`.

## Decision Logic
When tasked with upgrading a Dart project or fixing version-related compilation errors, follow this evaluation path:
1. **Identify Target SDK:** Determine the target Dart SDK version.
2. **Check Current Version:** Read `pubspec.yaml` to find the current lower bound SDK constraint.
3. **Evaluate Breaking Changes:** Cross-reference the version jump with the breaking changes log.
   - *If migrating to >= 3.0.0:* Sound null safety is strictly enforced.
   - *If migrating web libraries to >= 3.3.0:* Legacy `dart:html` and `dart:js` are deprecated/removed.
4. **Determine Migration Strategy:**
   - *Can the code be refactored immediately?* -> Apply API migrations.
   - *Is the refactor too large or blocked?* -> Pin specific files using `@dart = <version>` to maintain older language semantics while upgrading the package.

## Instructions

1. **Verify Current Language Version Requirements**
   Inspect the `pubspec.yaml` file to determine the default language version, which is dictated by the lower bound of the SDK constraint.
   ```yaml
   environment:
     sdk: '>=2.18.0 <3.0.0' # Defaults to Dart 2.18
   ```

2. **Consult Breaking Change Logs**
   Before performing major dependency or SDK upgrades, review the breaking changes for the target version. 
   **STOP AND ASK THE USER:** "I am about to upgrade the SDK constraint to `<target_version>`. This includes breaking changes such as `<list_key_changes>`. Should I proceed with the upgrade and begin refactoring?"

3. **Apply Per-Library Language Version Selection (Gradual Migration)**
   If a specific file cannot be immediately migrated to the new language version (e.g., pending null safety migration or complex refactoring), pin the file to an older version.
   - The `@dart` string must be in a `//` comment.
   - It must appear *before* any Dart code in the file.
   ```dart
   // @dart = 2.19
   import 'dart:math';
   
   // Legacy code that relies on 2.19 semantics
   void legacyFunction() {
     // ...
   }
   ```

4. **Migrate Deprecated Web and JS Interop Libraries (Dart 3.3+)**
   If the project targets Dart 3.3+ or compiles to Wasm, legacy web libraries (`dart:html`, `dart:js`, `package:js`) will cause compilation errors. Migrate these to `package:web` and `dart:js_interop`.
   ```dart
   // BEFORE (Legacy)
   import 'dart:html';
   import 'package:js/js.dart';
   
   @JS()
   external void legacyJsFunction();
   
   // AFTER (Modern)
   import 'package:web/web.dart' as web;
   import 'dart:js_interop';
   
   @JS()
   external void modernJsFunction();
   
   void updateDom() {
     final div = web.document.createElement('div') as web.HTMLDivElement;
     div.text = 'Migrated';
     web.document.body?.append(div);
   }
   ```

5. **Validate-and-Fix Loop**
   After updating the SDK constraint or modifying code, run static analysis to verify the migration.
   ```bash
   dart analyze
   ```
   *Fixing common post-upgrade errors:*
   - If `unnecessary_non_null_assertion` or `invalid_null_aware_operator` appears, remove the `!` or `?.` as type promotion has likely improved in the newer Dart version.
   - If `dart:js_util` or `dart:html` throws Wasm compilation errors, return to Step 4.

## Constraints
- DO check current language version requirements in `pubspec.yaml` before making any syntax changes.
- DO use `@dart = <version>` to pin specific files to older versions during migration if a full refactor is not requested.
- DO consult breaking change logs before performing major dependency upgrades.
- NEVER use `///` or `/* */` for the `@dart` version override comment; it must be `//`.
- NEVER place the `@dart` comment after imports or code declarations.
- NEVER attempt to use `dart:html`, `dart:js`, or `dart:js_util` when compiling to WebAssembly (`dart compile wasm`).
- NEVER disable sound null safety in Dart 3.0+; the `--no-sound-null-safety` flag and unsound execution are completely removed.
