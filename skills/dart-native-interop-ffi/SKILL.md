---
name: "dart-native-interop-ffi"
description: "Bridge Dart with native C/C++ libraries using FFI."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:34:17 GMT"

---
# dart-c-interop

## Goal
Integrates native C libraries into Dart applications using the `dart:ffi` library. Automates FFI binding generation for large API surfaces, safely maps native types across platforms, and strictly manages native memory lifecycles using manual allocation and finalizers. Assumes the user has a configured Dart or Flutter environment and access to the target C headers and compiled dynamic libraries (`.so`, `.dylib`, or `.dll`).

## Decision Logic
When implementing C interop, evaluate the API surface and memory requirements to determine the correct path:
1. **API Surface Size:**
   * If the C API is large or complex: Use `package:ffigen` to automate binding generation.
   * If the C API is small (1-5 functions): Manually define `typedef` signatures and lookups.
2. **Memory Ownership:**
   * If Dart creates native structures or strings: Manually allocate using `calloc` or `malloc` from `package:ffi`.
   * If Dart holds pointers to C-allocated memory that must be freed when the Dart object is garbage collected: Implement `Finalizable` and attach a `NativeFinalizer`.
3. **Cross-Platform Types:**
   * If mapping standard C integer types (`int`, `long`, `size_t`): PREFER `abiSpecificInteger` subtypes (e.g., `Int`, `Long`, `Size`) over fixed-width types (`Int32`, `Int64`) to ensure cross-platform ABI compatibility.

## Instructions

### 1. Determine Environment and Assets
**STOP AND ASK THE USER:**
* "What are the target platforms (macOS, Windows, Linux, Android, iOS)?"
* "Where are the C header files (`.h`) and compiled dynamic libraries located in your project?"

### 2. Configure Binding Generation (If using `ffigen`)
For large APIs, configure `package:ffigen` to parse C headers and generate Dart bindings.
Create or update `ffigen.yaml`:

```yaml
name: NativeLibrary
description: Bindings for native C library.
output: 'lib/src/generated_bindings.dart'
headers:
  entry-points:
    - 'src/native_lib.h'
  include-directives:
    - '**native_lib.h'
ffi-native:
  asset: 'native_lib'
```
Run the generator:
```bash
dart run ffigen --config ffigen.yaml
```

### 3. Load the Dynamic Library
Implement platform-specific routing to load the dynamic library.

```dart
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:path/path.dart' as path;

ffi.DynamicLibrary loadNativeLibrary(String libraryName) {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('lib$libraryName.dylib');
  } else if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$libraryName.dll');
  } else {
    return ffi.DynamicLibrary.open('lib$libraryName.so');
  }
}

final dylib = loadNativeLibrary('hello');
```

### 4. Manually Map Types and Look Up Functions (If not using `ffigen`)
Define the C signature and the Dart signature. Prefer `AbiSpecificInteger` types for standard C types.

```dart
import 'dart:ffi' as ffi;

// C signature: void hello_world();
typedef hello_world_func = ffi.Void Function();
// Dart signature
typedef HelloWorld = void Function();

// C signature: long process_data(size_t size);
// PREFER AbiSpecificInteger (Long, Size) over Int64/Int32
typedef process_data_func = ffi.Long Function(ffi.Size size);
typedef ProcessData = int Function(int size);

final HelloWorld hello = dylib
    .lookup<ffi.NativeFunction<hello_world_func>>('hello_world')
    .asFunction();
```

### 5. Manage Native Memory and Resources
When allocating memory in Dart to pass to C, use `calloc`. When wrapping C-allocated memory, use `Finalizable` and `NativeFinalizer` to prevent memory leaks.

```dart
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart'; // Provides calloc, malloc, Utf8

// 1. Manual Allocation
ffi.Pointer<Utf8> allocateString(String dartString) {
  // DO manually allocate memory using calloc
  final ffi.Pointer<Utf8> cString = dartString.toNativeUtf8(allocator: calloc);
  return cString;
}

void freeMemory(ffi.Pointer pointer) {
  // DO manually free memory
  calloc.free(pointer);
}

// 2. Native Finalizer for C-allocated memory
// Assume C provides: void free_resource(Resource* res);
final ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer)>> freeResourcePtr = 
    dylib.lookup('free_resource');

final ffi.NativeFinalizer _finalizer = ffi.NativeFinalizer(freeResourcePtr.cast());

class NativeResourceWrapper implements ffi.Finalizable {
  final ffi.Pointer<ffi.Void> _cResource;

  NativeResourceWrapper(this._cResource) {
    // DO use Finalizable and NativeFinalizer to ensure cleanup
    _finalizer.attach(this, _cResource.cast(), detach: this);
  }

  void dispose() {
    _finalizer.detach(this);
    // Manually call the free function if disposed early
    final freeFunc = freeResourcePtr.asFunction<void Function(ffi.Pointer)>();
    freeFunc(_cResource);
  }
}
```

### 6. Validate and Fix
After implementing the bindings, instruct the user to run a basic test script.
* **Validation:** Does the Dart code successfully invoke the C function without a segmentation fault?
* **Fix:** If an `Invalid argument(s): Unknown library` error occurs, verify the library path and ensure the library is compiled for the correct architecture (e.g., ARM64 vs x86_64). On macOS, ensure the library is signed if running in a strict environment.

## Constraints
* DO NOT use fixed-width integers (e.g., `Int32`, `Int64`) for C `long`, `int`, or `size_t`. You MUST use `abiSpecificInteger` types (`ffi.Long`, `ffi.Int`, `ffi.Size`).
* DO NOT leave native memory unmanaged. Any pointer allocated via `calloc` or `malloc` MUST have a corresponding `free` call or be managed by an allocator lifecycle.
* DO NOT manually write bindings for C headers exceeding 10 functions/structs. You MUST use `package:ffigen`.
* DO NOT block the main Dart isolate with long-running C functions. For heavy C computation, you MUST integrate with `dart-concurrency-isolates` to run the FFI calls on a background worker.
* DO NOT assume dynamic library paths are absolute. Always construct paths dynamically using `dart:io` `Platform` checks and `package:path`.
