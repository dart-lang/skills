// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:io/io.dart';
import 'package:stack_trace/stack_trace.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show detailed stack traces on failure.',
    )
    ..addOption('input', abbr: 'i', help: 'Path to input file.');

  try {
    final results = parser.parse(args);

    if (results['help'] as bool) {
      io.stdout.writeln('Usage: single_tool [options]');
      io.stdout.writeln(parser.usage);
      io.exitCode = ExitCode.success.code;
      return;
    }

    await runTool(results);
    io.exitCode = ExitCode.success.code;
  } on FormatException catch (e) {
    // Parameter and parsing errors write to stderr along with usage help.
    io.stderr.writeln('Error: ${e.message}');
    io.stderr.writeln(parser.usage);
    io.exitCode = ExitCode.usage.code;
  } catch (e, st) {
    io.stderr.writeln('Fatal error: $e');
    if (args.contains('-v') || args.contains('--verbose')) {
      io.stderr.writeln(Trace.from(st).terse);
    }
    io.exitCode = ExitCode.software.code;
  }
}

Future<void> runTool(ArgResults results) async {
  final input = results['input'] as String?;
  if (input == null) {
    throw const FormatException('Missing required option: --input');
  }
  io.stdout.writeln('Processing $input...');
}
