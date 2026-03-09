---
name: "dart-concurrency-isolates"
description: "Offload heavy computation to isolates to keep the main thread responsive."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:31:33 GMT"

---
# dart-isolates-concurrency

## Goal
Implements concurrent execution in Dart using isolates to offload heavy computations from the main thread. Manages both short-lived background tasks and long-lived bidirectional worker isolates while ensuring memory safety, proper port management, and strict resource cleanup. Assumes a Dart Native environment (isolates are not supported on Dart Web).

## Instructions

### 1. Determine Isolate Strategy (Decision Logic)
Evaluate the user's concurrency requirements using the following decision tree:
*   **Condition A:** Is the task a single, one-off computation (e.g., parsing a single large JSON file)?
    *   *Action:* Use `Isolate.run()`.
*   **Condition B:** Does the task require repeated executions, maintaining state, or streaming multiple messages over time?
    *   *Action:* Use `Isolate.spawn()` with manual `ReceivePort` and `SendPort` management.

**STOP AND ASK THE USER:** "Are you executing a one-off background task, or do you need a long-running worker that handles multiple messages over time?"

### 2. Implement Short-Lived Isolates (`Isolate.run`)
For simple background tasks, use `Isolate.run()` to automatically handle spawning, message transfer, error handling, and termination.

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

Future<Map<String, dynamic>> parseLargeJson(String filePath) async {
  // Isolate.run spawns the isolate, runs the closure, returns the result, and exits.
  return await Isolate.run(() async {
    final fileData = await File(filePath).readAsString();
    return jsonDecode(fileData) as Map<String, dynamic>;
  });
}
```

### 3. Implement Long-Lived Isolates (`Isolate.spawn`)
For complex workers, establish a robust 2-way communication channel. You must implement message sequencing (using IDs), error handling (`RemoteError`), and lifecycle management.

**Step 3a: Define the Worker Class and Spawning Logic**
Use a `RawReceivePort` to separate startup logic from message handling.

```dart
import 'dart:async';
import 'dart:convert';
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

**Step 3b: Implement the Remote Isolate Entrypoint**
Define the static method that runs on the spawned isolate.

```dart
  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      
      final (int id, String payload) = message as (int, String);
      try {
        // Perform heavy computation here
        final result = jsonDecode(payload);
        sendPort.send((id, result));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }
```

**Step 3c: Implement Message Passing and Response Handling**
Map outgoing messages to `Completer` instances using unique IDs.

```dart
  Future<Object?> executeTask(String payload) async {
    if (_closed) throw StateError('Worker is closed');
    
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    
    _commands.send((id, payload));
    return await completer.future;
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id);
    
    if (completer == null) return;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) {
      _responses.close();
    }
  }
```

**Step 3d: Implement Graceful Shutdown**
Ensure ports are closed to prevent memory leaks.

```dart
  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) {
        _responses.close();
      }
    }
  }
}
```

### 4. Validate and Fix
After generating isolate code, perform the following validation loop:
1.  **Check Port Closure:** Verify that `ReceivePort.close()` is called in both the main isolate and the worker isolate during shutdown.
2.  **Check Payload Types:** Ensure the data being sent through `SendPort.send()` does not contain native resources (e.g., `Socket`, `Pointer`, `ReceivePort`).
3.  **Fix:** If native resources are being passed, refactor the payload to extract and send only primitive data types or serializable maps/records.

## Constraints
*   DO use `Isolate.run()` for simple one-off background tasks.
*   DO manually manage `SendPort` and `ReceivePort` for complex, long-running background workers.
*   AVOID passing large mutable objects between isolates; prefer simple data types and records.
*   DO ensure isolates are terminated when no longer needed to free resources.
*   DO NOT attempt to use isolates on the Dart Web platform (use web workers instead).
*   DO NOT use shared-state concurrency patterns (e.g., mutexes); isolates communicate strictly via message passing.
*   Related Skills: `dart-async-programming`.
