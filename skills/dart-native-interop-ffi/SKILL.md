---
name: dart-native-interop-ffi
description: Bridge Dart with native C/C++ libraries using FFI.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:21:25 GMT
---
# Interoperating with C using dart:ffi

## Contents
- [Core Concepts](#core-concepts)
- [Memory Management & Finalization](#memory-management--finalization)
- [Cross-Platform Type Mapping](#cross-platform-type-mapping)
- [Workflow: Generating Bindings with ffigen](#workflow-generating-bindings-with-ffigen)
- [Workflow: Loading and Calling Native Functions](#workflow-loading-and-calling-native-functions)
- [Examples](#examples)

## Core Concepts
Use the `dart:ffi` library to call native C APIs and manage native memory in Dart applications running on the Dart Native platform. 

**Related Skills:** Refer to `dart-concurrency-isolates` when executing heavy FFI workloads to avoid blocking the main thread.

## Memory Management & Finalization
Manage native memory explicitly to prevent leaks. 

- **DO** manually allocate and free memory using `calloc` or `malloc` from `package:ffi` when passing dynamically sized data to C.
- **DO** use `Finalizable` and `NativeFinalizer` to ensure native resources are automatically cleaned up when the Dart object is garbage collected.
- **NEVER** rely solely on manual `free()` calls for objects that have a lifecycle managed by Dart's garbage collector. Attach a `NativeFinalizer`.

## Cross-Platform Type Mapping
Map C types to Dart FFI types accurately to prevent memory corruption and segmentation faults.

- **PREFER** `AbiSpecificInteger` subtypes (e.g., `Int`, `Long`, `Size`, `WChar`) for cross-platform type mapping where the C type size varies by architecture (e.g., `int`, `long`, `size_t`).
- Use fixed-size markers (`Int8`, `Int32`, `Float`, `Double`) only when the C header explicitly defines fixed-width types (e.g., `int32_t`).
- Use `Pointer<T>` to represent pointers into native C memory.
- Use `Struct` and `Union` as supertypes for complex C structures.

## Workflow: Generating Bindings with ffigen
**DO** use `package:ffigen` to automate the generation of FFI bindings for large API surfaces. Avoid writing manual bindings for complex headers.

### Task Progress
- [ ] Add `ffigen` as a dev dependency: `dart pub add --dev ffigen`.
- [ ] Add `ffi` as a standard dependency: `dart pub add ffi`.
- [ ] Create an `ffigen.yaml` configuration file (or add to `pubspec.yaml`) specifying the header files and output path.
- [ ] Run the generator: `dart run ffigen --config ffigen.yaml`.
- [ ] **Feedback Loop:** Run `dart analyze` -> review type mismatch or missing definition errors -> adjust `ffigen.yaml` (e.g., adding compiler options or include paths) -> regenerate.

## Workflow: Loading and Calling Native Functions
Implement conditional logic to load the correct dynamic library based on the host operating system.

### Task Progress
- [ ] Determine the library path using `Platform` from `dart:io`.
  - *If macOS:* Load `.dylib`.
  - *If Windows:* Load `.dll`.
  - *If Linux:* Load `.so`.
- [ ] Open the library using `DynamicLibrary.open(libraryPath)`.
- [ ] Define the C function signature using FFI types (e.g., `Void Function(Int32)`).
- [ ] Define the Dart function signature (e.g., `void Function(int)`).
- [ ] Lookup the function: `dylib.lookup<NativeFunction<CFunc>>('symbol_name').asFunction<DartFunc>()`.
- [ ] Invoke the resulting Dart function.

## Examples

### Example: Memory Allocation and Finalization
Demonstrates allocating memory, passing it to C, and ensuring cleanup using `NativeFinalizer`.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Assume this is imported from ffigen bindings
// typedef FreeFunc = Void Function(Pointer<Void>);
// final void Function(Pointer<Void>) nativeFree = ...;

final NativeFinalizer _finalizer = NativeFinalizer(nativeFreePtr);
final Pointer<NativeFunction<Void Function(Pointer<Void>)>> nativeFreePtr = DynamicLibrary.process().lookup('free');

class NativeResource implements Finalizable {
  late final Pointer<Uint8> _data;

  NativeResource(int size) {
    // Manually allocate memory
    _data = calloc<Uint8>(size);
    
    // Attach the finalizer to ensure cleanup when NativeResource is GC'd
    _finalizer.attach(this, _data.cast<Void>(), detach: this);
  }

  void dispose() {
    // Optional manual cleanup before GC
    _finalizer.detach(this);
    calloc.free(_data);
  }
}
```

### Example: Loading a Library and Calling a Function
Demonstrates the conditional loading workflow and ABI-specific integer usage.

```dart
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:path/path.dart' as path;

// C signature: void hello_world(size_t count);
typedef hello_world_func = ffi.Void Function(ffi.Size count);
// Dart signature
typedef HelloWorld = void Function(int count);

void main() {
  final String libraryName;
  if (Platform.isMacOS) {
    libraryName = 'libhello.dylib';
  } else if (Platform.isWindows) {
    libraryName = 'hello.dll';
  } else {
    libraryName = 'libhello.so';
  }

  final libraryPath = path.join(Directory.current.path, 'hello_library', libraryName);
  final dylib = ffi.DynamicLibrary.open(libraryPath);

  final HelloWorld hello = dylib
      .lookup<ffi.NativeFunction<hello_world_func>>('hello_world')
      .asFunction();

  hello(5);
}
```
