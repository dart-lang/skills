# repo_tool

Repo tooling to help validate dart skills.

In addition to test tooling utilities, `repo_tool` acts as the shared package
dependency configuration for static analysis and formatting verification across
all Dart code snippets and examples in the `skills/` directory.

## Running Validation

To validate the skills in the repository, run:

```bash
dart test
```

## Static Analysis

To analyze repo tooling and skill examples:

```bash
dart pub get
dart analyze --fatal-infos --packages=.dart_tool/package_config.json . ../skills
```

