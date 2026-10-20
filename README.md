# delve-app

Android client for **Delve**, a personal AI agent that runs on one Arch Linux desktop
(Qwen3.8-27B via llama.cpp, Hermes Agent and [`delve-backend`](https://github.com/csakos1/delve-backend)),
reached over Tailscale only.

## Status

- A1: theme, models, local database, navigation shell.
- A2: pairing (server URL + one-time code), session handling (401 → back to pairing,
  server too old → blocking screen), Settings (server, device, thinking route, versions,
  unpair).
- A3: WebSocket client — connection state machine, events into the local database,
  resume and reload, outbox, connection log (Settings → Connection).
- A4a: conversation list — newest first with preview, context fill, running / queued /
  approval markers; swipe to archive (with Undo), search, paging, empty state, first-load
  skeleton, reconnecting banner; More → Archived chats (swipe to restore).
- A4b: the chat — messages, runs on a rail (interim remarks, tool step cards in every
  state, Markdown answers), the streaming run overlaid live, failed runs with Retry,
  the composer (outbox states, Stop, queue note), context warning, new chat.
- A5a: approvals in the chat — the approval card in place of the waiting step (class,
  command verbatim, countdown to the agent's deadline, Allow once / Deny / Allow for
  session), the late-approval card once the agent stopped waiting, how an answered
  approval ended on its step. Answers go over the socket and are never queued: without
  a live connection the buttons are off.
- A5b: the Approvals tab — pending (nearest deadline first), expired in the agent but
  still approvable (late approval starts a follow-up run), recent answers with who and
  when; Allow once / Deny / ⋯ (Allow for session, Open chat), reloaded on open and on
  pull. The inbox answers over REST. In the chat, a follow-up run's prompt reads as
  "Follow-up run: approved" with its command.
- A6: Thinking — the pill in the composer (per chat, saved on the server; for a new
  chat sent with its first message), the thinking block (live clock and tokens, then
  "Thought for …" opening the reasoning); usage — the context chip in the chat top bar (ring and percent, warning
  above 75 %, the live sample while a run goes) opening the Usage sheet
  (totals, context, runs with prefill, generation and first-token time).

- B1: notifications — FCM data messages from the backend turned into Android
  notifications here: an approval ("Approval needed · <class>", the command, a countdown
  to the agent's deadline; Allow once / Deny / Open — Allow once opens the app, so a
  locked phone asks to unlock first, Deny works from the lock screen), updated when the
  agent stops waiting and removed once the approval is answered anywhere; "Run finished"
  while the app is in the background. Settings → Notifications switches (stored on the
  server per device), permission and availability banners. The socket pings every 20 s
  and closes 3 s after the app goes to the background, so the server knows when to push.
  The chat list falls back to the server's preview for chats never opened here.

With A6 the MVP is complete; B1 adds notifications; dashboard, system, schedules,
observability, attachments and the home widget follow (B2–B7). Requires a server with
API revision 3 or newer (`PATCH /api/v1/devices/me`, conversation `preview`).

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
| Markdown | flutter_markdown_plus |
| Push | firebase_messaging (data messages), flutter_local_notifications |
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
  app/chat_list.dart         conversation list: database query, paging, archive
  app/chat.dart              one chat: database query, ChatActions (send, stop, open)
  sync/                      WebSocket client: engine (connection, outbox, requests),
                             reducer (events → database), resync, live runs, transport
  push/                      notifications: FCM transport, controller (token, taps),
                             background handlers, notification texts (design 18)
  data/credentials.dart      token and server URL in Android secure storage
  data/db/                   drift tables and queries; store.dart: server objects → rows
  ui/chat/                   chat pieces: run rail, tool step card, composer, Markdown
  ui/                        shell (bottom navigation), screens, shared widgets;
                             format.dart: list times, previews, error texts
  l10n/app_en.arb            UI strings (English)
test/
  contract_test.dart         models and frames against the backend contract
  theme_test.dart            theme against the design tokens
  database_test.dart, app_test.dart, session_test.dart, rest_client_test.dart, …
  chat_list_test.dart        list query, paging, archive, the Chats screen states
  chat_screen_test.dart      the chat with a fake ChatActions: runs, steps, composer
  reducer_test.dart          recorded WebSocket conversations replayed into the database
  sync_engine_test.dart      the connection against a local fake WebSocket server
  push_test.dart             pushes → notifications, Deny in the background, the
                             controller with fakes, Settings → Notifications
  support/                   fake REST server (a dio adapter), fake WebSocket server,
                             recordings, the app harness
  fixtures/contract/         contract.json (from delve-backend), samples.json (generated)
  fixtures/design/           delve_tokens.json (from the design system)
  fixtures/ws/               WebSocket recordings (tool/ws-record.py)
tool/
  gen_contract_samples.py    regenerates samples.json with the backend serializers
  android-setup.py           one-off Android project settings
  ws-record.py               records WebSocket conversations with a backend
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
flutter gen-l10n              # after a change to lib/l10n/app_en.arb
tool/format.sh
flutter analyze
flutter test
flutter run                                                # device or emulator
```

Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`) and
`pubspec.lock` are committed; CI regenerates them and fails on any difference.

### Push (Firebase)

`android/app/google-services.json` (Firebase console → the project's Android app,
`hu.csakos.delve`) is not in the repository: keep a local copy there; CI writes it from
the `GOOGLE_SERVICES_JSON` secret. Without the file the Google Services Gradle plugin is
not applied, the app builds and runs, and Settings says it cannot receive notifications.
The server needs its own service account key (delve-backend README, "Push
notifications").

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

### WebSocket client

`lib/sync/sync_engine.dart` keeps one socket to `wss://<server>/api/v1/ws` while the app is
in the foreground (it closes 60 s after the app goes to the background; there is no
background service). States: `offline → connecting → awaitingHello → live ⇄ backoff`, plus
`authFailed` (close 4401: the token is forgotten and the app goes back to pairing).

- **Resume:** `hello {last_seq, epoch}` from `sync_state`. A new epoch (server restart),
  `resync_required` or a first connection reloads over REST instead (`sync/resync.dart`:
  conversations, run queue, approvals, and every conversation that looks unfinished),
  written in one transaction with the new position.
- **Events** are written in batches (80 ms) in one transaction together with `last_seq`,
  so after a crash nothing is lost or applied twice; the reducer (`sync/reducer.dart`)
  only upserts. Text deltas, interim remarks and context samples of a running run stay in
  memory (`liveRunsProvider`) until the final message arrives.
- **Reconnects:** backoff 1 → 30 s with jitter, at once after a network change; 45 s
  without a frame (the server sends a keepalive every 20 s) counts as a dead socket.
- **Outbox:** `sendMessage` stores the message first and sends it with its `client_msg_id`
  once live; unanswered sends are repeated with the same id (the backend is idempotent).
  Approval answers are never queued: without a live socket they fail with `NotConnected`.
- **Connection log:** the last 500 entries in the database (Settings → Connection), kept
  across unpairing.

#### Recordings

`test/fixtures/ws/*.jsonl` are conversations recorded with `tool/ws-record.py`; the
reducer tests replay them and compare the database with what the server said last. The
committed ones come from `delve-backend` with its fixture-replaying fake Hermes. To record
against the development backend (never production):

```sh
cd ~/delve-backend && . .venv/bin/activate && set -a && . ~/.config/delve/dev.env && set +a
DELVE_TOKEN=$(cat ~/.config/delve/dev.token) python ../delve-app/tool/ws-record.py \
  --url http://127.0.0.1:8700 --note "dev backend, Qwen3.8-27B"
```

The script redacts the token, the home directory, the user name and tailnet names; any
approval a scenario does not expect is denied. `late` (about six minutes) is only recorded
when named.

### Design tokens

The theme follows the Delve design system (Direction C, "Depth", no glow).
`test/fixtures/design/delve_tokens.json` is the design's Flutter token export; when the
design changes, replace it and `flutter test test/theme_test.dart` lists what differs.
Widgets use `Theme.of(context)`, `context.delve` (`DelveColors`), `DelveText` and
`DelveTokens` — never raw colours or sizes.

## CI

`.github/workflows/ci.yml`: gitleaks; `pub get`, generated code current, format,
`flutter analyze`, `flutter test`; a debug APK as a build artifact (with push when the
`GOOGLE_SERVICES_JSON` secret is set).

## Pre-commit hook

`.githooks/pre-commit` is the same guard as in `delve-infra` and `delve-backend`
(`git config core.hooksPath .githooks`).

## License

MIT. The bundled fonts are under the SIL Open Font License 1.1 (`assets/fonts/OFL-*.txt`);
the static instances were cut from the variable fonts in the Google Fonts repository.
