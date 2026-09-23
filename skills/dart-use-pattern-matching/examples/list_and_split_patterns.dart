// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Examples of Dart 3 list patterns for URI path segments, directory prefixes,
/// suffix extraction, and `String.split` token parsing.
library;

/// Matches a multi-segment route prefix (`['api', 'comments', ...]`).
///
/// Because `<expr> case <pattern>` is a control-flow `caseClause` rather than a
/// standalone boolean expression, use a `switch` expression when returning a
/// `bool` value directly.
bool isCommentsApiRoute(List<String> segments) => switch (segments) {
  ['api', 'comments', ...] => true,
  _ => false,
};

/// Matches a prefix and binds the remaining tail segments via `...final rest`.
///
/// Variables bound by `...final rest` are immediately in scope inside a `when`
/// guard clause.
String? resolveAllowedAssetSubpath(List<String> segments) {
  if (segments case ['assets', ...final rest]
      when rest.isNotEmpty && !rest.contains('..')) {
    return rest.join('/');
  }
  return null;
}

/// Extracts the penultimate segment (such as a parent collection or directory)
/// using a leading rest pattern (`[..., final parent, _]`).
String parentCollectionName(List<String> segments) => switch (segments) {
  [..., final parentCollection, _] => parentCollection,
  _ => '',
};

/// Parses a fixed-arity delimited header (`version-traceId-spanId-flags`) using
/// relational negation (`!= 'ff'`) and length guards.
({String traceId, String spanId, bool sampled})? parseTraceparent(
  String header,
) {
  if (header.trim().split('-')
      case [!= 'ff', final traceId, final spanId, final rawFlags, ...]
      when traceId.length == 32 && spanId.length == 16) {
    final flags = int.tryParse(rawFlags, radix: 16) ?? 0;
    return (
      traceId: traceId.toLowerCase(),
      spanId: spanId.toLowerCase(),
      sampled: (flags & 1) == 1,
    );
  }
  return null;
}

/// Splits a URL fragment on `'?'` into its base path and query parameters.
///
/// Calling `'section'.split('?')` on a string without `'?'` returns a
/// single-element list `['section']`. Matching at least two elements
/// (`[final base, final firstQuery, ...final rest]`) guarantees that at least
/// one `'?'` delimiter was present before joining any additional `'?'` tokens.
(String, Map<String, String>) parseFragment(String fragment) =>
    switch (fragment.split('?')) {
      [final base, final firstQuery, ...final rest] => (
        base,
        Uri.splitQueryString([firstQuery, ...rest].join('?')),
      ),
      _ => (fragment, const <String, String>{}),
    };

void main() {
  print('Comments route: ${isCommentsApiRoute(['api', 'comments', '42'])}');
  print(
    'Asset subpath: ${resolveAllowedAssetSubpath(['assets', 'img', 'logo.svg'])}',
  );
  print(
    'Parent collection: ${parentCollectionName(['projects', 'p1', 'docs', 'd1'])}',
  );
  print(
    'Traceparent: ${parseTraceparent('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01')}',
  );
  print('Fragment: ${parseFragment('overview?tab=metrics&filter=a?b')}');
}
