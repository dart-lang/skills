---
name: dart-use-path-package
description: >-
  Cross-platform file and directory path manipulation, segment splitting, extension extraction, and context conversion using `package:path` and `package:file`. Use when writing, inspecting, joining, splitting, or refactoring file paths, directory names, or extensions, or replacing raw string path operations (`.split('/')`, `'$dir/$file'`, `.endsWith('.ext')`, `.replaceAll('\\', '/')`). Don't use for HTTP network URI routing, database query strings, or non-path string processing.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sun, 06 Sep 2026 07:14:00 GMT
---

# Safe Cross-Platform Path Manipulation in Dart

## Contents
* [1. Core Principles & Cross-Platform Rules](#1-core-principles--cross-platform-rules)
* [2. String Anti-Patterns to package:path Mapping](#2-string-anti-patterns-to-packagepath-mapping)
* [3. Bridging Native Paths to POSIX & URL Contexts](#3-bridging-native-paths-to-posix--url-contexts)
* [4. Mockable File Systems (`package:file` vs. Global `p.*`)](#4-mockable-file-systems-packagefile-vs-global-p)
* [5. Extensions, Compound Extensions & Stem Extraction](#5-extensions-compound-extensions--stem-extraction)
* [6. Workflows & Audit Checklist](#6-workflows--audit-checklist)
* [References & Examples](#references--examples)

---

## 1. Core Principles & Cross-Platform Rules

### Never Treat File Paths as Raw Strings
* Native file paths on Windows use backslashes (`\`), whereas macOS and Linux use forward slashes (`/`).
* String operations like `.contains('foo/')`, `.startsWith('foo/')`, or `.split('/')` silently fail on Windows native paths.
* String interpolation like `'$dir/$file'` injects forward slashes on Windows and produces duplicate slashes (`//`) when `$dir` ends with a trailing slash.

**Rule**: Always decompose paths into segments using `p.split(path)` before inspecting directory hierarchy or segment names, and always join path components using `p.join(...)`.

### Pragmatic Boundary Joining vs. Multi-Segment Decomposition (`p.join`)
* **Cross-Platform Libraries (Windows + POSIX)**: Pass individual path segments to `p.join(dir, 'sub', 'file.json')` so `package:path` inserts OS-native separators (`\` on Windows, `/` on POSIX) between every component.
* **POSIX-Only Tools & Static Subpath Greppability**: In codebases exclusively targeting Linux/macOS (or when joining a dynamic base path to a known static subpath), decomposing 5–6 static segments into separate arguments (`p.join(home, '.local', 'share', 'app', 'bin', 'config.json')`) causes `dart format` to wrap across 6–8 vertical lines and **destroys substring greppability** (`grep` / `code_search` for `.local/share/app/bin`).
* **Rule for POSIX Targets**: Prefer **2-argument boundary joining** (`p.join(home, '.local/share/app/bin/config.json')`). This prevents duplicate-slash bugs (`//`) at variable boundaries while preserving single-line readability and exact string searchability.

### Normalization vs. Canonicalization (`p.normalize` vs. `p.canonicalize`)
* `p.normalize(path)` resolves `.` and `..` segments purely lexically without consulting the filesystem or standardizing case.
* When deduplicating directory paths or comparing physical file identity across symlinks, relative roots, or case-insensitive filesystems, use `p.canonicalize(path)`.

### Strip Location Specifiers & Convert URIs Safely
* Strings formatted as `<path>:<line>-<col>` or `<path>:<line>` are not pure file paths. Passing them directly to `p.normalize` or `Uri.parse` causes bugs (on Windows, `Uri.parse` mistakes `C:` for a URI scheme and `:line` for a port).
* Extract the trailing `:line-col` suffix via regular expression (`RegExp(r'^(.*?):(\d+(?:-\d+)?)$')`) *before* passing the file path to `package:path`.
* **URI Boundary Conversions**: When converting between file paths and `Uri` objects, always use `p.toUri(path)` and `p.fromUri(uri)` rather than `Uri.parse(path)` or manual string concatenation.

---

## 2. Recommended package:path Idioms vs. String Anti-Patterns

| Prefer (`package:path` Idiom) | Avoid (String Anti-Pattern) | Risk / Failure Mode |
| :--- | :--- | :--- |
| `p.join(dir, file)` | `'$dir/$file'` or `'a/$b'` | Injects `/` on Windows; produces `//` if `$dir` has a trailing slash. |
| `p.split(path).contains('foo')` | `path.contains('foo/')` | Fails on Windows (`foo\bar`); false positive on partial names (`barfoo/`). |
| `p.split(path).first == 'foo'` or `p.isWithin('foo', path)` | `path.startsWith('foo/')` | Fails on Windows; misses relative prefix variants (`./foo/`). |
| `p.extension(path) == '.wasm'` | `path.endsWith('.wasm')` | Matches directory names (`foo.wasm/`) or non-extension suffixes. |
| `p.withoutExtension(path)` and `p.extension(path, 2)` | `lastIndexOf('.')` + `substring` | Breaks on hidden dotfiles (`.gitignore`) and compound extensions (`.js.map`). |
| `p.posix.joinAll(p.split(path))` | `path.replaceAll(r'\', '/')` | Ad-hoc separator patching; mixes OS context with POSIX/URL targets. |
| `p.toUri(path)` / `p.fromUri(uri)` | `Uri.parse(path)` / `uri.path` | Fails on Windows drive letters (`C:`) and leaks `%20` percent-encoding. |
| `String canonicalDirName(Directory d) => p.basename(p.normalize(d.absolute.path));` | Repeating `p.basename(p.normalize(dir.absolute.path))` inline | Verbose boilerplate repeated across files. |

---

## 3. Bridging Native Paths to POSIX & URL Contexts

Never call `.replaceAll('\\', '/')` or `.replaceAll(r'\', '/')` to convert OS-native paths into POSIX paths (for Git, YAML, archive manifests) or URL segments.

**Rule**: Split the relative native path using `p.split(...)`, inspect segments with **Dart 3 list pattern matching**, and join using `p.posix.joinAll(...)` or `p.url.joinAll(...)`. Always call `p.relative(filePath, from: root)` first so leading root segments (`'/'` on POSIX or `r'C:\'` on Windows) do not interfere with relative prefix patterns:

```dart
import 'package:path/path.dart' as p;

String computeWebAssetKey(String filePath, String projectRoot) {
  final relative = p.relative(filePath, from: projectRoot);
  final segments = p.split(relative);
  return switch (segments) {
    ['assets', ...] => p.posix.joinAll(segments),
    _ => p.posix.joinAll(['assets', ...segments]),
  };
}
```

---

## 4. Mockable File Systems (`package:file` vs. Global `p.*`)

In codebases that use `package:file` (such as `flutter_tools` or CLI applications tested with `MemoryFileSystem`), **do not** call top-level `p.*` functions on `File` or `Directory` paths.

* Top-level `p.*` functions bind to the *host operating system* running the test.
* If a unit test creates a `MemoryFileSystem(style: FileSystemStyle.windows)` on a Linux or macOS runner, global `p.split(file.path)` will split on `/` instead of `\`, breaking the test.

**Rule**: Always use the `Context` attached to the `FileSystem` (`file.fileSystem.path`):

```dart
import 'package:file/file.dart';

List<String> listSubdirectoryNames(Directory dir) {
  final pathContext = dir.fileSystem.path;
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => pathContext.basename(d.path))
      .toList();
}
```

---

## 5. Extensions, Compound Extensions & Stem Extraction

Avoid manual `.lastIndexOf('.')` and `.substring()` arithmetic when extracting file extensions or inserting content hashes. `p.extension` natively supports multi-level extensions via its optional `level` parameter.

* **Multi-Dot Stem Nuance**: Calling `p.extension('main.dart.wasm', 2)` returns `'.dart.wasm'` because it blindly captures the last two dot-separated segments. When hashing or stripping extensions on files that may have multi-dot stems (e.g., `main.dart.wasm` vs. `main.dart.js.map`), check whether `p.extension(filename, 2)` matches a known compound extension (or `.endsWith('.map')`) before falling back to single-level `p.extension(filename)`:

```dart
import 'package:path/path.dart' as p;

String insertContentHash(String filename, String hash) {
  final compoundExt = p.extension(filename, 2);
  // Only use the 2-level extension for true compound suffixes (e.g., '.js.map')
  final ext = compoundExt.endsWith('.map')
      ? compoundExt
      : p.extension(filename);
  final stem = filename.substring(0, filename.length - ext.length);
  return '$stem.$hash$ext';
}
```

---

## 6. Workflows & Audit Checklist

### Path Refactoring Checklist
- [ ] Replace string interpolation (`'$dir/$file'`) with `p.join(dir, file)`.
- [ ] Replace `.contains('dir/')` and `.startsWith('dir/')` with `p.split(path)` segment checks or `p.isWithin(parent, child)`.
- [ ] Replace `.replaceAll(r'\', '/')` with `p.posix.joinAll(p.split(path))` (or `p.url.joinAll`).
- [ ] Replace `.endsWith('.ext')` on file paths with `p.extension(path) == '.ext'`.
- [ ] Replace manual dot-index slicing with `p.withoutExtension(path)` and `p.extension(path, [level])`.
- [ ] Verify that code using `package:file` accesses `fileSystem.path` instead of global `p.*`.

---

## References & Examples

* **Cross-Platform Path & POSIX Conversion Examples**: [examples/cross_platform_paths.dart](examples/cross_platform_paths.dart)
* **Mockable FileSystem Path Context Example**: [examples/file_system_context.dart](examples/file_system_context.dart)
