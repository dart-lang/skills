---
name: "dart-documentation"
description: "Use idiomatic doc comments to provide a professional API surface."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:33:43 GMT"

---
# Dart Documentation Generator

## Goal
Generates, formats, and validates Dart documentation comments and API reference sites according to Effective Dart guidelines. Assumes a standard Dart/Flutter environment with the Dart SDK installed and accessible via the command line.

## Instructions

1. **Analyze the Target Code**
   Review the provided Dart source code to identify public APIs, libraries, classes, methods, and properties that require documentation. 

2. **Apply Documentation Decision Logic**
   Determine the appropriate phrasing and structure for the doc comment based on the element type. Follow this decision tree:
   * **Is the element a Library, Class, or Type?**
     * -> Start with a noun phrase describing an *instance* of the type.
   * **Is the element a Boolean Variable or Property?**
     * -> Start with "Whether" followed by a noun or gerund phrase.
   * **Is the element a Non-Boolean Variable or Property?**
     * -> Start with a noun phrase stressing what the property *is*.
   * **Is the element a Function or Method?**
     * *Does it primarily produce a side effect?* -> Start with a third-person verb (e.g., "Connects", "Starts").
     * *Is its primary purpose returning a value (conceptual property)?* -> Start with a noun phrase (or "Whether" if returning a boolean).
   * **Does the property have both a Getter and a Setter?**
     * -> Document *only* one of them (usually the getter).

3. **Write the Doc Comments**
   Draft the documentation using `///` syntax. Ensure the first sentence is a brief, third-person singular summary placed on its own line.

   *Example: Class and Method Documentation*
   ```dart
   /// A chunk of non-breaking output text terminated by a hard or soft newline.
   class Chunk {
     /// The number of characters in this chunk when unsplit.
     int get length => ...

     /// Whether the chunk contains any characters.
     bool get isEmpty => ...

     /// Deletes the file at [path].
     ///
     /// Throws an [IOError] if the file could not be found. Throws a
     /// [PermissionError] if the file is present but could not be deleted.
     void delete(String path) {
       ...
     }
   }
   ```

   *Example: Library Documentation (placed before annotations)*
   ```dart
   /// A really great test library.
   @TestOn('browser')
   library;
   ```

4. **Prepare the Environment**
   Before generating documentation, ensure the package dependencies are resolved and the code is free of static analysis errors.
   ```bash
   dart pub get
   dart analyze
   ```
   **STOP AND ASK THE USER:** If `dart analyze` returns errors, halt and ask the user if they want you to fix the analysis errors before proceeding with documentation generation.

5. **Generate the Documentation**
   Run the Dart documentation generator. Use the dry-run flag first to catch formatting issues.
   ```bash
   dart doc --dry-run .
   ```
   If successful, generate the actual documentation:
   ```bash
   dart doc .
   ```
   *Optional: To output to a specific directory:*
   ```bash
   dart doc --output=api_docs .
   ```

6. **Validate and Fix**
   Verify the generated documentation links and references.
   ```bash
   dart doc --validate-links
   ```
   If the validation fails, parse the output, locate the broken `[reference]` tags in the source code, correct the identifiers, and regenerate.

7. **Serve the Documentation Locally**
   To view the generated docs, serve them using a local HTTP server.
   ```bash
   dart pub global activate dhttpd
   dart pub global run dhttpd --path doc/api
   ```

## Constraints

* **Syntax:** Use `///` exclusively for doc comments. NEVER use `/** ... */` block comments for documentation.
* **First Sentence:** Begin the first sentence with a brief, third-person singular summary. Place this summary on its own line, separated from the rest of the comment by a blank line.
* **Punctuation:** Format comments like standard sentences. Capitalize the first word (unless it's a case-sensitive identifier) and end with a period.
* **References:** Use square brackets `[]` to link to types, methods, or variables in scope (e.g., `[Duration.inDays]`, `[Point.new]`).
* **Formatting:** Use markdown backtick fences (```dart) for code blocks instead of indentation. Avoid excessive markdown or raw HTML.
* **Prose over Tags:** Do not use JavaDoc-style tags (e.g., `@param`, `@returns`). Use prose to explain parameters, return values, and exceptions (e.g., "The [name] string must not be empty. Returns a new flag.").
* **Placement:** Always put doc comments *before* metadata annotations (e.g., `@Component`).
* **Redundancy:** Do not repeat the method signature or class name in the description. Focus on what the reader does not already know.
* **Terminology:** Prefer using "this" instead of "the" to refer to a member's instance (e.g., "Whether this box contains a value."). Avoid abbreviations like "i.e." or "e.g." unless universally obvious.
