import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../files/device_files.dart';
import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../files/text_edit.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/editor_dialogs.dart';
import '../widgets/files_dialogs.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/text_editor.dart';
import 'files_screen.dart';

/// 23h1 + 23n: a text file – read-only first (mono, line numbers), then
/// edited in place: the field, the status row, the key row above the
/// keyboard, Save (`.part` + rename), the conflict and discard dialogs.
///
/// The edit lives in this screen only (Ákos, F2b): a lost connection keeps
/// it until it is saved or discarded; the app being killed loses it.
///
/// Back while editing (Android back, the app bar's arrow) goes to the
/// read-only view, not out of the file; unsaved changes ask first. Done
/// (only with nothing unsaved, in Save's place) does the same.
class TextFileScreen extends ConsumerStatefulWidget {
  const TextFileScreen({super.key, required this.entry, this.edit = false});

  final RemoteEntry entry;

  /// Opened from the actions sheet's Edit: start editing once loaded.
  final bool edit;

  @override
  ConsumerState<TextFileScreen> createState() => _TextFileScreenState();
}

class _TextFileScreenState extends ConsumerState<TextFileScreen> {
  late final FilesService _service;
  final _text = TextEditingController();
  final _undo = UndoHistoryController();
  final _focus = FocusNode();
  late final AppLifecycleListener _life;

  TextFile? _file;
  bool _binary = false;
  Object? _error;
  bool _loading = true;

  bool _editing = false;
  bool _askedToEdit = false;

  /// The text as opened or last saved: what "changed" is measured against.
  String _base = '';
  bool _dirty = false;
  LineDiff _diff = LineDiff.none;
  Timer? _diffTimer;

  bool _saving = false;
  DateTime? _savedAt;
  bool _notSaved = false;
  EditDenied? _denied;

  bool _lineNumbers = true;
  bool _wrap = false;
  bool _locked = false;
  bool _unlocking = false;

  /// Back behind the lock after Discard / Save: the pop is let through.
  bool _leave = false;

  @override
  void initState() {
    super.initState();
    _service = ref.read(filesServiceProvider);
    _service.addListener(_onService);
    _text.addListener(_onText);
    _undo.addListener(_onUndo);
    _focus.addListener(_onUndo);
    _life = AppLifecycleListener(onResume: _resumed);
    unawaited(_load());
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _diffTimer?.cancel();
    _life.dispose();
    _service.removeListener(_onService);
    _text
      ..removeListener(_onText)
      ..dispose();
    _undo
      ..removeListener(_onUndo)
      ..dispose();
    _focus
      ..removeListener(_onUndo)
      ..dispose();
    super.dispose();
  }

  void _onService() {
    if (mounted) setState(() {});
  }

  /// The history (and the focus) can change while the field is being
  /// built (a new UndoHistory reports itself): the rebuild waits a frame.
  void _onUndo() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _onText() {
    if (!_editing) return;
    if (_service.terminal.lock.locked) {
      // 15 minutes without a key: the edit goes behind the lock
      _lockNow();
    } else {
      _service.terminal.lock.keepAlive();
    }
    final dirty = _text.text != _base;
    if (dirty != _dirty) setState(() => _dirty = dirty);
    _diffTimer?.cancel();
    _diffTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _diff = diffLines(_base, _text.text));
    });
  }

  Future<void> _load() async {
    try {
      final f = await _service.openText(widget.entry);
      if (!mounted) return;
      if (f != null) _setText(f.text);
      setState(() {
        _loading = false;
        _binary = f == null;
        _file = f;
      });
      if (widget.edit && !_askedToEdit && (f?.editable ?? false)) {
        _askedToEdit = true;
        _startEditing();
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// The field and its base become [text]; the caret stays where it was
  /// (clamped).
  void _setText(String text) {
    _base = text;
    _dirty = false;
    _diff = LineDiff.none;
    final at = _text.selection.isValid ? _text.selection.extentOffset : 0;
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: at.clamp(0, text.length)),
    );
  }

  void _startEditing() {
    _service.terminal.lock.keepAlive();
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  bool get _offline => switch (_service.phase) {
    FilesPhase.offline ||
    FilesPhase.hostKeyChanged ||
    FilesPhase.denied ||
    FilesPhase.notSetUp => true,
    _ => false,
  };

  void _snack(String text, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                SymbolIcon(icon, size: 20, filled: true, color: color),
                const SizedBox(width: DelveTokens.space3),
              ],
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  void _download() {
    final l = AppLocalizations.of(context);
    _service.download(widget.entry);
    _snack(l.filesDownloadQueued(kDownloadFolder));
  }

  // --------------------------------------------------------------- save

  /// Saves; true when the desktop has the edit. A conflict asks (23n3),
  /// a refused folder shows its banner (23n5b).
  Future<bool> _save({bool force = false}) async {
    final f = _file;
    if (f == null || _saving || _offline) return false;
    final l = AppLocalizations.of(context);
    final text = _text.text;
    setState(() => _saving = true);
    Object? problem;
    TextFile? saved;
    try {
      saved = await _service.saveText(f, text, force: force);
    } on Object catch (e) {
      problem = e;
    }
    if (!mounted) return saved != null;
    setState(() => _saving = false);
    if (saved != null) {
      setState(() {
        _file = saved;
        _base = text;
        _dirty = _text.text != text;
        _diff = _dirty ? diffLines(text, _text.text) : LineDiff.none;
        _savedAt = DateTime.now();
        _notSaved = false;
        _denied = null;
      });
      _snack(l.editorSaved, icon: FileIcons.done, color: context.delve.okFg);
      return true;
    }
    switch (problem) {
      case EditConflict(:final now):
        final choice = await showEditConflict(
          context,
          name: f.entry.name,
          desktop: now,
          opened: f,
          editBytes: utf8.encode(text).length,
          changed: diffLines(_base, text).count,
        );
        if (!mounted) return false;
        if (choice == EditConflictChoice.overwrite) return _save(force: true);
        if (choice == EditConflictChoice.reload) {
          await _reload();
        } else {
          setState(() => _notSaved = true);
        }
        return false;
      case final EditDenied d:
        setState(() {
          _denied = d;
          _notSaved = true;
        });
        return false;
      default:
        setState(() => _notSaved = true);
        _snack(
          l.editorSaveFailed(writeErrorText(l, problem!)),
          icon: FileIcons.failed,
          color: context.delve.alertFg,
        );
        return false;
    }
  }

  Future<void> _reload() async {
    final l = AppLocalizations.of(context);
    try {
      final f = await _service.openText(widget.entry);
      if (!mounted) return;
      if (f == null) {
        setState(() => _binary = true);
        return;
      }
      _setText(f.text);
      setState(() {
        _file = f;
        _denied = null;
        _notSaved = false;
        _savedAt = null;
      });
    } on Object catch (e) {
      if (mounted) _snack(l.editorReloadFailed(writeErrorText(l, e)));
    }
  }

  void _discardChanges() {
    final at = _text.selection.isValid ? _text.selection.extentOffset : 0;
    _text.value = TextEditingValue(
      text: _base,
      selection: TextSelection.collapsed(offset: at.clamp(0, _base.length)),
    );
  }

  Future<void> _saveCopy() async {
    final f = _file;
    if (f == null) return;
    final l = AppLocalizations.of(context);
    try {
      final path = await _service.saveCopy(f, _text.text);
      if (!mounted) return;
      _snack(
        l.editorCopySaved(tildePath(path, _service.home)),
        icon: FileIcons.done,
        color: context.delve.okFg,
      );
    } on Object catch (e) {
      if (mounted) _snack(l.editorSaveFailed(writeErrorText(l, e)));
    }
  }

  Future<void> _copyAll() async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _text.text));
    if (mounted) _snack(l.editorCopied);
  }

  Future<void> _openInTerminal() async {
    final f = _file;
    if (f == null) return;
    await _service.terminal.newTab(startDir: parentPath(f.path));
    if (mounted) context.go(Routes.terminal);
  }

  // ----------------------------------------------------------- leaving

  /// Editing → the read-only view (Done, or back with nothing unsaved).
  void _stopEditing() {
    if (!_editing || _dirty || _saving || _locked) return;
    _focus.unfocus();
    _diffTimer?.cancel();
    setState(() {
      _editing = false;
      _diff = LineDiff.none;
      _notSaved = false;
      _denied = null;
    });
  }

  /// Back while editing: to the view; unsaved changes ask first (23n4) –
  /// Discard drops them, Save saves, and both end in the view.
  Future<void> _backToView() async {
    if (_saving) return;
    if (!_dirty) {
      _stopEditing();
      return;
    }
    final changed = diffLines(_base, _text.text).count;
    final choice = await showDiscardDialog(
      context,
      name: widget.entry.name,
      changed: changed == 0 ? 1 : changed,
      canSave: !_offline && !_saving,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case DiscardChoice.save:
        if (!await _save()) return;
      case DiscardChoice.discard:
        _discardChanges();
    }
    if (mounted) _stopEditing();
  }

  /// Behind the lock: back leaves the file, as before (the view would show
  /// it without the unlock).
  Future<void> _leaving() async {
    final changed = diffLines(_base, _text.text).count;
    final choice = await showDiscardDialog(
      context,
      name: widget.entry.name,
      changed: changed == 0 ? 1 : changed,
      canSave: !_offline && !_saving,
    );
    if (!mounted || choice == null) return;
    if (choice == DiscardChoice.save && !await _save()) return;
    if (!mounted) return;
    setState(() => _leave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  // -------------------------------------------------------------- lock

  void _resumed() {
    if (_editing && _service.terminal.lock.locked) _lockNow();
  }

  void _lockNow() {
    if (_locked) return;
    _focus.unfocus();
    setState(() => _locked = true);
    unawaited(_unlock());
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    final l = AppLocalizations.of(context);
    setState(() => _unlocking = true);
    await _service.terminal.unlock(l.filesUnlockReason);
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      _locked = _service.terminal.lock.locked;
    });
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return PopScope(
      canPop: _leave || !_editing || (_locked && !_dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_editing && !_locked ? _backToView() : _leaving());
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          notificationPredicate: (_) => false,
          leading: BackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: _title(l),
          actions: _editing ? _editActions(l) : _viewActions(l),
        ),
        body: _body(l),
      ),
    );
  }

  Widget _title(AppLocalizations l) {
    final e = widget.entry;
    final d = context.delve;
    final size = _file?.size ?? e.size;
    final sub = DelveText.monoSmall.copyWith(color: d.textMuted);
    return Semantics(
      label: _dirty ? l.editorUnsaved(e.name) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  e.name,
                  key: const Key('preview.title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_dirty) ...[
                const SizedBox(width: FilesTokens.dirtyDotGap),
                Container(
                  key: const Key('editor.dirty'),
                  width: FilesTokens.dirtyDot,
                  height: FilesTokens.dirtyDot,
                  decoration: BoxDecoration(
                    color: context.colors.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                if (_dirty)
                  TextSpan(
                    text: '${l.editorEdited} · ',
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                TextSpan(
                  text: [
                    tildePath(parentPath(e.path), _service.home),
                    if (size != null) sizeText(size),
                  ].join(' · '),
                ),
              ],
            ),
            key: const Key('preview.subtitle'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sub,
          ),
        ],
      ),
    );
  }

  String? _blockText(AppLocalizations l, EditBlock? b) => switch (b) {
    EditBlock.tooBig => l.editorBlockTooBig,
    EditBlock.notText => l.editorBlockNotText,
    EditBlock.readOnly => l.editorBlockReadOnly(_service.user),
    null => null,
  };

  List<Widget> _viewActions(AppLocalizations l) {
    final f = _file;
    final why = _blockText(l, f?.block);
    return [
      if (f != null)
        IconButton(
          key: const Key('preview.edit'),
          tooltip: why ?? l.editorEdit,
          icon: const SymbolIcon(FileIcons.edit),
          onPressed: f.editable ? _startEditing : null,
        ),
      IconButton(
        key: const Key('preview.download'),
        tooltip: l.filesActDownload,
        icon: const SymbolIcon(FileIcons.download),
        onPressed: _download,
      ),
      IconButton(
        key: const Key('preview.lineNumbers'),
        tooltip: l.filesLineNumbers,
        isSelected: _lineNumbers,
        icon: const SymbolIcon(FileIcons.numbers),
        onPressed: () => setState(() => _lineNumbers = !_lineNumbers),
      ),
    ];
  }

  List<Widget> _editActions(AppLocalizations l) {
    final cs = context.colors;
    final undo = _undo.value;
    return [
      IconButton(
        key: const Key('editor.undo'),
        tooltip: l.editorUndo,
        icon: const SymbolIcon(FileIcons.undo),
        onPressed: undo.canUndo ? _undo.undo : null,
      ),
      IconButton(
        key: const Key('editor.redo'),
        tooltip: l.editorRedo,
        icon: const SymbolIcon(FileIcons.redo),
        onPressed: undo.canRedo ? _undo.redo : null,
      ),
      if (_dirty || _saving)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space1),
          child: FilledButton.icon(
            key: const Key('editor.save'),
            onPressed: _saving || _offline ? null : () => unawaited(_save()),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, FilesTokens.editorSave),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  FilesTokens.editorSaveRadius,
                ),
              ),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: _saving
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: _saving
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.38),
            ),
            icon: _saving
                ? SizedBox.square(
                    dimension: FilesTokens.editorSaveIcon,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const SymbolIcon(
                    FileIcons.save,
                    size: FilesTokens.editorSaveIcon,
                  ),
            label: Text(_saving ? l.editorSaving : l.editorSave),
          ),
        )
      else
        // nothing unsaved: back to the read-only view
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space1),
          child: TextButton.icon(
            key: const Key('editor.done'),
            onPressed: _locked ? null : _stopEditing,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, FilesTokens.editorSave),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space3,
              ),
            ),
            icon: const SymbolIcon(
              DelveIcons.check,
              size: FilesTokens.editorSaveIcon,
            ),
            label: Text(l.editorDone),
          ),
        ),
      PopupMenuButton<String>(
        key: const Key('editor.menu'),
        tooltip: l.editorMore,
        icon: const SymbolIcon(DelveIcons.moreVert),
        onSelected: (v) {
          switch (v) {
            case 'wrap':
              setState(() => _wrap = !_wrap);
            case 'numbers':
              setState(() => _lineNumbers = !_lineNumbers);
            case 'reload':
              unawaited(_reload());
            case 'discard':
              _discardChanges();
          }
        },
        itemBuilder: (ctx) => [
          CheckedPopupMenuItem(
            key: const Key('editor.menu.wrap'),
            value: 'wrap',
            checked: _wrap,
            child: Text(l.editorWrap),
          ),
          CheckedPopupMenuItem(
            key: const Key('editor.menu.numbers'),
            value: 'numbers',
            checked: _lineNumbers,
            child: Text(l.filesLineNumbers),
          ),
          PopupMenuItem(enabled: false, child: Text(l.editorFindLater)),
          PopupMenuItem(
            key: const Key('editor.menu.reload'),
            value: 'reload',
            enabled: !_offline,
            child: Text(l.editorReload),
          ),
          if (_dirty)
            PopupMenuItem(
              key: const Key('editor.menu.discard'),
              value: 'discard',
              child: Text(
                l.editorDiscardChanges,
                style: TextStyle(color: ctx.delve.alertFg),
              ),
            ),
        ],
      ),
    ];
  }

  Widget _body(AppLocalizations l) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error case final e?) {
      return FilesMessage(
        key: const Key('preview.error'),
        icon: DelveIcons.error,
        title: l.filesPreviewFailed,
        body: Text(writeErrorText(l, e)),
        actions: [
          FilledButton.tonal(onPressed: _retry, child: Text(l.filesRetry)),
        ],
      );
    }
    final f = _file;
    if (_binary || f == null) {
      return FilesMessage(
        key: const Key('preview.binary'),
        icon: FileIcons.other,
        title: l.filesPreviewBinary,
        body: Text(l.filesPreviewBinaryBody),
        actions: [
          FilledButton(onPressed: _download, child: Text(l.filesActDownload)),
        ],
      );
    }
    if (!_editing) return _view(l, f);
    final ime = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_service.phase == FilesPhase.offline)
          FilesStateLine(service: _service),
        _StatusRow(
          text: _text,
          saving: _saving,
          offline: _offline,
          notSaved: _notSaved,
          savedAt: _dirty ? null : _savedAt,
          changed: _diff.count,
        ),
        if (_denied case final d?)
          _DeniedBanner(
            denied: d,
            user: _service.user,
            home: _service.home,
            onSaveCopy: () => unawaited(_saveCopy()),
            onCopyAll: () => unawaited(_copyAll()),
          ),
        Expanded(
          child: Stack(
            children: [
              Visibility(
                visible: !_locked,
                maintainState: true,
                child: TextEditorWell(
                  controller: _text,
                  undo: _undo,
                  focus: _focus,
                  changed: _diff.changed,
                  lineNumbers: _lineNumbers,
                  wrap: _wrap,
                ),
              ),
              if (_locked)
                FilesMessage(
                  key: const Key('editor.locked'),
                  icon: DelveIcons.fingerprint,
                  title: l.filesLockTitle,
                  body: Text(l.editorLockedBody),
                  actions: [
                    FilledButton.tonalIcon(
                      key: const Key('editor.unlock'),
                      onPressed: _unlocking ? null : () => unawaited(_unlock()),
                      icon: const SymbolIcon(
                        DelveIcons.fingerprint,
                        size: DelveTokens.iconMd,
                      ),
                      label: Text(l.termUnlock),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (ime && _focus.hasFocus && !_locked)
          // a tap on a key is not a tap outside the field
          TextFieldTapRegion(
            child: EditorKeys(
              canUndo: _undo.value.canUndo,
              canRedo: _undo.value.canRedo,
              onKey: (k) {
                switch (k) {
                  case EditorKey.undo:
                    _undo.undo();
                  case EditorKey.redo:
                    _undo.redo();
                  default:
                    applyEditorKey(_text, k);
                }
              },
            ),
          ),
      ],
    );
  }

  /// 23h1: read-only, with the reason Edit is off (23n5a's banner for a
  /// file the login can't write).
  Widget _view(AppLocalizations l, TextFile f) {
    final d = context.delve;
    var lines = f.text.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }
    final style = DelveText.mono.copyWith(
      color: d.codeFg,
      height: FilesTokens.editorLineHeight,
    );
    final gutter = style.copyWith(color: d.textMuted);
    final info = f.cut
        ? l.filesPreviewCut
        : f.block == EditBlock.notText
        ? l.editorInfoNotText(lines.length)
        : l.filesPreviewInfo(lines.length);
    final blocking = f.blocking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (f.block == EditBlock.readOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space2,
              0,
              DelveTokens.space2,
              DelveTokens.space2,
            ),
            child: StatusBanner(
              key: const Key('editor.readOnly'),
              kind: StatusKind.info,
              icon: FileIcons.lock,
              text: [
                l.editorBlockReadOnly(_service.user),
                if (blocking != null)
                  [blocking.owner, ?blocking.modeText].join(' '),
              ].join(' · '),
              actionLabel: l.editorOpenInTerminal,
              onAction: () => unawaited(_openInTerminal()),
            ),
          ),
        Expanded(
          child: Container(
            key: const Key('preview.text'),
            margin: const EdgeInsets.symmetric(horizontal: DelveTokens.space2),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DelveTokens.rmd),
            ),
            child: SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: DelveTokens.space3,
                ),
                itemCount: lines.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: DelveTokens.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lineNumbers)
                        SizedBox(
                          width:
                              FilesTokens.previewGutter +
                              (lines.length >= 1000 ? 10 : 0),
                          child: SelectionContainer.disabled(
                            child: Text(
                              '${i + 1}',
                              textAlign: TextAlign.right,
                              style: gutter,
                            ),
                          ),
                        ),
                      const SizedBox(width: DelveTokens.space3),
                      Expanded(child: Text(lines[i], style: style)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space2,
            DelveTokens.space2,
            DelveTokens.space2,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    info,
                    key: const Key('preview.info'),
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                    ),
                  ),
                ),
                if (f.cut)
                  TextButton(
                    onPressed: _download,
                    child: Text(l.filesActDownload),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 23n: Editing · Saved 22:41 · Not saved · Offline, then
/// "Ln 88, Col 28 · 182 lines · UTF-8 · 3 lines changed".
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.text,
    required this.saving,
    required this.offline,
    required this.notSaved,
    required this.savedAt,
    required this.changed,
  });

  final TextEditingController text;
  final bool saving;
  final bool offline;
  final bool notSaved;
  final DateTime? savedAt;
  final int changed;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: text,
    builder: (context, _) => _row(context),
  );

  Widget _row(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final (IconData icon, Color color, String word) = offline
        ? (DelveIcons.sync, d.warnFg, l.editorStatusOffline)
        : notSaved && !saving
        ? (DelveIcons.error, d.alertFg, l.editorStatusNotSaved)
        : savedAt != null
        ? (
            FileIcons.done,
            d.okFg,
            l.editorStatusSaved(TimeOfDay.fromDateTime(savedAt!).format24()),
          )
        : (FileIcons.edit, cs.onSurfaceVariant, l.editorStatusEditing);
    final v = text.value;
    final (line, col) = lineCol(
      v.text,
      v.selection.isValid ? v.selection.extentOffset : 0,
    );
    final details = [
      l.editorPosition(line + 1, col + 1),
      l.editorLines(countedLines(v.text)),
      'UTF-8',
      if (changed > 0) l.editorChanged(changed),
    ].join(' · ');
    final muted = context.text.labelMedium!.copyWith(
      color: d.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FilesTokens.editorStatusRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
        child: Row(
          key: const Key('editor.status'),
          children: [
            SymbolIcon(
              icon,
              size: FilesTokens.editorStatusIcon,
              filled: true,
              color: color,
            ),
            const SizedBox(width: DelveTokens.space1),
            Text(
              word,
              key: const Key('editor.status.word'),
              style: context.text.labelMedium!.copyWith(color: color),
            ),
            Expanded(
              child: Text(
                ' · $details',
                key: const Key('editor.status.details'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 23n5b: the folder refuses the `.part` file; the edit stays.
class _DeniedBanner extends StatelessWidget {
  const _DeniedBanner({
    required this.denied,
    required this.user,
    required this.home,
    required this.onSaveCopy,
    required this.onCopyAll,
  });

  final EditDenied denied;
  final String user;
  final String? home;
  final VoidCallback onSaveCopy;
  final VoidCallback onCopyAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.status(StatusKind.alert);
    final f = denied.folder;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space2,
        0,
        DelveTokens.space2,
        DelveTokens.space2,
      ),
      child: DecoratedBox(
        key: const Key('editor.denied'),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border, width: DelveTokens.hairline),
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space3,
            DelveTokens.space2,
            DelveTokens.space1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SymbolIcon(
                    DelveIcons.error,
                    size: DelveTokens.iconMd,
                    filled: true,
                    color: c.fg,
                  ),
                  const SizedBox(width: DelveTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.editorDenied(user, tildePath(denied.dir, home)),
                          style: context.text.bodyMedium!.copyWith(color: c.fg),
                        ),
                        if (f != null)
                          Text(
                            [f.owner, ?f.modeText].join(' '),
                            style: DelveText.monoSmall.copyWith(color: c.fg),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    key: const Key('editor.saveCopy'),
                    onPressed: onSaveCopy,
                    icon: const SymbolIcon(FileIcons.saveCopy, size: 18),
                    label: Text(l.editorSaveCopy),
                  ),
                  TextButton.icon(
                    key: const Key('editor.copyAll'),
                    onPressed: onCopyAll,
                    icon: const SymbolIcon(FileIcons.copyAll, size: 18),
                    label: Text(l.editorCopyAll),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
