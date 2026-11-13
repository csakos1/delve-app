# AGENTS.md

Flutter (3.41.9, Dart 3.11) Android-only client for Delve, a personal AI agent on a single
desktop, reached over Tailscale: REST (dio) + WebSocket. `README.md` is the authoritative,
detailed document (features, data flow, layout); read it before non-trivial work.

## Commands (CI order — .github/workflows/ci.yml)

```sh
flutter pub get
dart run build_runner build   # freezed / json_serializable / drift; after touching models or DB schema
flutter gen-l10n              # after editing lib/l10n/app_en.arb
tool/format.sh                # hand-written Dart only; generated files are excluded
flutter analyze
flutter test
```

- Single test: `flutter test test/theme_test.dart`. No backend or device needed —
  `test/support/` has a fake REST dio adapter, a fake WebSocket server, and an app harness.
- Drift tests on Linux need system sqlite (Arch: the `sqlite` package; CI installs `libsqlite3-dev`).
- Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`) and
  `pubspec.lock` are committed. CI re-runs `build_runner` + `gen-l10n` and fails on any git
  diff — always commit the regenerated output.
- Don't run plain `dart format` on the tree; `tool/format.sh` (CI runs `--check`) keeps
  generated files as the generators wrote them.
- Flutter version is pinned: 3.41.9 (CI installs exactly this).

## Commit guard (.githooks/pre-commit, core.hooksPath already set)

Blocks staged commits containing:
- any 64-hex string (possible key/hash; the `sha256:` lines of `pubspec.lock` are exempt), or
- denylist entries from `~/.config/agent-infra/denylist.txt` (`$AGENT_INFRA_DENYLIST` to
  override); a missing denylist file blocks the commit.

gitleaks runs when installed. So: never paste long hex blobs or denylisted host
identifiers into the repo.

## Architecture facts that change how you work

- Data flow: WebSocket events (`lib/sync/`) and REST loads are written into the drift
  database (`lib/data/db/`); screens only watch database queries. The one exception is the
  text of a still-streaming run, held in memory (`liveRunsProvider`) and overlaid on the
  stored row. New UI reads from the database, not from network providers.
- Wire format is snake_case: freezed models with `field_rename: snake` (build.yaml).
  State is Riverpod 3 with no code generation.
- The backend contract is pinned: `test/fixtures/contract/contract.json` (a copy of
  `delve-backend/docs/contract.json`) is enforced by `test/contract_test.dart`. On a backend
  change: copy the file → regenerate samples with `tool/gen_contract_samples.py` (needs a
  `delve-backend` checkout with its venv active) → `contract_test` names every model/frame
  to update → raise `kMinApiRevision` in `lib/api/protocol.dart` when the app relies on a
  new revision. Unknown WS event types are kept as `UnknownEvent`, so additive backend
  changes are safe.
- Design tokens are enforced: use `Theme.of(context)`, `context.delve`, `DelveText`,
  `DelveTokens` — never raw colours or sizes. `test/theme_test.dart` checks the theme
  against `test/fixtures/design/delve_tokens.json`; replace that file when the design
  changes and the test lists what differs.
- All UI strings live in `lib/l10n/app_en.arb`.

## Files intentionally absent (do not commit)

- `android/key.properties` — release signing key; without it, builds fall back to the
  debug key.
- `android/app/google-services.json` — Firebase push config (CI writes it from the
  `GOOGLE_SERVICES_JSON` secret); without it the app builds and runs, but notifications
  are unavailable.

## Terminal tab (lib/terminal/, MainActivity.kt)

SSH via dartssh2 to the desktop's OpenSSH on port 2222 over the tailnet (the backend is not
in the path); xterm 4.0.0 draws the view. Known quirk: xterm detaches lines when a scroll
region moves, so the tmux view re-adopts the on-screen lines after every write and resize
(README, T2b) — preserve that behavior when touching terminal drawing code. The Android
side is a small method channel in `MainActivity.kt`, no plugin.
