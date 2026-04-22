---
name: dart-run-static-analysis
description: Execute `dart analyze` to identify warnings and errors, and use `dart fix --apply` to automatically resolve mechanical lint issues. Use during development to ensure code quality and before committing changes.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 19:50:28 GMT
---
# Analyzing and Fixing Dart Code

## Contents
- [Executing Static Analysis](#executing-static-analysis)
- [Applying Automated Fixes](#applying-automated-fixes)
- [Configuring Analysis Options](#configuring-analysis-options)
- [Suppressing Diagnostics](#suppressing-diagnostics)
- [Using Analyzer Plugins](#using-analyzer-plugins)
- [Workflows](#workflows)

## Executing Static Analysis

Run the `dart analyze` command to perform static analysis on Dart source code. This utilizes the `analyzer` package to reveal type-related bugs, enforce linter rules, and validate code against the Dart language specification.

*   **Analyze the current directory:** Run `dart analyze`.
*   **Analyze a specific directory or file:** Run `dart analyze <DIRECTORY_OR_FILE>` (e.g., `dart analyze bin`).
*   **Customize failure thresholds:** By default, the analyzer reports failure for errors and warnings, but not for info-level issues. 
    *   Fail on info-level issues: `dart analyze --fatal-infos`
    *   Ignore warnings for exit codes: `dart analyze --no-fatal-warnings`

## Applying Automated Fixes

Use the `dart fix` command to apply automated edits that resolve issues reported by diagnostics and linter rules.

*   **Preview fixes:** Run `dart fix --dry-run` to see proposed changes without modifying files.
*   **Apply fixes:** Run `dart fix --apply` to execute the automated edits.
*   **Target specific diagnostics:** Use the `--code` flag to apply fixes for a specific issue.
    *   *Example (Dart 3 Migration):* `dart fix --apply --code=obsolete_colon_for_default_value` automates the migration of colon-syntax for default values to the equals syntax.

*Note: Not all diagnostics have associated fixes. Enabling additional lints in the analysis options file can increase the number of available automated fixes.*

## Configuring Analysis Options

Customize the analyzer's behavior using an `analysis_options.yaml` file placed at the root of the package (adjacent to `pubspec.yaml`).

### Core Configuration Structure

```yaml
# Include standard rule sets (e.g., lints or flutter_lints)
include: package:lints/recommended.yaml

analyzer:
  # Exclude specific files or directories using glob patterns
  exclude:
    - lib/client.dart
    - lib/server/*.g.dart
    - test/_data/**
  
  # Enable strict type checks to prevent implicit dynamic downcasts
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
    
  # Override the severity of specific diagnostics
  errors:
    invalid_assignment: warning
    missing_return: error
    todo: ignore

linter:
  # Enable or disable specific linter rules
  rules:
    # List syntax (if not disabling rules)
    - always_declare_return_types
    - cancel_subscriptions
    # OR Map syntax (if enabling/disabling specific rules)
    # avoid_shadowing_type_parameters: false
    # await_only_futures: true
```

## Suppressing Diagnostics

When a diagnostic is a false positive or intentionally violated, suppress it using specific code comments.

*   **If suppressing for a single line:** Add `// ignore: <diagnostic_code>` above or at the end of the target line.
    ```dart
    // ignore: invalid_assignment
    int x = '';
    ```
*   **If suppressing for an entire file:** Add `// ignore_for_file: <diagnostic_code>` anywhere in the file (typically at the top).
    ```dart
    // ignore_for_file: unused_local_variable, dead_code
    ```
*   **If suppressing all lints in a file (e.g., generated code):** Use the `type=lint` specifier.
    ```dart
    // ignore_for_file: type=lint
    ```
*   **If suppressing in a `pubspec.yaml` file:** Add the ignore comment directly above the affected line.
    ```yaml
    # ignore: sort_pub_dependencies
    collection: ^1.19.0
    ```

## Using Analyzer Plugins

Extend the Dart analyzer to report custom diagnostics, offer quick fixes, and provide assists by enabling analyzer plugins.

1. Add the plugin package as a `dev_dependency` in `pubspec.yaml`.
2. Enable the plugin in `analysis_options.yaml`:

```yaml
plugins:
  my_custom_plugin: ^1.0.0 # Or use a local path: { path: /path/to/plugin }
```

3. Configure plugin-specific diagnostics (if supported by the plugin):

```yaml
plugins:
  my_custom_plugin:
    diagnostics:
      custom_rule_1: true
      custom_rule_2: false
```

## Workflows

### Task Progress: Enforcing Strict Analysis & Fixing Issues

Copy this checklist to track the implementation of strict static analysis and automated remediation.

- [ ] Create or locate `analysis_options.yaml` at the package root.
- [ ] Include a baseline linting package (`package:lints/recommended.yaml` or `package:flutter_lints/flutter.yaml`).
- [ ] Enable strict language modes (`strict-casts`, `strict-inference`, `strict-raw-types`) under the `analyzer: language:` block.
- [ ] Exclude generated files (e.g., `**/*.g.dart`, `**/*.freezed.dart`) under the `analyzer: exclude:` block.
- [ ] Run `dart analyze --fatal-infos` to identify all baseline issues.
- [ ] Run `dart fix --dry-run` to evaluate available automated fixes.
- [ ] Run `dart fix --apply` to execute automated fixes.
- [ ] Manually resolve remaining analysis errors and warnings.
- [ ] Run validator -> review errors -> fix (Repeat until `dart analyze` returns 0 issues).
