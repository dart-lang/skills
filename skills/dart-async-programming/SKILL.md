---
name: "dart-async-programming"
description: "Handle asynchronous operations safely using Futures and Streams."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 21:41:05 GMT"

---
# dart-async-programming

## Goal
Implements robust, asynchronous Dart code using `Future` and `Stream` APIs. Handles concurrent operations, stream processing, and error management using modern `async`/`await` syntax and structured error handling, assuming a standard Dart or Flutter environment.

## Instructions

1. **Evaluate Asynchronous Requirements (Decision Logic)**
   Analyze the required asynchronous operation and route the implementation using the following decision tree:
   * *Is the operation returning a single value or error?* -> Use `Future<T>` with `async`/`await`.
   * *Are there multiple independent single-value operations?* -> Use `Future.wait`.
   * *Is the operation returning a sequence of values over time?* -> Use `Stream<T>`.
   * *Is the stream representing UI events (e.g., button clicks)?* -> Use `Stream.listen()`.
   * *Is the stream reading data chunks (e.g., file I/O, network responses)?* -> Use `await for`.
   * *Does the stream need multiple listeners?* -> **STOP AND ASK THE USER:** "Should this stream be a broadcast stream (`StreamController.broadcast()`) or a single-subscription stream?"

2. **Implement Single Future Operations**
   Declare functions with the `async` keyword and return `Future<T>`. Await the result inside a `try-catch` block to handle exceptions gracefully.
   ```dart
   Future<String> fetchUserStatus(String userId) async {
     try {
       final status = await networkClient.getStatus(userId);
       return status;
     } catch (e, stackTrace) {
       logError('Failed to fetch user status', e, stackTrace);
       throw UserStatusException(e.toString());
     }
   }
   ```

3. **Execute Concurrent Futures**
   When multiple independent asynchronous operations must be performed, initiate them concurrently using `Future.wait` rather than awaiting them sequentially.
   ```dart
   Future<UserProfile> loadCompleteProfile(String userId) async {
     try {
       final results = await Future.wait([
         fetchUserStatus(userId),
         fetchUserPreferences(userId),
         fetchUserHistory(userId),
       ]);
       
       return UserProfile(
         status: results[0] as String,
         preferences: results[1] as Preferences,
         history: results[2] as History,
       );
     } catch (e) {
       // Handle aggregated errors
       rethrow;
     }
   }
   ```

4. **Consume Streams Sequentially**
   Use the asynchronous for loop (`await for`) to consume streams when processing data sequences (e.g., file reading, data pipelines).
   ```dart
   Future<int> calculateTotal(Stream<int> numberStream) async {
     int sum = 0;
     try {
       await for (final number in numberStream) {
         sum += number;
       }
       return sum;
     } catch (e) {
       logError('Stream processing failed', e);
       return -1;
     }
   }
   ```

5. **Create and Manage Streams**
   When manually generating streams, use `StreamController`. You MUST explicitly call `close()` on the controller when data emission is complete or when the managing class is disposed to prevent memory leaks.
   ```dart
   class DataProducer {
     final StreamController<String> _controller = StreamController<String>();

     Stream<String> get dataStream => _controller.stream;

     void emitData(String data) {
       if (!_controller.isClosed) {
         _controller.add(data);
       }
     }

     Future<void> dispose() async {
       await _controller.close();
     }
   }
   ```

6. **Apply Stream Transformations and Timeouts**
   Chain stream methods to handle errors and timeouts before consuming the stream. Use `handleError` to intercept stream errors without breaking the `await for` loop, and `timeout` to enforce time limits.
   ```dart
   Stream<String> processNetworkStream(Stream<String> rawStream) async* {
     final safeStream = rawStream
         .handleError((error) => logError('Stream error intercepted', error))
         .timeout(
           const Duration(seconds: 5),
           onTimeout: (EventSink<String> sink) {
             sink.addError('Stream timed out');
             sink.close();
           },
         );

     await for (final event in safeStream) {
       yield event.toUpperCase();
     }
   }
   ```

7. **Validate and Fix**
   After generating asynchronous code, verify that:
   * No raw `.then()`, `.catchError()`, or `.whenComplete()` methods are used.
   * Every `StreamController` has a corresponding `close()` method call in a teardown/dispose block.
   * All `await` calls are wrapped in `try-catch` blocks.

## Constraints

* **Strict Async/Await:** Always use `async`/`await` instead of raw `.then()` calls for better readability and control flow.
* **Error Handling:** Wrap all asynchronous calls (`await`) in `try-catch` blocks to handle errors gracefully.
* **Concurrency:** Use `Future.wait` to initiate multiple independent futures concurrently; do not await them sequentially.
* **Stream Consumption:** Prefer `await for` when consuming streams, unless subscribing to endless UI event streams (in which case `.listen()` is permitted).
* **Memory Management:** Always use `StreamController` with a `close()` call to prevent memory leaks.
* **Linter Compliance:** Assume `discarded_futures` and `unawaited_futures` lints are active; never leave a `Future` unawaited unless explicitly assigned to a variable or intentionally ignored using `unawaited()`.
