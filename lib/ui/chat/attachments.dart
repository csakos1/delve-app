import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../attachments/attachment_store.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';

// Attachments in the composer (design 17: thumbnail, name, ✕) and in the
// chat (photos as tiles, files as chips); a tap opens a photo full screen or
// a file's details, both with "Send again" (N62: the model no longer sees
// earlier photos).

/// What a failed draft shows.
String draftProblemText(AppLocalizations l, DraftProblem? p) => switch (p) {
  DraftTooLarge(:final limit) => l.attachTooLarge(byteSize(limit)),
  DraftUnreadable() => l.attachUnreadable,
  DraftUploadFailed(:final error) => apiErrorText(l, error),
  null => l.attachFailedShort,
};

/// The composer's attachments, in one scrolling row above the text field.
class DraftAttachmentStrip extends StatelessWidget {
  const DraftAttachmentStrip({super.key, required this.controller});

  final ComposerAttachments controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final items = controller.items;
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(DelveTokens.space1),
        child: SingleChildScrollView(
          key: const Key('composer.attachments'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in items)
                Padding(
                  padding: const EdgeInsets.only(right: DelveTokens.space2),
                  child: DraftAttachmentChip(
                    key: ValueKey('draft.${d.localId}'),
                    draft: d,
                    onRemove: () => controller.remove(d.localId),
                    onRetry: () => controller.retry(d.localId),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// One attachment in the composer: a 40 dp thumbnail (or a file icon), the
/// name and ✕. Uploading: a spinner on the thumbnail; failed: an alert icon,
/// the reason, and a tap retries.
class DraftAttachmentChip extends StatelessWidget {
  const DraftAttachmentChip({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.onRetry,
  });

  final DraftAttachment draft;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final failed = draft.state == DraftState.failed;
    final working =
        draft.state == DraftState.preparing ||
        draft.state == DraftState.uploading;

    final Widget thumb;
    if (failed) {
      thumb = SymbolIcon(
        DelveIcons.error,
        size: DelveTokens.iconMd,
        filled: true,
        color: d.alertFg,
      );
    } else if (draft.preview case final Uint8List bytes) {
      thumb = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        cacheWidth: 120,
        gaplessPlayback: true,
      );
    } else {
      thumb = SymbolIcon(
        draft.isImage ? DelveIcons.photos : DelveIcons.file,
        size: DelveTokens.iconMd,
        color: cs.onSurfaceVariant,
      );
    }

    final label = failed
        ? l.attachFailedRetry(draft.filename)
        : working
        ? l.attachUploading(draft.filename)
        : draft.filename;

    return Semantics(
      label: label,
      button: failed,
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DelveTokens.rsm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: failed ? onRetry : null,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: DelveTokens.space1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DelveTokens.rxs),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        Center(child: thumb),
                        if (working)
                          ColoredBox(
                            color: cs.surface.withValues(alpha: 0.55),
                            child: const Center(
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DelveTokens.space3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                      if (failed)
                        Text(
                          draftProblemText(l, draft.problem),
                          key: const Key('draft.problem'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall!.copyWith(
                            color: d.alertFg,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('draft.remove'),
                  tooltip: l.attachRemove(draft.filename),
                  visualDensity: VisualDensity.compact,
                  icon: SymbolIcon(
                    DelveIcons.close,
                    size: 18,
                    color: d.textMuted,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A user message's attachments: photos as tiles (one large, several in a
/// grid of 112 dp), files as chips; right-aligned above the text.
class MessageAttachments extends StatelessWidget {
  const MessageAttachments({
    super.key,
    required this.attachments,
    required this.onOpen,
  });

  final List<Attachment> attachments;
  final void Function(Attachment)? onOpen;

  @override
  Widget build(BuildContext context) {
    final images = [
      for (final a in attachments)
        if (a.isImage) a,
    ];
    final files = [
      for (final a in attachments)
        if (!a.isImage) a,
    ];
    final tile = images.length == 1 ? 200.0 : 112.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: DelveTokens.space2,
            runSpacing: DelveTokens.space2,
            children: [
              for (final a in images)
                AttachmentTile(
                  key: ValueKey('att.${a.id}'),
                  attachment: a,
                  size: tile,
                  onTap: onOpen == null ? null : () => onOpen!(a),
                ),
            ],
          ),
        for (final a in files)
          Padding(
            padding: EdgeInsets.only(
              top: images.isEmpty && a == files.first ? 0 : DelveTokens.space2,
            ),
            child: FileChip(
              key: ValueKey('att.${a.id}'),
              attachment: a,
              onTap: onOpen == null ? null : () => onOpen!(a),
            ),
          ),
      ],
    );
  }
}

/// A photo in the chat, loaded from the server (or the upload's own bytes).
class AttachmentTile extends ConsumerWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.size,
    this.onTap,
  });

  final Attachment attachment;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final Widget body;
    if (!attachment.available) {
      body = _Gone(text: l.attachGone);
    } else {
      final bytes = ref.watch(attachmentBytesProvider(attachment.id));
      body = switch (bytes) {
        AsyncData(:final value) => Image.memory(
          value,
          fit: BoxFit.cover,
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _Gone(text: l.attachLoadFailed),
        ),
        AsyncError() => _Gone(text: l.attachLoadFailed),
        _ => const Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      };
    }
    return Semantics(
      image: true,
      button: onTap != null,
      label: l.attachImage(attachment.filename),
      child: Material(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
          side: BorderSide(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(dimension: size, child: body),
        ),
      ),
    );
  }
}

class _Gone extends StatelessWidget {
  const _Gone({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final d = context.delve;
    return Padding(
      padding: const EdgeInsets.all(DelveTokens.space2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SymbolIcon(DelveIcons.imageGone, size: 22, color: d.textMuted),
          const SizedBox(height: DelveTokens.space1),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall!.copyWith(color: d.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A file in the chat: icon, name, size (or "No longer available").
class FileChip extends StatelessWidget {
  const FileChip({super.key, required this.attachment, this.onTap});

  final Attachment attachment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final meta = attachment.available
        ? byteSize(attachment.sizeBytes)
        : l.attachGone;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
          side: BorderSide(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DelveTokens.space3,
              vertical: DelveTokens.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolIcon(
                  attachment.available ? DelveIcons.file : DelveIcons.imageGone,
                  size: DelveTokens.iconMd,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: DelveTokens.space2),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                      Text(
                        meta,
                        style: context.text.labelSmall!.copyWith(
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
    );
  }
}

/// A photo full screen (pinch to zoom), with "Send again".
class AttachmentViewer extends ConsumerWidget {
  const AttachmentViewer({
    super.key,
    required this.attachment,
    this.onSendAgain,
  });

  final Attachment attachment;
  final VoidCallback? onSendAgain;

  static Future<void> open(
    BuildContext context,
    Attachment attachment, {
    VoidCallback? onSendAgain,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          AttachmentViewer(attachment: attachment, onSendAgain: onSendAgain),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bytes = ref.watch(attachmentBytesProvider(attachment.id));
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: context.colors.surfaceContainer,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const SymbolIcon(DelveIcons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          attachment.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium,
        ),
        actions: [
          if (onSendAgain != null)
            TextButton.icon(
              key: const Key('viewer.sendAgain'),
              icon: const SymbolIcon(DelveIcons.sendAgain, size: 18),
              label: Text(l.attachSendAgain),
              onPressed: () {
                Navigator.of(context).maybePop();
                onSendAgain!();
              },
            ),
          const SizedBox(width: DelveTokens.space2),
        ],
      ),
      body: Center(
        child: switch (bytes) {
          AsyncData(:final value) => InteractiveViewer(
            maxScale: 6,
            child: Image.memory(value, gaplessPlayback: true),
          ),
          AsyncError() => _Gone(text: l.attachLoadFailed),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}

/// A file's details: name, type, size, and "Send again".
Future<void> showFileSheet(
  BuildContext context,
  Attachment attachment, {
  VoidCallback? onSendAgain,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space6,
          0,
          DelveTokens.space6,
          DelveTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attachment.filename, style: context.text.titleMedium),
            const SizedBox(height: DelveTokens.space1),
            Text(
              attachment.available
                  ? '${attachment.mime} · ${byteSize(attachment.sizeBytes)}'
                  : l.attachGone,
              style: context.text.bodySmall!.copyWith(color: d.textMuted),
            ),
            if (onSendAgain != null) ...[
              const SizedBox(height: DelveTokens.space4),
              FilledButton.tonalIcon(
                key: const Key('file.sendAgain'),
                icon: const SymbolIcon(DelveIcons.sendAgain, size: 18),
                label: Text(l.attachSendAgain),
                onPressed: () {
                  Navigator.of(context).pop();
                  onSendAgain();
                },
              ),
            ],
          ],
        ),
      ),
    );
  },
);

/// Where a new attachment comes from (the composer's "+").
enum AttachSource { photos, camera, file }

/// The "+" menu: Photos, Camera, File.
Future<AttachSource?> showAttachSourceSheet(BuildContext context) =>
    showModalBottomSheet<AttachSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l = AppLocalizations.of(context);
        Widget tile(AttachSource s, IconData icon, String label) => ListTile(
          key: Key('attach.${s.name}'),
          leading: SymbolIcon(icon),
          title: Text(label),
          onTap: () => Navigator.of(context).pop(s),
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(AttachSource.photos, DelveIcons.photos, l.attachPhotos),
              tile(AttachSource.camera, DelveIcons.camera, l.attachCamera),
              tile(AttachSource.file, DelveIcons.attachFile, l.attachFile),
              const SizedBox(height: DelveTokens.space2),
            ],
          ),
        );
      },
    );

/// The composer's "+": asks for Photos, Camera or File and adds what is
/// picked (it starts uploading at once); a snackbar says what did not fit.
Future<void> pickAttachmentsInto(
  BuildContext context,
  AttachmentPicker picker,
  ComposerAttachments attachments,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  final room = attachments.room;
  if (room <= 0) {
    snack(l.attachLimit(kMaxAttachments));
    return;
  }
  final source = await showAttachSourceSheet(context);
  if (source == null || !context.mounted) return;
  final List<PickedAttachment> picked;
  try {
    picked = switch (source) {
      AttachSource.photos => await picker.photos(limit: room),
      AttachSource.camera => [?await picker.camera()],
      AttachSource.file => await picker.files(limit: room),
    };
  } on Exception catch (e) {
    if (context.mounted) snack(l.attachPickFailed('$e'));
    return;
  }
  if (!context.mounted || picked.isEmpty) return;
  final left = attachments.addAll(picked);
  if (left > 0) snack(l.attachLeftOut(left, kMaxAttachments));
}
