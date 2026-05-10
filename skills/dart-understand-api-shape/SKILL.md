---
name: dart-understand-api-shape
description: Efficiently discover and understand the public API shape (classes, functions, constructors, properties) of a Dart package or module using Dart MCP tools, version audits, and diagnostic strategies.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sun, 10 May 2026 15:50:00 GMT
---
# Understanding Dart API Shapes

## Contents
- [When to Use This Skill](#when-to-use-this-skill)
- [Workflow: Discovering API Shapes](#workflow-discovering-api-shapes)
- [Auditing Locally Resolved Versions](#auditing-locally-resolved-versions)
- [Leveraging Dart MCP Server Tools](#leveraging-dart-mcp-server-tools)
- [Understanding Conditional & Platform Exports](#understanding-conditional--platform-exports)
- [Key Diagnostic & Syntax Strategies](#key-diagnostic--syntax-strategies)
- [Common Pitfalls & Constraints](#common-pitfalls--constraints)
- [Example Walkthrough](#example-walkthrough)
- [Related Skills](#related-skills)

## When to Use This Skill

Apply this skill when:
- **Integrating a Package for the First Time:** You need to know the primary entry points and classes of a new dependency.
- **Unresolved Symbols or Compilation Errors:** You encounter errors like `Method not found`, `Undefined class`, or `Wrong number of arguments`.
- **Refactoring or Modernizing Code:** You need to know if a modern equivalent or constructor exists for a deprecated or legacy class/method.
- **Writing Unit Tests or Mocks:** You need to determine the exact types of parameters and constructor arguments to correctly build mock objects.

---

## Workflow: Discovering API Shapes

Follow this systematic workflow to construct a precise map of any public Dart API:

### Step 0: Verify the Locally Resolved Package Version
Before reading any external documentation or web resources, **determine exactly which version of the package is resolved locally**.
- External websites and blog posts often document the absolute latest release, which may have breaking changes compared to the version pinned in your `pubspec.lock`.
- Do not assume the version range in `pubspec.yaml` (e.g., `^0.21.0`) is the one in use. Always query the exact, pinned version in `pubspec.lock`.
- *(See the [Auditing Locally Resolved Versions](#auditing-locally-resolved-versions) section below for how to do this.)*

### Step 1: Locate Public Entry Points
In Dart, the public API surface is defined entirely by files located directly in the `lib/` folder of the package (e.g., `lib/my_package.dart`).
- **Do NOT start by browsing `lib/src/` manually.** This directory contains internal implementation details that are subject to change and are not directly importable by consumers.
- **Locate the primary exports.** Use the `read_package_uris` MCP tool to inspect the entrypoint `.dart` files in `lib/` to identify the public facade.

### Step 2: Parse Export Directives
Examine the `export` statements in the entrypoint files to understand what is actually exposed to consumers:
- **Complete exports:** `export 'src/feature.dart';` exposes everything in `feature.dart`.
- **Selective exports:** `export 'src/feature.dart' show ClassA, helperB;` restricts exposure to only `ClassA` and `helperB`.
- **Exclusionary exports:** `export 'src/feature.dart' hide InternalHelper;` exposes everything *except* `InternalHelper`.

### Step 3: Check for Conditional/Platform Exports
Look out for export lines using `if (dart.library.io)` or `if (dart.library.js_interop)` conditional structures. These indicate platform-specific components that may require you to import a dedicated platform library (like `package:jaspr/server.dart` instead of `package:jaspr/jaspr.dart`).

### Step 4: Analyze Existing Tests and Examples
The intended usage of an API is best documented by its author's own examples and test suites.
- **Browse `example/`:** Look for real-world integration paths in the package's example files.
- **Browse `test/`:** Look at how tests instantiate classes, pass arguments, and call methods. Tests provide highly reliable, executable specifications of the API.

---

## Auditing Locally Resolved Versions

To reconcile external documentation with your local codebase, use these techniques to audit your dependency versions:

### 1. Check the Pinned Version in `pubspec.lock`
Read the `pubspec.lock` file at the project root. It contains the exact, resolved version of every package in the dependency graph.
* **Search query:** Locate the package name and check the `version` field.
```yaml
  jaspr:
    dependency: "direct main"
    description:
      name: jaspr
      sha256: "..."
      url: "https://pub.dev"
    source: hosted
    version: "0.21.0" # <--- This is the exact local reality!
```

### 2. Reconcile Web Docs vs. Local Code
If you find a class, constructor, or method documented on a website or in an AI output, but it fails to compile locally:
- **Compare versions:** Check if the online docs/examples are for a newer version than your locally resolved version in `pubspec.lock`.
- **Trust local source code over web docs:** If there is a version mismatch, **discard the web documentation**. Instead, use the `read_package_uris` and `rip_grep_packages` tools to search your locally resolved source code. Your local files are the absolute ground truth for what is available to your compiler.
- **Identify deprecations and migrations:** If an API exists in your local files but is marked `@deprecated`, check your local version's release comments or documentation files (e.g. `CHANGELOG.md` inside the package) to find the recommended replacement.

---

## Leveraging Dart MCP Server Tools

Rather than manually opening files or downloading packages, use the highly efficient tools provided by the **Dart MCP Server**:

### 1. `read_package_uris` (Instant file reading)
Use this to inspect any entrypoint or internal file directly within dependencies without searching the disk.
* **Usage:** Pass package scheme URIs (e.g., `package:package_name/library.dart` or `package-root:package_name/example/main.dart`).
* **Best for:** Parsing public export structures and looking up core class headers.

### 2. `rip_grep_packages` (Instant search)
Use this to execute high-precision regex searches across the `lib` folder of dependency packages.
* **Usage:** Provide target package names and the search query arguments (e.g., `["class Client", "-A", "10"]`).
* **Best for:** Instantly finding where a class or function is declared, retrieving constructor signatures, and discovering extension methods.

### 3. `lsp` (Semantic intelligence)
Interacts with the Dart Language Server Protocol.
* **Usage:** Call `resolveWorkspaceSymbol` to fuzzy-search for a symbol by name, or `hover` to get parameter signatures at a file position.
* **Fallback Warning:** If the language server is currently starting up or indexing (which can cause it to hang or take a long time), **abort the LSP call immediately** and use `rip_grep_packages` + `read_package_uris` instead. This is a much faster, deterministic recovery loop.

---

## Understanding Conditional & Platform Exports

In multi-platform frameworks (such as cross-platform web or native packages), libraries often employ conditional imports/exports to support both Web (client-side/browser) and IO (server-side/native VM) environments.

**The conditional export pattern:**
```dart
export 'src/client_stub.dart' 
    if (dart.library.io) 'src/server_implementation.dart' 
    show Client;
```

### The Pitfall: Defaulting to Stubs
During static analysis in your local workspace, the analyzer's environment frequently defaults to a non-IO configuration. 
- If you import the generic entry point (`package:net_widgets/net_widgets.dart`), the compiler maps `Client` to `client_stub.dart`.
- Because the stub does not implement all full-featured methods (which may only exist on server/IO platforms), `client_stub.dart` lacks specific constructors or methods.
- This results in compilation errors like: `The class 'Client' doesn't have an unnamed constructor.` or `Method not found.`

### The Solution: Import Platform Entry Points Directly
When writing platform-specific code (e.g., server-side or native-only), skip the generic entry point and import the platform-specific entry point directly if one is provided:
* **Instead of:** `import 'package:net_widgets/net_widgets.dart';`
* **Prefer:** `import 'package:net_widgets/server.dart';` (which directly exports the full-featured implementation and configuration).

---

## Key Diagnostic & Syntax Strategies

### 1. Constructor Signatures
Dart supports multiple types of constructors. Always differentiate:
- **Default Constructor:** `ClassName(...)`
- **Named Constructors:** `ClassName.fromJson(...)`
- **Factory Constructors:** `factory ClassName(...)` (often returns subtypes or cached instances)
- **Const Constructors:** `const ClassName(...)` (must be called with `const` if all arguments are constants)

### 2. Dot Shorthands (Dart 3.6+)
If you see a dot-prefixed call within a collection literal (like `[.info('value')]`), it is a **Dot Shorthand**.
- The dot shorthand omits the type name when it can be confidently inferred from the context.
- In a list expecting `List<LogEntry>`, `[.info('Message')]` is resolved by the compiler as `[LogEntry.info('Message')]` because the expected type of elements in the list is `LogEntry` and it defines an `info` constructor/factory.
- When writing code, prefer this syntax to reduce visual noise.


---

## Common Pitfalls & Constraints

- **NEVER import from `package:some_package/src/...`:** Imports referencing the `src` folder violate library boundaries, trigger lints, and cause brittle code that will break on subsequent package updates.
- **Do NOT view huge implementation files first:** Avoid reading entire `lib/src/...` files to extract signatures. It's extremely expensive and inefficient. Use `rip_grep_packages` or `read_package_uris` instead.
- **Beware of shadowed imports:** If two imported libraries export the same class name, use an import prefix (e.g., `import 'package:a/a.dart' as a;`).

---

## Discovery & Inspection Cheat Sheet

Use these precise `ripgrep` and MCP commands to locate API details fast:

| Objective | MCP / Command Example |
|---|---|
| Read resolved version in lockfile | View `pubspec.lock` |
| Read exports of a package | `read_package_uris` with URI `["package:package_name/package_name.dart"]` |
| Find a Class Definition | `rip_grep_packages` with arguments `["class Client"]` |
| Retrieve Constructor Signature | `rip_grep_packages` with arguments `["class Client", "-A", "15"]` |
| Search for Extension Methods | `rip_grep_packages` with arguments `["extension .* on Client"]` |

---

## Example Walkthrough

### Scenario: Integrating a generic package `package:net_widgets`
To integrate a multi-platform package like `net_widgets` safely without getting lost in its internals:

1. **Check locally resolved version:**
   Reading `pubspec.lock` tells us `net_widgets` is resolved at exactly `2.1.0`. We cross-reference this against the online docs to ensure we don't copy APIs introduced in `v2.5.0`.

2. **Locate public entry point using `read_package_uris`:**
   Reading `package:net_widgets/net_widgets.dart` reveals it exports `src/core/client.dart` and `src/stub/runner_stub.dart` (exposing a top-level `runWidget` function).

3. **Identify platform conditional exports:**
   Reading `package:net_widgets/src/core/client.dart` reveals:
   `export 'client_browser.dart' if (dart.library.io) 'client_server.dart' show Client;`
   *Insight:* If we need the server-specific features of `Client` (such as filesystem integrations), we realize that importing `net_widgets.dart` will default to the browser stub under standard analyzer environments. We look for a dedicated platform entry point instead, such as `package:net_widgets/server.dart`.

4. **Inspect constructors and class headers:**
   Using `rip_grep_packages` on `net_widgets` with query `class ServerClient` retrieves the exact signature:
   ```dart
   class ServerClient implements Client {
     ServerClient({required Uri endpoint, Map<String, String>? headers});
   }
   ```

5. **Write clean, compiler-safe code:**
   ```dart
   import 'package:net_widgets/server.dart'; // Direct platform import

   void main() {
     final client = ServerClient(
       endpoint: Uri.parse('https://api.example.com'),
     );
     runWidget(client);
   }
   ```

---

## Related Skills

- **[dart-resolve-package-conflicts](https://github.com/dart-lang/skills/blob/main/skills/dart-resolve-package-conflicts/SKILL.md):** If your local version check (`pubspec.lock`) reveals you are constrained to an older version of a package because of a version conflict, use this workflow to audit and upgrade your dependencies.

