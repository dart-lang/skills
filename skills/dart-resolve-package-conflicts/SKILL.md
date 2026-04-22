---
name: dart-resolve-package-conflicts
description: Workflow for fixing package version conflicts. Use this when `pub get` fails due to incompatible package versions.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 20:43:00 GMT
---
# Managing Dart Dependencies

## Contents
- [Dependency Resolution Constraints](#dependency-resolution-constraints)
- [Auditing Outdated Packages](#auditing-outdated-packages)
- [Updating Dependencies Workflow](#updating-dependencies-workflow)
- [Managing the Lockfile](#managing-the-lockfile)
- [Best Practices](#best-practices)

## Dependency Resolution Constraints
Dart strictly enforces a single-version rule for packages; multiple versions of the same package cannot coexist in a dependency graph. To prevent "version lock" (where packages are disincentivized to upgrade dependencies because it forces downstream upgrades), Dart relies on version constraints. 

If `pub` cannot find a set of concrete versions that satisfy all constraints across the entire dependency graph, it fails with a resolution error. Always use caret syntax (`^`) to provide the version solver with sufficient flexibility.

## Auditing Outdated Packages
Run `dart pub outdated` to analyze the dependency graph and identify packages that are not on the latest stable versions. 

Analyze the output columns to determine the appropriate upgrade path:
*   **Current:** The exact version currently recorded in `pubspec.lock`.
*   **Upgradable:** The latest version allowed by the constraints in `pubspec.yaml`. Resolvable via `dart pub upgrade`.
*   **Resolvable:** The absolute latest version that can be resolved when considering all other dependencies in the graph. Often requires manual `pubspec.yaml` edits.
*   **Latest:** The absolute latest version available on the registry (excluding prereleases).

## Updating Dependencies Workflow

Use the following checklist to systematically update dependencies and resolve conflicts.

### Task Progress
- [ ] Run `dart pub outdated` to audit current dependencies.
- [ ] Update packages within existing constraints (Upgradable).
- [ ] Update packages outside existing constraints (Resolvable).
- [ ] Tighten `dev_dependencies` constraints.
- [ ] Run validator -> review errors -> fix constraints.

### 1. Update Within Constraints (Upgradable)
If the target version is listed in the **Upgradable** column:
1. Run `dart pub upgrade`.
2. Verify that `pubspec.lock` updates to the new versions.

### 2. Update Outside Constraints (Resolvable)
If the target version is listed in the **Resolvable** column but *not* the **Upgradable** column:
1. Manually edit `pubspec.yaml` to bump the lower bound to the Resolvable version.
   *Example:* Change `http: ^0.11.0` to `http: ^0.12.1`.
2. Run `dart pub upgrade` to regenerate the lockfile with the new constraints.

### 3. Tighten Constraints
Set the lower bound of `dev_dependencies` to the latest version your package actually resolves to.
1. Run `dart pub upgrade --tighten`.
2. Verify that `pubspec.yaml` reflects the updated lower bounds (e.g., `build_runner: ^2.10.4`).

### 4. Feedback Loop: Resolve Conflicts
If `dart pub upgrade` fails with a resolution error:
1. **Run validator:** Read the CLI error output to identify the conflicting transitive dependency.
2. **Review errors:** Run `dart pub deps` to trace which top-level packages are pulling in the conflicting transitive dependency.
3. **Fix:** Downgrade the top-level package constraint, or use `dependency_overrides` temporarily if testing a forced resolution.

## Managing the Lockfile
The `pubspec.lock` file guarantees reproducible builds by pinning exact versions. 

*   **Do not delete the entire `pubspec.lock` file** to resolve conflicts. This alters the resolved versions of unrelated dependencies and introduces instability.
*   **To handle a retracted package version:**
    1. Open `pubspec.lock`.
    2. Delete the specific YAML block for the retracted package.
    3. Run `dart pub get`. The solver will fetch the newest compatible, non-retracted version and rewrite the entry.
*   **Automatic Unlocking:** `dart pub get` automatically unlocks the minimum required dependencies to achieve resolution when you add/remove packages in `pubspec.yaml` or change the Dart SDK version.

## Best Practices
*   **Use Caret Syntax:** Always specify dependencies using caret syntax (e.g., `^1.2.3`) to allow `pub` to select newer, non-breaking versions while placing a strict upper bound at the next major version.
*   **Proactive Freshness:** Keep packages on the freshest possible versions. Stale transitive dependencies severely impact the ability to resolve the overall dependency graph.
*   **Tighten Before Publishing:** Always run `dart pub upgrade --tighten` before publishing a package to ensure users get the versions you actually tested against.
