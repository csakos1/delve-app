import 'package:flutter/material.dart';

import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import 'files_ui.dart';
import 'page_scaffolds.dart';

/// 23n3: what to do with an edit whose file changed on the desktop.
enum EditConflictChoice { overwrite, reload }

/// 23n3, in 23f's shape: the desktop's version, the opened one, the edit;
/// Overwrite · Reload · Cancel (null).
Future<EditConflictChoice?> showEditConflict(
  BuildContext context, {
  required String name,
  required RemoteEntry? desktop,
  required TextFile opened,
  required int editBytes,
  required int changed,
}) => showDialog<EditConflictChoice>(
  context: context,
  builder: (ctx) {
    final l = AppLocalizations.of(ctx);
    final d = ctx.delve;
    final now = DateTime.now();
    final muted = ctx.text.labelMedium!.copyWith(color: d.textMuted);
    String meta(int? size, DateTime? at) => [
      if (size != null) sizeText(size),
      if (at != null) fileTime(at, now),
    ].join(' · ');
    Widget row(String label, String value, Key key) => Padding(
      padding: const EdgeInsets.only(bottom: DelveTokens.space1),
      child: Text(
        value.isEmpty ? label : '$label · $value',
        key: key,
        style: muted,
      ),
    );
    return AlertDialog(
      key: const Key('editor.conflict'),
      icon: SymbolIcon(FileIcons.editConflict, color: d.warnFg),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: DelveText.mono.copyWith(
                fontSize: ctx.text.titleLarge!.fontSize,
              ),
            ),
            TextSpan(text: l.editorConflictTitle),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            l.editorConflictDesktop,
            desktop == null
                ? l.editorConflictDeleted
                : meta(desktop.size, desktop.modified),
            const Key('editor.conflict.desktop'),
          ),
          row(
            l.editorConflictOpened,
            meta(opened.size, opened.modified),
            const Key('editor.conflict.opened'),
          ),
          row(
            l.editorConflictYours,
            [sizeText(editBytes), l.editorChanged(changed)].join(' · '),
            const Key('editor.conflict.yours'),
          ),
          const SizedBox(height: DelveTokens.space2),
          EditorChoice(
            key: const Key('editor.conflict.overwrite'),
            icon: FileIcons.overwrite,
            label: l.editorOverwrite,
            hint: l.editorOverwriteHint,
            alert: true,
            onTap: () => Navigator.of(ctx).pop(EditConflictChoice.overwrite),
          ),
          EditorChoice(
            key: const Key('editor.conflict.reload'),
            icon: FileIcons.reload,
            label: l.editorReload,
            hint: l.editorReloadHint(changed),
            onTap: () => Navigator.of(ctx).pop(EditConflictChoice.reload),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('editor.conflict.cancel'),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.cancel),
        ),
      ],
    );
  },
);

/// A 56 dp choice row of a dialog (23f / 23n3).
class EditorChoice extends StatelessWidget {
  const EditorChoice({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final d = context.delve;
    final fg = alert ? d.alertFg : context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: DelveTokens.space2),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
                vertical: DelveTokens.space2,
              ),
              child: Row(
                children: [
                  SymbolIcon(icon, size: 22, color: fg),
                  const SizedBox(width: DelveTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.text.labelLarge!.copyWith(
                            color: alert ? d.alertFg : null,
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
  }
}

/// 23n4: leaving with an unsaved edit.
enum DiscardChoice { discard, save }

/// "Discard changes?" – Discard (alert, left) · Keep editing (null) ·
/// Save (filled; off when [canSave] is false).
Future<DiscardChoice?> showDiscardDialog(
  BuildContext context, {
  required String name,
  required int changed,
  required bool canSave,
}) => showDialog<DiscardChoice>(
  context: context,
  builder: (ctx) {
    final l = AppLocalizations.of(ctx);
    return AlertDialog(
      key: const Key('editor.discard'),
      icon: SymbolIcon(FileIcons.discard, color: ctx.delve.alertFg),
      title: Text(l.editorDiscardTitle),
      content: Text(l.editorDiscardBody(changed, name)),
      // Discard first: on a narrow screen the buttons stack, Save last
      actions: [
        TextButton(
          key: const Key('editor.discard.discard'),
          style: TextButton.styleFrom(foregroundColor: ctx.delve.alertFg),
          onPressed: () => Navigator.of(ctx).pop(DiscardChoice.discard),
          child: Text(l.editorDiscardAction),
        ),
        TextButton(
          key: const Key('editor.discard.keep'),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.editorKeepEditing),
        ),
        FilledButton(
          key: const Key('editor.discard.save'),
          onPressed: canSave
              ? () => Navigator.of(ctx).pop(DiscardChoice.save)
              : null,
          child: Text(l.editorSave),
        ),
      ],
    );
  },
);
