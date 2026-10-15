// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:skills_lint/skills_lint.dart';
import 'package:test/test.dart';

const String _configFilePath = 'skills_lint.yaml';

void main() {
  test('Validate skills.sh.json and README.md', () {
    final repoRoot = Directory.current.path.endsWith('repo_tool')
        ? Directory.current.parent
        : Directory.current;
    final skillsDir = Directory(p.join(repoRoot.path, 'skills'));
    expect(skillsDir.existsSync(), isTrue);

    final actualSkills = skillsDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .where((name) => !name.startsWith('.'))
        .toSet();
    expect(actualSkills, isNotEmpty);

    final skillsShFile = File(p.join(repoRoot.path, 'skills.sh.json'));
    expect(skillsShFile.existsSync(), isTrue);

    final skillsShJson =
        jsonDecode(skillsShFile.readAsStringSync()) as Map<String, Object?>;
    expect(
      skillsShJson[r'$schema'],
      'https://skills.sh/schemas/skills.sh.json',
    );
    expect(skillsShJson['notGrouped'], 'bottom');

    final groups = (skillsShJson['groups'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(groups, isNotEmpty);

    final groupedSkills = <String>{};
    for (final group in groups) {
      final title = group['title'];
      expect(
        title,
        isA<String>().having(
          (s) =>
              s.trim().isNotEmpty && s.trim().split(RegExp(r'\s+')).length <= 3,
          '1-3 words',
          isTrue,
        ),
      );
      expect(
        group['description'],
        isA<String>().having((s) => s.isNotEmpty, 'non-empty', isTrue),
      );
      final skills = (group['skills'] as List<Object?>).cast<String>();
      expect(skills, isNotEmpty);
      for (final skill in skills) {
        expect(
          groupedSkills.add(skill),
          isTrue,
          reason: 'Duplicate skill "$skill" in skills.sh.json',
        );
      }
    }

    expect(groupedSkills, equals(actualSkills));

    final readmeFile = File(p.join(repoRoot.path, 'README.md'));
    expect(readmeFile.existsSync(), isTrue);
    final readmeMatches = RegExp(
      r'\| \[([^\]]+)\]\(skills/\1/SKILL\.md\) \|',
    ).allMatches(readmeFile.readAsStringSync());
    final readmeSkills = readmeMatches.map((m) => m.group(1)!).toSet();
    expect(readmeSkills, equals(actualSkills));
  });

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
