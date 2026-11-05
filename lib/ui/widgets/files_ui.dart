import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import 'page_scaffolds.dart';

/// Design 23 sizes (delve_tokens.json → files).
abstract final class FilesTokens {
  static const double row = 56;
  static const double tile = 40;
  static const double tileRadius = 10;
  static const double badge = 18;
  static const double badgeIcon = 12;
  static const double breadcrumb = 48;
  static const double quickRow = 48;
  static const double quickChip = 32;
  static const double quickChipRadius = 8;
  static const double listHeader = 32;
  static const double transferChip = 32;
  static const double transferBar = 4;
  static const double previewGutter = 34;
}

abstract final class FileIcons {
  static const IconData folder = Symbols.folder_rounded;
  static const IconData folderOpen = Symbols.folder_open_rounded;
  static const IconData pdf = Symbols.picture_as_pdf_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData text = Symbols.description_rounded;
  static const IconData code = Symbols.code_rounded;
  static const IconData structured = Symbols.data_object_rounded;
  static const IconData archive = Symbols.folder_zip_rounded;
  static const IconData executable = Symbols.terminal_rounded;
  static const IconData video = Symbols.video_file_rounded;
  static const IconData audio = Symbols.audio_file_rounded;
  static const IconData other = Symbols.draft_rounded;
  static const IconData link = Symbols.link_rounded;
  static const IconData lock = Symbols.lock_rounded;
  static const IconData home = Symbols.home_rounded;
  static const IconData download = Symbols.download_rounded;
  static const IconData documents = Symbols.description_rounded;
  static const IconData preview = Symbols.visibility_rounded;
  static const IconData copyPath = Symbols.content_copy_rounded;
  static const IconData goTo = Symbols.subdirectory_arrow_right_rounded;
  static const IconData chevron = Symbols.chevron_right_rounded;
  static const IconData arrowUp = Symbols.arrow_upward_rounded;
  static const IconData arrowDown = Symbols.arrow_downward_rounded;
  static const IconData ellipsis = Symbols.more_horiz_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData done = Symbols.check_circle_rounded;
  static const IconData failed = Symbols.error_rounded;
  static const IconData queued = Symbols.schedule_rounded;
  static const IconData cancelled = Symbols.block_rounded;
  static const IconData notFound = Symbols.search_off_rounded;
  static const IconData numbers = Symbols.format_list_numbered_rounded;
  static const IconData radioOn = Symbols.radio_button_checked_rounded;
  static const IconData radioOff = Symbols.radio_button_unchecked_rounded;
  static const IconData upload = Symbols.upload_rounded;
  static const IconData newFolder = Symbols.create_new_folder_rounded;
  static const IconData rename = Symbols.drive_file_rename_outline_rounded;
  static const IconData trash = Symbols.delete_rounded;
  static const IconData restore = Symbols.restore_from_trash_rounded;
  static const IconData deleteForever = Symbols.delete_forever_rounded;
  static const IconData saveToDesktop = Symbols.drive_folder_upload_rounded;
  static const IconData conflict = Symbols.file_copy_rounded;
  static const IconData skip = Symbols.redo_rounded;
  static const IconData replace = Symbols.find_replace_rounded;
  static const IconData keepBoth = Symbols.library_add_rounded;
}

IconData fileIcon(FileType t) => switch (t) {
  FileType.folder => FileIcons.folder,
  FileType.pdf => FileIcons.pdf,
  FileType.image => FileIcons.image,
  FileType.text => FileIcons.text,
  FileType.code => FileIcons.code,
  FileType.structured => FileIcons.structured,
  FileType.archive => FileIcons.archive,
  FileType.executable => FileIcons.executable,
  FileType.video => FileIcons.video,
  FileType.audio => FileIcons.audio,
  FileType.other => FileIcons.other,
};

/// `2 Nov 22:30` this year, `2 Nov 2025` before.
String fileTime(DateTime at, DateTime now) {
  final a = at.toLocal();
  return a.year == now.toLocal().year
      ? DateFormat('d MMM HH:mm').format(a)
      : DateFormat('d MMM y').format(a);
}

/// `4,703 items`.
String itemsText(AppLocalizations l, int n) => l.filesItems(n, tokenCount(n));

/// 40 dp tile with the type icon and a link / lock badge.
class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.entry, this.locked = false});

  final RemoteEntry entry;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final type = fileTypeOf(entry);
    final badge = locked
        ? FileIcons.lock
        : entry.isLink
        ? FileIcons.link
        : null;
    return SizedBox(
      width: FilesTokens.tile,
      height: FilesTokens.tile,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(FilesTokens.tileRadius),
              ),
              child: Center(
                child: SymbolIcon(
                  fileIcon(type),
                  filled: type == FileType.folder,
                  color: entry.hidden
                      ? context.delve.textMuted
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                width: FilesTokens.badge + 4,
                height: FilesTokens.badge + 4,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Center(
                  child: SymbolIcon(
                    badge,
                    size: FilesTokens.badgeIcon,
                    filled: true,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 56 dp row: tile, name (one line, middle ellipsis), one meta line, ⋮.
class FileRow extends StatelessWidget {
  const FileRow({
    super.key,
    required this.entry,
    required this.meta,
    required this.onTap,
    required this.onMenu,
    this.locked = false,
    this.mono = false,
  });

  final RemoteEntry entry;

  /// The meta line (size and date, item count, link target, permission).
  final String meta;

  /// The meta line is a path (link target): mono.
  final bool mono;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final dim = entry.hidden || locked;
    return InkWell(
      key: Key('files.row.${entry.name}'),
      onTap: onTap,
      onLongPress: onMenu,
      child: SizedBox(
        height: FilesTokens.row,
        child: Padding(
          padding: const EdgeInsets.only(left: DelveTokens.space4, right: 4),
          child: Row(
            children: [
              FileTile(entry: entry, locked: locked),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiddleEllipsis(
                      entry.name,
                      style: context.text.bodyMedium!.copyWith(
                        color: dim ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        if (entry.isLink) ...[
                          SymbolIcon(FileIcons.link, size: 14, color: muted),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mono
                                ? DelveText.monoSmall.copyWith(color: muted)
                                : context.text.labelMedium!.copyWith(
                                    color: muted,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('files.menu.${entry.name}'),
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                icon: const SymbolIcon(Symbols.more_vert_rounded),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of text cut in the middle (`delve-backend-…-2026.log`), so the
/// end of a long name (its extension, a number) stays visible.
class MiddleEllipsis extends StatelessWidget {
  const MiddleEllipsis(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context);
      bool fits(String s) {
        final p = TextPainter(
          text: TextSpan(text: s, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: scale,
        )..layout();
        final ok = p.width <= box.maxWidth;
        p.dispose();
        return ok;
      }

      var shown = text;
      if (box.maxWidth.isFinite && !fits(text)) {
        // binary search on how many characters each side keeps
        var lo = 1;
        var hi = text.length ~/ 2;
        var best = '${text.substring(0, 1)}…';
        while (lo <= hi) {
          final mid = (lo + hi) ~/ 2;
          final s =
              '${text.substring(0, mid)}…${text.substring(text.length - mid)}';
          if (fits(s)) {
            best = s;
            lo = mid + 1;
          } else {
            hi = mid - 1;
          }
        }
        shown = best;
      }
      return Text(
        shown,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: style,
        semanticsLabel: text,
      );
    },
  );
}

/// 48 dp breadcrumb: mono segments with chevrons, scrolled to the end;
/// the start collapses to `…` (a menu of the hidden ancestors).
class Breadcrumb extends StatefulWidget {
  const Breadcrumb({super.key, required this.path, required this.onOpen});

  final String path;
  final ValueChanged<String> onOpen;

  @override
  State<Breadcrumb> createState() => _BreadcrumbState();
}

class _BreadcrumbState extends State<Breadcrumb> {
  final _scroll = ScrollController();

  /// Segments kept at the end before the start collapses.
  static const _keep = 2;
  static const _collapseAbove = 4;

  @override
  void didUpdateWidget(Breadcrumb old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _toEnd();
  }

  @override
  void initState() {
    super.initState();
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _hidden(
    BuildContext context,
    List<(String, String)> hidden,
  ) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(Offset.zero, ancestor: overlay);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        at.dx,
        at.dy + box.size.height,
        overlay.size.width - at.dx,
        0,
      ),
      items: [
        for (final (label, path) in hidden)
          PopupMenuItem(
            value: path,
            child: Text(label, style: DelveText.mono),
          ),
      ],
    );
    if (choice != null) widget.onOpen(choice);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final segs = pathSegments(widget.path);
    final collapse = segs.length > _collapseAbove;
    final hidden = collapse ? segs.sublist(0, segs.length - _keep) : null;
    final shown = collapse ? segs.sublist(segs.length - _keep) : segs;
    Widget sep() => SymbolIcon(FileIcons.chevron, size: 16, color: muted);
    final children = <Widget>[
      if (hidden != null) ...[
        Builder(
          builder: (context) => IconButton(
            key: const Key('files.crumb.more'),
            tooltip: hidden.last.$2,
            icon: SymbolIcon(
              FileIcons.ellipsis,
              size: DelveTokens.iconMd,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () => _hidden(context, hidden),
          ),
        ),
        sep(),
      ],
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) sep(),
        InkWell(
          key: Key('files.crumb.${shown[i].$2}'),
          onTap: () => widget.onOpen(shown[i].$2),
          borderRadius: BorderRadius.circular(DelveTokens.rxs),
          child: Container(
            height: DelveTokens.touchTarget,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              shown[i].$1,
              style: DelveText.mono.copyWith(
                color: i == shown.length - 1
                    ? cs.onSurface
                    : cs.onSurfaceVariant,
                fontWeight: i == shown.length - 1
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    ];
    return SizedBox(
      height: FilesTokens.breadcrumb,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: DelveTokens.space2),
        child: Row(children: children),
      ),
    );
  }
}

/// A quick location: its icon, label (a path in mono) and where it goes.
class QuickLocation {
  const QuickLocation(this.icon, this.label, this.path, {this.mono = false});

  final IconData icon;
  final String label;
  final String path;
  final bool mono;
}

/// 48 dp row of 32 dp chips; the current location is an accent chip (its
/// own icon, no check mark).
class QuickLocations extends StatelessWidget {
  const QuickLocations({
    super.key,
    required this.locations,
    required this.current,
    required this.onOpen,
  });

  final List<QuickLocation> locations;
  final String? current;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SizedBox(
      height: FilesTokens.quickRow,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DelveTokens.space4,
          vertical: (FilesTokens.quickRow - FilesTokens.quickChip) / 2,
        ),
        itemCount: locations.length,
        separatorBuilder: (_, _) => const SizedBox(width: DelveTokens.space2),
        itemBuilder: (context, i) {
          final q = locations[i];
          final on = q.path == current;
          final fg = on ? cs.onPrimaryContainer : cs.onSurfaceVariant;
          return Material(
            color: on ? cs.primaryContainer : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FilesTokens.quickChipRadius),
              side: on
                  ? BorderSide.none
                  : BorderSide(
                      color: cs.outlineVariant,
                      width: DelveTokens.hairline,
                    ),
            ),
            child: InkWell(
              key: Key('files.quick.${q.path}'),
              borderRadius: BorderRadius.circular(FilesTokens.quickChipRadius),
              onTap: () => onOpen(q.path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SymbolIcon(q.icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      q.label,
                      style: q.mono
                          ? DelveText.mono.copyWith(color: fg)
                          : context.text.labelLarge!.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 32 dp: counts (and the filesystem) left, the sort key and direction
/// right (a tap flips it).
class FilesListHeader extends StatelessWidget {
  const FilesListHeader({
    super.key,
    required this.text,
    required this.sortLabel,
    required this.ascending,
    required this.onSort,
  });

  final String text;
  final String sortLabel;
  final bool ascending;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelMedium!.copyWith(
      color: context.delve.textMuted,
    );
    return SizedBox(
      height: FilesTokens.listHeader,
      child: Padding(
        padding: const EdgeInsets.only(left: DelveTokens.space4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                key: const Key('files.header'),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              key: const Key('files.sortKey'),
              onTap: onSort,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DelveTokens.space4,
                ),
                child: Row(
                  children: [
                    Text(sortLabel, style: style),
                    const SizedBox(width: 4),
                    SymbolIcon(
                      ascending ? FileIcons.arrowUp : FileIcons.arrowDown,
                      size: 16,
                      color: context.delve.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title row's chip while a transfer runs: a progress ring and "1 of 2".
class TransferChip extends StatelessWidget {
  const TransferChip({
    super.key,
    required this.fraction,
    required this.label,
    required this.onTap,
  });

  final double? fraction;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: DelveTokens.space1),
      child: Material(
        color: cs.surfaceContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const Key('files.transferChip'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: FilesTokens.transferChip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: context.text.labelMedium!.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
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

/// A row of the Transfers sheet.
class TransferRow extends StatelessWidget {
  const TransferRow({
    super.key,
    required this.transfer,
    required this.now,
    required this.onCancel,
    required this.onOpen,
    required this.onRetry,
    this.home,
  });

  final Transfer transfer;
  final DateTime now;
  final VoidCallback onCancel;

  /// A download's Open; an upload's Show folder.
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  /// The desktop's home (an upload's folder as `~/…`).
  final String? home;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = transfer;
    final d = context.delve;
    final muted = d.textMuted;
    final way = t.upload ? FileIcons.upload : FileIcons.download;
    final (IconData icon, Color color, String word) = switch (t.state) {
      TransferState.running => (
        way,
        context.colors.primary,
        '${((t.fraction ?? 0) * 100).round()} %',
      ),
      TransferState.queued => (
        FileIcons.queued,
        d.infoFg,
        l.filesTransferQueued,
      ),
      TransferState.done => (FileIcons.done, d.okFg, l.filesTransferDone),
      TransferState.failed => (
        FileIcons.failed,
        d.alertFg,
        l.filesTransferFailed,
      ),
      TransferState.cancelled => (
        FileIcons.cancelled,
        d.infoFg,
        l.filesTransferCancelled,
      ),
    };
    final total = t.total;
    final detail = switch (t.state) {
      TransferState.running => [
        total == null
            ? sizeText(t.bytes)
            : l.filesTransferOf(sizeText(t.bytes), sizeText(total)),
        if (t.speed(now) case final s?) '${sizeText(s.round())}/s',
      ].join(' · '),
      TransferState.queued => total == null ? '' : sizeText(total),
      TransferState.done => [
        if (total != null) sizeText(total),
        if (t.upload)
          tildePath(parentPath(t.remotePath), home)
        else
          l.filesTransferInDownloads,
      ].join(' · '),
      TransferState.failed => t.error ?? '',
      TransferState.cancelled => '',
    };
    final Widget? action = switch (t.state) {
      TransferState.running || TransferState.queued => IconButton(
        key: Key('files.transfer.cancel.${t.id}'),
        tooltip: l.filesTransferCancel,
        icon: const SymbolIcon(FileIcons.close),
        onPressed: onCancel,
      ),
      TransferState.done => TextButton(
        key: Key('files.transfer.open.${t.id}'),
        onPressed: onOpen,
        child: Text(t.upload ? l.filesShowFolder : l.filesOpen),
      ),
      TransferState.failed => TextButton(
        key: Key('files.transfer.retry.${t.id}'),
        onPressed: onRetry,
        child: Text(l.filesTransferRetry),
      ),
      TransferState.cancelled => null,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 4, 12),
      child: Row(
        children: [
          FileTile(entry: t.entry),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SymbolIcon(way, size: 16, color: muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: MiddleEllipsis(
                        t.name,
                        style: context.text.bodyMedium!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SymbolIcon(icon, size: 16, filled: true, color: color),
                    const SizedBox(width: 4),
                    Text(
                      word,
                      style: DelveText.mono.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelMedium!.copyWith(
                          color: muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                if (t.state == TransferState.running) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: t.fraction,
                      minHeight: FilesTokens.transferBar,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ?action,
        ],
      ),
    );
  }
}

/// A centred message: icon, title, body, actions (empty folder, permission
/// denied, not set up, host key changed).
class FilesMessage extends StatelessWidget {
  const FilesMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actions = const [],
    this.filledIcon = false,
  });

  final IconData icon;
  final String title;
  final Widget? body;
  final List<Widget> actions;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DelveTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(
              icon,
              size: 44,
              filled: filledIcon,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: DelveTokens.space4),
            Text(
              title,
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: DelveTokens.space2),
              DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                child: body!,
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: DelveTokens.space5),
              Wrap(
                spacing: DelveTokens.space2,
                runSpacing: DelveTokens.space2,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
