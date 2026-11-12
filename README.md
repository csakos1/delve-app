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

- B2: the Dashboard — the connection and the Lake Balaton water level: the latest
  scheduled reading (station and lake average, the change against yesterday) and the
  week as a chart (drawn by hand: the station line with its area, the lake average
  dashed). Cards arrive as `card.new` and load over REST when the tab opens or on pull;
  the agent's own water cards stay out of the chart. Settings → Water level turns on a
  notification after each scheduled reading.

- B3: System (More → System, and a System card on the Dashboard) — Hermes (degraded with
  the reason, e.g. the disk), llama-server (state since when, model, context, slots, last
  generation speed), the run queue and the GPUs (temperature, power, memory). Stop asks
  first and says what happens: the active run is stopped, queued messages wait until
  llama-server is started again (from here, or anywhere - the server notices). The screen
  asks again every 10 s while open; `system.updated` arrives over the socket. Without the
  server's privileged helper the view says so and offers no stop/start.

- M3a: the local model (design 25) — the desktop runs one model at a time; the Model row
  on both System cards opens "Local models", the presets the desktop lists (name and
  quantization, context, size, image input, thinking; what cannot be loaded says why).
  A pick asks first (and says when a run is stopped or messages wait), then the card
  shows "switching" with the time since the desktop started. While llama-server is
  stopped a pick only changes what Start loads. A switch that failed stays as a banner
  with the reason and a command to copy until it is dismissed; when going back failed
  too, there is no Dismiss and Start is on the card. Presets are files on the desktop;
  the app never edits them.
  M3b: the chat follows the loaded model - the Usage sheet names the model of the last
  answer (and of each run when there were several), the "+" sheet offers no photo to a
  model without image input, the Thinking pill is locked on or gone when the model
  always or never thinks; a failed switch is also a notification (its own "System"
  channel, a switch in Settings → Notifications).

- B4: Schedules (More → Schedules) — the morning brief and the prompt schedules, each with
  its timing in words, next and last run, an on/off switch and Run now. The editor sets
  the timing as daily times, weekdays at a time, or plain cron (Budapest time; several
  daily times share the minute past the hour), the prompt, a new or a fixed chat and
  thinking; the brief takes only its timing. The list is kept in memory, loaded when the
  screen opens and kept current by `schedule.updated` / `schedule.deleted`. The Dashboard
  shows the latest morning brief (uptime, package updates, open incidents, llama-server,
  last boot); Settings → Morning brief turns on its notification.

- B5: Observability (More → Observability) — for 24 h, 7 d or 30 d: generation and prefill
  speed (prefill only for prompts of 500 tokens or more), queue length, approval latency
  (median per bucket), cache hit ratio, tokens per day, GPU temperature and power (from the
  server's 60 s samples, kept 30 days). The server computes the buckets (Budapest time);
  the charts are drawn by hand like the water week. Loaded when the screen opens, on a
  range chip and on pull; a failing GPU sampling is shown as a banner.

- B6: attachments — the composer's "+" (Photos, Camera, File), up to four per message.
  Photos are resized on the phone (longer side 1536 px, JPEG 85; a photo picked as a file
  counts as one) and the model sees them; other files go to the agent's inbox (≤ 20 MB).
  Each one uploads as soon as it is picked (a chip with a thumbnail, a spinner, or the
  reason it failed – a tap retries); Send binds the uploads, and only over a live
  connection. Photos show in the chat as tiles, files as chips; a tap opens a photo full
  screen or a file's details, both with "Send again" (the server copies it; the model no
  longer sees earlier photos). After 14 days the server deletes them: "No longer
  available".

- B6: Share to Delve — photos, files and text shared from other apps open a screen with
  the composer already filled (design 17): the shared items as chips that upload at once,
  the text or link (with its title) in the field. It sends to a new chat by default
  (Thinking off, as elsewhere) or to an existing one; Send opens that chat. Up to four
  items; the rest are left out with a note. The Android side is a small method channel in
  `MainActivity.kt` (no plugin): the activity is `singleTask`, keeps the share intent until
  Dart takes it, and copies the shared content into the app's cache (files over 20 MB are
  not copied). Before pairing the share waits.

- Icon and signing — the design's "App icon" (concept B, "D of depth": a D cut into four
  contour layers with the cyan cursor at the deepest point): adaptive launcher icon with
  a monochrome layer for themed icons, legacy PNGs, a white notification icon tinted with
  the accent, a dark launch window, and the mark next to "Delve" on the new chat
  (`DelveMark`, drawn from the same geometry). Release builds are signed with the key
  from `android/key.properties` when it is there (see Development); otherwise with the
  debug key.

- W3: watches — what the agent checks on a schedule for the user (listings, tickets),
  made and changed in a chat. More → Watches lists them with their state and new hits
  (design 21a); a watch shows its condition and filters, Pause / Resume / Run now, the
  hits with the judge's reason (on hold, now available) and the rejected listings
  collapsed (21b); a hit opens its link in the browser, a long press copies it. The
  Dashboard shows the newest hits (21d); a hit is a notification on its own "Watches"
  channel with Open link (21e), switched in Settings → Notifications ("Watch hits").
  New watch, Change in chat and Fix in chat open a new chat with a draft or with the
  watch hint and two examples (21g). The morning brief says when it was written late.

- T2a: the Terminal tab — SSH straight to the desktop's OpenSSH on port 2222 over the
  tailnet (the backend is not on the path), into a tmux session that also opens on the
  desktop (`tmux attach -t delve-1`). The bottom navigation is now Chats · Terminal ·
  Dashboard · More; Approvals opens from the Chats header (with the waiting count; a warn
  dot on Chats). Setup (22d/22e): the phone's own ed25519 key (secure storage) as one
  `authorized_keys` line restricted to the tailnet, host / user / port from the paired
  server, the desktop's host key in groups of four to compare, then pinned. The session
  (22a): a tab, the extra key row with sticky Ctrl / Alt, the state line (22c: connecting,
  reconnecting with backoff, disconnected, host key changed — no retry). It comes back by
  itself after the phone cut the network in the background, the keyboard returns, and the
  pty is resized once the keyboard has settled. A fingerprint unlocks the tab after
  15 minutes without input (22f). Settings → Terminal (22h): host & port, font size, the
  key line, a new key, the trusted host key and Forget.

- T2b: selection on the terminal (22j3). The view itself takes no touch; one layer reads
  them all: a drag scrolls (wheel steps for tmux), a tap brings the keyboard (and clicks
  for tmux), a long press selects the word under the finger without either. Two handles
  move the ends cell by cell; the toolbar has Copy and Send to chat (the Share to Delve
  chat picker, the selection as a code block with the cursor above it). A key or a tap
  ends the selection; scrolling keeps it, on the lines it is on — partly scrolled out it
  is cut at the pane's edge, scrolled out entirely it waits, and Copy takes all of it. It
  is drawn reversed (each cell in its text colour, the text in the background colour), as
  in Termux. xterm 4.0.0 detached the lines a scroll region moved (a selection on them was
  gone): the tmux view adopts the lines on screen again after every write and resize, and
  keeps the lines that scroll out at the top and the bottom, so they come back as the same
  lines.
  Scrolling up puts tmux in copy mode, where keys are commands: the app sees it by tmux's
  position indicator, draws the shell's cursor where the prompt went (not tmux's), and a
  key typed then is sent after a `q`, so it goes to the shell. Tab is the first extra key.
  A wheel step is one line in the app's tmux sessions: the pty command marks the session
  (`@delve`) and binds the wheel keys of the root and copy-mode tables to scroll one line
  there (the first step enters copy mode and scrolls too); the desktop's other sessions
  keep tmux's 5 lines. A line of drag is one step, so the text follows the finger; a fling
  stops below 4 lines a second instead of creeping on.
  The app's sessions have no tmux status line (`status off`; the tab bar names the
  session), and the cursor is drawn over the view, from the cell's top to as far below the
  middle of the capitals: xterm's filled the cell, so it sat low beside the text.
  The extra row has a second page, swiped to (Home End PgUp PgDn F1 F2 F3 F5 F10 Ins Del
  ⌫; two dots while swiping; it keeps its page). PgUp and PgDn page through tmux's copy mode
  after a scroll instead of leaving it. Two fingers pinch the font size, 9–20 sp in whole
  steps, with a chip of the size and the new columns × rows for a second. Bold text is
  JetBrains Mono 700. Rows whose edge cells are coloured (htop's bars) reach the screen's
  edges. Leaving copy mode with a key keeps the lines tmux has in its history (N110).

- T3: tabs, one tmux session each, each with its own SSH connection (22a). `+` opens a
  new session, `delve-N` with the smallest N not used by a tab or a session on the
  desktop; the app's sessions are made with a 10 000-line history (tmux sets a pane's
  history when the pane is made, so the session is made detached, the option set, and its
  first window replaced; then it is attached). Only the tab in front and the one left last
  stay connected, the last one for a minute; the others connect when they come to the
  front. A long press on a tab opens its menu (Rename, Close tab, Kill session…), a long
  press and a drag moves it; the tabs and their order are kept. Closing a tab only
  detaches: the session keeps running on the desktop. ⋯ → Sessions on archlinux (22g1)
  lists every tmux session there — open here as a tab, attached on the desktop or
  detached, its windows and age — opens one as a tab, renames it or kills it after asking
  (22g2); the list, rename and kill run over a connected tab, or a connection of their own
  that only trusts the pinned host key. A session started on the desktop is attached as it
  is: its status line stays and a wheel step is tmux's 5 lines (a drag follows it). With
  every tab closed the terminal offers a new session or the list.
- T4: Settings → Terminal → Keep connected in background (off by default). On, the tab
  in front stays connected while Delve is away: a foreground service with a partial wake
  lock (TerminalKeepService.kt, `specialUse`) runs while that tab is connected or
  connecting, its notification on a channel of the lowest importance (silent, no
  status-bar icon, swipeable); the connection is probed every 30 s while away, which also
  keeps the Tailscale tunnel awake (after a long sleep it took 7–17 s to come back, and a
  fresh connection had to wait for it), and a drop reconnects in the background too. Only
  the tab in front is kept; the one left last is parked. Turning it on asks Android once
  for the battery-optimization exemption (Settings shows a warning while it is missing).
  A reconnect now tries a new TCP connection every half second for up to 20 s – the first
  one through wins – and its first try shows "Reconnecting…" without a countdown.
- A connection trace for slow reconnects after a long time away. The
  terminal keeps the last 400 timed lines – the app going away and coming back, network
  changes (wifi, mobile, vpn), each attempt's steps (name lookup, TCP, host key, sign-in,
  session, first output), probes, drops and retries – with no keystrokes or output; ⋯ →
  Copy connection trace puts them on the clipboard, and each also goes to the log
  (`adb logcat -s flutter`). The dialer now looks the name up on its own (IPv4 first),
  then connects to the address.

With A6 the MVP is complete; B1 adds notifications, B2 the dashboard, B3 the system view,
B4 schedules and the morning brief, B5 observability, B6 attachments and the share
target, W3 the watches, T2a–T3 the terminal. (A home-screen widget was planned and dropped.)
Requires a server with API revision 10 or newer (model presets in `/api/v1/system`); the
terminal needs sshd on 2222 (delve-infra, installation step 19).

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
| Links | url_launcher (a watch's hits open in the browser) |
| Terminal | dartssh2 (SSH), xterm (the view), pinenacl (ed25519), local_auth (the lock) |
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
  app/dashboard.dart         water readings from the cards, the week, REST reload
  app/system.dart            the system view in memory: REST, system.updated, stop/start
  app/schedules.dart         the schedule list in memory: REST, schedule.* events
  app/cron_preset.dart       cron ↔ daily times / weekdays at a time / plain cron
  app/watches.dart           the watches and their items in memory: REST, watch.* events
  terminal/                  the phone key and pins (secrets), the SSH link (dartssh2), the
                             connection with reconnects, sticky Ctrl/Alt, the lock, the
                             tabs (terminal_tabs.dart: saved tabs, the tmux session list
                             and commands), the service (one per app) and its providers,
                             the connection trace (terminal_trace.dart)
  attachments/               pickers, photo resizing, uploads (ComposerAttachments),
                             the image cache
  share/                     Share to Delve: the method channel (share_channel.dart), the
                             waiting share, ShareHost (opens the screen)
  sync/                      WebSocket client: engine (connection, outbox, requests),
                             reducer (events → database), resync, live runs, transport
  push/                      notifications: FCM transport, controller (token, taps),
                             background handlers, notification texts (design 18)
  data/credentials.dart      token and server URL in Android secure storage
  data/db/                   drift tables and queries; store.dart: server objects → rows
  ui/chat/                   chat pieces: run rail, tool step card, composer, Markdown,
                             attachments (chips, tiles, viewer)
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
  dashboard_test.dart        water readings, the week, the brief, the Dashboard screen
  schedules_test.dart        cron presets and texts, the Schedules list and editor
  watches_test.dart          watch texts, the watch push, the Watches list and detail, the
                             Dashboard card, Settings → Watch hits
  attachments_test.dart      resizing bounds, uploads and retries, REST, the chat's "+",
                             tiles and "Send again"
  share_test.dart            shared payloads, the method channel, the Share to Delve screen
  terminal_test.dart         key line, secrets, sticky keys, the connection with a fake
                             SSH dialer (pins, refusals, reconnects, background, resize),
                             the lock and the service
  terminal_screen_test.dart  the tab: setup, trust, denied, lock, host key changed,
                             reconnecting, the extra keys, selection, Terminal settings
  terminal_tabs_test.dart    session lists, names and tmux commands, saved tabs,
                             the service's tabs: saved, new, kept / parked, closed,
                             moved, renamed, killed
  terminal_tabs_screen_test.dart  the tab bar, +, the sessions sheet, the tab menu,
                             rename, kill, the empty state, dragging a tab
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

### Release signing

Release builds use the key named in `android/key.properties` (outside the repository, like
the keystore itself – both are in `.gitignore`):

```properties
storeFile=/home/<user>/keys/delve-release.jks
storePassword=…
keyAlias=delve
keyPassword=…          # the same as storePassword for a PKCS12 keystore
```

Without the file (CI, a fresh clone) the release build is signed with the debug key. Check
the signer with `apksigner verify --print-certs <apk>` (the `keytool -printcert -jarfile`
check sees no v1 signature and prints nothing). An app signed with one key cannot be
updated by an APK signed with another: switching keys means uninstalling (and pairing
again). Keep a backup of the keystore and its password.

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
