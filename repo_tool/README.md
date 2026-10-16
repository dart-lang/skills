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

## Adding, Renaming, or Deleting Skills

When adding, renaming, or deleting a skill in `skills/`:

1.  **Update `README.md`**: Add, rename, or remove the corresponding row in the `Available Skills` table in the root `README.md`.
2.  **Update `skills.sh.json`**: Add, rename, or remove the skill entry under `groups` in the root `skills.sh.json` file ([skills.sh documentation](https://www.skills.sh/docs/customize)).
    *   Because `skills.sh` retains historical skill slugs from install telemetry after a skill is renamed or deleted in Git, `"notGrouped": "bottom"` at the end of `skills.sh.json` automatically demotes any retired skill slugs into an `Other skills` section at the bottom of the page.
3.  **Verify**: Run `dart test` in `repo_tool` (`test/lint_skills_test.dart` verifies that `skills.sh.json` and `README.md` match the directories in `skills/`).


