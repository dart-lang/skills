---
name: dart-collect-coverage
description: Collect test coverage for both Dart and Flutter projects and produce an LCOV report
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Fri, 24 Apr 2026 15:14:32 GMT
---
# Dart and Flutter Test Coverage

This skill covers **both Dart and Flutter projects**.  It detects which one
you're in and dispatches to the correct toolchain:

- **Dart projects** use `package:coverage` and `dart run coverage:test_with_coverage`.
- **Flutter projects** use the Flutter SDK's built-in `flutter test --coverage`.

Run `collect_coverage.sh` from the project root — it picks the right path,
runs the tool, and emits LCOV file. The only step left to human/LLM judgment is
deciding what to do about uncovered files, rest of it is deterministic.

## Usage

```bash
./skills/dart-collect-coverage/collect_coverage.sh [flags]
```

| Flag | Effect |
|---|---|
| `--branch` | Pass `--branch-coverage` to the collector (Dart only). |
| `--function` | Pass `--function-coverage` to the collector (Dart only). |
| `--manual` | Use the VM-service workflow (Dart only). |
| `-- <args>` | Forward `<args>` to the underlying test runner. |

Exit codes: `0` success, `1` not a Dart/Flutter project, `2` collection
failed, `3` expected outputs missing.

Outputs in `coverage/`:
- `lcov.info` — LCOV report (always)
- `coverage.json` — raw VM data (Dart only)
- `summary.txt` — per-file `pct  hits/total  path`, sorted ascending

## What the script handles

- Dart vs. Flutter detection (`sdk: flutter` in `pubspec.yaml`).
- Dart path: `dart pub add dev:coverage` (idempotent) → `dart run coverage:test_with_coverage` → `--check-ignore` formatting.
- Flutter path: `flutter test --coverage` (no extra dep needed).
- Pub workspace detection; passes member `test/` dirs to the collector.
- Background test-process cleanup in `--manual` mode (`trap`).
- Output validation and per-file coverage summary.

## What you still decide

For any file flagged at 0% in `summary.txt`, choose one:

1. **Write tests** — production logic that should be exercised.
2. **Ignore** — generated code or intentionally untestable paths. Apply
   `// coverage:ignore-file`, `// coverage:ignore-start` / `…ignore-end`,
   or `// coverage:ignore-line`. Auto-ignore is reasonable for `*.g.dart`,
   `*.freezed.dart`, `*.mocks.dart`, and `lib/generated/**`.
3. **Accept** — if you enforce a project-wide threshold instead.

The script always passes `--check-ignore`, so the directives above are
honored by the LCOV output.
