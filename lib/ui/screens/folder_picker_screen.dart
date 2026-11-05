import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../attachments/picker.dart';
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

/// What Share → Save to desktop folder saves.
class FolderPickArgs {
  const FolderPickArgs(this.files);

  final List<PickedAttachment> files;
}

List<PickedAttachment>? pickArgsOf(Object? extra) => switch (extra) {
  FolderPickArgs(:final files) when files.isNotEmpty => files,
  _ => null,
};

/// 23k2: a folder on the desktop for what was shared – its own path and
/// listing (folders open, files dimmed), New folder, Save here. Saving
/// asks about taken names (23f), queues the uploads and opens Files there.
class FolderPickerScreen extends ConsumerStatefulWidget {
  const FolderPickerScreen({super.key, required this.files});

  final List<PickedAttachment> files;

  @override
  ConsumerState<FolderPickerScreen> createState() => _FolderPickerState();
}

enum _Gate { loading, notSetUp, locked, ready }

class _FolderPickerState extends ConsumerState<FolderPickerScreen> {
  late final FilesService _service = ref.read(filesServiceProvider);
  late final TerminalService _terminal = ref.read(terminalServiceProvider);

  _Gate _gate = _Gate.loading;
  String? _home;
  String? _path;
  List<RemoteEntry>? _entries;
  String? _problem;
  bool _busy = false;
  int _reading = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    if (!await _service.isSetUp()) {
      if (mounted) setState(() => _gate = _Gate.notSetUp);
      return;
    }
    if (_terminal.lock.locked) {
      if (mounted) setState(() => _gate = _Gate.locked);
      return;
    }
    if (mounted) setState(() => _gate = _Gate.ready);
    try {
      final start = await _service.saveStart();
      final home = await _service.homeFolder();
      if (!mounted) return;
      _home = home;
      await _go(start);
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
    if (mounted && !_terminal.lock.locked) await _start();
  }

  /// Lists [path] (dotfiles left out); a folder that can't be read stays
  /// shown with why.
  Future<void> _go(String path) async {
    _terminal.lock.keepAlive();
    final n = ++_reading;
    setState(() {
      _path = path;
      _entries = null;
      _problem = null;
    });
    try {
      final here = await _service.entriesIn(path);
      if (!mounted || n != _reading) return;
      setState(() {
        _entries = sortEntries(
          here.values.where((e) => !e.name.startsWith('.')),
          SortKey.name,
        );
      });
    } on Exception catch (e) {
      if (!mounted || n != _reading) return;
      setState(
        () => _problem = writeErrorText(AppLocalizations.of(context), e),
      );
    }
  }

  void _enter(RemoteEntry e) {
    final to = e.isLink
        ? normalizePath(e.link!, from: parentPath(e.path))
        : e.path;
    unawaited(_go(to));
  }

  Future<void> _newFolder() async {
    final dir = _path;
    if (dir == null) return;
    final l = AppLocalizations.of(context);
    String? made;
    await showNameDialog(
      context,
      title: l.filesNewFolder,
      action: l.filesCreate,
      submit: (name) async {
        try {
          made = await _service.makeFolder(name, dir: dir);
          return null;
        } on Exception catch (e) {
          return writeErrorText(l, e);
        }
      },
    );
    if (made case final m? when mounted) await _go(m);
  }

  Future<void> _save() async {
    final dir = _path;
    if (dir == null || _busy) return;
    setState(() => _busy = true);
    final ok = await uploadAsking(context, _service, dir, widget.files);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _service.rememberSaveFolder(dir);
    context.go(Routes.files);
    unawaited(_service.open(dir));
  }

  List<QuickLocation> _quick(AppLocalizations l) {
    final home = _home;
    if (home == null) return const [];
    return [
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
    ];
  }

  String _what(AppLocalizations l) {
    final files = widget.files;
    if (files.length == 1) return files.single.name;
    final sizes = files.map((f) => f.size).toList();
    return [
      l.saveFiles(files.length),
      if (!sizes.contains(null)) sizeText(sizes.fold<int>(0, (a, b) => a + b!)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('save.close'),
            tooltip: l.close,
            icon: const SymbolIcon(DelveIcons.close),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.saveTitle),
              Text(
                _what(l),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
            ],
          ),
        ),
        body: switch (_gate) {
          _Gate.loading => const Center(child: CircularProgressIndicator()),
          _Gate.notSetUp => FilesMessage(
            key: const Key('save.notSetUp'),
            icon: FileIcons.executable,
            title: l.filesNotSetUpTitle,
            body: Text(l.filesNotSetUpBody),
          ),
          _Gate.locked => FilesMessage(
            key: const Key('save.locked'),
            icon: DelveIcons.fingerprint,
            title: l.filesLockTitle,
            body: Text(l.filesLockBody),
            actions: [
              FilledButton.tonal(
                key: const Key('save.unlock'),
                onPressed: () => unawaited(_unlock()),
                child: Text(l.termUnlock),
              ),
            ],
          ),
          _Gate.ready => _picker(context, l),
        },
      ),
    );
  }

  Widget _picker(BuildContext context, AppLocalizations l) {
    final path = _path;
    final entries = _entries;
    final d = context.delve;
    final Widget list;
    if (_problem != null) {
      list = FilesMessage(
        key: const Key('save.error'),
        icon: DelveIcons.error,
        title: l.filesErrorTitle,
        body: Text(_problem!),
        actions: [
          FilledButton.tonal(
            onPressed: () => unawaited(path == null ? _start() : _go(path)),
            child: Text(l.filesRetry),
          ),
          if (_home != null && path != _home)
            OutlinedButton(
              onPressed: () => unawaited(_go(_home!)),
              child: Text(l.filesGoHome),
            ),
        ],
      );
    } else if (entries == null) {
      list = const Center(child: CircularProgressIndicator());
    } else if (entries.isEmpty) {
      list = FilesMessage(
        key: const Key('save.empty'),
        icon: FileIcons.folderOpen,
        title: l.filesEmptyTitle,
      );
    } else {
      list = ListView.builder(
        key: const Key('save.list'),
        itemCount: entries.length,
        itemExtent: FilesTokens.row,
        itemBuilder: (context, i) {
          final e = entries[i];
          final folder = e.isDir;
          return Opacity(
            opacity: folder ? 1 : 0.4,
            child: InkWell(
              key: ValueKey('save.entry.${e.name}'),
              onTap: folder ? () => _enter(e) : null,
              child: Padding(
                padding: const EdgeInsets.only(left: DelveTokens.space4),
                child: Row(
                  children: [
                    FileTile(entry: e),
                    const SizedBox(width: 14),
                    Expanded(
                      child: MiddleEllipsis(
                        e.name,
                        style: context.text.bodyMedium!,
                      ),
                    ),
                    if (folder)
                      Padding(
                        padding: const EdgeInsets.all(DelveTokens.space3),
                        child: SymbolIcon(
                          FileIcons.chevron,
                          color: d.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (path != null)
          Breadcrumb(path: path, onOpen: (p) => unawaited(_go(p))),
        QuickLocations(
          locations: _quick(l),
          current: path,
          onOpen: (p) => unawaited(_go(p)),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: list),
        Material(
          color: context.colors.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                DelveTokens.space3,
                DelveTokens.space4,
                DelveTokens.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    path == null ? '' : tildePath(path, _home),
                    key: const Key('save.path'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DelveText.monoSmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DelveTokens.space2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('save.newFolder'),
                          onPressed: path == null || _busy || _problem != null
                              ? null
                              : () => unawaited(_newFolder()),
                          icon: const SymbolIcon(FileIcons.newFolder, size: 18),
                          label: Text(l.filesNewFolder),
                        ),
                      ),
                      const SizedBox(width: DelveTokens.space2),
                      Expanded(
                        child: FilledButton(
                          key: const Key('save.here'),
                          onPressed:
                              entries == null || _busy || _problem != null
                              ? null
                              : () => unawaited(_save()),
                          child: Text(l.saveHere),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
