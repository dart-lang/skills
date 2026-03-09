---
name: "dart-web-development"
description: "Build high-performance web apps using modern interop and browser APIs."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:33:50 GMT"

---
# dart-web-js-interop

## Goal
Configures Dart web applications for modern JavaScript interoperability using `dart:js_interop` and `package:web`, and manages the build, serve, and test lifecycle using `webdev`. Assumes a standard Dart web environment requiring integration with external JavaScript libraries or browser APIs.

## Decision Logic
Evaluate the user's current objective to determine the appropriate action path:
1. **Project Setup:** If the project lacks web build tools, proceed to dependency configuration.
2. **JS Binding Creation:** If the user needs to call JS from Dart, implement `@JS` annotations with Extension Types.
3. **Local Development:** If the user is actively developing, utilize `webdev serve` with hot-reload capabilities.
4. **Production Deployment:** If the user is preparing for release, utilize `webdev build`.
5. **Testing:** If the user needs to validate web components, utilize `build_runner test`.

## Instructions

1. **Configure Web Dependencies**
   Ensure the project has the required development and web dependencies. Modify `pubspec.yaml` to include `build_runner`, `build_web_compilers`, and `package:web`.
   ```yaml
   dependencies:
     web: ^0.5.0 # Use latest compatible version

   dev_dependencies:
     build_runner: ^2.4.0
     build_web_compilers: ^4.0.0
     build_test: ^3.0.0 # If testing is required
   ```
   Run `dart pub get` to resolve dependencies.
   *Validate-and-Fix:* If dependency resolution fails, verify SDK constraints in `pubspec.yaml` support Dart 3.3+ (required for modern JS interop).

2. **Implement JavaScript Interoperability**
   Define JavaScript boundaries using `dart:js_interop` and Extension Types. Do not use legacy `dart:html` or older interop libraries.
   ```dart
   import 'dart:js_interop';
   import 'package:web/web.dart' as web;

   // Bind to a global JavaScript function
   @JS('console.log')
   external void logToConsole(JSAny? obj);

   // Bind to a JavaScript object/class using Extension Types
   @JS('MyJSClass')
   extension type MyDartWrapper._(JSObject _) implements JSObject {
     external MyDartWrapper(JSString name);
     
     external JSString get name;
     external set name(JSString value);
     
     external void doSomething();
   }

   void main() {
     // Example usage interacting with the DOM via package:web
     final div = web.document.createElement('div') as web.HTMLDivElement;
     div.text = 'Hello from Dart!';
     web.document.body?.append(div);

     // Example usage of custom JS interop
     final myObj = MyDartWrapper('Test'.toJS);
     myObj.doSomething();
   }
   ```

3. **Initialize Local Development Server**
   **STOP AND ASK THE USER:** "Do you need to run the development server on a specific port, or enable Dart DevTools debugging?"
   If standard development is requested, start the server using `webdev`:
   ```bash
   # Standard serve (defaults to localhost:8080)
   webdev serve

   # Serve with Dart DevTools enabled
   webdev serve --debug

   # Serve on a custom port
   webdev serve web:8083
   ```

4. **Execute Production Build**
   Compile the application for production deployment. This generates minified JavaScript.
   ```bash
   # Build the 'web' directory into the 'build' directory
   webdev build --output web:build
   ```
   *Validate-and-Fix:* Inspect the output directory. If the build fails due to missing builders, ensure `build_web_compilers` is correctly listed in `dev_dependencies`.

5. **Run Web Tests**
   Execute component or unit tests in a browser environment.
   ```bash
   # Run tests on the Chrome platform
   dart run build_runner test -- -p chrome
   ```

## Constraints
* DO NOT use `dart:html`, `dart:js`, or `dart:js_util`. Strictly use `package:web` and `dart:js_interop`.
* DO NOT use `dart:mirrors` under any circumstances; it is unsupported in Dart web applications.
* MUST use `extension type` for defining complex JavaScript object bindings.
* MUST annotate external JS declarations with `@JS()`.
* MUST convert Dart types to JS types explicitly (e.g., `'string'.toJS`) when passing arguments to JS interop functions.
* Related Skills: `dart-migration-versioning`, `dart-compilation-deployment`.
