/// Examples of Dart 3 list, path segment, and `String.split()` patterns.
library;

/// Matches a multi-segment route prefix (`['api', 'comments', ...]`).
///
/// Because `<expr> case <pattern>` is a control-flow `caseClause` (valid only
/// inside `if`, `for`, or `while` headers) and not a standalone boolean
/// expression, use a `switch` expression when returning a `bool` directly.
bool isCommentsApiRoute(List<String> segments) => switch (segments) {
  ['api', 'comments', ...] => true,
  _ => false,
};

/// Matches a prefix and extracts the remaining segments (`...final rest`) with
/// a `when` guard checking the extracted tail.
String? resolveAllowedAssetSubpath(List<String> segments) {
  if (segments case ['assets', ...final rest]
      when rest.isNotEmpty && !rest.contains('..')) {
    return rest.join('/');
  }
  return null;
}

/// Extracts the penultimate segment (`[..., final parent, _]`) without manual
/// `segments.length >= 2` and `segments[segments.length - 2]` indexing.
String parentCollectionName(List<String> segments) => switch (segments) {
  [..., final parent, _] => parent,
  _ => '',
};

/// Parses a fixed 4-element W3C `traceparent` header (`version-traceId-spanId-flags`)
/// using list destructuring, relational negation (`!=`), and a `when` guard.
({String traceId, String spanId, bool sampled})? parseTraceparent(
  String header,
) {
  if (header.trim().split('-')
      case [!= 'ff', final traceId, final spanId, final rawFlags]
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

/// Splits a space-delimited command line into its command name and non-empty
/// argument list.
///
/// Calling `'help'.split(' ')` on a string without spaces returns a
/// single-element list `['help']`. Matching at least two elements
/// (`[final command, final firstArg, ...final extraArgs]`) guarantees that at
/// least one space delimiter was present.
(String, List<String>)? parseCommandWithArgs(String line) =>
    switch (line.trim().split(' ')) {
      [final command, final firstArg, ...final extraArgs] => (
        command,
        [firstArg, ...extraArgs],
      ),
      _ => null,
    };

/// Combines list destructuring with `Set.contains` in a `when` guard to extract
/// the matched top-level route segment and its remaining tail.
(String, List<String>)? matchAllowedRoute(
  List<String> segments,
  Set<String> allowedPrefixes,
) {
  if (segments case [final first, ...final rest]
      when allowedPrefixes.contains(first)) {
    return (first, rest);
  }
  return null;
}

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
  print('Command: ${parseCommandWithArgs('deploy --env prod --dry-run')}');
  print(
    'Allowed route: ${matchAllowedRoute(['docs', 'intro'], const {'api', 'docs', 'status'})}',
  );
}
