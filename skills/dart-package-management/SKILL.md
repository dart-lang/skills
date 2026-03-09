---
name: "dart-package-management"
description: "Structure packages and manage dependencies using the pub ecosystem."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:42:02 GMT"

---
# dart-package-management

## Goal
Configures and manages Dart packages, monorepo workspaces, and standard directory layouts. Enforces strict `pubspec.yaml` validation, standardizes public/private library boundaries within the `lib/` directory, and orchestrates shared dependency resolution across workspace packages.

## Instructions

1. **Determine Project Scope via Decision Logic**
   Evaluate the user's request against the following decision tree to determine the required architecture:
   * Is the project a single standalone package?
     * **Yes:** Proceed to standard package layout and single `pubspec.yaml` generation.
     * **No:** Is the project a monorepo containing multiple interdependent packages?
       * **Yes:** Proceed to Workspace Configuration (requires Dart SDK `^3.6.0`).
       * **Unclear:** **STOP AND ASK THE USER:** "Does this project require a single package setup or a monorepo workspace configuration for multiple packages?"

2. **Scaffold the Package Layout**
   Enforce the standard Dart package directory structure. Create files and directories strictly adhering to these boundaries:
   * `lib/`: Public exports only.
   * `lib/src/`: Internal implementation files. Never import from `lib/src/` outside the package.
   * `bin/`: Public command-line executables.
   * `tool/`: Internal scripts and automation.
   * `example/`: Example usage code.
   * `test/`: Unit and integration tests.

   *Example internal import (inside `lib/`):*
   ```dart
   import 'src/internal_logic.dart';
   ```
   *Example public export (`lib/my_package.dart`):*
   ```dart
   export 'src/internal_logic.dart' show PublicClass;
   ```

3. **Configure Standard `pubspec.yaml`**
   Generate a valid `pubspec.yaml` for individual packages. Always use the caret (`^`) syntax for version constraints.
   ```yaml
   name: my_package
   description: >-
     A concise description of the package (60-180 characters).
   version: 1.0.0
   publish_to: none # Remove if publishing to pub.dev

   environment:
     sdk: ^3.6.0

   dependencies:
     path: ^1.9.0

   dev_dependencies:
     test: ^1.24.0
   ```

4. **Implement Workspace Configuration (Monorepos Only)**
   If the decision logic dictates a monorepo, configure a Dart workspace to share dependency resolution.
   
   *Step 4a: Root `pubspec.yaml`*
   Create a root configuration using glob patterns for the workspace.
   ```yaml
   name: my_monorepo_root
   publish_to: none
   environment:
     sdk: ^3.6.0
   workspace:
     - packages/*
   ```

   *Step 4b: Child `pubspec.yaml`*
   In every child package (e.g., `packages/client_package/pubspec.yaml`), enforce the `resolution: workspace` key and ensure the SDK constraint matches the root.
   ```yaml
   name: client_package
   description: Client package for the monorepo.
   version: 0.1.0
   
   environment:
     sdk: ^3.6.0
     
   resolution: workspace

   dependencies:
     shared_package: ^1.0.0 # Resolves locally if in the same workspace
   ```

5. **Manage Dependencies and Assets**
   * Execute package resolution commands whenever `pubspec.yaml` is modified:
     ```bash
     dart pub get
     ```
     *To update existing dependencies:*
     ```bash
     dart pub upgrade
     ```
   * Ensure all public assets (e.g., images, fonts) are placed in the `lib/` directory or explicitly declared if using Flutter-specific asset configurations.

6. **Validate-and-Fix**
   After generating or modifying the package structure, perform the following validation loop:
   * *Check:* Are there stray `pubspec.lock` or `.dart_tool/package_config.json` files in child workspace directories?
     * *Fix:* Execute `rm packages/*/pubspec.lock` and rely solely on the root lockfile.
   * *Check:* Do all workspace packages have an SDK constraint of `>=3.6.0`?
     * *Fix:* Update the `environment.sdk` field in failing `pubspec.yaml` files.
   * *Check:* Are there relative imports reaching into or out of `lib/`?
     * *Fix:* Rewrite imports crossing the `lib/` boundary to use `package:` URIs.

## Constraints
* DO NOT use exact version pinning (e.g., `1.2.3`) or unbounded ranges (e.g., `>=1.2.3`) for dependencies; strictly use caret syntax (`^1.2.3`).
* DO NOT place entrypoint scripts (files with a `main()` function) inside the `lib/` directory. They must reside in `bin/`, `tool/`, `web/`, or `example/`.
* DO NOT check `.dart_tool/` directories into source control.
* DO NOT allow external packages to import files from `lib/src/`.
* MUST use `dart pub get` or `dart pub upgrade` to manage `package_config.json` state; never modify it manually.
* MUST ensure all workspace packages share an SDK constraint of `^3.6.0` or higher.
