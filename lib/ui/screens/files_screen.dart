import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../attachments/picker.dart';
import '../../files/device_files.dart';
import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_lock.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../theme/delve_theme.dart';
import '../widgets/files_dialogs.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/skeleton.dart';
import '../widgets/status_ui.dart';
import 'file_preview_screen.dart';

/// 23 Files: the desktop's filesystem as `csakos` sees it, over SFTP on the
/// terminal's key and host, behind the terminal's lock (F1: browse,
/// download, preview; F2a: upload, new folder, rename, trash).
class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with WidgetsBindingObserver {
  late final FilesService _service = ref.read(filesServiceProvider);
  late final TerminalService _terminal = ref.read(terminalServiceProvider);
  StreamSubscription<Transfer>? _finished;
  bool _visible = false;
  bool _promptLock = true;
  bool _unlocking = false;
  String? _unlockProblem;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _finished = _service.finished.listen(_onFinished);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      if (visible) _promptLock = true;
      _service.setVisible(visible: visible);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _service.setForeground(foreground: true);
        if (mounted) setState(() => _promptLock = true);
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _service.setForeground(foreground: false);
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_finished?.cancel());
    _tick?.cancel();
    super.dispose();
  }

  void _onFinished(Transfer t) {
    if (!mounted || !_visible) return;
    final l = AppLocalizations.of(context);
    final m = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (t.upload) {
      final dir = parentPath(t.remotePath);
      if (t.state == TransferState.done) {
        m.showSnackBar(
          SnackBar(
            key: const Key('files.uploaded'),
            content: Row(
              children: [
                SymbolIcon(
                  FileIcons.done,
                  filled: true,
                  size: DelveTokens.iconMd,
                  color: context.delve.okFg,
                ),
                const SizedBox(width: DelveTokens.space2),
                Expanded(
                  child: Text(l.filesUploaded(tildePath(dir, _service.home))),
                ),
              ],
            ),
            action: _service.path == dir
                ? null
                : SnackBarAction(
                    label: l.filesShowFolder,
                    onPressed: () => _open(dir),
                  ),
          ),
        );
      } else {
        m.showSnackBar(
          SnackBar(
            content: Text(l.filesUploadFailedFile(t.name, t.error ?? '')),
          ),
        );
      }
      return;
    }
    if (t.state == TransferState.done) {
      m.showSnackBar(
        SnackBar(
          key: const Key('files.saved'),
          content: Row(
            children: [
              SymbolIcon(
                FileIcons.done,
                filled: true,
                size: DelveTokens.iconMd,
                color: context.delve.okFg,
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(child: Text(l.filesSaved(kDownloadFolder))),
            ],
          ),
          action: SnackBarAction(
            label: l.filesOpen,
            onPressed: () => unawaited(_openDownload(t)),
          ),
        ),
      );
    } else {
      m.showSnackBar(
        SnackBar(content: Text(l.filesDownloadFailed(t.name, t.error ?? ''))),
      );
    }
  }

  Future<void> _openDownload(Transfer t) async {
    final ok = await _service.openDownload(t);
    if (ok || !mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.filesNoApp)));
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _unlocking = true;
      _unlockProblem = null;
    });
    final out = await _terminal.unlock(l.filesUnlockReason);
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      _unlockProblem = out.result == UnlockResult.failed
          ? l.termUnlockFailed(out.detail ?? '')
          : null;
    });
    if (!_terminal.lock.locked) unawaited(_service.start());
  }

  // ------------------------------------------------------------ actions

  void _open(String path) => unawaited(_service.open(path));

  void _tapRow(RemoteEntry e) {
    if (e.isDir) {
      unawaited(_service.enter(e));
      return;
    }
    if (previewKindOf(e) != PreviewKind.none) {
      _preview(e);
      return;
    }
    _actions(e);
  }

  /// An image opens with the folder's other images to swipe through (in the
  /// list's order); a text file opens alone.
  void _preview(RemoteEntry e) {
    _terminal.lock.keepAlive();
    final images = previewKindOf(e) == PreviewKind.image
        ? [
            for (final x in _service.entries ?? const <RemoteEntry>[])
              if (previewKindOf(x) == PreviewKind.image) x,
          ]
        : const <RemoteEntry>[];
    final at = images.indexWhere((x) => x.path == e.path);
    unawaited(
      context.push(
        Routes.filePreview,
        extra: at < 0
            ? FilePreviewArgs([e])
            : FilePreviewArgs(images, index: at),
      ),
    );
  }

  void _download(RemoteEntry e) => _service.download(e);

  Future<void> _copyPath(RemoteEntry e) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: e.path));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.filesPathCopied)));
  }

  void _snack(String text, {SnackBarAction? action, Key? key}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(key: key, content: Text(text), action: action));
  }

  /// The folder on screen as the upload sheet names it.
  String _folderName(String dir) => dir == _service.home
      ? AppLocalizations.of(context).filesQuickHome
      : dir == '/'
      ? '/'
      : baseName(dir);

  Future<void> _upload() async {
    final dir = _service.path;
    if (dir == null) return;
    _terminal.lock.keepAlive();
    final picked = await pickForUpload(
      context,
      ref.read(attachmentPickerProvider),
      folder: _folderName(dir),
      path: tildePath(dir, _service.home),
    );
    if (picked == null) return;
    if (!mounted) return;
    await uploadAsking(context, _service, dir, picked);
  }

  Future<void> _newFolder() async {
    final dir = _service.path;
    if (dir == null) return;
    _terminal.lock.keepAlive();
    final l = AppLocalizations.of(context);
    await showNameDialog(
      context,
      title: l.filesNewFolder,
      action: l.filesCreate,
      submit: (name) async {
        try {
          await _service.makeFolder(name, dir: dir);
          return null;
        } on Exception catch (e) {
          return writeErrorText(l, e);
        }
      },
    );
  }

  Future<void> _rename(RemoteEntry e) async {
    _terminal.lock.keepAlive();
    final l = AppLocalizations.of(context);
    await showNameDialog(
      context,
      title: l.filesRename,
      action: l.filesRenameAction,
      initial: e.name,
      submit: (name) async {
        try {
          await _service.renameEntry(e, name);
          return null;
        } on Exception catch (err) {
          return writeErrorText(l, err);
        }
      },
    );
  }

  Future<void> _toTrash(RemoteEntry e) async {
    final l = AppLocalizations.of(context);
    try {
      final item = await _service.moveToTrash(e);
      _snack(
        l.filesTrashed(e.name),
        key: const Key('files.trashed'),
        action: SnackBarAction(
          label: l.filesUndo,
          onPressed: () => unawaited(_undoTrash(item)),
        ),
      );
    } on NoTrash {
      if (mounted) await _deleteForever(e, otherFs: true);
    } on Exception catch (err) {
      _snack(l.filesTrashFailed(writeErrorText(l, err)));
    }
  }

  Future<void> _undoTrash(TrashItem item) async {
    final l = AppLocalizations.of(context);
    try {
      await _service.restore(item, onConflict: ConflictChoice.keepBoth);
    } on Exception catch (err) {
      _snack(l.trashRestoreFailed(writeErrorText(l, err)));
    }
  }

  /// 23j: no trash (outside home, or another filesystem inside it).
  Future<void> _deleteForever(RemoteEntry e, {bool otherFs = false}) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDeleteForever(
      context,
      what: [
        tildePath(e.path, _service.home),
        if (!e.isDir && e.size != null) sizeText(e.size!),
      ].join(' · '),
      body: otherFs ? l.filesNoTrashOtherFs : l.filesNoTrashBody,
    );
    if (!ok || !mounted) return;
    try {
      await _service.deletePermanently(e);
      _snack(l.filesDeleted(e.name));
    } on Exception catch (err) {
      _snack(l.filesDeleteFailed(writeErrorText(l, err)));
    }
  }

  void _actions(RemoteEntry e) {
    _terminal.lock.keepAlive();
    final l = AppLocalizations.of(context);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        // over the shell's snackbar (Moved to trash · Undo) and the nav
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          Widget row(
            String key,
            IconData icon,
            String label,
            VoidCallback onTap, {
            String? hint,
            bool alert = false,
          }) => ListTile(
            key: Key('files.act.$key'),
            minTileHeight: DelveTokens.touchTarget,
            leading: SymbolIcon(
              icon,
              size: 22,
              color: alert ? ctx.delve.alertFg : ctx.colors.onSurfaceVariant,
            ),
            title: Text(
              label,
              style: ctx.text.bodyLarge!.copyWith(
                color: alert ? ctx.delve.alertFg : null,
              ),
            ),
            subtitle: hint == null
                ? null
                : Text(
                    hint,
                    style: ctx.text.bodySmall!.copyWith(
                      color: ctx.delve.textMuted,
                    ),
                  ),
            onTap: () {
              Navigator.of(ctx).pop();
              onTap();
            },
          );
          final meta = [
            if (!e.isDir && e.size != null) sizeText(e.size!),
            if (e.modified != null) fileTime(e.modified!, DateTime.now()),
          ].join(' · ');
          final owner = [?e.modeText, ?e.owner].join(' ');
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DelveTokens.space5,
                      0,
                      DelveTokens.space5,
                      DelveTokens.space3,
                    ),
                    child: Row(
                      children: [
                        FileTile(entry: e),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                style: ctx.text.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (meta.isNotEmpty)
                                Text(
                                  meta,
                                  style: ctx.text.labelMedium!.copyWith(
                                    color: ctx.delve.textMuted,
                                  ),
                                ),
                              Text(
                                [
                                  if (owner.isNotEmpty) owner,
                                  tildePath(e.path, _service.home),
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DelveText.monoSmall.copyWith(
                                  color: ctx.delve.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (e.isDir)
                    row('open', FileIcons.folderOpen, l.filesActOpen, () {
                      unawaited(_service.enter(e));
                    }),
                  if (e.kind == EntryKind.file)
                    row(
                      'download',
                      FileIcons.download,
                      l.filesActDownload,
                      () => _download(e),
                      hint: l.filesActDownloadHint(kDownloadFolder),
                    ),
                  if (previewKindOf(e) != PreviewKind.none)
                    row(
                      'preview',
                      FileIcons.preview,
                      l.filesActPreview,
                      () => _preview(e),
                    ),
                  if (e.isLink && !e.linkBroken)
                    row('target', FileIcons.goTo, l.filesActGoToTarget, () {
                      final target = normalizePath(
                        e.link!,
                        from: parentPath(e.path),
                      );
                      _open(e.isDir ? target : parentPath(target));
                    }),
                  row(
                    'copyPath',
                    FileIcons.copyPath,
                    l.filesActCopyPath,
                    () => unawaited(_copyPath(e)),
                  ),
                  row(
                    'rename',
                    FileIcons.rename,
                    l.filesRename,
                    () => unawaited(_rename(e)),
                  ),
                  const Divider(height: 1),
                  if (_service.canTrash(e))
                    row(
                      'trash',
                      FileIcons.trash,
                      l.filesActTrash,
                      () => unawaited(_toTrash(e)),
                      alert: true,
                    )
                  else
                    row(
                      'deleteForever',
                      FileIcons.deleteForever,
                      l.filesActDeleteForever,
                      () => unawaited(_deleteForever(e)),
                      alert: true,
                    ),
                  const SizedBox(height: DelveTokens.space2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _menu(BuildContext anchor) async {
    final l = AppLocalizations.of(context);
    // where the menu opens: measured before the trash count is awaited
    final box = anchor.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(anchor).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    int? trash;
    try {
      trash = await _service.trashCount().timeout(
        const Duration(milliseconds: 600),
        onTimeout: () => null,
      );
    } on Exception {
      trash = null;
    }
    if (!mounted) return;
    PopupMenuItem<String> sortItem(SortKey key, String label) => PopupMenuItem(
      key: Key('files.sort.${key.name}'),
      value: 'sort.${key.name}',
      child: Row(
        children: [
          SymbolIcon(
            _service.sort == key ? FileIcons.radioOn : FileIcons.radioOff,
            size: DelveTokens.iconMd,
            color: _service.sort == key
                ? context.colors.primary
                : context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: DelveTokens.space3),
          Text(label),
        ],
      ),
    );
    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        CheckedPopupMenuItem(
          key: const Key('files.menu.hidden'),
          value: 'hidden',
          checked: _service.showHidden,
          child: Text(l.filesMenuHidden),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          height: 32,
          child: Text(l.filesMenuSortBy, style: context.text.labelMedium),
        ),
        sortItem(SortKey.name, l.filesSortName),
        sortItem(SortKey.size, l.filesSortSize),
        sortItem(SortKey.modified, l.filesSortDate),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('files.menu.newFolder'),
          value: 'newFolder',
          enabled: _service.path != null,
          child: Text(l.filesNewFolder),
        ),
        PopupMenuItem(
          key: const Key('files.menu.trash'),
          value: 'trash',
          child: Text(trash == null ? l.filesTrash : l.filesTrashCount(trash)),
        ),
        PopupMenuItem(
          key: const Key('files.menu.refresh'),
          value: 'refresh',
          child: Text(l.filesMenuRefresh),
        ),
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'hidden':
        _service.setShowHidden(show: !_service.showHidden);
      case 'refresh':
        unawaited(_service.refresh());
      case 'newFolder':
        unawaited(_newFolder());
      case 'trash':
        _terminal.lock.keepAlive();
        unawaited(context.push(Routes.filesTrash));
      case final String c when c.startsWith('sort.'):
        final key = SortKey.values.byName(c.substring(5));
        if (key != _service.sort) _service.sortBy(key);
    }
  }

  void _transfers() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        // over the shell's snackbar (Moved to trash · Undo) and the nav
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) => _TransfersSheet(
          service: _service,
          onOpen: (t) {
            if (t.upload) {
              Navigator.of(ctx).pop();
              _open(parentPath(t.remotePath));
            } else {
              unawaited(_openDownload(t));
            }
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------- build

  List<QuickLocation> _quick(AppLocalizations l) {
    final home = _service.home;
    return [
      if (home != null) ...[
        QuickLocation(FileIcons.home, l.filesQuickHome, home),
        QuickLocation(
          FileIcons.download,
          l.filesQuickDownloads,
          joinPath(home, 'Downloads'),
        ),
        QuickLocation(
          FileIcons.documents,
          l.filesQuickDocuments,
          joinPath(home, 'Documents'),
        ),
      ],
    ];
  }

  String _headerText(AppLocalizations l) {
    final s = _service;
    final parts = <String>[];
    if (s.entries != null) {
      parts.add(
        s.hiddenCount > 0 && !s.showHidden
            ? l.filesShownHidden(
                (s.totalCount - s.hiddenCount).toString(),
                s.hiddenCount.toString(),
              )
            : itemsText(l, s.totalCount),
      );
    }
    final m = s.mountHere;
    if (m != null) {
      parts.add(m.fsType);
      if (m.size != null) parts.add(sizeText(m.size!));
      if (m.usedFraction case final f?) {
        parts.add(l.filesUsedPct((f * 100).round()));
      }
    }
    return parts.join(' · ');
  }

  String _meta(AppLocalizations l, RemoteEntry e, DateTime now) {
    if (e.linkBroken) return l.filesBrokenLink(e.link ?? '?');
    if (e.isLink) return l.filesLinkTo(tildePath(e.link!, _service.home));
    final date = e.modified == null ? null : fileTime(e.modified!, now);
    if (e.isDir) {
      final n = _service.countOf(e);
      final known = _service.countKnown(e);
      if (known && n == null) {
        return l.filesDeniedRow(e.owner ?? '?');
      }
      return [if (n != null) itemsText(l, n), ?date].join(' · ');
    }
    final size = e.size == null ? null : sizeText(e.size!);
    return [?size, ?date].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: ListenableBuilder(
        listenable: Listenable.merge([_service, _terminal]),
        // an empty folder has its own Upload button
        builder: (context, _) => _canWrite && _service.entries!.isNotEmpty
            ? FloatingActionButton.extended(
                key: const Key('files.upload'),
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                onPressed: () => unawaited(_upload()),
                icon: const SymbolIcon(FileIcons.upload),
                label: Text(l.filesUpload),
              )
            : const SizedBox.shrink(),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_service, _terminal]),
        builder: (context, _) {
          final s = _service;
          if (!_terminal.ready) {
            return TopLevelPage(
              title: l.navFiles,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (s.phase == FilesPhase.notSetUp) {
            return TopLevelPage(
              title: l.navFiles,
              child: FilesMessage(
                key: const Key('files.notSetUp'),
                icon: FileIcons.executable,
                title: l.filesNotSetUpTitle,
                body: Text(l.filesNotSetUpBody),
                actions: [
                  FilledButton(
                    key: const Key('files.openTerminal'),
                    onPressed: () => context.go(Routes.terminal),
                    child: Text(l.filesOpenTerminal),
                  ),
                ],
              ),
            );
          }
          if (_terminal.lock.locked) {
            if (_promptLock && _visible && !_unlocking) {
              _promptLock = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) unawaited(_unlock());
              });
            }
            return TopLevelPage(
              title: l.navFiles,
              child: _Locked(
                busy: _unlocking,
                problem: _unlockProblem,
                onUnlock: _unlock,
              ),
            );
          }
          if (s.phase == FilesPhase.hostKeyChanged ||
              s.phase == FilesPhase.denied) {
            final changed = s.phase == FilesPhase.hostKeyChanged;
            return TopLevelPage(
              title: l.navFiles,
              child: FilesMessage(
                key: Key(changed ? 'files.hostKeyChanged' : 'files.keyDenied'),
                icon: changed ? DelveIcons.gppBad : DelveIcons.keyOff,
                title: changed ? l.filesHostKeyTitle : l.filesKeyDeniedTitle,
                body: Text(changed ? l.filesHostKeyBody : l.filesKeyDeniedBody),
                actions: [
                  OutlinedButton(
                    onPressed: () => context.go(Routes.terminal),
                    child: Text(l.filesOpenTerminal),
                  ),
                  FilledButton.tonal(
                    key: const Key('files.retry'),
                    onPressed: () => unawaited(s.retry()),
                    child: Text(l.filesRetry),
                  ),
                ],
              ),
            );
          }
          return PopScope(
            canPop: !s.canGoBack,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) s.back();
            },
            child: _browser(context, l),
          );
        },
      ),
    );
  }

  /// Upload and New folder: a folder listed, live, unlocked.
  bool get _canWrite {
    final s = _service;
    return _terminal.ready &&
        !_terminal.lock.locked &&
        s.phase == FilesPhase.live &&
        s.path != null &&
        s.entries != null &&
        s.listProblem == null;
  }

  Widget _browser(BuildContext context, AppLocalizations l) {
    final s = _service;
    final path = s.path;
    final running = s.runningTransfer;
    final progress = s.transferProgress;
    _syncTick(running != null);
    return TopLevelPage(
      title: l.navFiles,
      actions: [
        if (progress != null)
          TransferChip(
            fraction: running?.fraction,
            label: l.filesTransferChip(progress.$1, progress.$2),
            onTap: _transfers,
          )
        else if (s.transfers.isNotEmpty)
          IconButton(
            key: const Key('files.transfers'),
            tooltip: l.filesTransfers,
            icon: const SymbolIcon(FileIcons.download),
            onPressed: _transfers,
          ),
        Builder(
          builder: (anchor) => IconButton(
            key: const Key('files.menu'),
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            icon: const SymbolIcon(DelveIcons.moreVert),
            onPressed: () => unawaited(_menu(anchor)),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null) Breadcrumb(path: path, onOpen: _open),
          QuickLocations(locations: _quick(l), current: path, onOpen: _open),
          if (s.loading || s.phase == FilesPhase.connecting)
            const LinearProgressIndicator(minHeight: 2)
          else if (s.phase == FilesPhase.offline)
            _StateLine(service: s)
          else
            const SizedBox(height: 2),
          if (s.entries != null || s.mountHere != null)
            FilesListHeader(
              text: _headerText(l),
              sortLabel: switch (s.sort) {
                SortKey.name => l.filesSortName,
                SortKey.size => l.filesSortSize,
                SortKey.modified => l.filesSortDate,
              },
              ascending: s.ascending,
              onSort: () => s.sortBy(s.sort),
            ),
          Expanded(
            child: AnimatedOpacity(
              duration: DelveTokens.short,
              opacity: s.phase == FilesPhase.offline ? 0.5 : 1,
              child: IgnorePointer(
                ignoring: s.phase == FilesPhase.offline,
                child: _list(context, l),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Redraws once a second while a transfer runs (its speed).
  void _syncTick(bool running) {
    if (running && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  Widget _list(BuildContext context, AppLocalizations l) {
    final s = _service;
    final problem = s.listProblem;
    if (problem != null) return _problem(context, l, problem);
    final entries = s.entries;
    if (entries == null) {
      if (!s.loading && s.phase != FilesPhase.connecting) {
        return const SizedBox.shrink();
      }
      return ListView.builder(
        key: const Key('files.loading'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (_, _) => const SkeletonPulse(child: _SkeletonRow()),
      );
    }
    if (entries.isEmpty) {
      return FilesMessage(
        key: const Key('files.empty'),
        icon: FileIcons.folderOpen,
        title: l.filesEmptyTitle,
        body: s.hiddenCount > 0 && !s.showHidden
            ? Text(l.filesEmptyHidden(s.hiddenCount))
            : null,
        actions: [
          if (s.hiddenCount > 0 && !s.showHidden)
            OutlinedButton(
              onPressed: () => s.setShowHidden(show: true),
              child: Text(l.filesMenuHidden),
            ),
          OutlinedButton.icon(
            key: const Key('files.empty.newFolder'),
            onPressed: () => unawaited(_newFolder()),
            icon: const SymbolIcon(FileIcons.newFolder, size: 18),
            label: Text(l.filesNewFolder),
          ),
          FilledButton.icon(
            key: const Key('files.empty.upload'),
            onPressed: () => unawaited(_upload()),
            icon: const SymbolIcon(FileIcons.upload, size: 18),
            label: Text(l.filesUpload),
          ),
        ],
      );
    }
    final now = DateTime.now();
    // a new scroll position (at the top) for each folder
    return KeyedSubtree(
      key: ValueKey(s.path),
      child: RefreshIndicator(
        onRefresh: s.refresh,
        child: Scrollbar(
          interactive: true,
          child: ListView.builder(
            key: const Key('files.list'),
            // room under the last row for the Upload button
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: entries.length,
            itemExtent: FilesTokens.row,
            itemBuilder: (context, i) {
              final e = entries[i];
              final meta = _meta(l, e, now);
              final locked = e.isDir && s.countKnown(e) && s.countOf(e) == null;
              return FileRow(
                entry: e,
                meta: meta,
                mono: e.isLink,
                locked: locked,
                onTap: () => _tapRow(e),
                onMenu: () => _actions(e),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _problem(BuildContext context, AppLocalizations l, ListProblem p) {
    final home = _service.home;
    switch (p.failure) {
      case FsFailure.denied:
        final e = p.entry;
        return FilesMessage(
          key: const Key('files.denied'),
          icon: FileIcons.lock,
          filledIcon: true,
          title: l.filesDeniedTitle,
          body: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: p.path,
                  style: DelveText.mono.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                TextSpan(
                  text: e?.owner != null && e?.modeText != null
                      ? l.filesDeniedOwned(e!.owner!, e.modeText!)
                      : l.filesDeniedPlain,
                ),
              ],
            ),
          ),
          actions: [
            FilledButton.tonal(
              key: const Key('files.goRoot'),
              onPressed: () => _open('/'),
              child: Text(l.filesGoRoot),
            ),
            if (home != null)
              OutlinedButton(
                onPressed: () => _open(home),
                child: Text(l.filesGoHome),
              ),
          ],
        );
      case FsFailure.notFound || FsFailure.notADirectory:
        return FilesMessage(
          key: const Key('files.notFound'),
          icon: FileIcons.notFound,
          title: l.filesNotFoundTitle,
          body: Text(p.path, style: DelveText.mono),
          actions: [
            if (home != null)
              FilledButton.tonal(
                onPressed: () => _open(home),
                child: Text(l.filesGoHome),
              ),
          ],
        );
      case FsFailure.unreachable ||
          FsFailure.other ||
          FsFailure.exists ||
          FsFailure.crossDevice:
        return FilesMessage(
          key: const Key('files.error'),
          icon: DelveIcons.error,
          title: l.filesErrorTitle,
          body: Text(p.detail),
          actions: [
            FilledButton.tonal(
              onPressed: () => unawaited(_service.refresh()),
              child: Text(l.filesRetry),
            ),
          ],
        );
    }
  }
}

/// Offline: "Reconnecting · attempt 2 · next in 4 s" with Retry (the
/// terminal's language, 22c).
class _StateLine extends StatelessWidget {
  const _StateLine({required this.service});

  final FilesService service;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.status(StatusKind.warn);
    final next = service.nextAttemptAt;
    return Material(
      key: const Key('files.offline'),
      color: c.bg,
      child: InkWell(
        onTap: () => unawaited(service.retry()),
        child: SizedBox(
          height: DelveTokens.terminalStateLine,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
            child: Row(
              children: [
                SymbolIcon(
                  DelveIcons.sync,
                  size: DelveTokens.iconSm,
                  color: c.fg,
                ),
                const SizedBox(width: DelveTokens.space2),
                Expanded(
                  child: Text(
                    l.filesReconnecting(service.attempt),
                    style: context.text.labelMedium!.copyWith(color: c.fg),
                  ),
                ),
                if (next != null)
                  _NextIn(at: next)
                else
                  Text(
                    l.filesRetry,
                    style: context.text.labelMedium!.copyWith(color: c.fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextIn extends StatefulWidget {
  const _NextIn({required this.at});

  final DateTime at;

  @override
  State<_NextIn> createState() => _NextInState();
}

class _NextInState extends State<_NextIn> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.at.difference(DateTime.now()).inSeconds + 1;
    return Text(
      AppLocalizations.of(context).filesNextIn(s < 1 ? 1 : s),
      style: DelveText.monoSmall.copyWith(
        color: context.status(StatusKind.warn).fg,
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: FilesTokens.row,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: DelveTokens.space4),
      child: Row(
        children: [
          SkeletonBlock(width: FilesTokens.tile, height: FilesTokens.tile),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 160, height: 12),
                SizedBox(height: 6),
                SkeletonBlock(width: 96, height: 10, strong: false),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The shared 15-min lock: nothing of the folder is drawn.
class _Locked extends StatelessWidget {
  const _Locked({
    required this.busy,
    required this.problem,
    required this.onUnlock,
  });

  final bool busy;
  final String? problem;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FilesMessage(
      key: const Key('files.locked'),
      icon: DelveIcons.fingerprint,
      title: l.filesLockTitle,
      body: Column(
        children: [
          Text(l.filesLockBody),
          if (problem != null) ...[
            const SizedBox(height: DelveTokens.space3),
            Text(
              problem!,
              style: context.text.bodySmall!.copyWith(
                color: context.delve.alertFg,
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.tonalIcon(
          key: const Key('files.unlock'),
          onPressed: busy ? null : onUnlock,
          icon: const SymbolIcon(
            DelveIcons.fingerprint,
            size: DelveTokens.iconMd,
          ),
          label: Text(l.termUnlock),
        ),
      ],
    );
  }
}

/// 23g: the downloads, running and finished.
class _TransfersSheet extends StatelessWidget {
  const _TransfersSheet({required this.service, required this.onOpen});

  final FilesService service;
  final ValueChanged<Transfer> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final list = service.transfers.reversed.toList();
        final active = list.where((t) => t.active).length;
        final done = list.where((t) => t.state == TransferState.done).length;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.filesTransfers,
                              style: context.text.titleLarge,
                            ),
                            Text(
                              l.filesTransfersSummary(active, done),
                              style: context.text.labelMedium!.copyWith(
                                color: context.delve.textMuted,
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
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in list)
                        TransferRow(
                          key: Key('files.transfer.${t.id}'),
                          transfer: t,
                          now: DateTime.now(),
                          onCancel: () => service.cancel(t),
                          onOpen: () => onOpen(t),
                          onRetry: () => service.retryTransfer(t),
                          home: service.home,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
