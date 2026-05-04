# Agent Skills for Dart

Agent skills for Dart, maintained by the Dart team.

If you are using Dart to build Flutter apps, you may also be 
interested in [Agent Skills for Flutter](https://github.com/flutter/skills).

## Installation

To install all skills into your project, run the following command. 
The `--agent universal` flag puts it in the standard `.agents/skills` 
folder that most agents use.

```bash
npx skills add dart-lang/skills --skill '*' --agent universal
```

## Updating Skills

To update, run the following command:

```bash
npx skills update
```


## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Code of Conduct

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for more information.

## Available Skills

| Skill | Description | Example prompt |
|---|---|---|
| [dart-add-unit-test](skills/dart-add-unit-test/SKILL.md) | Write and organize unit tests for functions, methods, and classes using `package:test`. Use when creating new logic or fixing bugs to ensure code remains correct and regression-free. | "Add a unit test for the calculateTotal function to verify edge cases." |
| [dart-build-cli-app](skills/dart-build-cli-app/SKILL.md) | Entrypoint structure, exit codes, cross-platform scripts. Use when building command line utilities, scripts, or applications. | "Create a basic CLI app structure with argument parsing for a file search tool." |
| [dart-collect-coverage](skills/dart-collect-coverage/SKILL.md) | Collect coverage using the coverage packge and create an LCOV report | "Collect test coverage and generate an LCOV report for the project." |
| [dart-fix-runtime-errors](skills/dart-fix-runtime-errors/SKILL.md) | Uses get_runtime_errors and lsp to fetch an active stack trace, locate the failing line, apply a fix, and verify resolution via hot_reload. | "Fix the NullPointer error in the user profile service." |
| [dart-fix-static-analysis-errors](skills/dart-fix-static-analysis-errors/SKILL.md) | Workflow for identifying and fixing static analysis errors. Use this after modifying code or if `dart analyze` fails. | "Fix all static analysis warnings in the lib/src directory." |
| [dart-generate-test-mocks](skills/dart-generate-test-mocks/SKILL.md) | Define and generate mock objects for external dependencies using `package:mockito` and `build_runner`. Use when unit testing classes that depend on complex external services like APIs or databases. | "Generate a mock for the ApiClient class using mockito." |
| [dart-migrate-to-checks-package](skills/dart-migrate-to-checks-package/SKILL.md) | Replace the usage of `expect` and similar functions from `package:matcher` to `package:checks` equivalents. | "Migrate the tests in test/user_test.dart to use package:checks." |
| [dart-resolve-package-conflicts](skills/dart-resolve-package-conflicts/SKILL.md) | Workflow for fixing package version conflicts. Use this when `pub get` fails due to incompatible package versions. | "Resolve the dependency conflict between the http and shelf packages." |
| [dart-run-static-analysis](skills/dart-run-static-analysis/SKILL.md) | Execute `dart analyze` to identify warnings and errors, and use `dart fix --apply` to automatically resolve mechanical lint issues. Use during development to ensure code quality and before committing changes. | "Run static analysis and apply mechanical fixes to the whole project." |
| [dart-use-pattern-matching](skills/dart-use-pattern-matching/SKILL.md) | Use switch expressions and pattern matching where appropriate | "Refactor the JSON parser to use switch expressions and pattern matching." |
