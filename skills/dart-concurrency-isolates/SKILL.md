---
name: dart-concurrency-isolates
description: Offload heavy computation to isolates to keep the main thread responsive.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:19:26 GMT
---
# Managing Dart Concurrency and Isolates

## Contents
- [Core Guidelines](#core-guidelines)
- [Choosing the Right Isolate Strategy](#choosing-the-right-isolate-strategy)
- [Implementing One-Off Tasks](#implementing-one-off-tasks)
- [Implementing Long-Running Workers](#implementing-long-running-workers)
- [Workflows](#workflows)
- [Examples](#examples)

## Core Guidelines

- **Isolate Memory:** Assume zero shared memory between isolates. Isolates communicate exclusively via message passing.
- **Data Transfer:** Avoid passing large mutable objects between isolates. Prefer simple data types or immutable records to minimize serialization overhead.
- **Resource Management:** Always ensure isolates and ports are terminated when no longer needed to prevent memory leaks.
- **Platform Limitations:** Do not use isolates on the Dart Web platform. Web compiles to JavaScript, which uses Web Workers instead.
- **Related Skills:** Refer to `dart-async-programming` for standard asynchronous operations (`Future`, `Stream`, `async`/`await`) running on the Main Isolate.

## Choosing the Right Isolate Strategy

Apply conditional logic to determine the correct isolate implementation:

- **If executing a simple, one-off background task** (e.g., parsing a single large JSON payload, compressing a file): Use `Isolate.run()`.
- **If executing complex, long-running background workers** (e.g., continuous data processing, maintaining a persistent database connection): Use `Isolate.spawn()` and manually manage `SendPort` and `ReceivePort`.

## Implementing One-Off Tasks

Use `Isolate.run()` to spawn an isolate, execute a function, capture the result, and automatically terminate the isolate.

1. Pass a top-level function, static method, or closure to `Isolate.run()`.
2. Await the result in the Main Isolate.

```dart
Future<Map<String, dynamic>> parseLargeJson(String jsonString) async {
  // Spawns isolate, runs decode, returns result, and terminates automatically.
  return await Isolate.run(() => jsonDecode(jsonString) as Map<String, dynamic>);
}
```

## Implementing Long-Running Workers

Manually manage `SendPort` and `ReceivePort` to establish two-way communication for long-lived worker isolates.

1. **Initialize with `RawReceivePort`:** Use `RawReceivePort` in the Main Isolate to separate startup logic from ongoing message handling.
2. **Establish Two-Way Communication:** Pass the Main Isolate's `SendPort` to the Worker Isolate via `Isolate.spawn()`. The Worker Isolate must create its own `ReceivePort` and send its `SendPort` back to the Main Isolate.
3. **Map Requests to Responses:** Use a `Completer` map with unique IDs to track asynchronous requests sent to the Worker Isolate and resolve them when the response is received.
4. **Handle Errors:** Catch exceptions in the Worker Isolate and send them back as `RemoteError` objects.
5. **Teardown:** Send a specific shutdown message to the Worker Isolate to close its `ReceivePort`, and close the Main Isolate's `ReceivePort` when all active requests are completed.

## Workflows

### Task Progress: Long-Running Worker Setup
Copy this checklist to track progress when implementing a long-running worker isolate:

- [ ] Create a `Worker` class to encapsulate isolate management.
- [ ] Implement a static `spawn()` method using `RawReceivePort` to capture the initial `SendPort` from the worker.
- [ ] Call `Isolate.spawn()`, passing the `RawReceivePort.sendPort` and the worker entrypoint method.
- [ ] Implement the worker entrypoint method (`_startRemoteIsolate`).
- [ ] Create a `ReceivePort` inside the worker and send its `SendPort` back to the Main Isolate.
- [ ] Set up a listener on the worker's `ReceivePort` to process incoming commands.
- [ ] Set up a listener on the Main Isolate's `ReceivePort` to process responses and resolve `Completer` instances.
- [ ] Implement a `close()` method to send a shutdown command and close all ports.
- [ ] Run validator -> review errors -> fix (Ensure no memory leaks and all ports close cleanly).

## Examples

### Robust Long-Running Worker Implementation

Use this pattern for robust, two-way communication with a long-running worker isolate.

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

class JsonWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  JsonWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  static Future<JsonWorker> spawn() async {
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
    return JsonWorker._(receivePort, sendPort);
  }

  Future<Object?> parseJson(String message) async {
    if (_closed) throw StateError('Worker is closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, message));
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

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      
      final (int id, String jsonText) = message as (int, String);
      try {
        final jsonData = jsonDecode(jsonText);
        sendPort.send((id, jsonData));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
    }
  }
}
```
