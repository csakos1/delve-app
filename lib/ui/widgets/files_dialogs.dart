import 'dart:async';

import 'package:flutter/material.dart';

import '../../attachments/picker.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import 'files_ui.dart';
import 'page_scaffolds.dart';

/// The words for a name that can't be one.
String nameProblemText(AppLocalizations l, NameProblem p) => switch (p) {
  NameProblem.empty => l.filesNameEmpty,
  NameProblem.dots => l.filesNameDots,
  NameProblem.slash => l.filesNameSlash,
  NameProblem.tooLong => l.filesNameTooLong,
};

/// What a failed write says (a dialog's error line, a snackbar).
String writeErrorText(AppLocalizations l, Object e) => switch (e) {
  BadName(:final problem) => nameProblemText(l, problem),
  RemoteFsError(failure: FsFailure.exists, :final detail) => l.filesNameTaken(
    baseName(detail),
  ),
  RemoteFsError(failure: FsFailure.denied) => l.filesWriteDenied,
  RemoteFsError(failure: FsFailure.unreachable) => l.filesWriteOffline,
  RemoteFsError(:final detail) => detail,
  _ => '$e',
};

/// A name for a new folder or a rename: [submit] does it and returns an
/// error to show (the dialog stays), or null (it closes with the name).
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String action,
  required Future<String?> Function(String name) submit,
  String initial = '',
  Key? fieldKey,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NameDialog(
    title: title,
    action: action,
    initial: initial,
    submit: submit,
    fieldKey: fieldKey ?? const Key('files.name.field'),
  ),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initial,
    required this.submit,
    required this.fieldKey,
  });

  final String title;
  final String action;
  final String initial;
  final Future<String?> Function(String name) submit;
  final Key fieldKey;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // a rename selects the name without its extension
    final (stem, _) = splitExtension(widget.initial);
    _name.selection = TextSelection(baseOffset: 0, extentOffset: stem.length);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (checkName(name) case final p?) {
      setState(() => _error = nameProblemText(l, p));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.submit(name);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(name);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _name,
        autofocus: true,
        enabled: !_busy,
        style: DelveText.mono,
        decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => unawaited(_go()),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('files.name.ok'),
          onPressed: _busy ? null : () => unawaited(_go()),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// 23f: [name] is taken in the folder. A choice acts on tap; with
/// [count] > 1 "Apply to all" covers the rest. Null: cancelled.
Future<(ConflictChoice, bool)?> showConflictDialog(
  BuildContext context, {
  required String name,
  required RemoteEntry here,
  required int? incomingSize,
  required int count,
  String? cancelLabel,
}) => showDialog<(ConflictChoice, bool)>(
  context: context,
  builder: (_) => _ConflictDialog(
    name: name,
    here: here,
    incomingSize: incomingSize,
    count: count,
    cancelLabel: cancelLabel,
  ),
);

class _ConflictDialog extends StatefulWidget {
  const _ConflictDialog({
    required this.name,
    required this.here,
    required this.incomingSize,
    required this.count,
    required this.cancelLabel,
  });

  final String name;
  final RemoteEntry here;
  final int? incomingSize;
  final int count;
  final String? cancelLabel;

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final muted = context.text.labelMedium!.copyWith(color: d.textMuted);
    final here = widget.here;
    final folder = here.isDir;
    Widget choice(
      ConflictChoice c,
      IconData icon,
      String label,
      String hint, {
      bool enabled = true,
    }) => Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space2),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('files.conflict.${c.name}'),
          onTap: enabled ? () => Navigator.of(context).pop((c, _all)) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
                vertical: DelveTokens.space2,
              ),
              child: Row(
                children: [
                  SymbolIcon(
                    icon,
                    size: 22,
                    color: enabled
                        ? context.colors.onSurfaceVariant
                        : d.textDisabled,
                  ),
                  const SizedBox(width: DelveTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.text.labelLarge!.copyWith(
                            color: enabled ? null : d.textDisabled,
                          ),
                        ),
                        Text(
                          hint,
                          style: context.text.bodySmall!.copyWith(
                            color: d.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final hereMeta = [
      if (folder)
        l.filesFolder
      else if (here.size != null)
        sizeText(here.size!),
      if (here.modified != null) fileTime(here.modified!, DateTime.now()),
    ].join(' · ');
    return AlertDialog(
      key: const Key('files.conflict'),
      icon: SymbolIcon(FileIcons.conflict, color: d.warnFg),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: widget.name,
              style: DelveText.mono.copyWith(
                fontSize: context.text.titleLarge!.fontSize,
              ),
            ),
            TextSpan(text: l.filesConflictTitle),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${l.filesConflictHere} · $hereMeta', style: muted),
          if (widget.incomingSize case final n?)
            Text('${l.filesConflictIncoming} · ${sizeText(n)}', style: muted),
          const SizedBox(height: DelveTokens.space2),
          choice(
            ConflictChoice.skip,
            FileIcons.skip,
            l.filesConflictSkip,
            l.filesConflictSkipHint,
          ),
          choice(
            ConflictChoice.replace,
            FileIcons.replace,
            l.filesConflictReplace,
            folder ? l.filesConflictReplaceFolder : l.filesConflictReplaceHint,
            enabled: !folder,
          ),
          choice(
            ConflictChoice.keepBoth,
            FileIcons.keepBoth,
            l.filesConflictKeepBoth,
            l.filesConflictKeepBothHint(keepBothName(widget.name, 2)),
          ),
          if (widget.count > 1)
            CheckboxListTile(
              key: const Key('files.conflict.all'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _all,
              onChanged: (v) => setState(() => _all = v ?? false),
              title: Text(l.filesConflictAll(widget.count)),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('files.conflict.cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel ?? l.cancel),
        ),
      ],
    );
  }
}

/// Asks about each picked name that is taken in [here] (23f, one at a
/// time, "Apply to all" covers the rest). Null: cancelled.
Future<Map<String, ConflictChoice>?> resolveUploadConflicts(
  BuildContext context, {
  required Map<String, RemoteEntry> here,
  required List<PickedAttachment> files,
}) => resolveConflicts(
  context,
  here: here,
  incoming: [for (final f in files) (FilesOps.uploadName(f.name), f.size)],
  cancelLabel: AppLocalizations.of(context).filesConflictCancelUpload,
);

/// Asks about each incoming (name, size) whose name is taken in [here]
/// (23f, one at a time, "Apply to all" covers the rest; a folder here is
/// never replaced). Null: cancelled.
Future<Map<String, ConflictChoice>?> resolveConflicts(
  BuildContext context, {
  required Map<String, RemoteEntry> here,
  required List<(String, int?)> incoming,
  required String cancelLabel,
}) async {
  final taken = <String, int?>{};
  for (final (name, size) in incoming) {
    if (here.containsKey(name) && !taken.containsKey(name)) {
      taken[name] = size;
    }
  }
  final choices = <String, ConflictChoice>{};
  final names = taken.keys.toList();
  for (var i = 0; i < names.length; i++) {
    final name = names[i];
    final answer = await showConflictDialog(
      context,
      name: name,
      here: here[name]!,
      incomingSize: taken[name],
      count: names.length - i,
      cancelLabel: cancelLabel,
    );
    if (answer == null) return null;
    if (!context.mounted) return null;
    final (choice, all) = answer;
    if (all) {
      for (final n in names.skip(i)) {
        // a folder is never replaced
        choices[n] = choice == ConflictChoice.replace && here[n]!.isDir
            ? ConflictChoice.keepBoth
            : choice;
      }
      break;
    }
    choices[name] = choice;
  }
  return choices;
}

/// Uploads [files] to [dir] after asking about taken names; false when
/// cancelled or the folder could not be read (a snackbar says why).
Future<bool> uploadAsking(
  BuildContext context,
  FilesService service,
  String dir,
  List<PickedAttachment> files,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final Map<String, RemoteEntry> here;
  try {
    here = await service.entriesIn(dir);
  } on RemoteFsError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.filesUploadFailed(writeErrorText(l, e)))),
      );
    return false;
  }
  if (!context.mounted) return false;
  final choices = await resolveUploadConflicts(
    context,
    here: here,
    files: files,
  );
  if (choices == null) return false;
  service.upload(dir, files, here: here, choices: choices);
  return true;
}

/// Pastes the clip into [dir] after asking about taken names (23f);
/// null when cancelled or the folder could not be read (a snackbar says
/// why).
Future<PasteResult?> pasteAsking(
  BuildContext context,
  FilesService service,
  String dir,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(Object e) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(l.filesPasteFailed(writeErrorText(l, e)))),
    );
  final Map<String, RemoteEntry> here;
  try {
    here = await service.entriesIn(dir);
  } on RemoteFsError catch (e) {
    say(e);
    return null;
  }
  if (!context.mounted) return null;
  final conflicts = service.pasteConflicts(dir, here);
  final choices = await resolveConflicts(
    context,
    here: here,
    incoming: [for (final e in conflicts) (e.name, e.isDir ? null : e.size)],
    cancelLabel: l.filesConflictCancelPaste,
  );
  if (choices == null) return null;
  try {
    return await service.paste(dir, here: here, choices: choices);
  } on RemoteFsError catch (e) {
    say(e);
    return null;
  }
}

/// A filled alert button (the strong, irreversible choice).
class AlertFilledButton extends StatelessWidget {
  const AlertFilledButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: context.delve.alertFg,
      foregroundColor: context.colors.onError,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// 23j: delete [title] for good ([what] in mono: its path and size;
/// [body] why there is no trash).
Future<bool> confirmDeleteForever(
  BuildContext context, {
  required String what,
  required String body,
  String? title,
}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('files.deleteForever'),
      icon: SymbolIcon(FileIcons.deleteForever, color: ctx.delve.alertFg),
      title: Text(title ?? l.filesDeleteForeverTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            what,
            style: DelveText.monoSmall.copyWith(color: ctx.colors.onSurface),
          ),
          const SizedBox(height: DelveTokens.space3),
          Text(body),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        AlertFilledButton(
          key: const Key('files.deleteForever.ok'),
          onPressed: () => Navigator.of(ctx).pop(true),
          label: l.filesDeleteForever,
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// 23i2: empty the trash – the button stays off until the box is ticked.
Future<bool> confirmEmptyTrash(
  BuildContext context, {
  required int count,
  required int? size,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _EmptyTrashDialog(count: count, size: size),
  );
  return ok ?? false;
}

class _EmptyTrashDialog extends StatefulWidget {
  const _EmptyTrashDialog({required this.count, required this.size});

  final int count;
  final int? size;

  @override
  State<_EmptyTrashDialog> createState() => _EmptyTrashDialogState();
}

class _EmptyTrashDialogState extends State<_EmptyTrashDialog> {
  bool _sure = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final what = [
      itemsText(l, widget.count),
      if (widget.size != null) sizeText(widget.size!),
    ].join(' · ');
    return AlertDialog(
      key: const Key('trash.emptyDialog'),
      icon: SymbolIcon(FileIcons.deleteForever, color: context.delve.alertFg),
      title: Text(l.trashEmptyTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            what,
            style: DelveText.mono.copyWith(color: context.colors.onSurface),
          ),
          const SizedBox(height: DelveTokens.space3),
          Text(l.trashEmptyBody),
          const SizedBox(height: DelveTokens.space2),
          CheckboxListTile(
            key: const Key('trash.emptySure'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _sure,
            onChanged: (v) => setState(() => _sure = v ?? false),
            title: Text(l.trashEmptySure(widget.count)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        AlertFilledButton(
          key: const Key('trash.emptyOk'),
          onPressed: _sure ? () => Navigator.of(context).pop(true) : null,
          label: l.trashEmpty,
        ),
      ],
    );
  }
}

/// 23k1: where the upload comes from (the composer's sources, with the
/// target folder on top).
enum UploadSource { photos, camera, files }

Future<UploadSource?> showUploadSourceSheet(
  BuildContext context, {
  required String folder,
  required String path,
}) => showModalBottomSheet<UploadSource>(
  context: context,
  showDragHandle: true,
  builder: (ctx) {
    final l = AppLocalizations.of(ctx);
    Widget tile(UploadSource s, IconData icon, String label, String hint) =>
        ListTile(
          key: Key('files.upload.${s.name}'),
          minTileHeight: 64,
          leading: SymbolIcon(icon, color: ctx.colors.onSurfaceVariant),
          title: Text(label, style: ctx.text.bodyLarge),
          subtitle: Text(
            hint,
            style: ctx.text.bodySmall!.copyWith(color: ctx.delve.textMuted),
          ),
          onTap: () => Navigator.of(ctx).pop(s),
        );
    return SafeArea(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.filesUploadTo(folder), style: ctx.text.titleMedium),
                Text(
                  path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DelveText.monoSmall.copyWith(
                    color: ctx.delve.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          tile(
            UploadSource.photos,
            DelveIcons.photos,
            l.attachPhotos,
            l.filesUploadPhotosHint,
          ),
          tile(
            UploadSource.camera,
            DelveIcons.camera,
            l.attachCamera,
            l.filesUploadCameraHint,
          ),
          tile(
            UploadSource.files,
            DelveIcons.attachFile,
            l.filesUploadFiles,
            l.filesUploadFilesHint,
          ),
          const SizedBox(height: DelveTokens.space2),
        ],
      ),
    );
  },
);

/// Up to this many photos or files in one upload.
const kMaxUpload = 100;

/// Asks for the source and picks; null when nothing was picked (a failed
/// pick says so).
Future<List<PickedAttachment>?> pickForUpload(
  BuildContext context,
  AttachmentPicker picker, {
  required String folder,
  required String path,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final source = await showUploadSourceSheet(
    context,
    folder: folder,
    path: path,
  );
  if (source == null) return null;
  try {
    final picked = switch (source) {
      UploadSource.photos => await picker.photos(limit: kMaxUpload),
      UploadSource.camera => [?await picker.camera()],
      UploadSource.files => await picker.files(limit: kMaxUpload),
    };
    return picked.isEmpty ? null : picked;
  } on Exception catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.attachPickFailed('$e'))));
    return null;
  }
}
