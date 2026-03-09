---
name: "dart-package-management"
description: "Structure packages and manage dependencies using the pub ecosystem."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:32:01 GMT"

---
# Dart Package Management

## Goal
Configures and manages Dart packages, monorepo workspaces, and directory layouts. Enforces `pubspec.yaml` standards, dependency resolution, and strict public/private API boundaries. Assumes a modern Dart environment (SDK >= 3.6.0) utilizing the official package layout conventions and workspace features for multi-package repositories.

## Instructions

1. **Determine Repository Architecture**
   Evaluate the user's project scope using the following Decision Logic:
   * *Is the project a single standalone package?* -> Proceed to Step 2a (Standard Package).
   * *Does the project contain multiple interdependent packages?* -> Proceed to Step 2b (Monorepo Workspace).
   * **STOP AND ASK THE USER:** If the repository structure is ambiguous, ask: "Should this project be configured as a single Dart package or a monorepo workspace containing multiple packages?"

2. **Configure `pubspec.yaml`**
   Based on the architecture decision, generate the appropriate configuration files.

   *Step 2a: Standard Package*
   Create a standard `pubspec.yaml` at the project root.
   ```yaml
   name: package_name
   description: >-
     A concise description of the package (60-180 characters).
   version: 1.0.0
   homepage: https://example.com/package_name
   environment:
     sdk: ^3.6.0
   dependencies:
     path: ^1.9.0
   dev_dependencies:
     test: ^2.4.0
   ```

   *Step 2b: Monorepo Workspace*
   Create a root `pubspec.yaml` to define the workspace. Use glob patterns (`*`) to automatically include sub-packages.
   ```yaml
   name: root_workspace
   publish_to: none
   environment:
     sdk: ^3.6.0
   workspace:
     - packages/*
   ```
   For each child package (e.g., `packages/client_package/pubspec.yaml`), enforce the `resolution: workspace` directive and ensure the SDK constraint matches the root.
   ```yaml
   name: client_package
   description: Client implementation for the workspace.
   version: 0.1.0
   environment:
     sdk: ^3.6.0
   resolution: workspace
   dependencies:
     shared_package: ^1.0.0 # Resolves locally within the workspace
   ```

3. **Scaffold Package Layout**
   Enforce the standard Dart directory structure. Create the following directories and files as needed:
   * `lib/`: Publicly exported libraries and assets.
   * `lib/src/`: Private implementation files.
   * `bin/`: Public command-line executables.
   * `tool/`: Internal development scripts.
   * `test/`: Unit and integration tests.
   * `example/`: Usage examples.

4. **Implement Import Boundaries**
   Apply strict import rules based on file location.
   * *Within `lib/` reaching into `lib/src/`:* Use relative imports.
     ```dart
     // lib/my_package.dart
     import 'src/internal_logic.dart';
     ```
   * *Outside `lib/` (e.g., `test/`, `bin/`, `example/`) reaching into `lib/src/`:* Use `package:` imports.
     ```dart
     // test/my_package_test.dart
     import 'package:my_package/src/internal_logic.dart';
     ```

5. **Manage Dependencies and State**
   Execute package resolution commands to generate the `package_config.json` and `pubspec.lock` files.
   ```bash
   # For initial setup or adding new dependencies
   dart pub get

   # To upgrade existing dependencies to their latest compatible versions
   dart pub upgrade
   ```

6. **Validate and Fix**
   Verify the configuration state.
   * Run `dart pub workspace list` (if in a monorepo) to ensure all child packages are recognized.
   * Run `dart analyze` to catch import boundary violations (`avoid_relative_lib_imports`).
   * If `dart pub get` fails due to a stray `pubspec.yaml` in a non-workspace directory, delete the stray file or add it to the `workspace:` list, then re-run `dart pub get`.

## Constraints

* DO maintain a valid `pubspec.yaml` with clear version constraints (prefer `^` syntax, e.g., `^2.1.0`).
* DO follow the `lib/` directory convention for public exports; never place entrypoints (`main()`) directly in `lib/`.
* DO use `dart pub get` and `dart pub upgrade` to manage the `.dart_tool/package_config.json`.
* DO implement workspaces in monorepos to share dependencies across local packages.
* DO ensure all public assets (e.g., CSS, images) are listed correctly in the pubspec or placed in the top-level `lib/` directory for web/asset sharing.
* DO NOT check the `.dart_tool/` directory into source control; ensure it is added to `.gitignore`.
* DO NOT use `resolution: workspace` on packages with an SDK constraint lower than `^3.6.0`.
* DO NOT import from another package's `lib/src/` directory under any circumstances.
* Related Skills: `dart-api-design`.
