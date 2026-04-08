---
name: dart-documentation
description: Use idiomatic doc comments to provide a professional API surface.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:16:57 GMT
---
# Documenting Dart Code

## Contents
- [Core Principles](#core-principles)
- [Formatting Doc Comments](#formatting-doc-comments)
- [Documenting Specific Constructs](#documenting-specific-constructs)
- [Workflow: Generating and Validating Docs](#workflow-generating-and-validating-docs)
- [Examples](#examples)

## Core Principles

- **Use `///` exclusively:** Document members and types using `///`. Never use `/** ... */` block comments for documentation.
- **Use `//` for internal comments:** Use standard `//` comments for implementation details that should not appear in generated public documentation.
- **Format as sentences:** Capitalize the first word (unless it is a case-sensitive identifier) and end with a period.
- **Prefer brevity:** Be clear, precise, and terse. Avoid redundant information that can be inferred from the method signature or class name.
- **Use Markdown:** Utilize standard Markdown for formatting. Prefer backtick fences (```) for code blocks over indentation. Avoid HTML tags.

## Formatting Doc Comments

- **Start with a summary:** Begin the first sentence with a brief, third-person singular summary. 
- **Isolate the summary:** Place the summary on its own line, followed by a blank line, to ensure optimal readability in IDE tooltips and generated summaries.
- **Use square brackets for references:** Link to types, methods, or variables in scope using `[identifier]`. 
  - Use `[ClassName.memberName]` for specific members.
  - Use `[ClassName.new]` for unnamed constructors.
- **Use prose for parameters and returns:** Integrate parameter, return value, and exception descriptions into the prose rather than using verbose tags (e.g., `@param`). Highlight parameters using square brackets.
- **Place docs before metadata:** Always position doc comments before metadata annotations (e.g., `@override`).

## Documenting Specific Constructs

### Methods and Functions
- **Side effects:** If the primary purpose is a side effect, start the summary with a third-person verb (e.g., "Connects to the server...").
- **Return values:** If the primary purpose is returning a value, start with a noun phrase (e.g., "The [index]th element...").

### Variables and Properties
- **Non-booleans:** Start with a noun phrase describing what the property *is* (e.g., "The current day of the week...").
- **Booleans:** Start with "Whether" followed by a noun or gerund phrase (e.g., "Whether the modal is currently displayed...").
- **Getters/Setters:** If a property has both a getter and a setter, document *only* the getter.

### Classes and Libraries
- **Classes:** Start with a noun phrase describing an *instance* of the type.
- **Libraries:** Place a `///` comment before the `library` directive. Include a single-sentence summary, terminology explanations, and code samples.

## Workflow: Generating and Validating Docs

Follow this sequential workflow when writing and verifying documentation for a Dart package.

### Task Progress
- [ ] 1. Write doc comments using `///` and Markdown.
- [ ] 2. Resolve dependencies: Run `dart pub get`.
- [ ] 3. Ensure code is error-free: Run `dart analyze`.
- [ ] 4. Generate and validate docs: Run `dart doc --validate-links`.
- [ ] 5. Review output for missing references or formatting warnings.
- [ ] 6. (Optional) Serve locally to verify UI rendering.

### Feedback Loop: Validation
When generating documentation, you must validate that all `[references]` resolve correctly.
1. **Run validator:** Execute `dart doc --validate-links .`
2. **Review errors:** Check the console output for broken links or unresolved symbols.
3. **Fix:** Correct typos in `[brackets]`, ensure referenced members are in scope, or adjust imports. Repeat until the command succeeds without warnings.

### Conditional Logic: Viewing Docs Locally
- **If you need to preview the generated HTML:**
  1. Activate the local server: `dart pub global activate dhttpd`
  2. Serve the `doc/api` directory: `dart pub global run dhttpd --path doc/api`
  3. Open the provided localhost URL in a browser.

## Examples

### High-Quality Method Documentation

```dart
/// Deletes the file at [path].
///
/// Throws an [IOError] if the file could not be found. Throws a
/// [PermissionError] if the file is present but could not be deleted.
void delete(String path) {
  // Implementation details...
}
```

### High-Quality Property Documentation

```dart
/// The pH level of the water in the pool.
///
/// Ranges from 0-14, representing acidic to basic, with 7 being neutral.
int get phLevel => _phLevel;
set phLevel(int level) => _phLevel = level;
```

### High-Quality Boolean Documentation

```dart
/// Whether the modal should confirm the user's intent on navigation.
bool get shouldConfirm => _shouldConfirm;
```

### High-Quality Class Documentation with Code Sample

```dart
/// The lesser of two numbers.
///
/// ```dart
/// min(5, 3) == 3
/// ```
num min(num a, num b) => (a < b) ? a : b;
```
