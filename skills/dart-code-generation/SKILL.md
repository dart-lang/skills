---
name: dart-code-generation
description: Automate repetitive code tasks using the build_runner system.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:21:52 GMT
---
# Generating Dart Code with Build Runner

## Contents
- [Setup and Configuration](#setup-and-configuration)
- [Core Commands](#core-commands)
- [Version Control Policy](#version-control-policy)
- [Workflow: Continuous Development](#workflow-continuous-development)
- [Workflow: Resolving Build Conflicts](#workflow-resolving-build-conflicts)
- [Examples](#examples)

## Setup and Configuration

Configure `build_runner` to handle code generation for packages utilizing the Dart build system (e.g., `json_serializable`, `built_value_generator`). 

Add the required packages to your `dev_dependencies` in `pubspec.yaml`. Include `build_test` only if you are writing tests that depend on generated code.

*Note: For web-specific development and serving, refer to the `dart-web-development` skill and use the `webdev` tool instead of `build_runner serve`.*
*Note: For testing strategies, refer to the `dart-testing` skill.*

## Core Commands

Execute `build_runner` commands via the Dart CLI. Apply the following conditional logic to select the appropriate command:

- **If developing locally:** Use `watch` to launch a persistent build server that monitors input files and performs incremental rebuilds automatically. This is the **preferred** method during active development.
- **If running in a CI/CD pipeline or performing a final release build:** Use `build` to perform a strict, one-time build.
- **If executing tests that require generated code:** Use `test` to compile generated assets and run the test suite.
- **If building a web application:** Delegate serving to `webdev serve` rather than using `build_runner serve`.

## Version Control Policy

Apply conditional logic based on the project's repository policy regarding generated files (typically `.g.dart`, `.freezed.dart`, or `.part.dart`):

- **If the project policy requires on-the-fly generation:** Do NOT commit generated files. Add `*.g.dart` (and other generated extensions) to the `.gitignore` file.
- **If the project policy requires caching generated code:** Commit the generated files and ensure CI pipelines verify that generated files are up-to-date with their source inputs.

## Workflow: Continuous Development

Use this workflow for standard feature development requiring code generation.

**Task Progress**
- [ ] Run `dart pub get` to ensure all builder dependencies are resolved.
- [ ] Execute `dart run build_runner watch` in a dedicated terminal process.
- [ ] Modify source files (e.g., adding `@JsonSerializable()` annotations).
- [ ] Verify the watcher detects changes and successfully outputs the generated files.
- [ ] Review errors in the watcher output -> fix source annotations -> verify the watcher rebuilds successfully.

## Workflow: Resolving Build Conflicts

Use this workflow when `build_runner` fails due to pre-existing generated files or conflicting outputs from previous build runs.

**Task Progress**
- [ ] Identify `ConflictingOutputsException` or similar errors in the build output.
- [ ] Terminate any running `watch` processes.
- [ ] Execute the build command with the conflict resolution flag: `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Verify the build completes successfully.
- [ ] Restart the `watch` process for continued development.

## Examples

### Dependency Setup
```yaml
# pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.0
  build_test: ^3.2.0 # Optional: Include if testing generated code
  json_serializable: ^8.0.0 # Example builder
```

### Command Execution

**Start continuous generation (Preferred for Dev):**
```bash
dart run build_runner watch
```

**Force a clean build by deleting conflicting outputs:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Run tests with generated code:**
```bash
dart run build_runner test
```
