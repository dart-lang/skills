---
name: "dart-static-analysis"
description: "Configure and resolve static analysis warnings to maintain project health."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:34:12 GMT"

---
# dart-static-analysis-and-promotion

## Goal
Configures Dart static analysis, enforces linter rules, and resolves type promotion failures in Dart codebases. Assumes a Dart or Flutter environment with an existing `pubspec.yaml` and SDK version 3.2 or higher. Analyzes code to catch potential bugs, applies strict type checking, and refactors code to ensure sound null safety and type promotion using local variable shadowing and other safe patterns.

## Instructions

1. **Configure Base Analysis Options**
   Create or update the `analysis_options.yaml` file at the root of the project. Apply strict type checks and include the recommended linting package.
   
   **Decision Logic: Choosing the Base Linter**
   * If the project is a Flutter app or package: Use `flutter_lints`.
   * If the project is a pure Dart package: Use `lints`.

   ```yaml
   # analysis_options.yaml
   include: package:lints/recommended.yaml # OR package:flutter_lints/recommended.yaml

   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
     exclude:
       - build/**
       - "**/*.g.dart"
       - "**/*.freezed.dart"
   ```

2. **Customize Linter Rules and Severities**
   Modify the `linter` and `analyzer` sections to enable specific rules, disable conflicting rules, or change diagnostic severities.
   
   **STOP AND ASK THE USER:** Before globally ignoring a rule or changing a severity to `ignore`, ask the user if they prefer to fix the root cause instead.

   ```yaml
   analyzer:
     errors:
       todo: ignore
       invalid_assignment: warning
       missing_return: error

   linter:
     rules:
       # Enable specific rules
       - always_declare_return_types
       - cancel_subscriptions
       # Disable specific rules from the included package
       avoid_shadowing_type_parameters: false
   ```

3. **Apply Localized Diagnostic Suppressions**
   When a rule cannot be fixed and must be bypassed, use localized suppressions rather than global exclusions.
   * **File-level:** `// ignore_for_file: <rule_name>` at the top of the file.
   * **Line-level:** `// ignore: <rule_name>` above or on the specific line.
   * **Pubspec:** `# ignore: <rule_name>` above the dependency in `pubspec.yaml`.

   ```dart
   // ignore_for_file: unused_local_variable, dead_code

   void example() {
     // ignore: invalid_assignment
     int x = ''; 
   }
   ```

4. **Resolve Type Promotion Failures**
   When `dart analyze` reports that a variable or field cannot be promoted to a non-nullable type, apply the following decision logic to refactor the code.

   **Decision Logic: Type Promotion Fixes**
   * **Condition A:** The target is a public field, non-final field, getter, or external field.
     * *Fix:* Assign the field to a local `final` variable before checking for null.
     ```dart
     // BEFORE
     if (widget.myNullableField != null) { print(widget.myNullableField.isEven); }
     
     // AFTER
     final myField = widget.myNullableField;
     if (myField != null) { print(myField.isEven); }
     ```
   * **Condition B:** The target is `this` (e.g., in an extension method).
     * *Fix:* Assign `this` to a local variable.
     ```dart
     extension on int? {
       int get valueOrZero {
         final self = this;
         return self == null ? 0 : self;
       }
     }
     ```
   * **Condition C:** The variable is written to inside a closure, loop, or `try/catch` block after the null check.
     * *Fix:* Move the null check inside the loop/closure, or shadow the variable locally before the closure.
     ```dart
     // BEFORE
     void f(int? i) {
       var foo = () { if (i != null) print(i.isEven); };
       i = 10; 
     }

     // AFTER
     void f(int? i) {
       var foo = () {
         final localI = i;
         if (localI != null) print(localI.isEven);
       };
       i = 10;
     }
     ```
   * **Condition D:** Subtype mismatch (e.g., promoting `Object` to `Comparable` then to `Pattern`).
     * *Fix:* Use an explicit cast (`as`) or check against a more specific type that satisfies both bounds.
     ```dart
     if (o is Comparable) {
       if (o is Pattern) {
         print((o as Pattern).matchAsPrefix('foo'));
       }
     }
     ```

5. **Validate and Fix**
   Execute the following feedback loop to ensure the codebase is clean:
   1. Run `dart analyze` to catch potential bugs and style violations.
   2. If non-promotion errors occur, apply the logic from Step 4.
   3. Run `dart fix --apply` to bulk-fix common lint and migration issues.
   4. Re-run `dart analyze` to verify zero remaining issues.

## Constraints
* Run `dart analyze` to catch potential bugs and style violations early.
* Configure custom lint rules in `analysis_options.yaml` (prefer using `package:lints` or `package:flutter_lints`).
* Resolve "non-promotion" reasons strictly by using local variables for field promotion. Do not use the `!` operator unless explicitly instructed or if local shadowing is impossible.
* Use `dart fix --apply` for bulk-fixing common lint and migration issues.
* Avoid ignoring lints manually unless absolutely necessary; prefer fixing the root cause.
* Do not mix list (`- rule`) and key-value (`rule: true/false`) syntax under `linter: rules:` in YAML. Use key-value syntax if disabling rules from an included package.
