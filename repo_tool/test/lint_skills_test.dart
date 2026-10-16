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
const String _expectedSkillsShSchema =
    'https://skills.sh/schemas/skills.sh.json';
const int _maxGroupTitleLength = 30;

void _validateGroupTitle(Object? title) {
  expect(
    title,
    isA<String>()
        .having((s) => s.trim(), 'trimmed title', isNotEmpty)
        .having(
          (s) => s.length,
          'length',
          lessThanOrEqualTo(_maxGroupTitleLength),
        ),
  );
}

void _validateGroupDescription(Object? description) {
  expect(
    description,
    isA<String>().having((s) => s.trim(), 'trimmed description', isNotEmpty),
  );
}

Set<String> _collectUniqueGroupedSkills(List<Map<String, Object?>> groups) {
  final groupedSkills = <String>{};
  for (final group in groups) {
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
  return groupedSkills;
}

void main() {
  test('skills.sh.json and README.md match skills in skills/', () {
    final repoRoot = Directory.current.path.endsWith('repo_tool')
        ? Directory.current.parent
        : Directory.current;

    // 1. Collect all skill directories in skills/.
    final skillsDir = Directory(p.join(repoRoot.path, 'skills'));
    expect(skillsDir.existsSync(), isTrue);

    final actualSkills = skillsDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .where((name) => !name.startsWith('.'))
        .toSet();
    expect(actualSkills, isNotEmpty);

    // 2. Parse skills.sh.json and validate its local properties (this performs
    // a string comparison against _expectedSkillsShSchema and makes no HTTP or
    // network calls).
    final skillsShFile = File(p.join(repoRoot.path, 'skills.sh.json'));
    expect(skillsShFile.existsSync(), isTrue);

    final skillsShJson =
        jsonDecode(skillsShFile.readAsStringSync()) as Map<String, Object?>;
    expect(skillsShJson[r'$schema'], _expectedSkillsShSchema);

    // Setting notGrouped to "bottom" instructs skills.sh to render any skill
    // not listed in "groups" (such as previously deleted or renamed skill slugs
    // retained in skills.sh install telemetry) under its built-in
    // "Other skills" heading at the bottom of the repository page (the schema
    // only accepts "top", "bottom", or "hidden", and does not support a custom
    // label).
    expect(skillsShJson['notGrouped'], 'bottom');
    expect(skillsShJson.keys.last, 'notGrouped');

    // 3. Validate each group's title, description, and unique skill
    // identifiers, and ensure that all grouped skills exist in skills/ (without
    // typos or missing skills).
    final groups = (skillsShJson['groups'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(groups, isNotEmpty);

    for (final group in groups) {
      _validateGroupTitle(group['title']);
      _validateGroupDescription(group['description']);
    }

    final groupedSkills = _collectUniqueGroupedSkills(groups);
    expect(groupedSkills, equals(actualSkills));

    // 4. Verify the Available Skills table in README.md lists the exact same
    // set of skills.
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
