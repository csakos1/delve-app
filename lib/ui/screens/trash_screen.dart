import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../theme/delve_theme.dart';
import '../widgets/files_dialogs.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';

/// 23i: the desktop's trash (`~/.local/share/Trash`, the one the desktop's
/// file managers use): restore, delete for good, empty.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  late final FilesService _service = ref.read(filesServiceProvider);
  late final TerminalService _terminal = ref.read(terminalServiceProvider);

  List<TrashItem>? _items;
  int? _size;
  String? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_terminal.lock.locked) {
      setState(() {});
      return;
    }
    setState(() => _problem = null);
    try {
      final items = await _service.trashItems();
      if (!mounted) return;
      setState(() => _items = items);
      final size = await _service.trashSize();
      if (mounted) setState(() => _size = size);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(
        () => _problem = writeErrorText(AppLocalizations.of(context), e),
      );
    }
  }

  Future<void> _unlock() async {
    final l = AppLocalizations.of(context);
    await _terminal.unlock(l.filesUnlockReason);
    if (mounted && !_terminal.lock.locked) await _load();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Runs [op] with the list dimmed, then reads the trash again.
  Future<void> _run(Future<void> Function() op) async {
    if (_busy) return;
    _terminal.lock.keepAlive();
    setState(() => _busy = true);
    try {
      await op();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _restore(TrashItem item) => _run(() async {
    final l = AppLocalizations.of(context);
    final home = _service.home;
    try {
      final to = await _service.restore(item);
      _snack(l.trashRestored(item.name, tildePath(parentPath(to!), home)));
    } on RemoteFsError catch (e) {
      if (e.failure != FsFailure.exists) {
        _snack(l.trashRestoreFailed(writeErrorText(l, e)));
        return;
      }
      // the name is taken where it was: ask (23f)
      try {
        final dir = parentPath(item.original);
        final here = (await _service.entriesIn(dir))[item.name];
        if (here == null) return;
        if (!mounted) return;
        final answer = await showConflictDialog(
          context,
          name: item.name,
          here: here,
          incomingSize: item.entry.isDir ? null : item.entry.size,
          count: 1,
        );
        if (answer == null) return;
        final to = await _service.restore(item, onConflict: answer.$1);
        if (to != null) {
          _snack(l.trashRestored(baseName(to), tildePath(dir, home)));
        }
      } on Exception catch (e) {
        _snack(l.trashRestoreFailed(writeErrorText(l, e)));
      }
    }
  });

  Future<void> _delete(TrashItem item) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDeleteForever(
      context,
      what: [
        item.name,
        if (!item.entry.isDir && item.entry.size != null)
          sizeText(item.entry.size!),
      ].join(' · '),
      body: l.trashDeleteBody,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      try {
        await _service.deleteFromTrash(item);
      } on Exception catch (e) {
        _snack(l.filesDeleteFailed(writeErrorText(l, e)));
      }
    });
  }

  Future<void> _empty() async {
    final l = AppLocalizations.of(context);
    final items = _items;
    if (items == null || items.isEmpty) return;
    final ok = await confirmEmptyTrash(
      context,
      count: items.length,
      size: _size,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      try {
        await _service.emptyTrash();
        _snack(l.trashEmptied);
      } on Exception catch (e) {
        _snack(l.filesDeleteFailed(writeErrorText(l, e)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = _items;
    return SubPage(
      title: l.filesTrash,
      actions: [
        PopupMenuButton<String>(
          key: const Key('trash.menu'),
          icon: const SymbolIcon(DelveIcons.moreVert),
          enabled: !_busy && (items?.isNotEmpty ?? false),
          onSelected: (_) => unawaited(_empty()),
          itemBuilder: (_) => [
            PopupMenuItem(
              key: const Key('trash.empty'),
              value: 'empty',
              child: Text(l.trashEmpty),
            ),
          ],
        ),
      ],
      child: ListenableBuilder(
        listenable: _terminal,
        builder: (context, _) => _body(context, l),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l) {
    if (_terminal.lock.locked) {
      return FilesMessage(
        key: const Key('trash.locked'),
        icon: DelveIcons.fingerprint,
        title: l.filesLockTitle,
        body: Text(l.filesLockBody),
        actions: [
          FilledButton.tonal(
            onPressed: () => unawaited(_unlock()),
            child: Text(l.termUnlock),
          ),
        ],
      );
    }
    final items = _items;
    if (_problem != null && items == null) {
      return FilesMessage(
        key: const Key('trash.error'),
        icon: DelveIcons.error,
        title: l.trashErrorTitle,
        body: Text(_problem!),
        actions: [
          FilledButton.tonal(
            onPressed: () => unawaited(_load()),
            child: Text(l.filesRetry),
          ),
        ],
      );
    }
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return FilesMessage(
        key: const Key('trash.none'),
        icon: FileIcons.trash,
        title: l.trashNoneTitle,
        body: Text(l.trashNoneBody),
      );
    }
    final now = DateTime.now();
    final home = _service.home;
    final d = context.delve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_busy)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space2,
            DelveTokens.space4,
            DelveTokens.space2,
          ),
          child: Text(
            [
              itemsText(l, items.length),
              if (_size != null) sizeText(_size!),
              l.trashShared,
            ].join(' · '),
            key: const Key('trash.info'),
            style: context.text.labelMedium!.copyWith(color: d.textMuted),
          ),
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: _busy,
            child: ListView.builder(
              key: const Key('trash.list'),
              itemCount: items.length,
              itemExtent: 72,
              itemBuilder: (context, i) {
                final item = items[i];
                final folder = tildePath(parentPath(item.original), home);
                final meta = [
                  if (item.deleted != null)
                    l.trashDeletedAt(fileTime(item.deleted!, now)),
                  if (!item.entry.isDir && item.entry.size != null)
                    sizeText(item.entry.size!),
                ].join(' · ');
                return Padding(
                  key: ValueKey('trash.item.${item.entry.name}'),
                  padding: const EdgeInsets.only(left: DelveTokens.space4),
                  child: Row(
                    children: [
                      FileTile(entry: item.entry),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MiddleEllipsis(
                              item.name,
                              style: context.text.bodyMedium!,
                            ),
                            Text(
                              folder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DelveText.monoSmall.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            if (meta.isNotEmpty)
                              Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelMedium!.copyWith(
                                  color: d.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: Key('trash.restore.${item.entry.name}'),
                        tooltip: l.trashRestore,
                        icon: const SymbolIcon(FileIcons.restore),
                        onPressed: () => unawaited(_restore(item)),
                      ),
                      PopupMenuButton<String>(
                        key: Key('trash.more.${item.entry.name}'),
                        icon: const SymbolIcon(DelveIcons.moreVert),
                        onSelected: (v) => unawaited(
                          v == 'restore' ? _restore(item) : _delete(item),
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'restore',
                            child: Text(l.trashRestoreTo(folder)),
                          ),
                          PopupMenuItem(
                            key: Key('trash.delete.${item.entry.name}'),
                            value: 'delete',
                            child: Text(
                              l.filesActDeleteForever,
                              style: TextStyle(color: d.alertFg),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
