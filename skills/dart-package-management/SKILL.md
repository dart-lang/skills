---
name: dart-package-management
description: Structure packages and manage dependencies using the pub ecosystem.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:19:51 GMT
---
# Managing Dart Packages

## Contents
- [Package Layout Conventions](#package-layout-conventions)
- [Pubspec Configuration](#pubspec-configuration)
- [Monorepo Workspaces](#monorepo-workspaces)
- [Workflows](#workflows)
- [Examples](#examples)

## Package Layout Conventions

Structure Dart packages using standardized directories to ensure tooling compatibility and clear API boundaries.

- **`lib/`**: Place public libraries and assets here. Export only the public API surface.
- **`lib/src/`**: Place internal implementation files here. Never import from another package's `lib/src/`. Use relative imports within your own package when importing from `lib/src/` to `lib/`.
- **`bin/`**: Place public command-line executables here.
- **`tool/`**: Place internal scripts and tools (e.g., code generation, documentation scripts) here.
- **`test/`**: Place unit tests here, suffixed with `_test.dart`.
- **`integration_test/`**: Place slow, integration-level tests here.
- **`example/`**: Place standalone example programs demonstrating package usage. Use `package:` imports to reference the parent package.
- **`web/`**: Place web-specific entrypoints (`main.dart`) and assets (`index.html`, CSS) here.
- **`hook/`**: Place SDK build hooks (e.g., `build.dart`) here.

## Pubspec Configuration

Maintain a valid `pubspec.yaml` at the root of every package. 

- **Version Constraints**: Use caret syntax (`^`) for dependency version constraints (e.g., `^3.2.0`) to allow non-breaking updates.
- **SDK Constraints**: Always define an `environment` with a lower-bound SDK constraint.
- **Public Assets**: Explicitly list all public assets (images, fonts) required by the package.
- **Executables**: Map scripts from `bin/` to command names under the `executables` field.
- **Metadata**: Include `name`, `version`, `description`, `repository`, and `issue_tracker` for published packages.
- **Topics**: Categorize published packages using the `topics` field (max 5 topics, lowercase alphanumeric and hyphens).
- **False Secrets**: Use the `false_secrets` field with gitignore patterns to prevent false positives during pub's pre-publish leak detection.

## Monorepo Workspaces

Implement workspaces in monorepos to share dependencies across local packages, reducing memory usage and ensuring version consistency. 

- **Root Pubspec**: Define the workspace at the repository root. Set `publish_to: none`, require SDK `^3.6.0` or higher, and use the `workspace` field with glob patterns (e.g., `packages/*`).
- **Child Pubspecs**: In each workspace package, require SDK `^3.6.0` or higher and set `resolution: workspace`.
- **Interdependencies**: Depend on other workspace packages normally. Pub automatically resolves to the local workspace version.
- **Overrides**: Place `dependency_overrides` in the root `pubspec.yaml` to apply them globally across the workspace.

## Workflows

### Setting up a Monorepo Workspace

Use this checklist to convert a standard repository into a Dart workspace.

- [ ] Create a root `pubspec.yaml`.
- [ ] Set `publish_to: none` and `environment: sdk: ^3.6.0` in the root pubspec.
- [ ] Add the `workspace:` field to the root pubspec using glob patterns (e.g., `- packages/*`).
- [ ] Update all child `pubspec.yaml` files to include `environment: sdk: ^3.6.0` (or higher).
- [ ] Add `resolution: workspace` to all child `pubspec.yaml` files.
- [ ] Run `dart pub get` at the repository root.
- [ ] **Feedback Loop**: Run validator -> review errors -> fix. Ensure no stray `pubspec.lock` or `.dart_tool/package_config.json` files exist in child directories. If resolution fails, align conflicting dependency versions across child packages.

### Managing Dependencies

- [ ] Run `dart pub get` to fetch dependencies and generate the `package_config.json`.
- [ ] Run `dart pub upgrade` to update dependencies to their latest compatible versions.
- [ ] Commit `pubspec.lock` ONLY for application packages. Omit it for library packages.

## Examples

### Standard Library Pubspec

```yaml
name: enchilada
description: A comprehensive toolkit for newt transmogrification.
version: 1.2.3
repository: https://github.com/example/enchilada
issue_tracker: https://github.com/example/enchilada/issues

environment:
  sdk: ^3.6.0

dependencies:
  path: ^1.8.0
  transmogrify: ^0.4.0

dev_dependencies:
  test: ^2.0.0
  lints: ^3.0.0

executables:
  enchilada: main

topics:
  - transmogrification
  - utilities
```

### Workspace Root Pubspec

```yaml
name: my_monorepo
publish_to: none

environment:
  sdk: ^3.6.0

workspace:
  - packages/*

# Apply overrides globally across all workspace packages
dependency_overrides:
  transmogrify: ^0.5.0-dev
```

### Workspace Child Pubspec

```yaml
name: client_package
description: The client application for the monorepo.
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.6.0

resolution: workspace

dependencies:
  shared_package: ^1.0.0 # Resolves locally within the workspace
  http: ^1.1.0
```
