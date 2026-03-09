---
name: "dart-native-interop-ffi"
description: "Bridge Dart with native C/C++ libraries using FFI."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:43:48 GMT"

---
# dart-ffi-c-interop

## Goal
Implements C-interop in Dart applications using `dart:ffi`. Automates FFI binding generation via `package:ffigen`, manages native memory allocation and cleanup using `Finalizable` and `NativeFinalizer`, and ensures cross-platform type safety using ABI-specific integers. Assumes the user has a valid C header file and a compiled dynamic library (or build system) available in the project workspace.

## Decision Logic
Evaluate the integration requirements using the following logic:
1. **API Surface Size:** 
   - If the C API contains more than 3 functions or complex structs, use `package:ffigen` to generate bindings.
   - If the C API is trivial (1-2 simple functions), manual binding is acceptable, but `ffigen` is still preferred.
2. **Memory Allocation:**
   - If the C function requires passing pointers to buffers or structs created in Dart, allocate memory using `calloc` or `malloc` from `package:ffi`.
   - If memory is allocated, a `NativeFinalizer` MUST be attached to a `Finalizable` Dart wrapper class to prevent memory leaks.
3. **Type Mapping:**
   - If the C type is platform-dependent (e.g., `int`, `long`, `size_t`), map it using `abiSpecificInteger` subtypes (`Int`, `Long`, `Size`).
   - If the C type is fixed-width (e.g., `int32_t`), use exact markers (`Int32`).

## Instructions

1. **Configure Dependencies**
   Add `ffi` as a standard dependency and `ffigen` as a dev dependency.
   ```bash
   dart pub add ffi
   dart pub add dev:ffigen
   ```

2. **Configure `ffigen`**
   Create the `ffigen` configuration in `pubspec.yaml` (or a dedicated `ffigen.yaml`).
   ```yaml
   ffigen:
     name: NativeBindings
     description: Auto-generated FFI bindings.
     output: 'lib/src/generated_bindings.dart'
     headers:
       entry-points:
         - 'native/library.h'
     type-map:
       typedefs:
         include:
           - 'size_t'
           - 'int'
   ```
   **STOP AND ASK THE USER:** "Please confirm the path to your C header file(s) so I can correctly configure the `entry-points` for `ffigen`."

3. **Generate Bindings**
   Execute the binding generator.
   ```bash
   dart run ffigen
   ```
   *Validate-and-Fix:* If `ffigen` fails due to missing LLVM, instruct the user to install LLVM (e.g., `brew install llvm` on macOS) and set the `llvm-path` in the configuration.

4. **Implement Dynamic Library Loading**
   Create a robust loader for the dynamic library that handles platform-specific extensions.
   ```dart
   import 'dart:ffi' as ffi;
   import 'dart:io' show Platform;
   import 'package:path/path.dart' as path;

   ffi.DynamicLibrary loadNativeLibrary(String libraryName, String libraryPath) {
     String fullPath;
     if (Platform.isMacOS) {
       fullPath = path.join(libraryPath, 'lib$libraryName.dylib');
     } else if (Platform.isWindows) {
       fullPath = path.join(libraryPath, '$libraryName.dll');
     } else {
       fullPath = path.join(libraryPath, 'lib$libraryName.so');
     }
     
     try {
       return ffi.DynamicLibrary.open(fullPath);
     } catch (e) {
       // Validate-and-Fix: Fallback or error reporting
       throw Exception('Failed to load native library at $fullPath: $e');
     }
   }
   ```

5. **Implement Memory Management with Finalizers**
   Wrap native resources in a Dart class implementing `Finalizable`. Use `calloc` for allocation and `NativeFinalizer` for guaranteed cleanup.
   ```dart
   import 'dart:ffi';
   import 'package:ffi/ffi.dart';

   // Use the native free function pointer provided by package:ffi
   final NativeFinalizer _finalizer = NativeFinalizer(calloc.nativeFree);

   class NativeBuffer implements Finalizable {
     late final Pointer<Uint8> pointer;

     NativeBuffer(int size) {
       // Manually allocate memory
       pointer = calloc<Uint8>(size);
       
       // Attach the finalizer to ensure native resources are cleaned up
       _finalizer.attach(this, pointer.cast(), detach: this);
     }

     void dispose() {
       // Manual early cleanup
       _finalizer.detach(this);
       calloc.free(pointer);
     }
   }
   ```

6. **Map ABI-Specific Types**
   When writing manual bindings or interacting with generated code, strictly use `abiSpecificInteger` types for standard C integers.
   ```dart
   import 'dart:ffi';

   // Example: C function signature `size_t process_data(long input)`
   typedef ProcessDataC = Size Function(Long);
   typedef ProcessDataDart = int Function(int);

   int runProcess(ffi.DynamicLibrary dylib, int input) {
     final processData = dylib
         .lookup<NativeFunction<ProcessDataC>>('process_data')
         .asFunction<ProcessDataDart>();
         
     return processData(input);
   }
   ```

## Constraints
*   **DO NOT** use fixed-width integers (e.g., `Int32`, `Int64`) for C types like `int`, `long`, or `size_t`. You MUST prefer `abiSpecificInteger` (`Int`, `Long`, `Size`).
*   **DO NOT** rely on Dart's garbage collector alone to free native memory. You MUST use `Finalizable` and `NativeFinalizer`.
*   **DO NOT** manually write large FFI binding files. You MUST use `package:ffigen` to automate the generation of FFI bindings from header files.
*   **DO NOT** hardcode `.so`, `.dylib`, or `.dll` extensions without a platform check.
*   **DO NOT** leave allocated memory without a `calloc.free` or `malloc.free` path.
