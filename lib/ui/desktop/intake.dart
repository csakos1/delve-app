import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/layout.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

// --- what the clipboard holds (Ctrl+V) ---------------------------------------

/// What the desktop's clipboard offers the composer.
sealed class PasteContent {
  const PasteContent();
}

/// An image (a screenshot, “Copy image” in a browser).
final class PasteImage extends PasteContent {
  const PasteImage(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;
}

/// Files copied in a file manager.
final class PasteFiles extends PasteContent {
  const PasteFiles(this.paths);
  final List<String> paths;
}

/// Text, or nothing the composer attaches: the text field pastes as before.
final class PasteText extends PasteContent {
  const PasteText();
}

/// The desktop's clipboard. Tests replace it.
abstract class DesktopPasteboard {
  Future<PasteContent> read();
}

/// The types a clipboard offers that mean text: with one of them an image
/// is not taken (a spreadsheet's cells come with a picture of themselves).
bool _isText(String type) =>
    type == 'text/plain' ||
    type.startsWith('text/plain;') ||
    type == 'UTF8_STRING' ||
    type == 'STRING' ||
    type == 'TEXT';

const _imageTypes = [
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
  'image/bmp',
];

/// The image type to read from what the clipboard [offers]; null: none, or
/// it offers text as well.
String? pasteImageType(Iterable<String> offers) {
  final types = {for (final t in offers) t.trim()};
  if (types.any(_isText)) return null;
  for (final t in _imageTypes) {
    if (types.contains(t)) return t;
  }
  return types.where((t) => t.startsWith('image/')).firstOrNull;
}

/// The local files of a `text/uri-list` (comments and other schemes are
/// skipped).
List<String> filePathsOfUriList(String list) => [
  for (final line in const LineSplitter().convert(list))
    if (line.trim() case final l when l.isNotEmpty && !l.startsWith('#'))
      if (Uri.tryParse(l) case final uri? when uri.scheme == 'file')
        uri.toFilePath(),
];

/// Wayland's clipboard through `wl-paste` (wl-clipboard).
class WlPasteboard implements DesktopPasteboard {
  const WlPasteboard();

  @override
  Future<PasteContent> read() async {
    final listed = await _run(['--list-types']);
    if (listed == null) return const PasteText();
    final offers = const LineSplitter().convert(utf8.decode(listed));
    final image = pasteImageType(offers);
    if (image != null) {
      final bytes = await _run(['--no-newline', '--type', image]);
      if (bytes != null && bytes.isNotEmpty) return PasteImage(bytes, image);
    }
    if (offers.map((t) => t.trim()).contains('text/uri-list')) {
      final bytes = await _run(['--no-newline', '--type', 'text/uri-list']);
      if (bytes != null) {
        final paths = filePathsOfUriList(
          utf8.decode(bytes, allowMalformed: true),
        );
        if (paths.isNotEmpty) return PasteFiles(paths);
      }
    }
    return const PasteText();
  }

  static Future<Uint8List?> _run(List<String> args) async {
    try {
      final r = await Process.run(
        'wl-paste',
        args,
        stdoutEncoding: null,
      ).timeout(const Duration(seconds: 3));
      if (r.exitCode != 0) return null;
      final out = r.stdout;
      return out is List<int> ? Uint8List.fromList(out) : null;
    } on Object {
      return null;
    }
  }
}

final desktopPasteboardProvider = Provider<DesktopPasteboard>(
  (ref) => const WlPasteboard(),
);

// --- files and images as attachments -----------------------------------------

/// A local file as an attachment; null for a folder or a path that is gone.
PickedAttachment? pickedFromPath(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  final name = path
      .split(Platform.pathSeparator)
      .lastWhere((s) => s.isNotEmpty, orElse: () => 'file');
  return PickedAttachment(
    kind: isImageName(name) ? 'image' : 'file',
    name: name,
    mime: mimeForName(name),
    size: f.lengthSync(),
    read: f.readAsBytes,
  );
}

/// What a paste attaches; null: nothing (the text field pastes).
List<PickedAttachment>? pickedOfPaste(PasteContent content, {DateTime? now}) =>
    switch (content) {
      PasteImage(:final bytes, :final mime) => [
        PickedAttachment(
          kind: 'image',
          name:
              'pasted-${DateFormat('HHmmss').format(now ?? DateTime.now())}'
              '.${mime.split('/').last}',
          mime: mime,
          size: bytes.length,
          read: () async => bytes,
        ),
      ],
      PasteFiles(:final paths) => [for (final p in paths) ?pickedFromPath(p)],
      PasteText() => null,
    };

/// Adds what came from the desktop (a drop, Ctrl+V, Ctrl+O) to
/// [attachments]. [refuseImages] (the loaded model reads no images) leaves
/// the images out and says so; [imagesOnly] (General) leaves the rest out;
/// a snackbar says what did not fit.
void addPickedInto(
  BuildContext context,
  ComposerAttachments attachments,
  List<PickedAttachment> picked, {
  String? refuseImages,
  String? imagesOnly,
}) {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  var take = picked;
  if (refuseImages != null && take.any((p) => p.kind == 'image')) {
    take = [
      for (final p in take)
        if (p.kind != 'image') p,
    ];
    snack(refuseImages);
  }
  if (imagesOnly != null && take.any((p) => p.kind != 'image')) {
    take = [
      for (final p in take)
        if (p.kind == 'image') p,
    ];
    snack(imagesOnly);
  }
  if (take.isEmpty) return;
  if (attachments.room <= 0) {
    snack(l.attachLimit(kMaxAttachments));
    return;
  }
  final left = attachments.addAll(take);
  if (left > 0) snack(l.attachLeftOut(left, kMaxAttachments));
}

// --- the chat's keys ----------------------------------------------------------

/// What the desktop's chat keys do in the chat that is open: Ctrl+O, Ctrl+V
/// outside a text field, Ctrl+. and Ctrl+T. The open chat registers itself
/// (the last one built wins); the desktop shell calls it.
@immutable
class ChatCommands {
  const ChatCommands({
    required this.attachFile,
    required this.paste,
    required this.stop,
    required this.toggleThinking,
    this.find,
  });

  /// Ctrl+O: the file dialog, as the composer's “+”.
  final VoidCallback attachFile;

  /// Ctrl+V outside a text field: an image or files from the clipboard.
  final Future<bool> Function() paste;

  /// Ctrl+.: stops the run (or the answer) that is going.
  final VoidCallback stop;

  /// Ctrl+T: Thinking on / off for the next message.
  final VoidCallback toggleThinking;

  /// Ctrl+F: search in the chat (L2b2); null: the list's search.
  final VoidCallback? find;
}

/// The open chat's [ChatCommands]; nothing listens (the shell reads it when
/// a key comes).
class ChatCommandSlot {
  Object? _owner;
  ChatCommands? _current;

  ChatCommands? get current => _current;

  void register(Object owner, ChatCommands commands) {
    _owner = owner;
    _current = commands;
  }

  void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _current = null;
  }
}

final chatCommandSlotProvider = Provider<ChatCommandSlot>(
  (ref) => ChatCommandSlot(),
);

/// The list column's keys outside text fields (design 27 “Shortcuts”,
/// L2b2): J / ↓ the next row, K / ↑ the previous one, E archives the open
/// row, Ctrl+Z undoes it. The Chats list registers itself.
@immutable
class ListCommands {
  const ListCommands({
    required this.next,
    required this.previous,
    required this.archive,
    required this.undo,
  });

  final VoidCallback next;
  final VoidCallback previous;
  final VoidCallback archive;
  final VoidCallback undo;
}

/// The open list's [ListCommands] (the last one built wins).
class ListCommandSlot {
  Object? _owner;
  ListCommands? _current;

  ListCommands? get current => _current;

  void register(Object owner, ListCommands commands) {
    _owner = owner;
    _current = commands;
  }

  void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _current = null;
  }
}

final listCommandSlotProvider = Provider<ListCommandSlot>(
  (ref) => ListCommandSlot(),
);

/// The focus is in a text field (Ctrl+V there pastes text).
bool focusInTextField() {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  if (focus.widget is EditableText) return true;
  return focus.findAncestorStateOfType<EditableTextState>() != null;
}

// --- drag and drop ------------------------------------------------------------

/// Files dropped on a chat (design 27W-14g): while files are dragged over
/// it, a dashed accent frame on `accent-container` at 55 % (flat, inset 8,
/// radius 16) says “Drop to attach”. Only in the desktop layout; elsewhere
/// it is just [child].
class DesktopDropZone extends StatefulWidget {
  const DesktopDropZone({
    super.key,
    required this.onPaths,
    required this.child,
    this.enabled = true,
  });

  /// The dropped local paths (folders among them are skipped later).
  final void Function(List<String> paths) onPaths;
  final Widget child;
  final bool enabled;

  @override
  State<DesktopDropZone> createState() => _DesktopDropZoneState();
}

class _DesktopDropZoneState extends State<DesktopDropZone> {
  bool _over = false;

  void _setOver(bool over) {
    if (mounted && _over != over) setState(() => _over = over);
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.of(context)) return widget.child;
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => _setOver(true),
      onDragExited: (_) => _setOver(false),
      onDragDone: (details) {
        _setOver(false);
        final paths = [
          for (final f in details.files)
            if (f.path.isNotEmpty) f.path,
        ];
        if (paths.isNotEmpty) widget.onPaths(paths);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_over)
            const Positioned.fill(child: IgnorePointer(child: _DropOverlay())),
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return Padding(
      key: const Key('chat.drop'),
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        foregroundPainter: _DashedFrame(color: cs.primary, radius: _radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolIcon(
                  DelveIcons.dropToAttach,
                  size: 30,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(height: DelveTokens.space2),
                Text(
                  l.desktopDropToAttach,
                  style: context.text.titleMedium!.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: DelveTokens.space1),
                Text(
                  l.desktopDropHint(kMaxAttachments),
                  style: context.text.bodySmall!.copyWith(
                    color: cs.onPrimaryContainer,
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

/// A 2 px dashed rounded rectangle (dashes 6, gaps 4).
class _DashedFrame extends CustomPainter {
  const _DashedFrame({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = (at + 6).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFrame old) =>
      old.color != color || old.radius != radius;
}
