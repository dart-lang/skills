---
name: "dart-concurrency-isolates"
description: "Offload heavy computation to isolates to keep the main thread responsive."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:41:34 GMT"

---
# Dart Concurrency and Isolates

## Goal
Implements concurrent execution and background processing in Dart applications. Analyzes performance bottlenecks and offloads heavy computations from the main isolate to background workers, preventing UI jank and blocked event loops. Assumes a Dart Native environment (non-web) where the `dart:isolate` library is fully supported.

## Decision Logic
When tasked with implementing concurrency, evaluate the requirements using the following logic:
1. **Is the task I/O bound (e.g., network request, file read)?**
   * Use standard asynchronous APIs (`Future`, `Stream`, `async`/`await`).
2. **Is the task CPU-bound but only needs to run once (e.g., parsing a single large JSON payload)?**
   * Use `Isolate.run()`.
3. **Is the task CPU-bound and requires repeated execution or ongoing communication (e.g., continuous data processing, complex stateful worker)?**
   * Use `Isolate.spawn()` with manual `ReceivePort` and `SendPort` management.
4. **Is the target platform Dart Web?**
   * **STOP AND ASK THE USER:** Isolates are not supported on the web. Ask if you should implement Web Workers instead.

## Instructions

1. **Implement One-Off Background Tasks**
   For simple, single-shot heavy computations, use `Isolate.run()`. Pass a top-level function, static method, or closure.
   ```dart
   import 'dart:isolate';
   import 'dart:convert';
   import 'dart:io';

   Future<Map<String, dynamic>> parseLargeJson(String filePath) async {
     return await Isolate.run(() async {
       final fileData = await File(filePath).readAsString();
       return jsonDecode(fileData) as Map<String, dynamic>;
     });
   }
   ```

2. **Scaffold Long-Lived Worker Isolates**
   For complex workers, create a dedicated class to manage the isolate lifecycle, utilizing `RawReceivePort` to separate startup logic from message handling.
   ```dart
   import 'dart:async';
   import 'dart:isolate';

   class BackgroundWorker {
     final SendPort _commands;
     final ReceivePort _responses;
     final Map<int, Completer<Object?>> _activeRequests = {};
     int _idCounter = 0;
     bool _closed = false;

     BackgroundWorker._(this._responses, this._commands) {
       _responses.listen(_handleResponsesFromIsolate);
     }

     static Future<BackgroundWorker> spawn() async {
       final initPort = RawReceivePort();
       final connection = Completer<(ReceivePort, SendPort)>.sync();
       
       initPort.handler = (initialMessage) {
         final commandPort = initialMessage as SendPort;
         connection.complete((
           ReceivePort.fromRawReceivePort(initPort),
           commandPort,
         ));
       };

       try {
         await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
       } catch (e) {
         initPort.close();
         rethrow;
       }

       final (ReceivePort receivePort, SendPort sendPort) = await connection.future;
       return BackgroundWorker._(receivePort, sendPort);
     }
   ```

3. **Implement Bidirectional Communication**
   Define the entry point for the spawned isolate and establish the message passing protocol.
   ```dart
     static void _startRemoteIsolate(SendPort sendPort) {
       final receivePort = ReceivePort();
       sendPort.send(receivePort.sendPort);

       receivePort.listen((message) {
         if (message == 'shutdown') {
           receivePort.close();
           return;
         }
         
         final (int id, dynamic payload) = message as (int, dynamic);
         try {
           // Perform heavy computation here
           final result = _processPayload(payload);
           sendPort.send((id, result));
         } catch (e) {
           sendPort.send((id, RemoteError(e.toString(), '')));
         }
       });
     }

     static dynamic _processPayload(dynamic payload) {
       // Implementation specific logic
       return payload; 
     }
   ```

4. **Handle Responses and Request Mapping**
   Map outgoing requests to incoming responses using a `Completer` registry.
   ```dart
     Future<Object?> executeTask(dynamic payload) async {
       if (_closed) throw StateError('Worker is closed');
       final completer = Completer<Object?>.sync();
       final id = _idCounter++;
       _activeRequests[id] = completer;
       _commands.send((id, payload));
       return await completer.future;
     }

     void _handleResponsesFromIsolate(dynamic message) {
       final (int id, Object? response) = message as (int, Object?);
       final completer = _activeRequests.remove(id)!;

       if (response is RemoteError) {
         completer.completeError(response);
       } else {
         completer.complete(response);
       }

       if (_closed && _activeRequests.isEmpty) _responses.close();
     }
   ```

5. **Implement Resource Cleanup**
   Ensure the isolate and all ports are properly terminated when no longer needed.
   ```dart
     void close() {
       if (!_closed) {
         _closed = true;
         _commands.send('shutdown');
         if (_activeRequests.isEmpty) _responses.close();
       }
     }
   }
   ```

6. **Validate and Fix**
   Implement a validation loop. Verify that the isolate successfully spawns and that `executeTask` returns the expected payload. If a `RemoteError` is caught, inspect the payload to ensure it does not contain unsendable objects.
   
   **STOP AND ASK THE USER:** "Does the payload you intend to send to the isolate contain any native resources, Sockets, ReceivePorts, or FFI Pointers? These cannot be passed through a SendPort."

## Constraints
* Use `Isolate.run()` strictly for simple one-off background tasks.
* Manually manage `SendPort` and `ReceivePort` for complex, long-running background workers.
* Avoid passing large mutable objects between isolates; prefer simple data types to minimize transfer overhead.
* Ensure isolates are terminated when no longer needed to free resources (always implement a `close()` or `dispose()` method).
* Never attempt to send unsendable objects (e.g., `Socket`, `ReceivePort`, `DynamicLibrary`, `Pointer`) through a `SendPort`.
* Do not use shared-state concurrency patterns (mutexes/locks); rely entirely on message passing.
