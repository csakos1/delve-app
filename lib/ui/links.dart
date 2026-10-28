import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Opens a link outside the app (the browser, or the app that handles it);
/// false when nothing did. Tests replace it.
typedef LinkOpener = Future<bool> Function(Uri url);

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => (url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  },
);

/// Opens [url]; if that does not work, copies it and says so.
Future<void> openLink(BuildContext context, WidgetRef ref, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  final uri = Uri.tryParse(url);
  final opened = uri != null && await ref.read(linkOpenerProvider)(uri);
  if (opened) return;
  await Clipboard.setData(ClipboardData(text: url));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.linkOpenFailed)));
}

/// Long press on a link: copies it ("Link copied").
Future<void> copyLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: url));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.chatLinkCopied)));
}
