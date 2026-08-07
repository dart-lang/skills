// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:skills_lint/skills_lint.dart';
import 'package:test/test.dart';

const String _configFilePath = 'skills_lint.yaml';

void main() {
  test('Run skills linter', () async {
    // Enable logging to see detailed validation errors in test output.
    final Level oldLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    final StreamSubscription<LogRecord> subscription = Logger.root.onRecord
        .listen((record) => print(record.message));

    try {
      final Configuration config = await ConfigParser.loadConfig(
        path: _configFilePath,
      );
      final bool isValid = await validateSkills(config: config);
      expect(
        isValid,
        isTrue,
        reason: 'Skills validation failed. See above for details.',
      );
    } finally {
      Logger.root.level = oldLevel;
      await subscription.cancel();
    }
  });
}
