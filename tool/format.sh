#!/bin/sh
# Formats hand-written Dart only (generated files stay as the generators wrote them).
# `tool/format.sh --check` fails instead of rewriting.
set -eu
cd "$(dirname "$0")/.."
files=$(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -path 'lib/l10n/app_localizations*')
if [ "${1:-}" = "--check" ]; then
  # shellcheck disable=SC2086
  dart format --output=none --set-exit-if-changed $files
else
  # shellcheck disable=SC2086
  dart format $files
fi
