---
name: "dart-web-development"
description: "Build high-performance web apps using modern interop and browser APIs."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:43:22 GMT"

---
# dart-web-js-interop

## Goal
Configures Dart web applications to seamlessly integrate with JavaScript libraries using `dart:js_interop` and `package:web`. Establishes a hot-reload development environment, testing pipeline, and production build process using `webdev` and `build_runner`. Assumes a standard Dart web project structure with a `pubspec.yaml` file.

## Instructions

1. **Configure Dependencies**
   Update the `pubspec.yaml` to include the required web and build packages.
   ```yaml
   dependencies:
     web: ^0.5.0 # Use latest compatible version
     js_interop: ^0.0.0 # If explicitly required by specific interop patterns

   dev_dependencies:
     build_runner: ^2.4.0
     build_web_compilers: ^4.0.0
     build_test: ^3.0.0 # Required if running tests
   ```
   Run the dependency fetch command:
   ```bash
   dart pub get
   ```

2. **Install Global Tooling**
   Ensure the `webdev` CLI is globally activated for the local environment.
   ```bash
   dart pub global activate webdev
   ```

3. **Implement JavaScript Interoperability**
   When writing Dart code that interacts with JavaScript or the DOM, strictly use `dart:js_interop` and `package:web`.
   
   *Example: Interacting with the DOM and an external JS function.*
   ```dart
   import 'dart:js_interop';
   import 'package:web/web.dart' as web;

   // Bind to an external JavaScript function
   @JS('console.log')
   external void jsLog(JSAny? message);

   // Bind to a custom JS object/class
   @JS('MyJsLibrary')
   extension type MyJsLibrary._(JSObject _) implements JSObject {
     external factory MyJsLibrary();
     external void doSomething();
   }

   void main() {
     // Use package:web for DOM manipulation
     final div = web.document.createElement('div') as web.HTMLDivElement;
     div.text = 'Hello from Dart JS Interop!';
     web.document.body?.append(div);

     // Call JS interop
     jsLog('DOM updated successfully'.toJS);
     
     final myLib = MyJsLibrary();
     myLib.doSomething();
   }
   ```

4. **Determine Execution Path (Decision Logic)**
   Evaluate the user's current objective using the following logic:
   *   *Condition A:* User wants to develop locally with hot-reload. -> Proceed to Step 5a.
   *   *Condition B:* User wants to compile a minified production build. -> Proceed to Step 5b.
   *   *Condition C:* User wants to run component/unit tests. -> Proceed to Step 5c.

   **STOP AND ASK THE USER:** "Which environment do you want to target? (1) Local Development [serve], (2) Production Build [build], or (3) Run Tests [test]?"

5. **Execute Build/Serve Commands**
   Based on the user's response, execute the corresponding command:

   *5a. Local Development (Serve)*
   ```bash
   # Serves on localhost:8080 with Dart DevTools enabled
   webdev serve --debug
   ```
   *Validate-and-Fix:* If the command fails with a missing dependency error, verify `build_web_compilers` is in `dev_dependencies` and re-run `dart pub get`.

   *5b. Production Build*
   ```bash
   # Compiles the 'web' directory into the 'build' directory using the production JS compiler
   webdev build --output web:build
   ```

   *5c. Run Tests*
   ```bash
   # Runs tests specifically on the Chrome platform
   dart run build_runner test -- -p chrome
   ```

## Constraints
*   **Strictly use `package:web`:** Never use the legacy `dart:html`, `dart:js`, or `dart:js_util` libraries.
*   **Strictly use `dart:js_interop`:** All JavaScript bindings must use the `@JS` annotation from `dart:js_interop` and utilize JS types (e.g., `JSAny`, `JSObject`, `.toJS`).
*   **No `dart:mirrors`:** Never import or use `dart:mirrors` as it is entirely unsupported in Dart web applications.
*   **Development Server:** Always use `webdev serve` for local development to ensure incremental compilation and hot-reload functionality. Do not use custom HTTP servers for serving raw Dart files.
*   **Browser Support:** Assume the development compiler (`webdev serve`) only supports Chrome. Do not attempt to debug development builds in other browsers.
