---
name: "dart-async-programming"
description: "Handle asynchronous operations safely using Futures and Streams."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Mon, 09 Mar 2026 22:31:03 GMT"

---
# dart-async-programming

## Goal
Implements robust, idiomatic asynchronous Dart code using `Future` and `Stream` APIs. Manages concurrency, stream processing, and error handling while adhering to strict Dart async patterns, memory safety guidelines, and optimal execution flow.

## Decision Logic
When determining the appropriate asynchronous pattern, evaluate the following decision tree:
*   **Single Asynchronous Operation:** Use `Future<T>` with `async` and `await`.
*   **Multiple Independent Operations:** Use `Future.wait` to execute concurrently.
*   **Sequence of Asynchronous Events:** Use `Stream<T>`.
    *   *Finite/Sequential Data (e.g., File I/O, Network Responses):* Consume using `await for`.
    *   *Infinite/Event-Driven Data (e.g., UI Events):* Use `listen()` on a Broadcast Stream.
*   **Custom Stream Generation:** 
    *   *Simple Generation:* Use `async*` and `yield`.
    *   *Complex State/Event Management:* Use `StreamController`.

## Instructions

1. **Implement Single Futures with Error Handling**
   Always use `async`/`await` syntax instead of `.then()`. Wrap operations in `try-catch` blocks to handle exceptions gracefully.
   ```dart
   Future<String> fetchUserData(String userId) async {
     try {
       final result = await api.getUser(userId);
       return result.name;
     } catch (e, stackTrace) {
       // Handle specific errors or rethrow
       logError('Failed to fetch user: $e', stackTrace);
       throw UserFetchException(e.toString());
     }
   }
   ```

2. **Execute Independent Futures Concurrently**
   When multiple asynchronous operations do not depend on each other, initiate them concurrently using `Future.wait`.
   ```dart
   Future<UserProfile> loadCompleteProfile(String userId) async {
     try {
       final results = await Future.wait([
         api.getUser(userId),
         api.getUserPreferences(userId),
         api.getUserHistory(userId),
       ]);
       
       return UserProfile(
         user: results[0] as User,
         preferences: results[1] as Preferences,
         history: results[2] as History,
       );
     } catch (e) {
       throw ProfileLoadException('Failed to load profile components: $e');
     }
   }
   ```

3. **Consume Streams Sequentially**
   Use `await for` to consume streams when you need to process events sequentially and wait for the stream to close.
   ```dart
   Future<int> calculateTotal(Stream<int> numberStream) async {
     int total = 0;
     try {
       await for (final number in numberStream) {
         total += number;
       }
     } catch (e) {
       logError('Stream processing failed: $e');
       return -1;
     }
     return total;
   }
   ```

4. **Generate Streams using Generators**
   For straightforward sequential event generation, use `async*` and `yield`.
   ```dart
   Stream<int> generateCountdown(int from) async* {
     for (int i = from; i >= 0; i--) {
       await Future.delayed(const Duration(seconds: 1));
       yield i;
     }
   }
   ```

5. **Manage Complex Streams with StreamController**
   When manually controlling stream state, instantiate a `StreamController`. You MUST ensure the controller is closed when no longer needed to prevent memory leaks.
   ```dart
   class DataManager {
     final StreamController<DataEvent> _controller = StreamController<DataEvent>.broadcast();

     Stream<DataEvent> get dataStream => _controller.stream;

     void addData(DataEvent event) {
       if (!_controller.isClosed) {
         _controller.add(event);
       }
     }

     void dispose() {
       _controller.close();
     }
   }
   ```

6. **Apply Stream Transformations and Timeouts**
   Use built-in stream methods to handle errors, timeouts, and transformations before consumption.
   ```dart
   Stream<String> processNetworkStream(Stream<List<int>> byteStream) async* {
     final safeStream = byteStream
         .handleError((e) => logError('Network error: $e'))
         .timeout(
           const Duration(seconds: 5),
           onTimeout: (sink) {
             sink.addError(TimeoutException('Stream timed out'));
             sink.close();
           },
         )
         .transform(utf8.decoder)
         .transform(const LineSplitter());

     await for (final line in safeStream) {
       if (line.isNotEmpty) yield line;
     }
   }
   ```

7. **Context Checkpoint**
   **STOP AND ASK THE USER:** If the user requests stream implementation but does not specify if the stream will have multiple listeners (e.g., UI state) or a single listener (e.g., file reading), ask them to clarify before implementing `StreamController` or `StreamController.broadcast()`.

8. **Validate-and-Fix**
   After generating asynchronous code, perform a validation pass:
   *   *Check:* Are there any raw `.then()` or `.catchError()` chains? *Fix:* Convert to `async`/`await` and `try-catch`.
   *   *Check:* Are multiple independent `await` calls made sequentially? *Fix:* Combine them using `Future.wait`.
   *   *Check:* Is a `StreamController` instantiated without a corresponding `close()` method in a disposal lifecycle? *Fix:* Add the `close()` call.

## Constraints
*   DO use `async`/`await` instead of raw `.then()` calls for better readability.
*   DO wrap asynchronous calls in `try-catch` to handle errors gracefully.
*   PREFER `Future.wait` to initiate multiple independent futures concurrently.
*   PREFER `await for` over `forEach` or `listen` when consuming streams sequentially.
*   DO use `StreamController` with a `close()` call to prevent memory leaks.
*   DO NOT use `await for` for UI event listeners, as UI frameworks send endless streams of events which will block execution indefinitely.
*   Related Skills: `dart-idiomatic-usage`, `dart-concurrency-isolates`.
