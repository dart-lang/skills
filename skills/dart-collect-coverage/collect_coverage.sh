#!/usr/bin/env bash
# collect_coverage.sh
#
# Deterministic implementation of the dart-collect-coverage skill.
# Replaces the LLM-driven workflow with a single self-contained script.
#
# What it does (mechanically):
#   1. Detects Dart vs. Flutter project from pubspec.yaml.
#   2. Detects whether the project is a pub workspace (monorepo) and finds
#      every member's test/ directory.
#   3. Adds the `coverage` package to dev_dependencies if absent (idempotent).
#   4. Runs `dart run coverage:test_with_coverage` with the right args,
#      always passing `--check-ignore` to honor coverage:ignore-* directives.
#   5. Validates that coverage/coverage.json and coverage/lcov.info exist
#      and are non-empty; exits non-zero with a clear message otherwise.
#   6. Reports per-file line coverage from lcov.info so the caller can
#      decide which gaps need new tests vs. ignore directives.
#
# What it does NOT do (these still require human/LLM judgment):
#   - Decide whether an uncovered file should get more tests or
#     a `// coverage:ignore-file` directive.
#   - Diagnose why a specific code path is unreached.
#
# Usage:
#   collect_coverage.sh [--manual] [--branch] [--function] [-- <extra args>]
#
# Flags:
#   --manual    Use the manual VM-service workflow instead of test_with_coverage.
#   --branch    Pass --branch-coverage to the collector (Dart VM >= 2.17).
#   --function  Pass --function-coverage to the collector.
#   --          Forward remaining args verbatim to test_with_coverage.
#
# Exit codes:
#   0  success
#   1  pubspec.yaml not found / not a Dart project
#   2  coverage tool failed
#   3  expected output files missing or empty

set -euo pipefail

# ---------- helpers ----------
log()  { printf '[collect_coverage] %s\n' "$*" >&2; }
die()  { log "ERROR: $*"; exit "${2:-1}"; }

# Read a top-level scalar key from a YAML file. Good enough for pubspec.yaml,
# which is conventionally simple. Returns empty string if the key is absent.
yaml_top_key() {
  local file=$1 key=$2
  awk -v k="$key" '
    /^[[:space:]]/ { next }
    $1 == k":" { sub(/^[^:]*:[[:space:]]*/, ""); print; exit }
  ' "$file"
}

# Returns 0 if the given top-level mapping key exists in the YAML file.
yaml_has_key() {
  local file=$1 key=$2
  awk -v k="$key" '
    /^[[:space:]]/ { next }
    $1 == k":" || $1 == k { found=1; exit }
    END { exit !found }
  ' "$file"
}

# Returns 0 if pubspec.yaml shows the package uses the Flutter SDK.
is_flutter_project() {
  local file=$1
  awk '
    # Primary: any indented "sdk: flutter" line, regardless of which block.
    /^[[:space:]]+sdk:[[:space:]]*flutter[[:space:]]*$/ { found=1; exit }
    # Secondary: top-level `flutter:` mapping for assets / plugin config.
    /^flutter:[[:space:]]*$/ { found=1; exit }
    END { exit !found }
  ' "$file"
}

# Returns 0 if pubspec declares a `workspace:` list (pub workspaces).
is_workspace() {
  local file=$1
  awk '
    /^workspace:/ { found=1; exit }
    END { exit !found }
  ' "$file"
}

# Print every workspace member path listed under `workspace:`.
workspace_members() {
  local file=$1
  awk '
    /^workspace:/ { in_ws=1; next }
    /^[a-zA-Z_]/  { in_ws=0 }
    in_ws && /^[[:space:]]+-[[:space:]]+/ {
      sub(/^[[:space:]]+-[[:space:]]+/, "")
      gsub(/["'\'']/, "")
      print
    }
  ' "$file"
}

# Returns 0 if `coverage` is already declared under dev_dependencies.
has_coverage_dep() {
  local file=$1
  awk '
    /^dev_dependencies:/ { in_dev=1; next }
    /^[a-zA-Z_]/         { in_dev=0 }
    in_dev && /^[[:space:]]+coverage:/ { found=1; exit }
    END { exit !found }
  ' "$file"
}

# ---------- arg parsing ----------
MANUAL=0
BRANCH=0
FUNCTION=0
PASSTHRU=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --manual)   MANUAL=1; shift ;;
    --branch)   BRANCH=1; shift ;;
    --function) FUNCTION=1; shift ;;
    --)         shift; PASSTHRU=("$@"); break ;;
    -h|--help)  sed -n '1,40p' "$0"; exit 0 ;;
    *)          die "unknown flag: $1" ;;
  esac
done

# ---------- preflight ----------
[[ -f pubspec.yaml ]] || die "no pubspec.yaml in $(pwd); run this from a Dart/Flutter project root"

if is_flutter_project pubspec.yaml; then
  PUB=flutter
  log "detected Flutter project"
else
  PUB=dart
  log "detected Dart project"
fi

WORKSPACE=0
TEST_DIRS=()
if is_workspace pubspec.yaml; then
  WORKSPACE=1
  log "detected pub workspace"
  while IFS= read -r member; do
    [[ -z $member ]] && continue
    if [[ -d "$member/test" ]]; then
      TEST_DIRS+=("$member/test")
    else
      log "  skipping workspace member without test/: $member"
    fi
  done < <(workspace_members pubspec.yaml)
  [[ ${#TEST_DIRS[@]} -gt 0 ]] || die "workspace has no test/ directories"
fi

# ---------- step 1: ensure coverage dev dep ----------
# Flutter projects don't need package:coverage: `flutter test --coverage`
# is bundled with the Flutter SDK and produces lcov.info directly. Adding
# the package would be harmless but we skip it to keep pubspec.yaml clean.
if [[ $PUB == flutter ]]; then
  log "step 1/3: Flutter project — skipping 'coverage' dev dep (built into Flutter SDK)"
elif has_coverage_dep pubspec.yaml; then
  log "step 1/3: 'coverage' already in dev_dependencies, skipping pub add"
else
  log "step 1/3: adding 'coverage' to dev_dependencies via 'dart pub add dev:coverage'"
  dart pub add dev:coverage >&2
fi

# ---------- step 2: collect ----------
mkdir -p coverage

if [[ $MANUAL -eq 1 ]]; then
  # Manual VM-service collection only works for Dart projects, because it
  # invokes `dart run … test` (i.e. package:test). Flutter widget tests
  # require the Flutter test runner, not package:test.
  [[ $PUB == flutter ]] && die "--manual is not supported for Flutter projects (use 'flutter test --coverage' which is the default)" 2

  log "step 2/3: running manual VM-service collection"
  PORT=${VM_SERVICE_PORT:-8181}

  # Run tests in background with the VM service exposed and isolates paused.
  dart run --pause-isolates-on-exit --disable-service-auth-codes \
    --enable-vm-service="$PORT" test &
  TEST_PID=$!
  trap 'kill "$TEST_PID" 2>/dev/null || true' EXIT

  EXTRA=()
  [[ $BRANCH   -eq 1 ]] && EXTRA+=(--branch-coverage)
  [[ $FUNCTION -eq 1 ]] && EXTRA+=(--function-coverage)

  dart run coverage:collect_coverage \
    --wait-paused \
    --uri="http://127.0.0.1:$PORT/" \
    -o coverage/coverage.json \
    --resume-isolates \
    "${EXTRA[@]}"

  wait "$TEST_PID" || die "test process exited non-zero" 2

  dart run coverage:format_coverage \
    --packages=.dart_tool/package_config.json \
    --lcov \
    -i coverage/coverage.json \
    -o coverage/lcov.info \
    --check-ignore

elif [[ $PUB == flutter ]]; then
  # Flutter has its own coverage flow. `flutter test --coverage` runs the
  # Flutter test runner AND emits coverage/lcov.info in one step. It does
  # not produce coverage.json (it goes straight from VM coverage to lcov),
  # and --branch/--function-coverage are not exposed via this command.
  if [[ $BRANCH -eq 1 || $FUNCTION -eq 1 ]]; then
    log "WARNING: --branch/--function ignored for Flutter (not exposed by 'flutter test --coverage')"
  fi
  log "step 2/3: running 'flutter test --coverage'"
  CMD=(flutter test --coverage)
  if [[ ${#PASSTHRU[@]} -gt 0 ]]; then
    CMD+=("${PASSTHRU[@]}")
  fi
  "${CMD[@]}" || die "coverage collection failed (exit $?)" 2

else
  log "step 2/3: running 'dart run coverage:test_with_coverage'"
  CMD=(dart run coverage:test_with_coverage)
  [[ $BRANCH   -eq 1 ]] && CMD+=(--branch-coverage)
  [[ $FUNCTION -eq 1 ]] && CMD+=(--function-coverage)

  # test_with_coverage forwards args after `--` to the test runner / formatter.
  if [[ $WORKSPACE -eq 1 ]] && [[ ${#PASSTHRU[@]} -eq 0 ]]; then
    CMD+=(-- "${TEST_DIRS[@]}")
  elif [[ ${#PASSTHRU[@]} -gt 0 ]]; then
    CMD+=(-- "${PASSTHRU[@]}")
  fi

  "${CMD[@]}" || die "coverage collection failed (exit $?)" 2
fi

# ---------- step 3: validate ----------
# `flutter test --coverage` only emits lcov.info; the Dart path emits both.
log "step 3/3: validating outputs"
EXPECTED=(coverage/lcov.info)
[[ $PUB == dart ]] && EXPECTED+=(coverage/coverage.json)
for f in "${EXPECTED[@]}"; do
  [[ -s $f ]] || die "expected output missing or empty: $f" 3
done

# ---------- summary ----------
# Parse lcov.info to surface uncovered files. Pure awk, no LLM.
awk '
  /^SF:/   { file=substr($0,4); lh=0; lf=0 }
  /^LH:/   { lh=substr($0,4)+0 }
  /^LF:/   { lf=substr($0,4)+0 }
  /^end_of_record/ {
    pct = (lf>0) ? (100*lh/lf) : 0
    printf "%6.2f%%  %d/%d  %s\n", pct, lh, lf, file
  }
' coverage/lcov.info | sort -n > coverage/summary.txt

UNCOVERED=$(awk '$1=="0.00%"' coverage/summary.txt | wc -l | tr -d ' ')
TOTAL_FILES=$(wc -l < coverage/summary.txt | tr -d ' ')

if [[ $PUB == flutter ]]; then
  log "wrote coverage/lcov.info, coverage/summary.txt"
else
  log "wrote coverage/coverage.json, coverage/lcov.info, coverage/summary.txt"
fi
log "files reported: $TOTAL_FILES, files with 0% coverage: $UNCOVERED"
if [[ $UNCOVERED -gt 0 ]]; then
  log ""
  log "files with 0% line coverage (decide: add tests or // coverage:ignore-file):"
  awk '$1=="0.00%" { print "  " $0 }' coverage/summary.txt >&2
fi
