# Agent Skills for Dart

This repository contains agent skills for Dart.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Code of Conduct

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for more information.

## Available Skills

| Skill | Description |
|---|---|
| [dart-add-unit-test](skills/dart-add-unit-test/SKILL.md) | Write and organize unit tests for functions, methods, and classes using `package:test`. Use when creating new logic or fixing bugs to ensure code remains correct and regression-free. |
| [dart-build-cli-app](skills/dart-build-cli-app/SKILL.md) | Entrypoint structure, exit codes, cross-platform scripts. Use when building command line utilities, scripts, or applications. |
| [dart-collect-coverage](skills/dart-collect-coverage/SKILL.md) | Collect coverage using the coverage packge and create an LCOV report |
| [dart-fix-runtime-errors](skills/dart-fix-runtime-errors/SKILL.md) | Uses get_runtime_errors and lsp to fetch an active stack trace, locate the failing line, apply a fix, and verify resolution via hot_reload. |
| [dart-fix-static-analysis-errors](skills/dart-fix-static-analysis-errors/SKILL.md) | Workflow for identifying and fixing static analysis errors. Use this after modifying code or if `dart analyze` fails. |
| [dart-generate-test-mocks](skills/dart-generate-test-mocks/SKILL.md) | Define and generate mock objects for external dependencies using `package:mockito` and `build_runner`. Use when unit testing classes that depend on complex external services like APIs or databases. |
| [dart-migrate-to-checks-package](skills/dart-migrate-to-checks-package/SKILL.md) | Replace the usage of `expect` and similar functions from `package:matcher` to `package:checks` equivalents. |
| [dart-resolve-package-conflicts](skills/dart-resolve-package-conflicts/SKILL.md) | Workflow for fixing package version conflicts. Use this when `pub get` fails due to incompatible package versions. |
| [dart-run-static-analysis](skills/dart-run-static-analysis/SKILL.md) | Execute `dart analyze` to identify warnings and errors, and use `dart fix --apply` to automatically resolve mechanical lint issues. Use during development to ensure code quality and before committing changes. |
| [dart-use-pattern-matching](skills/dart-use-pattern-matching/SKILL.md) | Use switch expressions and pattern matching where appropriate |
