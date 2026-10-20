import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';

/// Assistant text as Markdown in the chat's type roles: body in bodyLarge,
/// inline code in mono at 0.88 em on surface-2, code blocks in a surface-1
/// well. Links are copied (the app opens no browser).
class DelveMarkdown extends StatelessWidget {
  const DelveMarkdown({super.key, required this.data});

  final String data;

  static MarkdownStyleSheet styleSheet(BuildContext context) {
    final cs = context.colors;
    final text = context.text;
    final body = text.bodyLarge!;
    final codeSize = (body.fontSize ?? 15) * 0.88;
    return MarkdownStyleSheet.fromTheme(context.theme).copyWith(
      p: body,
      a: body.copyWith(
        color: cs.primary,
        decoration: TextDecoration.underline,
        decorationColor: cs.primary,
      ),
      listBullet: body,
      h1: text.titleLarge,
      h2: text.titleMedium,
      h3: text.titleSmall,
      h4: text.titleSmall,
      h5: text.titleSmall,
      h6: text.titleSmall,
      strong: const TextStyle(fontWeight: FontWeight.w600),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: body.copyWith(color: cs.onSurfaceVariant),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: cs.outlineVariant, width: 2)),
      ),
      blockquotePadding: const EdgeInsets.only(left: DelveTokens.space3),
      code: DelveText.mono.copyWith(
        fontSize: codeSize,
        color: cs.onSurface,
        backgroundColor: cs.surfaceContainer,
      ),
      codeblockPadding: const EdgeInsets.fromLTRB(
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space3,
        DelveTokens.space3,
      ),
      codeblockDecoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(
          color: cs.outlineVariant,
          width: DelveTokens.hairline,
        ),
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      tableBody: body,
      tableHead: text.titleSmall,
      tableBorder: TableBorder.all(
        color: cs.outlineVariant,
        width: DelveTokens.hairline,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
        ),
      ),
      blockSpacing: DelveTokens.space3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: styleSheet(context),
      onTapLink: (text, href, title) {
        if (href == null) return;
        unawaited(Clipboard.setData(ClipboardData(text: href)));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).chatLinkCopied),
            ),
          );
      },
    );
  }
}
