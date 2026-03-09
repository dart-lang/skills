---
name: "dart-code-generation"
description: "Automate repetitive code tasks using the build_runner system."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:34:48 GMT"

---
# dart-build-runner-automation

## Goal
Configures and executes Dart's `build_runner` tool to automate code generation, testing, and serving of Dart applications. Analyzes project requirements to inject necessary development dependencies, determines the optimal build strategy (one-time build vs. continuous watching), and resolves file conflict errors during the generation phase. 

## Decision Logic
When tasked with running a build or code generation process, evaluate the user's current context to select the correct command:
*   **Is the user actively developing and modifying files?** -> Choose `watch`.
*   **Is this a CI/CD pipeline or a one-off production build?** -> Choose `build`.
*   **Is the user building a web application?** -> Do NOT use `build_runner serve`; delegate to `webdev serve` (see `dart-web-development`).
*   **Does the user need to run tests on generated code?** -> Choose `test`.

## Instructions

1.  **Verify and Inject Dependencies**
    Inspect the `pubspec.yaml` file. Ensure that `build_runner` is listed under `dev_dependencies`. If testing generated code, also ensure `build_test` is present.
    ```yaml
    dev_dependencies:
      build_runner: ^2.4.0 # Use the latest compatible version
      build_test: ^3.2.0   # Optional: Only if testing is required
    ```
    Run the package fetch command:
    ```bash
    dart pub get
    ```

2.  **Determine Project Policy on Generated Files**
    **STOP AND ASK THE USER:** "Should generated files (e.g., `.g.dart`) be committed to version control, or are they generated on-the-fly in this project?"
    *   *If generated on-the-fly:* Ensure `.g.dart` is added to the `.gitignore` file.
    *   *If committed:* Proceed without modifying `.gitignore`.

3.  **Execute the Build Command**
    Based on the Decision Logic, execute the appropriate command from the project root.
    
    *For continuous background generation during development (PREFERRED):*
    ```bash
    dart run build_runner watch
    ```
    
    *For a one-time build:*
    ```bash
    dart run build_runner build
    ```

    *For running tests that require code generation:*
    ```bash
    dart run build_runner test
    ```

4.  **Validate-and-Fix: Handle Conflicting Outputs**
    Monitor the terminal output for the build command. If the build fails with a `ConflictingOutputsException` (indicating that generated files already exist and conflict with the new build), automatically recover by appending the `--delete-conflicting-outputs` flag.
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
    *Or for watch mode:*
    ```bash
    dart run build_runner watch --delete-conflicting-outputs
    ```
    Verify that the command succeeds after applying this flag.

## Constraints
*   **Strict Web App Routing:** Never use `dart run build_runner serve` for web applications. You must use the `webdev` tool instead.
*   **File Tracking:** AVOID committing `.g.dart` files if the project policy is to generate them on-the-fly. Always clarify this policy before running git commands.
*   **Development Preference:** PREFER the `watch` command for continuous background generation during active development sessions to prevent stale code errors.
*   **Conflict Resolution:** Always use `--delete-conflicting-outputs` when regenerating files that have changed structure or when switching branches, rather than manually deleting `.dart_tool` or `.g.dart` files.
*   **Related Skills:** Defer to `dart-testing` for advanced test configurations and `dart-web-development` for web-specific serving and compilation.
