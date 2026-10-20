# delve-app

Android client for **Delve**, a personal AI agent that runs on one Arch Linux desktop
(Qwen3.8-27B via llama.cpp, Hermes Agent and [`delve-backend`](https://github.com/csakos1/delve-backend)),
reached over Tailscale only.

## Status

- A1: theme, models, local database, navigation shell.
- A2: pairing (server URL + one-time code), session handling (401 → back to pairing,
  server too old → blocking screen), Settings (server, device, thinking route, versions,
  unpair).

The WebSocket client, chat and approvals follow in A3–A6. Requires a server with
API revision 2 or newer (`DELETE /api/v1/devices/me` for unpairing).

## Stack

| Concern | Choice |
|---|---|
| Flutter | **3.41.9** (Dart 3.11), pinned in CI |
| State | Riverpod 3 (no code generation) |
| Models | freezed + json_serializable, snake_case on the wire |
| Local data | drift — the single source of truth for the UI |
| Navigation | go_router, `StatefulShellRoute` for the bottom navigation |
| Network | dio (REST), web_socket_channel (events) |
| Secrets | flutter_secure_storage (device token) |
| Icons | Material Symbols Rounded (`material_symbols_icons`) |
| Fonts | Jost, Inter, JetBrains Mono — bundled, SIL OFL 1.1 |

Data flow: WebSocket events and REST loads are written to the drift database; screens only
watch database queries. The text of a run that is still streaming is the one exception: it
is held in memory and overlaid on the stored message until the run finishes.

## Layout

```
lib/
  main.dart, app/            app widget, router, providers
  theme/                     design tokens: colours, text styles, spacing, ThemeData
  api/models/                conversation, message, run, approval, tool step, server info
  api/events.dart            WebSocket frames → sealed ServerEvent / ConnectionFrame
  api/protocol.dart          REST routes, client frames, minimum API revision
  api/rest_client.dart       REST client (dio); api_error.dart maps every failure
  app/session.dart           paired / unpaired / server-too-old, credentials, 401 handling
  app/pairing*.dart          pairing flow, URL and code checks
  data/credentials.dart      token and server URL in Android secure storage
  data/db/                   drift tables and queries
  ui/                        shell (bottom navigation), screens, shared widgets
  l10n/app_en.arb            UI strings (English)
test/
  contract_test.dart         models and frames against the backend contract
  theme_test.dart            theme against the design tokens
  database_test.dart, app_test.dart, session_test.dart, rest_client_test.dart, …
  support/                   fake server (a dio adapter) and the app harness
  fixtures/contract/         contract.json (from delve-backend), samples.json (generated)
  fixtures/design/           delve_tokens.json (from the design system)
tool/
  gen_contract_samples.py    regenerates samples.json with the backend serializers
  android-setup.py           one-off Android project settings
  format.sh                  dart format for hand-written files
```

## Development

First checkout of an empty repository:

```sh
flutter create --org hu.csakos --project-name delve --platforms android .
# then add this repository's files on top, and:
rm -f test/widget_test.dart
python3 tool/android-setup.py      # label, INTERNET, no cleartext, no backup
```

Every change:

```sh
flutter pub get
dart run build_runner build   # freezed, json, drift
tool/format.sh
flutter analyze
flutter test
flutter run                                                # device or emulator
```

Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`) and
`pubspec.lock` are committed; CI regenerates them and fails on any difference.

### Backend contract

`test/fixtures/contract/contract.json` is a copy of `delve-backend/docs/contract.json`.
When the backend changes it:

1. copy the new file here;
2. regenerate the samples from a `delve-backend` checkout with its venv active:
   `python ../delve-app/tool/gen_contract_samples.py > ../delve-app/test/fixtures/contract/samples.json`
   (add sample values for new keys to the script);
3. `flutter test test/contract_test.dart` names every model, event or frame to update;
4. raise `kMinApiRevision` (`lib/api/protocol.dart`) when the app starts to rely on the
   new revision.

Unknown event types are kept as `UnknownEvent`, so an additive backend change does not
break an older app.

### Design tokens

The theme follows the Delve design system (Direction C, "Depth", no glow).
`test/fixtures/design/delve_tokens.json` is the design's Flutter token export; when the
design changes, replace it and `flutter test test/theme_test.dart` lists what differs.
Widgets use `Theme.of(context)`, `context.delve` (`DelveColors`), `DelveText` and
`DelveTokens` — never raw colours or sizes.

## CI

`.github/workflows/ci.yml`: gitleaks; `pub get`, generated code current, format,
`flutter analyze`, `flutter test`; a debug APK as a build artifact.

## Pre-commit hook

`.githooks/pre-commit` is the same guard as in `delve-infra` and `delve-backend`
(`git config core.hooksPath .githooks`).

## License

MIT. The bundled fonts are under the SIL Open Font License 1.1 (`assets/fonts/OFL-*.txt`);
the static instances were cut from the variable fonts in the Google Fonts repository.
