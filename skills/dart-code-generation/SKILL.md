---
name: "dart-code-generation"
description: "Automate repetitive code tasks using the build_runner system."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:44:16 GMT"

---
# dart-build-runner

## Goal
Configures and executes Dart's `build_runner` toolchain to generate files, run tests, and serve Dart applications. Automatically resolves build conflicts, manages continuous background generation workflows, and enforces version control policies for generated code.

## Instructions

1. **Configure Dependencies**
   Ensure the target Dart project has the required development dependencies. Inject `build_runner` (and `build_test` if testing generated code) into the `pubspec.yaml` file.
   ```yaml
   dev_dependencies:
     build_runner: ^2.4.0 # Use latest compatible version
     build_test: ^3.2.0   # Optional: Only if testing generated code
   ```
   Execute the package fetch command:
   ```bash
   dart pub get
   ```

2. **Evaluate Execution Context (Decision Logic)**
   Determine the appropriate `build_runner` command based on the current development phase:
   *   **Active Development:** Use `watch` for continuous background generation.
   *   **CI/CD or Single Pass:** Use `build` for a one-time build.
   *   **Web Application:** **STOP AND ASK THE USER:** "Are you building a web application?" If yes, pivot to using the `webdev` tool instead of `build_runner serve`.
   *   **Testing:** Use `test` to run tests requiring generated code.

3. **Execute Build Command**
   Run the selected command via the Dart CLI. 
   
   *For continuous generation (Development):*
   ```bash
   dart run build_runner watch
   ```
   
   *For a one-time build:*
   ```bash
   dart run build_runner build
   ```

4. **Validate-and-Fix: Handle Conflicting Outputs**
   Monitor the output of the build command. If the build fails due to pre-existing generated files or conflicting outputs, automatically recover by appending the `--delete-conflicting-outputs` flag.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   *Note: Apply this flag to `watch` or `test` commands as well if conflicts arise during those operations.*

5. **Manage Version Control for Generated Files**
   **STOP AND ASK THE USER:** "What is the project policy for generated files? Should `.g.dart` files be committed to version control, or generated on-the-fly?"
   
   *If the policy is to generate on-the-fly (do not commit):*
   Append the following rule to the project's `.gitignore` file:
   ```text
   # Ignore generated files
   *.g.dart
   *.freezed.dart
   *.chopper.dart
   ```

## Constraints
*   **Never** use `build_runner serve` for web applications; strictly enforce the use of `webdev serve` for web targets.
*   **Always** run `dart pub get` immediately after modifying `pubspec.yaml`.
*   **Do not** manually edit `.g.dart` or other generated files. If modifications are needed, alter the source annotations or builder configurations and re-run the build command.
*   **Always** prefer `watch` over `build` during active local development to prevent stale generated code.
*   **Never** assume the version control policy for generated files; always prompt the user before modifying `.gitignore` for `.g.dart` files.
