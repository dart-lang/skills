---
name: dart-idiomatic-usage
description: Apply Effective Dart usage patterns for cleaner and more efficient code.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 07 Apr 2026 18:18:33 GMT
---
# Writing Idiomatic Dart Collections and Strings

## Contents
- [String Composition](#string-composition)
- [Collection Initialization](#collection-initialization)
- [Collection Operations](#collection-operations)
- [Type Casting in Collections](#type-casting-in-collections)
- [Workflow: Refactoring Legacy Collections](#workflow-refactoring-legacy-collections)

## String Composition

Follow these practices to compose strings efficiently and readably.

- **Use adjacent strings for concatenation:** Do not use the `+` operator to concatenate string literals. Place them next to each other to form a single string.
- **Prefer string interpolation:** Use `$variable` or `${expression}` to compose strings and values instead of concatenation (`+`).
- **Omit unnecessary curly braces:** Use `$identifier` instead of `${identifier}` when interpolating a simple identifier that is not immediately followed by alphanumeric text.

### Examples

**Good:**
```dart
// Adjacent strings
raiseAlarm(
  'ERROR: Parts of the spaceship are on fire. Other '
  'parts are overrun by martians. Unclear which are which.',
);

// Interpolation without unnecessary braces
var greeting = 'Hi, $name! I love your ${decade}s costume.';
```

**Bad:**
```dart
// Do not use + for literals or variables
raiseAlarm(
  'ERROR: Parts of the spaceship are on fire. Other ' +
  'parts are overrun by martians. Unclear which are which.',
);

var greeting = 'Hi, ' + name + '! I love your ' + decade.toString() + 's costume.';
var badBraces = 'Hi, ${name}!';
```

## Collection Initialization

Leverage Dart's built-in syntax for creating and structuring collections.

- **Use collection literals:** Instantiate lists, maps, and sets using `[]`, `{}`, and `<Type>{}` instead of their unnamed constructors (e.g., `Map()`, `Set()`).
- **Use spread and control flow operators:** Build dynamic collections using the spread operator (`...`, `...?`) and collection `if`/`for` rather than imperative `add()` or `addAll()` calls.

### Examples

**Good:**
```dart
var points = <Point>[];
var addresses = <String, Address>{};

var arguments = [
  ...options,
  command,
  ...?modeFlags,
  for (var path in filePaths)
    if (path.endsWith('.dart')) path.replaceAll('.dart', '.js'),
];
```

**Bad:**
```dart
var addresses = Map<String, Address>();

var arguments = <String>[];
arguments.addAll(options);
arguments.add(command);
if (modeFlags != null) arguments.addAll(modeFlags);
```

## Collection Operations

Optimize collection querying and iteration.

- **Use `.isEmpty` and `.isNotEmpty`:** Never check if a collection's `.length` is `0` or `> 0`. The `Iterable` contract does not guarantee constant-time length calculations.
- **Avoid `Iterable.forEach()` with function literals:** Use standard `for-in` loops when iterating over sequences. Reserve `forEach()` for passing existing function tear-offs (e.g., `people.forEach(print)`).
- **Use `whereType<T>()`:** Filter collections by type using the built-in `whereType<T>()` method rather than `where((e) => e is T)`.

### Examples

**Good:**
```dart
if (lunchBox.isEmpty) return 'so hungry...';

for (final person in people) {
  process(person);
}

var ints = objects.whereType<int>();
```

**Bad:**
```dart
if (lunchBox.length == 0) return 'so hungry...';

people.forEach((person) {
  process(person);
});

var ints = objects.where((e) => e is int).cast<int>();
```

## Type Casting in Collections

Minimize the use of `.cast<T>()`, as it creates a lazy collection that checks the element type on *every operation*, degrading performance.

- **Create with the correct type:** Define the collection with the correct generic type at instantiation.
- **Eagerly cast using `List.from()`:** If you must convert a collection and will access most of its elements, use `List<T>.from(iterable)` or `Map<K, V>.from(map)` to eagerly cast the elements once.
- **Preserve types with `.toList()`:** Use `.toList()` when you want to copy an iterable while preserving its original type. Use `List.from()` only when intentionally changing the type.

### Examples

**Good:**
```dart
// Eager cast
var stuff = <dynamic>[1, 2];
var ints = List<int>.from(stuff);

// Map with explicit type
var reciprocals = stuff.map<double>((n) => n * 2);
```

**Bad:**
```dart
// Lazy cast (performance hit on every access)
var stuff = <dynamic>[1, 2];
var ints = stuff.toList().cast<int>();

var reciprocals = stuff.map((n) => n * 2).cast<double>();
```

## Workflow: Refactoring Legacy Collections

When updating legacy Dart code to modern standards, follow this sequential checklist.

### Task Progress
- [ ] **Step 1: Replace Constructors.** Scan for `Map()`, `Set()`, and `List()` (if applicable). Replace with `<K, V>{}`, `<T>{}`, and `<T>[]`.
- [ ] **Step 2: Eliminate `.length` checks.** Regex search for `.length == 0`, `.length > 0`, `.length != 0`. Replace with `.isEmpty` or `.isNotEmpty`.
- [ ] **Step 3: Flatten imperative builds.** Identify sequential `.add()` and `.addAll()` calls on a newly instantiated collection. Rewrite using `...`, `if`, and `for` inside the collection literal.
- [ ] **Step 4: Remove `.cast<T>()`.** Search for `.cast<`. 
  - If applied after `.toList()`, replace with `List<T>.from()`.
  - If applied after `.where()`, replace with `.whereType<T>()`.
  - If applied after `.map()`, add the generic type to the map call: `.map<T>(...)`.
- [ ] **Step 5: Run validator -> review errors -> fix.** Run `dart analyze` to ensure no type promotion or syntax errors were introduced during refactoring.
