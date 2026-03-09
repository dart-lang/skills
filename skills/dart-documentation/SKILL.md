---
name: "dart-documentation"
description: "Use idiomatic doc comments to provide a professional API surface."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:28:42 GMT"

---
# dart-documentation

## Goal
Generates, formats, and validates Dart documentation comments and API reference sites according to Effective Dart guidelines. Assumes a standard Dart or Flutter project environment with the Dart SDK installed and accessible.

## Instructions

1. **Analyze the Target Declaration**
   Review the Dart code requiring documentation. Identify the declaration type (e.g., library, class, method, getter/setter, variable) to determine the appropriate phrasing and structure.

2. **Apply Phrasing Decision Logic**
   Determine the opening sentence structure based on the following decision tree:
   * **Is it a function or method primarily for side effects?**
     * -> Start with a third-person verb (e.g., "Connects to...", "Starts the...").
   * **Is it a non-boolean variable, property, or a method conceptually returning a value?**
     * -> Start with a noun phrase (e.g., "The current day...", "The [index]th element...").
   * **Is it a boolean variable or property?**
     * -> Start with "Whether" followed by a noun/gerund phrase (e.g., "Whether the modal is...").
   * **Is it a library or type (class, enum, etc.)?**
     * -> Start with a noun phrase describing an *instance* of the type (e.g., "A chunk of non-breaking output...").

3. **Draft the Doc Comment**
   Write the documentation using `///` syntax. Place the brief, third-person singular summary on its own line. Leave a blank line before starting the next paragraph.
   
   ```dart
   /// Deletes the file at [path].
   ///
   /// Throws an [IOError] if the file could not be found. Throws a
   /// [PermissionError] if the file is present but could not be deleted.
   void delete(String path) { ... }
   ```

4. **Format Parameters, Returns, and Exceptions**
   Integrate parameter descriptions, return values, and exceptions into prose using square brackets `[]` for in-scope identifiers. Do not use verbose tags like `@param` or `@returns`.
   
   ```dart
   /// Defines a flag with the given [name] and [abbreviation].
   ///
   /// Returns a new flag.
   ///
   /// Throws a [DuplicateFlagException] if there is already an option named
   /// [name] or there is already an option using the [abbreviation].
   Flag addFlag(String name, String abbreviation) => ...
   ```

5. **Handle Metadata Annotations**
   Always place doc comments *before* metadata annotations.
   
   ```dart
   /// A button that can be flipped on and off.
   @Component(selector: 'toggle')
   class ToggleComponent {}
   ```

6. **Generate and Validate Documentation**
   **STOP AND ASK THE USER:** "Would you like me to generate and validate the documentation using the `dart doc` CLI?"
   If the user confirms, execute the following validation loop:
   
   ```bash
   # Ensure dependencies are resolved and code is valid
   dart pub get
   dart analyze
   
   # Run a dry-run to catch documentation warnings/errors
   dart doc --dry-run .
   ```

7. **Validate-and-Fix Loop**
   If `dart doc --dry-run .` outputs warnings (e.g., unresolved doc references), parse the output, locate the broken `[identifier]` links, and correct them. Once clean, generate the final docs:
   
   ```bash
   dart doc .
   # Optionally specify output: dart doc --output=api_docs .
   ```

## Constraints

* **Syntax:** DO use `///` exclusively for doc comments. NEVER use `/** ... */` or block comments `/* ... */` for documentation.
* **Summary Line:** DO begin the first sentence with a brief, third-person singular summary. PREFER placing the summary on its own line for better readability in IDE tooltips.
* **References:** DO use square brackets `[]` to link to types, methods, or variables in scope (e.g., `[Duration.inDays]`, `[Point.new]`).
* **Code Blocks:** PREFER providing concise code examples for complex logic using markdown backtick blocks (```dart ... ```).
* **Redundancy:** AVOID redundancy with the surrounding context. Do not spell out the method signature or enclosing class if it is obvious.
* **Properties:** DON'T write documentation for both the getter and setter of a property. Document only one (usually the getter).
* **Validation:** DO verify generated docs using `dart doc --validate-links` (or `--dry-run`).
* **Formatting:** Capitalize the first word of comments and end with a period.
* **Related Skills:** `dart-effective-style`.
