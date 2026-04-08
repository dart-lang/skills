---
name: dart-compilation-deployment
description: Compile and deploy Dart apps for various native and web target platforms.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:20:36 GMT
---
# Compiling Dart Applications

## Contents
- [Compilation Targets & Conditional Logic](#compilation-targets--conditional-logic)
- [Workflow: Compiling Native Executables](#workflow-compiling-native-executables)
- [Workflow: Compiling AOT Snapshots](#workflow-compiling-aot-snapshots)
- [Workflow: Compiling for the Web](#workflow-compiling-for-the-web)
- [Examples](#examples)

## Compilation Targets & Conditional Logic

Select the appropriate `dart compile` subcommand based on the deployment target and constraints:

*   **If deploying self-contained native binaries on Windows/macOS/Linux:** Use `exe`. This bundles the machine code and a minimal Dart runtime.
*   **If deploying to resource-constrained environments or distributing multiple command-line apps:** Use `aot-snapshot`. This produces an architecture-specific module without the runtime. Execute it using `dartaotruntime`.
*   **If deploying to web targets:** Use `js` or `wasm`. (See related skill: `dart-web-development`).
*   **If optimizing for fast startup using training data:** Use `jit-snapshot`.
*   **If requiring a portable module across all OS/CPU architectures:** Use `kernel`. Note that startup time is slower than AOT formats.

*Note: The `exe` and `aot-snapshot` commands do not support `dart:mirrors` or `dart:developer`. They also do not run build hooks; use `dart build` if hooks are present.*

## Workflow: Compiling Native Executables

Follow this workflow to generate standalone executables.

**Task Progress Checklist:**
- [ ] Verify the application does not rely on `dart:mirrors` or `dart:developer`.
- [ ] Determine the target OS and architecture.
- [ ] Execute the `dart compile exe` command with appropriate flags.
- [ ] Run validator -> execute the binary in the target environment -> review errors -> fix.

**Implementation Steps:**
1. Compile the source file and specify the output path using `-o`:
   ```bash
   dart compile exe bin/myapp.dart -o bin/myapp
   ```
2. **Cross-compilation (Linux targets only):** If compiling for a different architecture on a 64-bit host, specify `--target-os` and `--target-arch` (`arm`, `arm64`, `riscv64`, `x64`):
   ```bash
   dart compile exe --target-os=linux --target-arch=arm64 bin/myapp.dart -o bin/myapp_arm64
   ```

## Workflow: Compiling AOT Snapshots

Use AOT snapshots to optimize performance and reduce disk space when the target environment already has the Dart runtime installed.

**Task Progress Checklist:**
- [ ] Compile the Dart code to an AOT snapshot.
- [ ] Deploy the `.aot` file to the target environment.
- [ ] Ensure `dartaotruntime` is available in the target environment's `PATH`.
- [ ] Execute the snapshot using `dartaotruntime`.

**Implementation Steps:**
1. Generate the AOT snapshot:
   ```bash
   dart compile aot-snapshot bin/myapp.dart -o bin/myapp.aot
   ```
2. Run the snapshot using the standalone AOT runtime:
   ```bash
   dartaotruntime bin/myapp.aot
   ```

## Workflow: Compiling for the Web

Compile Dart code to deployable JavaScript or WebAssembly. 

**Task Progress Checklist:**
- [ ] Select the target format (`js` or `wasm`).
- [ ] Select the optimization level (`-O1` through `-O4`).
- [ ] Compile the application.
- [ ] Run validator -> test edge cases in user input -> review runtime type errors -> downgrade optimization level if necessary -> fix.

**Implementation Steps:**
1. Compile to JavaScript using the `-O2` optimization level (safe default):
   ```bash
   dart compile js -O2 -o build/main.js web/main.dart
   ```
2. **Optimization Levels:**
   *   `-O1`: Default optimizations.
   *   `-O2`: Adds safe minification. (Recommended baseline).
   *   `-O3`: Omits implicit type checks. *Warning: Test thoroughly with `-O2` first to ensure no `TypeError` exceptions are thrown.*
   *   `-O4`: Aggressive optimizations. *Warning: Susceptible to variations in input data. Test edge cases rigorously.*
3. **Environment Declarations:** Pass environment variables using `-D<flag>=<value>`:
   ```bash
   dart compile js -DAPI_URL=https://api.example.com -O2 -o build/main.js web/main.dart
   ```

## Examples

### Example 1: Cross-Compiling a Native Executable for Linux ARM64
```bash
# Input
dart compile exe --target-os=linux --target-arch=arm64 bin/server.dart -o build/server_linux_arm64

# Output
# Generates a standalone binary at build/server_linux_arm64 containing the compiled machine code and Dart runtime.
```

### Example 2: Generating and Running an AOT Snapshot
```bash
# Input: Compilation
dart compile aot-snapshot bin/cli.dart -o build/cli.aot

# Input: Execution
dartaotruntime build/cli.aot

# Output
# Executes the pre-compiled AOT snapshot without the overhead of the full Dart SDK.
```

### Example 3: Compiling for Web with Strict Optimizations
```bash
# Input
dart compile js -O3 --no-source-maps -DENVIRONMENT=production -o deploy/app.js web/app.dart

# Output
# Generates a highly optimized, minified JavaScript file (deploy/app.js) with type checks omitted and no source maps.
```
