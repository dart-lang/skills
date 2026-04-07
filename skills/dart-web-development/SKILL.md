---
name: dart-web-development
description: Build high-performance web apps using modern interop and browser APIs.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:21:00 GMT
---
# Developing Dart Web Applications

## Contents
- [Core Constraints](#core-constraints)
- [JavaScript Interoperability](#javascript-interoperability)
- [Web Tooling & Environment](#web-tooling--environment)
- [Workflows](#workflows)
- [Examples](#examples)

## Core Constraints

- **Use `package:web`:** Always prefer `package:web` over the legacy `dart:html`, `dart:js`, or `dart:js_util` libraries.
- **Avoid `dart:mirrors`:** Never use `dart:mirrors` in web applications, as it is completely unsupported in Dart web compilation.
- **Use `dart:js_interop`:** Implement all JavaScript interoperability using the `dart:js_interop` library.
- **Prefer Extension Types:** Define JavaScript interop boundaries and complex JS objects using Dart `extension type` declarations combined with `@JS` annotations.

## JavaScript Interoperability

Implement JavaScript interoperability to seamlessly integrate JS libraries and browser APIs into Dart web apps.

- Annotate libraries or external declarations with `@JS()` to bind them to JavaScript objects.
- Use `extension type` to wrap `JSObject` or other JS types. This provides a zero-cost abstraction boundary for JS interop.
- Use specific JS types provided by `dart:js_interop` (e.g., `JSString`, `JSNumber`, `JSObject`, `JSAny`) instead of native Dart types (`String`, `int`) when crossing the interop boundary.

## Web Tooling & Environment

Manage the development lifecycle, compilation, and testing using `webdev` and `build_runner`.

- **Dependencies:** Ensure `build_runner` and `build_web_compilers` are listed under `dev_dependencies` in the `pubspec.yaml`. If testing, include `build_test`.
- **Local Development:** Use `webdev serve` to launch a development server. This utilizes the development compiler, supporting incremental updates and fast refresh.
- **Debugging:** Append the `--debug` flag to `webdev serve` to enable Dart DevTools.
- **Production Build:** Use `webdev build` to generate a minified, deployable JavaScript application.

## Workflows

### Workflow: Setting up a Dart Web Project

Copy and complete this checklist when initializing or configuring a Dart web project:

- [ ] Add required dev dependencies: `dart pub add build_runner build_web_compilers --dev`
- [ ] Add `package:web` dependency: `dart pub add web`
- [ ] Install webdev globally: `dart pub global activate webdev`
- [ ] Verify `pubspec.yaml` contains the correct dependencies.
- [ ] Run `dart pub get` to synchronize dependencies.

### Workflow: Implementing JS Interop

Follow this sequence when binding a new JavaScript library or object:

- [ ] Import `dart:js_interop`.
- [ ] Add the `@JS()` annotation to the library or specific external function/class.
- [ ] Define the JS object boundary using `extension type Name._(JSObject _) implements JSObject`.
- [ ] Declare `external` methods and properties inside the extension type, using `dart:js_interop` types (e.g., `JSString`).
- [ ] Run validator -> review compilation errors -> fix type mismatches between Dart and JS types.

### Workflow: Compiling and Serving

Apply conditional logic based on the deployment target:

- **If developing locally:**
  - [ ] Run `webdev serve` (default port 8080).
  - [ ] For DevTools, run `webdev serve --debug`.
- **If testing:**
  - [ ] Run `dart run build_runner test -- -p chrome`.
- **If building for production:**
  - [ ] Run `webdev build --output web:build` to compile the `web` directory into the `build` directory.

## Examples

### High-Fidelity JS Interop Implementation

This example demonstrates the correct usage of `dart:js_interop`, `package:web`, and extension types to bind a hypothetical JavaScript `UserAuth` object.

```dart
@JS()
library user_auth_interop;

import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Bind to a global JavaScript function
@JS('console.log')
external void _log(JSAny? message);

// Define the JS interop boundary using an extension type
@JS('UserAuth')
extension type UserAuth._(JSObject _) implements JSObject {
  // External constructor
  external UserAuth(JSString apiKey);

  // External properties using JS types
  external JSString get currentUser;
  external set currentUser(JSString value);

  // External methods
  external void login(JSString username, JSString password);
  external JSBoolean isLoggedIn();
}

void main() {
  // Interact with the DOM using package:web
  final web.HTMLDivElement appDiv = web.document.querySelector('#app') as web.HTMLDivElement;
  appDiv.text = 'Initializing Auth...';

  // Instantiate and use the JS interop object
  final auth = UserAuth('api_key_123'.toJS);
  auth.login('admin'.toJS, 'password'.toJS);

  if (auth.isLoggedIn().toDart) {
    _log('User logged in successfully!'.toJS);
    appDiv.text = 'Welcome, ${auth.currentUser.toDart}';
  }
}
```
