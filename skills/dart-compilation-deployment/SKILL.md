---
name: "dart-compilation-deployment"
description: "Compile and deploy Dart apps for various native and web target platforms."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:42:58 GMT"

---
# Dart Compilation Manager

## Goal
Manages the compilation of Dart applications into highly optimized deployment formats. Evaluates target environments to select the appropriate compilation strategy, ranging from self-contained native executables and AOT snapshots to web-optimized JavaScript and WebAssembly. Handles cross-compilation routing, optimization flags, and runtime execution validation.

## Instructions

1. **Determine the Target Environment (Decision Logic)**
   Evaluate the user's deployment requirements to select the correct compilation subcommand:
   *   **Self-contained native binary (Windows/macOS/Linux):** Use `exe`.
   *   **Resource-constrained native environment:** Use `aot-snapshot` (requires `dartaotruntime` on the host).
   *   **Web deployment:** Use `js` or `wasm`.
   *   **Fast startup with training data:** Use `jit-snapshot`.
   *   **Portable intermediate representation:** Use `kernel`.

2. **Gather Compilation Parameters**
   Identify if cross-compilation or specific optimization flags are required.
   **STOP AND ASK THE USER:**
   *   "What is the target operating system and architecture? (Note: Cross-compilation is only supported for Linux targets: `arm`, `arm64`, `riscv64`, `x64`)."
   *   "Are there any specific environment variables to inject (e.g., `-D<flag>=<value>`)?"
   *   "If targeting web (JS), what optimization level is required (`-O1` through `-O4`)?"

3. **Execute the Compilation Command**
   Construct and execute the appropriate `dart compile` command based on the decision logic.

   *For self-contained native binaries:*
   ```bash
   # Standard compilation
   dart compile exe bin/main.dart -o bin/app.exe

   # Cross-compilation to Linux
   dart compile exe --target-os=linux --target-arch=x64 bin/main.dart -o bin/app_linux_x64
   ```

   *For resource-constrained environments (AOT Snapshot):*
   ```bash
   # Generate AOT snapshot
   dart compile aot-snapshot bin/main.dart -o bin/app.aot
   ```

   *For Web (JavaScript):*
   ```bash
   # Compile to JS with O2 optimization (safe minification)
   dart compile js -O2 -o build/app.js web/main.dart
   
   # Compile to JS with aggressive O4 optimization and environment variables
   dart compile js -O4 -DAPI_URL=https://api.example.com -o build/app.js web/main.dart
   ```

   *For Web (WebAssembly):*
   ```bash
   dart compile wasm web/main.dart -o build/app.wasm
   ```

4. **Validate Output and Execution (Validate-and-Fix)**
   Verify that the compiled artifact exists and functions correctly in its intended runtime.
   
   *If validating an `exe`:*
   ```bash
   # Verify file exists and is executable
   ls -la bin/app.exe
   ./bin/app.exe
   ```

   *If validating an `aot-snapshot`:*
   ```bash
   # Execute using the Dart AOT runtime
   dartaotruntime bin/app.aot
   ```

   *Error Handling:* If the compilation fails due to the presence of build hooks, fallback to `dart build`. If JS compilation with `-O4` causes runtime type errors, downgrade to `-O2` and recompile.

## Constraints
*   Use `dart compile exe` strictly for self-contained native binaries on Windows, macOS, or Linux.
*   Use `dart compile js` or `dart compile wasm` strictly for web deployment targets.
*   Optimize for performance using AOT compilation (`exe` or `aot-snapshot`) wherever natively supported.
*   Use `dartaotruntime` for running AOT snapshots in resource-constrained environments; do not bundle the full Dart VM.
*   Do not use `dart compile exe` or `dart compile aot-snapshot` if the package or its dependencies utilize build hooks (use `dart build` instead).
*   Cross-compilation (`--target-os`) is strictly limited to `linux`. Do not attempt to cross-compile to macOS or Windows from another host.
*   Do not use `dart:mirrors` or `dart:developer` libraries when compiling to `exe` or `aot-snapshot`.
