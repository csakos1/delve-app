import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';
import 'more_screen.dart';

/// A More sub-page that a later step builds.
class SubPagePlaceholder extends StatelessWidget {
  const SubPagePlaceholder({super.key, required this.page});

  final MorePage page;

  @override
  Widget build(BuildContext context) => SubPage(
    title: page.title(AppLocalizations.of(context)),
    child: NotBuiltYet(icon: page.icon, step: page.step),
  );
}
