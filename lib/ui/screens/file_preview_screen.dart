import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../files/device_files.dart';
import '../../files/files_providers.dart';
import '../../files/files_service.dart';
import '../../files/remote_fs.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/files_ui.dart';
import '../widgets/page_scaffolds.dart';

/// 23h: a text file (read-only, mono, line numbers) or an image (pinch to
/// zoom), with Download.
class FilePreviewScreen extends ConsumerStatefulWidget {
  const FilePreviewScreen({super.key, required this.entry});

  final RemoteEntry entry;

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  late final FilesService _service = ref.read(filesServiceProvider);
  late final PreviewKind _kind = previewKindOf(widget.entry);
  Future<Object?>? _load;
  bool _lineNumbers = true;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<Object?> _fetch() async {
    final e = widget.entry;
    switch (_kind) {
      case PreviewKind.text:
        return _service.readText(e);
      case PreviewKind.image:
        if ((e.size ?? 0) > kPreviewImageMax) return const _TooBig();
        return _service.fetchImage(e);
      case PreviewKind.none:
        return null;
    }
  }

  void _download() {
    final l = AppLocalizations.of(context);
    _service.download(widget.entry);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.filesDownloadQueued(kDownloadFolder))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = widget.entry;
    final cs = context.colors;
    final image = _kind == PreviewKind.image;
    return Scaffold(
      backgroundColor: image ? const Color(0xFF0C0D0E) : cs.surface,
      appBar: AppBar(
        backgroundColor: image ? const Color(0xFF0C0D0E) : cs.surface,
        notificationPredicate: (_) => false,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              [
                tildePath(parentPath(e.path), _service.home),
                if (e.size != null) sizeText(e.size!),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DelveText.monoSmall.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('preview.download'),
            tooltip: l.filesActDownload,
            icon: const SymbolIcon(FileIcons.download),
            onPressed: _download,
          ),
          if (!image)
            IconButton(
              key: const Key('preview.lineNumbers'),
              tooltip: l.filesLineNumbers,
              isSelected: _lineNumbers,
              icon: const SymbolIcon(FileIcons.numbers),
              onPressed: () => setState(() => _lineNumbers = !_lineNumbers),
            ),
        ],
      ),
      body: FutureBuilder<Object?>(
        future: _load,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return FilesMessage(
              key: const Key('preview.error'),
              icon: DelveIcons.error,
              title: l.filesPreviewFailed,
              body: Text('${snap.error}'),
              actions: [
                FilledButton.tonal(
                  onPressed: () => setState(() => _load = _fetch()),
                  child: Text(l.filesRetry),
                ),
              ],
            );
          }
          return switch (snap.data) {
            (final String text, final bool cut) => _TextView(
              text: text,
              cut: cut,
              lineNumbers: _lineNumbers,
              onDownload: _download,
            ),
            final File file => _ImageView(file: file),
            _TooBig() => FilesMessage(
              icon: FileIcons.image,
              title: l.filesPreviewTooBig,
              actions: [
                FilledButton(
                  onPressed: _download,
                  child: Text(l.filesActDownload),
                ),
              ],
            ),
            _ => FilesMessage(
              key: const Key('preview.binary'),
              icon: FileIcons.other,
              title: l.filesPreviewBinary,
              body: Text(l.filesPreviewBinaryBody),
              actions: [
                FilledButton(
                  onPressed: _download,
                  child: Text(l.filesActDownload),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

class _TooBig {
  const _TooBig();
}

class _TextView extends StatelessWidget {
  const _TextView({
    required this.text,
    required this.cut,
    required this.lineNumbers,
    required this.onDownload,
  });

  final String text;
  final bool cut;
  final bool lineNumbers;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    var lines = text.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }
    final style = DelveText.mono.copyWith(color: d.codeFg, height: 20 / 13);
    final gutter = DelveText.mono.copyWith(color: d.textMuted, height: 20 / 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      if (lineNumbers)
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
                    cut ? l.filesPreviewCut : l.filesPreviewInfo(lines.length),
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                    ),
                  ),
                ),
                if (cut)
                  TextButton(
                    onPressed: onDownload,
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

class _ImageView extends StatefulWidget {
  const _ImageView({required this.file});

  final File file;

  @override
  State<_ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<_ImageView> {
  final _zoom = TransformationController();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTap: () => _zoom.value = _zoom.value.getMaxScaleOnAxis() > 1.01
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(2.5, 2.5, 1),
    child: InteractiveViewer(
      key: const Key('preview.image'),
      transformationController: _zoom,
      maxScale: 8,
      child: Center(
        child: Image.file(
          widget.file,
          errorBuilder: (context, _, _) => FilesMessage(
            icon: FileIcons.image,
            title: AppLocalizations.of(context).filesPreviewBinary,
          ),
        ),
      ),
    ),
  );
}
