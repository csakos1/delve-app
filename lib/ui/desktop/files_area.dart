import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../screens/file_preview_screen.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'list_area.dart';
import 'panes.dart';

/// The desktop's file selection (L2c4c): the selected rows of a folder, the
/// anchor of a Shift range and the row the keys move from. A pick of
/// another folder counts as nothing.
@immutable
class FilesPick {
  const FilesPick({
    this.folder,
    this.paths = const {},
    this.anchor,
    this.cursor,
  });

  final String? folder;
  final Set<String> paths;

  /// Where a Shift range starts.
  final String? anchor;

  /// The row J / K and the arrows move from (the last one clicked or
  /// reached).
  final String? cursor;

  /// The paths picked in [folder] (none for another folder).
  Set<String> of(String? folder) =>
      folder != null && folder == this.folder ? paths : const {};
}

class FilesPicks extends Notifier<FilesPick> {
  @override
  FilesPick build() => const FilesPick();

  /// A plain click: this row alone.
  void only(String folder, String path) => state = FilesPick(
    folder: folder,
    paths: {path},
    anchor: path,
    cursor: path,
  );

  /// Ctrl+click: in or out of the selection.
  void toggle(String folder, String path) {
    final now = {...state.of(folder)};
    if (!now.remove(path)) now.add(path);
    state = FilesPick(folder: folder, paths: now, anchor: path, cursor: path);
  }

  /// Shift+click (and Shift+↓ / ↑): every row from the anchor to [path].
  void range(String folder, List<RemoteEntry> order, String path) {
    final anchor = state.folder == folder ? state.anchor : null;
    final a = anchor == null ? -1 : order.indexWhere((e) => e.path == anchor);
    final b = order.indexWhere((e) => e.path == path);
    if (b < 0) return;
    if (a < 0) return only(folder, path);
    final lo = math.min(a, b);
    final hi = math.max(a, b);
    state = FilesPick(
      folder: folder,
      paths: {for (var i = lo; i <= hi; i++) order[i].path},
      anchor: anchor,
      cursor: path,
    );
  }

  /// Ctrl+A.
  void all(String folder, List<RemoteEntry> order) => state = FilesPick(
    folder: folder,
    paths: {for (final e in order) e.path},
    anchor: state.folder == folder ? state.anchor : null,
    cursor: state.folder == folder ? state.cursor : null,
  );

  /// Esc, and every action that ends with the selection.
  void clear() {
    if (state.paths.isEmpty) return;
    state = FilesPick(folder: state.folder);
  }

  /// J / K, ↓ / ↑ ([extend]: with Shift): the row [by] from the cursor (the
  /// first or the last row without one); its index, to scroll to.
  int? step(
    String folder,
    List<RemoteEntry> order,
    int by, {
    bool extend = false,
  }) {
    if (order.isEmpty) return null;
    final cursor = state.folder == folder ? state.cursor : null;
    final at = cursor == null ? -1 : order.indexWhere((e) => e.path == cursor);
    final next = at < 0
        ? (by > 0 ? 0 : order.length - 1)
        : (at + by).clamp(0, order.length - 1);
    final path = order[next].path;
    if (extend) {
      if (state.folder != folder || state.anchor == null) {
        state = FilesPick(
          folder: folder,
          paths: state.of(folder),
          anchor: cursor ?? path,
          cursor: cursor,
        );
      }
      range(folder, order, path);
    } else {
      only(folder, path);
    }
    return next;
  }
}

final filesPickProvider = NotifierProvider<FilesPicks, FilesPick>(
  FilesPicks.new,
);

/// The Files inspector's tabs (design 27): the file itself, and its facts.
enum FileInspectorTab { preview, info }

class FileInspectorTabs extends Notifier<FileInspectorTab> {
  @override
  FileInspectorTab build() => FileInspectorTab.preview;

  void show(FileInspectorTab tab) => state = tab;

  /// Ctrl+].
  void next() => state = FileInspectorTab
      .values[(state.index + 1) % FileInspectorTab.values.length];
}

final fileInspectorTabProvider =
    NotifierProvider<FileInspectorTabs, FileInspectorTab>(
      FileInspectorTabs.new,
    );

/// The Files area in the desktop layout (27W-13; only with Settings →
/// Desktop tools on): the places and the transfers in the list column, the
/// folder as a table in the content (or a file's preview pushed over it),
/// Preview / Info in the inspector.
class FilesArea extends ConsumerStatefulWidget {
  const FilesArea({super.key, required this.content, required this.navigator});

  final Widget content;

  /// The area's own navigator: a place clicked while a preview is open
  /// leaves the preview first (an editor with changes asks).
  final GlobalKey<NavigatorState> navigator;

  @override
  ConsumerState<FilesArea> createState() => _FilesAreaState();
}

class _FilesAreaState extends ConsumerState<FilesArea> {
  late final FilesService _service;

  @override
  void initState() {
    super.initState();
    // read now: dispose must not be the first to touch ref
    _service = ref.read(filesServiceProvider);
  }

  @override
  void dispose() {
    // the inspector's image previews leave with the area (NL23)
    unawaited(_service.clearPreviews());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListArea(
    area: DesktopArea.files.name,
    // the content is never empty (the folder, or why it is not there)
    selected: 'files',
    list: FilesPlacesPane(navigator: widget.navigator),
    content: widget.content,
    inspector: const FileInspector(),
  );
}

/// The list column: Home, Downloads, Documents, the file system and the
/// trash; at the foot the transfers, while there are any.
class FilesPlacesPane extends ConsumerWidget {
  const FilesPlacesPane({super.key, required this.navigator});

  final GlobalKey<NavigatorState> navigator;

  /// Opens [path] in the table, after leaving a preview (if it lets go).
  Future<void> _go(FilesService service, String path) async {
    final nav = navigator.currentState;
    if (nav != null && nav.canPop()) {
      await nav.maybePop();
      await Future<void>.delayed(Duration.zero);
      // an editor with changes asks first; it stays when told to
      if (nav.mounted && nav.canPop()) return;
    }
    await service.open(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final service = ref.watch(filesServiceProvider);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final home = service.home;
        final path = service.path;
        Widget place(String id, IconData icon, String label, String to) =>
            SectionRow(
              key: Key('files.place.$id'),
              icon: icon,
              label: label,
              trailing: id == 'root' ? '/' : null,
              selected: path == to,
              onTap: () => unawaited(_go(service, to)),
            );
        return TopLevelPage(
          key: const Key('files.places'),
          title: l.navFiles,
          background: cs.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  children: [
                    if (home != null) ...[
                      place('home', FileIcons.home, l.filesQuickHome, home),
                      place(
                        'downloads',
                        FileIcons.download,
                        l.filesQuickDownloads,
                        joinPath(home, 'Downloads'),
                      ),
                      place(
                        'documents',
                        FileIcons.documents,
                        l.filesQuickDocuments,
                        joinPath(home, 'Documents'),
                      ),
                    ],
                    place('root', FileIcons.root, l.desktopFilesRoot, '/'),
                    SectionRow(
                      key: const Key('files.place.trash'),
                      icon: FileIcons.trash,
                      label: l.filesTrash,
                      selected: false,
                      // over the folder, as the phone's menu opens it
                      onTap: () =>
                          unawaited(context.push<void>(Routes.filesTrash)),
                    ),
                  ],
                ),
              ),
              if (service.transfers.isNotEmpty)
                _TransfersFoot(
                  service: service,
                  onOpenFolder: (dir) => unawaited(_go(service, dir)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The transfers at the foot of the list column (the phone's Transfers
/// sheet): newest first, at most 240 px of rows, Clear finished.
class _TransfersFoot extends StatelessWidget {
  const _TransfersFoot({required this.service, required this.onOpenFolder});

  final FilesService service;
  final ValueChanged<String> onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final list = service.transfers.reversed.toList();
    final active = list.where((t) => t.active).length;
    final done = list.where((t) => t.state == TransferState.done).length;
    return Column(
      key: const Key('files.transfers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: cs.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 6, 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.filesTransfers.toUpperCase(),
                      style: context.text.labelSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: d.textMuted,
                      ),
                    ),
                    Text(
                      l.filesTransfersSummary(active, done),
                      style: DelveDesktopText.rowSecondary.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (list.any((t) => !t.active))
                TextButton(
                  key: const Key('files.clearFinished'),
                  onPressed: service.clearFinished,
                  child: Text(l.filesClearFinished),
                ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: DelveDesktop.filesTransfersMax,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 6),
            children: [
              for (final t in list)
                TransferRow(
                  key: Key('files.transfer.${t.id}'),
                  transfer: t,
                  now: DateTime.now(),
                  onCancel: () => service.cancel(t),
                  onOpen: () => t.toDesktop
                      ? onOpenFolder(parentPath(t.remotePath))
                      : unawaited(service.openDownload(t)),
                  onRetry: () => service.retryTransfer(t),
                  home: service.home,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Files inspector (27W-13): Preview · Info of the one selected file;
/// with a folder or several items selected, or none, their Info (none: the
/// folder on screen).
class FileInspector extends ConsumerWidget {
  const FileInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final service = ref.watch(filesServiceProvider);
    final pick = ref.watch(filesPickProvider);
    final tab = ref.watch(fileInspectorTabProvider);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final picked = pick.of(service.path);
        final items = [
          for (final e in service.entries ?? const <RemoteEntry>[])
            if (picked.contains(e.path)) e,
        ];
        final one = items.length == 1 ? items.single : null;
        final canPreview = one != null && !one.isDir;
        final shown = canPreview ? tab : FileInspectorTab.info;
        void show(FileInspectorTab t) =>
            ref.read(fileInspectorTabProvider.notifier).show(t);
        return Column(
          key: const Key('files.inspector'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: DelveDesktop.paneHeader,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    if (canPreview)
                      InspectorTab(
                        key: const Key('files.inspector.tab.preview'),
                        label: l.filesActPreview,
                        selected: shown == FileInspectorTab.preview,
                        onTap: () => show(FileInspectorTab.preview),
                      ),
                    InspectorTab(
                      key: const Key('files.inspector.tab.info'),
                      label: l.desktopFileInfo,
                      selected: shown == FileInspectorTab.info,
                      onTap: () => show(FileInspectorTab.info),
                    ),
                    const Spacer(),
                    const InspectorOverlayClose(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: switch (shown) {
                FileInspectorTab.preview => FilePreviewPane(
                  key: ValueKey('files.preview.${one!.path}'),
                  entry: one,
                  service: service,
                ),
                FileInspectorTab.info => _InfoPane(
                  service: service,
                  items: items,
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// The Preview tab: an image (fetched like the preview page's), the start
/// of a text file, or what the file is with Open. Waits a moment before it
/// fetches, so stepping through the rows with J / K does not fetch each.
class FilePreviewPane extends StatefulWidget {
  const FilePreviewPane({
    super.key,
    required this.entry,
    required this.service,
  });

  final RemoteEntry entry;
  final FilesService service;

  @override
  State<FilePreviewPane> createState() => _FilePreviewPaneState();
}

class _FilePreviewPaneState extends State<FilePreviewPane> {
  /// Up to this much of a text file is drawn (the rest is in the preview
  /// page).
  static const _textMax = 16 * 1024;

  Timer? _wait;
  Future<Object?>? _load;

  PreviewKind get _kind => previewKindOf(widget.entry);

  @override
  void initState() {
    super.initState();
    if (_kind == PreviewKind.image || _kind == PreviewKind.text) {
      _wait = Timer(DelveDesktop.filesPreviewDelay, () {
        if (!mounted) return;
        setState(() {
          _load = _kind == PreviewKind.image
              ? widget.service.fetchPreview(
                  widget.entry,
                  cancelled: () => !mounted,
                )
              : widget.service.readText(widget.entry);
        });
      });
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  void _open() => openFilePreview(context, widget.service, widget.entry);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final e = widget.entry;
    final load = _load;
    final Widget body;
    if (_kind == PreviewKind.pdf || _kind == PreviewKind.none) {
      body = _Facts(entry: e, onOpen: _kind == PreviewKind.pdf ? _open : null);
    } else if (load == null) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else {
      body = FutureBuilder<Object?>(
        future: load,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Facts(
              entry: e,
              onOpen: _open,
              note: l.desktopFilePreviewFailed('${snap.error}'),
            );
          }
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return switch (snap.data) {
            final File f => GestureDetector(
              key: const Key('files.preview.image'),
              onDoubleTap: _open,
              child: Image.file(
                f,
                fit: BoxFit.contain,
                cacheWidth: 960,
                errorBuilder: (_, _, _) => _Facts(entry: e, onOpen: _open),
              ),
            ),
            (final String text, final bool cut) => _TextHead(
              text: text.length > _textMax ? text.substring(0, _textMax) : text,
              more: cut || text.length > _textMax,
              onOpen: _open,
            ),
            // not text after all: what it is
            _ => _Facts(entry: e, note: l.filesPreviewBinary),
          };
        },
      );
    }
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DelveDesktop.cardRadius),
                child: ColoredBox(
                  color: cs.surfaceContainerLowest,
                  child: body,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              e.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
            Text(
              [
                if (e.size != null) sizeText(e.size!),
                if (e.modified != null) fileTime(e.modified!, DateTime.now()),
              ].join(' · '),
              style: DelveDesktopText.rowSecondary.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextHead extends StatelessWidget {
  const _TextHead({
    required this.text,
    required this.more,
    required this.onOpen,
  });

  final String text;
  final bool more;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: SingleChildScrollView(
          key: const Key('files.preview.text'),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 40),
          child: Text(
            text,
            style: DelveText.monoSmall.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ),
      Positioned(
        right: 8,
        bottom: 8,
        child: FilledButton.tonal(
          key: const Key('files.preview.open'),
          onPressed: onOpen,
          child: Text(
            more
                ? AppLocalizations.of(context).desktopFileOpenWhole
                : AppLocalizations.of(context).filesActOpen,
          ),
        ),
      ),
    ],
  );
}

/// A file without a picture: its icon, what it is, Open where it opens.
class _Facts extends StatelessWidget {
  const _Facts({required this.entry, this.onOpen, this.note});

  final RemoteEntry entry;
  final VoidCallback? onOpen;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FileTile(entry: entry),
            const SizedBox(height: 10),
            Text(
              note ?? l.desktopFileNoPreview,
              key: const Key('files.preview.none'),
              textAlign: TextAlign.center,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (onOpen != null) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                key: const Key('files.preview.open'),
                onPressed: onOpen,
                child: Text(l.filesActOpen),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Info tab: one item's facts; several items' count and size; nothing
/// selected: the folder on screen.
class _InfoPane extends StatelessWidget {
  const _InfoPane({required this.service, required this.items});

  final FilesService service;
  final List<RemoteEntry> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final home = service.home;
    final rows = <Widget>[];
    void row(String key, String label, String? value, {bool mono = false}) {
      if (value == null || value.isEmpty) return;
      rows.add(_InfoRow(id: key, label: label, value: value, mono: mono));
    }

    final String title;
    Widget? tile;
    if (items.length == 1) {
      final e = items.single;
      title = e.name;
      tile = FileTile(entry: e);
      if (e.isDir) {
        final n = service.countOf(e);
        row('items', l.desktopFileItems, n == null ? null : itemsText(l, n));
      } else if (e.size != null) {
        row('size', l.filesSortSize, '${sizeText(e.size!)} · ${e.size} B');
      }
      if (e.modified case final m?) {
        row('modified', l.filesSortDate, _full(m));
      }
      row('permissions', l.desktopFilePermissions, e.modeText, mono: true);
      row('owner', l.desktopFileOwner, e.owner);
      row(
        'where',
        l.desktopFileWhere,
        tildePath(parentPath(e.path), home),
        mono: true,
      );
      if (e.isLink) {
        row(
          'link',
          l.desktopFileLink,
          e.linkBroken ? l.filesBrokenLink(e.link ?? '?') : e.link,
          mono: true,
        );
      }
    } else if (items.length > 1) {
      title = l.filesSelected(items.length);
      final size = items.fold<int>(
        0,
        (n, e) => e.kind == EntryKind.file && !e.isLink ? n + (e.size ?? 0) : n,
      );
      row(
        'items',
        l.desktopFileItems,
        [
          l.desktopFileFolders(items.where((e) => e.isDir).length),
          l.desktopFileFiles(items.where((e) => !e.isDir).length),
        ].join(' · '),
      );
      if (size > 0) row('size', l.filesSortSize, sizeText(size));
      final p = service.path;
      if (p != null) {
        row('where', l.desktopFileWhere, tildePath(p, home), mono: true);
      }
    } else {
      final p = service.path;
      title = p == null
          ? l.navFiles
          : p == '/'
          ? '/'
          : baseName(p);
      if (service.entries != null) {
        row(
          'items',
          l.desktopFileItems,
          service.hiddenCount > 0 && !service.showHidden
              ? l.filesShownHidden(
                  (service.totalCount - service.hiddenCount).toString(),
                  service.hiddenCount.toString(),
                )
              : itemsText(l, service.totalCount),
        );
      }
      if (p != null) {
        row('where', l.desktopFilePath, tildePath(p, home), mono: true);
      }
      final m = service.mountHere;
      if (m != null) {
        row(
          'fs',
          l.desktopFileFilesystem,
          [
            m.fsType,
            if (m.size != null) sizeText(m.size!),
            if (m.usedFraction case final f?) l.filesUsedPct((f * 100).round()),
          ].join(' · '),
        );
      }
    }
    return ColoredBox(
      key: Key('files.info.pane.${items.isEmpty ? 'folder' : 'items'}'),
      color: context.colors.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              if (tile != null) ...[tile, const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  static String _full(DateTime at) =>
      DateFormat('y-MM-dd HH:mm').format(at.toLocal());
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.id,
    required this.label,
    required this.value,
    required this.mono,
  });

  /// The row's key: `files.info.<id>`.
  final String id;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final d = context.delve;
    return Padding(
      key: Key('files.info.$id'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.text.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: d.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: mono
                ? DelveText.monoSmall.copyWith(color: context.colors.onSurface)
                : DelveDesktopText.rowSecondary.copyWith(
                    color: context.colors.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}

/// The table's 30 px header: Name · Size · Modified; a click sorts by the
/// column (again: the other way), the sorted one shows its arrow.
class FilesTableHeader extends StatelessWidget {
  const FilesTableHeader({
    super.key,
    required this.sort,
    required this.ascending,
    required this.onSort,
  });

  final SortKey sort;
  final bool ascending;
  final ValueChanged<SortKey> onSort;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    Widget column(SortKey key, String label, {bool end = false}) {
      final on = key == sort;
      final style = DelveDesktopText.meta.copyWith(
        color: on ? cs.onSurface : d.textMuted,
      );
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: Key('files.col.${key.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onSort(key),
          child: Row(
            mainAxisAlignment: end
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (on) ...[
                const SizedBox(width: 3),
                SymbolIcon(
                  ascending ? FileIcons.arrowUp : FileIcons.arrowDown,
                  size: 13,
                  color: cs.onSurface,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      height: DelveDesktop.filesHeaderRow,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 25),
          Expanded(child: column(SortKey.name, l.filesSortName)),
          SizedBox(
            width: DelveDesktop.filesSizeColumn,
            child: column(SortKey.size, l.filesSortSize, end: true),
          ),
          SizedBox(
            width: DelveDesktop.filesDateColumn,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: column(SortKey.modified, l.desktopFileModified),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 32 px table row: icon 16 · name (middle ellipsis) · size or item count
/// · modified. A click selects (Ctrl / Shift: several), a second click on
/// the same row in the double-click time opens it, right-click: its menu.
class FilesTableRow extends StatefulWidget {
  const FilesTableRow({
    super.key,
    required this.entry,
    required this.size,
    required this.modified,
    required this.selected,
    required this.onTap,
    required this.onMenu,
    this.locked = false,
  });

  final RemoteEntry entry;
  final String size;
  final String modified;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  /// Right-click at this global position.
  final ValueChanged<Offset> onMenu;

  @override
  State<FilesTableRow> createState() => _FilesTableRowState();
}

class _FilesTableRowState extends State<FilesTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final d = context.delve;
    final e = widget.entry;
    final type = fileTypeOf(e);
    final dim = e.hidden || widget.locked;
    final meta = DelveDesktopText.rowSecondary.copyWith(
      color: d.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          key: Key('files.row.${e.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onSecondaryTapUp: (t) => widget.onMenu(t.globalPosition),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? cs.surfaceContainerHigh
                  : _hover
                  ? cs.surfaceContainerLow
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                SymbolIcon(
                  widget.locked
                      ? FileIcons.lock
                      : e.isLink
                      ? FileIcons.link
                      : fileIcon(type),
                  size: 16,
                  filled: type == FileType.folder,
                  color: dim ? d.textMuted : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: MiddleEllipsis(
                    e.name,
                    style: DelveDesktopText.rowSecondary.copyWith(
                      color: dim ? cs.onSurfaceVariant : cs.onSurface,
                      fontWeight: widget.selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  width: DelveDesktop.filesSizeColumn,
                  child: Text(
                    widget.size,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: meta,
                  ),
                ),
                SizedBox(
                  width: DelveDesktop.filesDateColumn,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      widget.modified,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: meta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
