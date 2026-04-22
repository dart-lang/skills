---
name: dart-build-cli-app
description: Entrypoint structure, exit codes, cross-platform scripts. Use
    when building command line utilities, scripts, or applications.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 22 Apr 2026 20:01:22 GMT
---
# Building Dart CLI Applications

## Contents
- [Project Setup & Architecture](#project-setup--architecture)
- [Argument Parsing & Commands](#argument-parsing--commands)
- [I/O & Error Handling](#io--error-handling)
- [Testing CLI Applications](#testing-cli-applications)
- [Compilation & Distribution](#compilation--distribution)
- [Workflows](#workflows)

## Project Setup & Architecture

Initialize new CLI projects using the official Dart template to ensure standard directory structure and dependency resolution.

*   Run `dart create -t cli <project_name>` to scaffold the application.
*   Place executable entry points (files containing `main()`) exclusively in the `bin/` directory.
*   Place all core business logic, command definitions, and utilities in the `lib/` directory.
*   Place internal implementation details not meant for external consumption in `lib/src/`.

## Argument Parsing & Commands

Implement command-line interfaces using the `args` package, specifically leveraging `CommandRunner` and `Command` for scalable, multi-command applications (e.g., `git commit`, `git stash`).

*   Instantiate a `CommandRunner` in your `bin/<executable>.dart` entry point.
*   Extend the `Command` class for each sub-command.
*   Define options (`addOption`) and flags (`addFlag`) within the constructor of your `Command` subclasses.
*   Catch `UsageException` to gracefully handle invalid arguments and print usage instructions.

```dart
import 'dart:io';
import 'package:args/command_runner.dart';

class CommitCommand extends Command {
  @override
  final name = 'commit';
  @override
  final description = 'Record changes to the repository.';

  CommitCommand() {
    argParser.addFlag('all', abbr: 'a', help: 'Commit all changed files.');
  }

  @override
  void run() {
    final commitAll = argResults?['all'] as bool? ?? false;
    print('Committing all: $commitAll');
  }
}

void main(List<String> args) async {
  final runner = CommandRunner('dgit', 'Distributed version control.')
    ..addCommand(CommitCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(e.usage);
    exit(64); // ExitCode.usage.code
  }
}
```

## I/O & Error Handling

Utilize the `io` and `stack_trace` packages to manage process execution, standard streams, and error reporting.

*   Use `ExitCode` from the `io` package to return standardized POSIX exit codes (e.g., `ExitCode.usage.code`, `ExitCode.success.code`).
*   Wrap asynchronous execution blocks in `Chain.capture()` from the `stack_trace` package to maintain stack traces across asynchronous gaps.
*   Format captured stack chains using `Chain.terse` to remove core library noise and provide readable error output.
*   Use `sharedStdIn` from the `io` package if multiple subscribers need to listen to standard input sequentially.

## Testing CLI Applications

Validate CLI behavior using `test_process` for execution and `test_descriptor` for filesystem mocking.

*   Define expected filesystem states using `d.dir()` and `d.file()`.
*   Create the mock filesystem before execution using `await d.Descriptor.create()`.
*   Spawn the CLI process using `TestProcess.start()`.
*   Assert standard output and error streams using `emits()` and `emitsThrough()` matchers on `process.stdout` and `process.stderr`.
*   Verify the process exit code using `await process.shouldExit(0)`.
*   Validate resulting filesystem mutations using `await d.Descriptor.validate()`.

```dart
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('CLI creates a file and exits successfully', () async {
    // 1. Setup mock filesystem
    await d.dir('workspace', [
      d.file('input.txt', 'raw data')
    ]).create();

    // 2. Execute CLI
    final process = await TestProcess.start('dart', [
      'run', 'bin/my_cli.dart', '--target', '${d.sandbox}/workspace'
    ]);

    // 3. Validate Output
    await expectLater(process.stdout, emitsThrough('Processing complete!'));
    await process.shouldExit(0);

    // 4. Validate Filesystem mutations
    await d.dir('workspace', [
      d.file('output.txt', 'processed data')
    ]).validate();
  });
}
```

## Compilation & Distribution

Compile Dart CLI applications to optimize for startup time, distribution method, and target architecture.

*   **If distributing a standalone binary:** Use `dart compile exe bin/main.dart -o <output_path>`. This bundles the Dart runtime and machine code into a single executable.
*   **If cross-compiling (Linux targets only):** Append `--target-os=linux` and `--target-arch=<arm64|x64|riscv64>` to the `dart compile exe` command.
*   **If distributing multiple apps to save disk space:** Use `dart compile aot-snapshot bin/main.dart`. Execute the resulting `.aot` file using `dartaotruntime <file.aot>`.
*   **If building a portable module:** Use `dart compile kernel bin/main.dart` to generate a `.dill` file runnable on any architecture via `dart run <file.dill>`.

## Workflows

### Task Progress: CLI Implementation & Deployment
Copy this checklist to track progress when building a new CLI tool.

- [ ] **Initialize:** Run `dart create -t cli <name>`.
- [ ] **Configure Dependencies:** Add `args`, `io`, `stack_trace`, `test_process`, and `test_descriptor` to `pubspec.yaml`.
- [ ] **Scaffold Commands:** Create `CommandRunner` in `bin/` and `Command` subclasses in `lib/src/commands/`.
- [ ] **Implement Logic:** Add `run()` overrides. Wrap execution in `Chain.capture()` for async error tracking.
- [ ] **Handle Errors:** Catch `UsageException` and map to `ExitCode.usage.code`.
- [ ] **Write Tests:** Use `test_descriptor` to mock files and `TestProcess.start()` to verify stdout/stderr and exit codes.
- [ ] **Run Validator:** Execute `dart test` -> review errors -> fix.
- [ ] **Format:** Run `dart format . --set-exit-if-changed` to ensure style compliance.
- [ ] **Compile:** Run `dart compile exe bin/<name>.dart -o build/<name>` for the target platform.
