---
name: dart-async-programming
description: Handle asynchronous operations safely using Futures and Streams.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:19:00 GMT
---
# Writing Asynchronous Dart Code

## Contents
- [Core Guidelines](#core-guidelines)
- [Handling Futures](#handling-futures)
- [Managing Streams](#managing-streams)
- [Workflows](#workflows)
- [Examples](#examples)
- [Related Skills](#related-skills)

## Core Guidelines

Write asynchronous Dart code using modern, declarative patterns. Avoid legacy callback-based approaches. Assume all network, file I/O, and database operations are asynchronous.

- **Use `async`/`await`**: Always prefer `async` and `await` over raw `.then()`, `.catchError()`, or `.whenComplete()` chains. This flattens the execution flow and improves readability.
- **Handle Errors Gracefully**: Wrap all `await` calls in `try-catch` blocks to handle exceptions. Do not rely on unhandled future rejections.
- **Execute Concurrently**: Use `Future.wait` to initiate and await multiple independent futures concurrently rather than awaiting them sequentially.
- **Consume Streams Sequentially**: Prefer `await for` over `.forEach()` or `.listen()` when consuming streams, unless you specifically need low-level subscription management (like pausing or resuming).
- **Prevent Memory Leaks**: Always call `.close()` on a `StreamController` when it is no longer needed or when the owning class is disposed.

## Handling Futures

### Sequential vs. Concurrent Execution

If operations depend on each other, await them sequentially. If operations are independent, initiate them concurrently to optimize execution time.

**Sequential (Dependent):**
```dart
final user = await fetchUser(id);
final profile = await fetchProfile(user.profileId);
```

**Concurrent (Independent):**
```dart
final results = await Future.wait([
  fetchUserData(id),
  fetchUserPreferences(id),
  fetchUserPermissions(id),
]);
```

### Error Handling

Always use standard `try-catch-finally` blocks within `async` functions.

```dart
try {
  final data = await fetchData();
  process(data);
} on NetworkException catch (e) {
  handleNetworkError(e);
} catch (e) {
  handleGenericError(e);
} finally {
  cleanupResources();
}
```

## Managing Streams

### Consuming Streams

Use the asynchronous for-loop (`await for`) to process stream events sequentially. This automatically handles stream completion and integrates cleanly with `try-catch` for error handling.

```dart
try {
  await for (final chunk in fileStream) {
    processChunk(chunk);
  }
} catch (e) {
  logError('Stream processing failed: $e');
}
```

### Creating and Managing Streams

When creating custom streams using `StreamController`, ensure you manage the lifecycle properly to avoid memory leaks.

```dart
class DataProvider {
  final _controller = StreamController<Data>.broadcast();

  Stream<Data> get dataStream => _controller.stream;

  void updateData(Data newData) {
    if (!_controller.isClosed) {
      _controller.add(newData);
    }
  }

  void dispose() {
    _controller.close(); // Mandatory cleanup
  }
}
```

## Workflows

### Task Progress: Implementing an Async Data Fetcher
Copy this checklist to track progress when implementing asynchronous data fetching logic:

- [ ] Identify if the required operations are sequential or independent.
- [ ] Mark the function with the `async` keyword and return a `Future<T>`.
- [ ] Wrap the asynchronous operations in a `try-catch` block.
- [ ] If independent, group futures using `Future.wait`.
- [ ] If sequential, use `await` for each step.
- [ ] Handle specific exceptions using `on ExceptionType catch (e)`.
- [ ] Run validator -> review errors -> fix unhandled promise rejections.

### Task Progress: Implementing a Stream Consumer
Copy this checklist to track progress when consuming a stream:

- [ ] Verify the stream source (Single subscription vs. Broadcast).
- [ ] Mark the consuming function as `async`.
- [ ] Wrap the consumption logic in a `try-catch` block.
- [ ] Implement an `await for` loop to iterate over the stream.
- [ ] Ensure the loop breaks or returns if a specific termination condition is met.
- [ ] If managing a `StreamController`, implement a `dispose()` or `close()` method.

## Examples

### Anti-Pattern vs. Best Practice: Futures

**Anti-Pattern (Do Not Use):**
```dart
Future<void> loadUserData() {
  return fetchUser()
    .then((user) {
      return fetchProfile(user.id)
        .then((profile) {
          print('User: ${user.name}, Profile: ${profile.status}');
        });
    })
    .catchError((error) {
      print('Error: $error');
    });
}
```

**Best Practice:**
```dart
Future<void> loadUserData() async {
  try {
    final user = await fetchUser();
    final profile = await fetchProfile(user.id);
    print('User: ${user.name}, Profile: ${profile.status}');
  } catch (error) {
    print('Error: $error');
  }
}
```

### Anti-Pattern vs. Best Practice: Streams

**Anti-Pattern (Do Not Use):**
```dart
void processEvents(Stream<Event> eventStream) {
  eventStream.listen(
    (event) => handleEvent(event),
    onError: (error) => print('Error: $error'),
  );
}
```

**Best Practice:**
```dart
Future<void> processEvents(Stream<Event> eventStream) async {
  try {
    await for (final event in eventStream) {
      handleEvent(event);
    }
  } catch (error) {
    print('Error: $error');
  }
}
```

## Related Skills
- `dart-idiomatic-usage`
- `dart-concurrency-isolates`
