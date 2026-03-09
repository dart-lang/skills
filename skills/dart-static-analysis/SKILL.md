---
name: "dart-static-analysis"
description: "Configure and resolve static analysis warnings to maintain project health."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:29:09 GMT"

---
# Dart Static Analysis and Type Promotion

## Goal
Configures Dart static analysis environments, enforces strict type checking, and resolves complex type promotion failures. Assumes a standard Dart or Flutter project structure with access to the Dart SDK CLI and a `pubspec.yaml` file at the project root.

## Instructions

1. **Determine Project Environment**
   **STOP AND ASK THE USER:** "Is this a pure Dart project or a Flutter project? Are there any specific linter rules you want to explicitly disable?"

2. **Configure Dependencies**
   Based on the user's response, add the appropriate linting package as a development dependency.
   For pure Dart:
   ```bash
   dart pub add --dev lints
   ```
   For Flutter:
   ```bash
   flutter pub add --dev flutter_lints
   ```

3. **Configure `analysis_options.yaml`**
   Create or update the `analysis_options.yaml` file at the project root. You MUST enforce strict language modes and include the recommended lint rules.
   ```yaml
   include: package:lints/recommended.yaml # Use package:flutter_lints/recommended.yaml for Flutter

   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
     exclude:
       - "**/*.g.dart"
       - "**/*.freezed.dart"

   linter:
     rules:
       # Add specific rule overrides here if requested by the user
       # e.g., avoid_print: false
   ```

4. **Decision Logic: Resolving Type Promotion Failures**
   When encountering type promotion failures during analysis, apply the following decision logic to refactor the code:
   
   * **Scenario A: Promoting an instance field, getter, or `this`**
     * *Reason:* The analyzer cannot guarantee that fields, getters, or `this` will return a stable value.
     * *Fix:* Assign the property to a local `final` variable before performing the null or type check.
     ```dart
     // DO NOT DO THIS:
     // if (_myNullableField != null) { print(_myNullableField.isEven); }

     // DO THIS:
     final myField = _myNullableField;
     if (myField != null) {
       print(myField.isEven);
     }
     ```

   * **Scenario B: Variable is write-captured by a closure or local function**
     * *Reason:* The analyzer assumes the closure could execute at any time, invalidating the promotion.
     * *Fix:* Shadow the variable locally before the closure or before the check.
     ```dart
     // DO THIS:
     final localValue = capturedValue;
     if (localValue != null) {
       print(localValue.isEven);
     }
     ```

   * **Scenario C: Subtype mismatch during promotion**
     * *Reason:* Promoting to a type that is not a subtype of the current promoted type.
     * *Fix:* Use a redundant type check (`as`) or check against a more precise subtype.
     ```dart
     if (o is Comparable) {
       if (o is String) { // String is a subtype of Comparable
         print(o.matchAsPrefix('foo'));
       }
     }
     ```

5. **Apply Automated Fixes**
   Execute the Dart fix command to bulk-apply safe, automated fixes for common lint and migration issues.
   ```bash
   dart fix --apply
   ```

6. **Validate and Fix**
   Run the static analyzer to catch potential bugs and style violations early.
   ```bash
   dart analyze
   ```
   If `dart analyze` returns errors or warnings, iteratively apply the decision logic in Step 4 to resolve them. Do not proceed until the analysis returns zero issues.

## Constraints
* DO run `dart analyze` to catch potential bugs and style violations early.
* DO configure custom lint rules in `analysis_options.yaml` (prefer using `package:lints` or `package:flutter_lints`).
* DO resolve "non-promotion" reasons by using local variables for field promotion.
* DO use `dart fix --apply` for bulk-fixing common lint and migration issues.
* AVOID ignoring lints manually (e.g., `// ignore: ...` or `// ignore_for_file: ...`) unless absolutely necessary; prefer fixing the root cause.
* NEVER use the deprecated `implicit-casts: false` under `strong-mode`; always use `strict-casts: true` under `language`.
* Related Skills: `dart-effective-style`, `dart-api-design`.
