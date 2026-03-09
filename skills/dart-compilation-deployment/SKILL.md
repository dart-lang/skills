---
name: "dart-compilation-deployment"
description: "Compile and deploy Dart apps for various native and web target platforms."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:33:21 GMT"

---
# dart-compilation

## Goal
Compiles Dart source code into optimized, target-specific formats including self-contained native executables, ahead-of-time (AOT) snapshots, just-in-time (JIT) modules, and web-deployable JavaScript or WebAssembly. Assumes the Dart SDK is installed, the target environment is configured, and the source code does not rely on unsupported libraries (e.g., `dart:mirrors`) for native compilation.

## Decision Logic
Use the following logic to determine the appropriate compilation target:

*   **Is the target a Web environment?**
    *   Yes -> Use `dart compile js` (or `dart compile wasm`). *See Related Skill: `dart-web-development`.*
*   **Is the target a Native OS (Windows, macOS, Linux)?**
    *   Does the deployment require a single, self-contained binary?
        *   Yes -> Use `dart compile exe`.
    *   Is the deployment environment resource-constrained (e.g., embedded systems, containers) where multiple apps share a runtime?
        *   Yes -> Use `dart compile aot-snapshot` and execute with `dartaotruntime`.
    *   Does the application benefit from profile-guided optimization via a training run?
        *   Yes -> Use `dart compile jit-snapshot`.
*   **Is the target platform-agnostic?**
    *   Yes -> Use `dart compile kernel` to generate a portable `.dill` file.

## Instructions

1.  **Determine Compilation Target and Parameters**
    Evaluate the project requirements against the Decision Logic. 
    **STOP AND ASK THE USER:** "Which target platform and architecture are you compiling for? Do you require cross-compilation (e.g., compiling for Linux ARM64 from macOS)?"

2.  **Compile to Self-Contained Executable (Native)**
    For standard native binaries, use the `exe` subcommand. This bundles the machine code and a minimal Dart runtime.
    ```bash
    dart compile exe bin/main.dart -o build/app.exe
    ```
    *Cross-Compilation (Linux targets only):*
    ```bash
    dart compile exe \
      --target-os=linux \
      --target-arch=arm64 \
      bin/main.dart -o build/app_linux_arm64
    ```

3.  **Compile to AOT Snapshot (Resource-Constrained)**
    For environments where disk space is limited and a shared runtime is preferred, generate an AOT snapshot.
    ```bash
    dart compile aot-snapshot bin/main.dart -o build/app.aot
    ```
    *Execution:*
    ```bash
    dartaotruntime build/app.aot
    ```

4.  **Compile to Web Targets (JS / Wasm)**
    For web deployments, compile to optimized JavaScript or WebAssembly.
    ```bash
    # Compile to JS with aggressive optimizations (O2 is safe, O3/O4 omit type checks)
    dart compile js -O2 -o build/app.js web/main.dart
    
    # Compile to WebAssembly
    dart compile wasm web/main.dart -o build/app.wasm
    ```

5.  **Compile to JIT or Kernel Modules (Specialized)**
    *JIT Snapshot (requires a training run):*
    ```bash
    dart compile jit-snapshot bin/main.dart -o build/app.jit
    dart run build/app.jit
    ```
    *Portable Kernel:*
    ```bash
    dart compile kernel bin/main.dart -o build/app.dill
    dart run build/app.dill
    ```

6.  **Validate-and-Fix Loop**
    After executing the compilation command, verify the output file exists and test its execution.
    ```bash
    # Verify file generation
    ls -la build/

    # Test execution (example for exe)
    ./build/app.exe
    ```
    *Error Handling:* If compilation fails due to build hooks, fallback to `dart build`. If type errors occur in JS compilation at `-O3` or `-O4`, downgrade to `-O2` and recompile.

## Constraints
*   **DO NOT** use `dart compile exe` or `dart compile aot-snapshot` if the package or its dependencies utilize build hooks; these commands will fail. Use `dart build` instead.
*   **DO NOT** use `dart:mirrors` or `dart:developer` in code targeted for `exe` or `aot-snapshot` compilation.
*   **DO** use `dart compile exe` for self-contained native binaries on Windows/macOS/Linux.
*   **DO** use `dart compile js` or `dart compile wasm` for web deployment targets.
*   **DO** optimize for performance using AOT compilation where supported.
*   **DO** use `dartaotruntime` for running AOT snapshots in resource-constrained environments.
*   **DO NOT** attempt cross-compilation for target operating systems other than Linux.
*   **DO NOT** use `-O3` or `-O4` JavaScript optimizations without verifying that the application never throws a subtype of `Error` (e.g., `TypeError`) and handles edge-case user input safely.
