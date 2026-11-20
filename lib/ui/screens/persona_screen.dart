import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../persona/persona_controller.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart' show DesktopPage, DesktopPageBody;
import '../desktop/intake.dart' show EditorScope;
import '../desktop/layers.dart' show showDesktopConfirm, showDesktopDialog;
import '../desktop/list_area.dart' show SectionRow;
import '../desktop/panes.dart' show KeyCap, PaneHeader;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// The server's limits (delve-backend `delve.persona`).
const int kPersonaSectionsMax = 12;
const int kPersonaTitleMax = 80;
const int kPersonaSectionTextMax = 4000;
const int kPersonaTopicsMax = 32;
const int kPersonaSummaryMax = 200;
const int kPersonaTopicTextMax = 32000;

/// More → About me (P1): what the agent knows about its user. The profile
/// lives on the desktop; this page reads and edits it through the backend.
/// The core's sections are part of every agent chat, a topic file is read
/// when a question needs it, and a switch per item says whether it may also
/// go to the General chats (a cloud model). A change applies to the chats
/// started after it.
///
/// On the desktop (27W-10) the content of the About me area: one [item] –
/// a section or topic file in its editor, what is sent, or the overview.
class PersonaScreen extends ConsumerStatefulWidget {
  const PersonaScreen({super.key, this.item});

  /// The desktop's item ([PersonaItem]); null: the overview.
  final String? item;

  @override
  ConsumerState<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends ConsumerState<PersonaScreen> {
  @override
  void initState() {
    super.initState();
    // the desktop: an item opened from the list column needs no reload
    if (widget.item == null || ref.read(personaProvider).persona == null) {
      unawaited(ref.read(personaProvider.notifier).refresh());
    }
  }

  PersonaController get _controller => ref.read(personaProvider.notifier);

  /// The desktop: a new topic's name, for the page after its save.
  String? _savedTopic;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Runs an edit made on this page (a switch); a failure is a snackbar.
  Future<void> _apply(Future<void> Function() edit) async {
    final l = AppLocalizations.of(context);
    try {
      await edit();
    } on Object catch (e) {
      _snack(l.personaSaveFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _sectionGeneral(Persona p, int index, {required bool on}) =>
      _apply(
        () => _controller.saveProfile([
          for (final (i, s) in p.sections.indexed)
            i == index ? s.copyWith(general: on) : s,
        ]),
      );

  Future<void> _topicGeneral(PersonaTopic topic, {required bool on}) =>
      _apply(() => _controller.saveTopic(topic.copyWith(general: on)));

  Future<void> _editSection(Persona p, int? index) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PersonaSectionEditor(
            original: index == null ? null : p.sections[index],
            onSave: (section) => _controller.saveProfile([
              for (final (i, s) in p.sections.indexed) i == index ? section : s,
              if (index == null) section,
            ]),
            onDelete: index == null
                ? null
                : () => _controller.saveProfile([
                    for (final (i, s) in p.sections.indexed)
                      if (i != index) s,
                  ]),
          ),
        ),
      );

  Future<void> _editTopic(Persona p, PersonaTopic? topic) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => PersonaTopicEditor(
            original: topic,
            taken: {for (final t in p.topics) t.name},
            onSave: _controller.saveTopic,
            onDelete: topic == null
                ? null
                : () => _controller.deleteTopic(topic.name),
          ),
        ),
      );

  void _preview(String title, String text) {
    final l = AppLocalizations.of(context);
    if (DesktopLayout.of(context)) {
      // the desktop: a dialog as wide as a page (L2d3)
      unawaited(
        showDesktopDialog<void>(
          context,
          width: DelveDesktop.previewDialogWidth,
          builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: ListView(
              key: const Key('persona.preview'),
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: DelveTokens.space3),
                SelectableText(
                  text.isEmpty ? l.personaPreviewEmpty : text,
                  style: DelveText.monoSmall.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            key: const Key('persona.preview'),
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              0,
              DelveTokens.space4,
              DelveTokens.space8,
            ),
            children: [
              Text(title, style: context.text.titleLarge),
              const SizedBox(height: DelveTokens.space3),
              SelectableText(
                text.isEmpty ? l.personaPreviewEmpty : text,
                style: DelveText.monoSmall.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(personaProvider);
    final persona = view.persona;
    final error = view.error;
    if (DesktopLayout.of(context)) return _desktop(context, l, view);
    return SubPage(
      title: l.personaTitle,
      actions: [
        IconButton(
          key: const Key('persona.refresh'),
          tooltip: l.personaRefresh,
          icon: const SymbolIcon(DelveIcons.refresh),
          onPressed: () => unawaited(_controller.refresh()),
        ),
      ],
      child: switch (persona) {
        null when error != null => Padding(
          padding: const EdgeInsets.all(DelveTokens.space4),
          child: Align(
            alignment: Alignment.topCenter,
            child: StatusBanner(
              key: const Key('persona.loadFailed'),
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.personaLoadFailed(apiErrorText(l, error)),
              actionLabel: l.retry,
              onAction: () => unawaited(_controller.refresh()),
            ),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        final Persona p => _list(context, l, p, error),
      },
    );
  }

  /// The desktop's content (27W-10): the item of the list column – a
  /// section's or a topic file's editor in place (Save: Ctrl+S), what is
  /// sent, or the overview with the rules.
  Widget _desktop(BuildContext context, AppLocalizations l, PersonaView view) {
    final p = view.persona;
    final error = view.error;
    if (p == null) {
      return DesktopPage(
        title: l.personaTitle,
        child: error == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: StatusBanner(
                    key: const Key('persona.loadFailed'),
                    kind: StatusKind.alert,
                    icon: DelveIcons.error,
                    text: l.personaLoadFailed(apiErrorText(l, error)),
                    actionLabel: l.retry,
                    onAction: () => unawaited(_controller.refresh()),
                  ),
                ),
              ),
      );
    }
    void open(String? item) => context.open(Routes.aboutAt(item));
    final item = p.available ? PersonaItem.of(widget.item) : null;
    switch (item) {
      case PersonaSectionItem(:final index) when index < p.sections.length:
        return PersonaSectionEditor(
          key: ValueKey('persona.edit.s$index'),
          original: p.sections[index],
          onSave: (section) => _controller.saveProfile([
            for (final (i, s) in p.sections.indexed) i == index ? section : s,
          ]),
          onDelete: () => _controller.saveProfile([
            for (final (i, s) in p.sections.indexed)
              if (i != index) s,
          ]),
          onDone: ({required bool deleted}) {
            if (deleted) open(null);
          },
        );
      case PersonaNewSection():
        return PersonaSectionEditor(
          key: const ValueKey('persona.edit.newSection'),
          original: null,
          onSave: (section) =>
              _controller.saveProfile([...p.sections, section]),
          onDone: ({required bool deleted}) {
            open('s${p.sections.length}');
          },
        );
      case PersonaTopicItem(:final name):
        final topic = p.topics.where((t) => t.name == name).firstOrNull;
        if (topic == null) break;
        return PersonaTopicEditor(
          key: ValueKey('persona.edit.t.$name'),
          original: topic,
          taken: {for (final t in p.topics) t.name},
          onSave: _controller.saveTopic,
          onDelete: () => _controller.deleteTopic(name),
          onDone: ({required bool deleted}) {
            if (deleted) open(null);
          },
        );
      case PersonaNewTopic():
        return PersonaTopicEditor(
          key: const ValueKey('persona.edit.newTopic'),
          original: null,
          taken: {for (final t in p.topics) t.name},
          onSave: (topic) async {
            await _controller.saveTopic(topic);
            _savedTopic = topic.name;
          },
          onDone: ({required bool deleted}) {
            open(_savedTopic == null ? null : 't:$_savedTopic');
          },
        );
      case PersonaSent(:final general):
        final text = general ? p.generalText : p.block;
        return DesktopPage(
          key: Key('persona.sent.${general ? 'general' : 'agent'}'),
          title: general ? l.personaPreviewGeneral : l.personaPreviewAgent,
          child: DesktopPageBody(
            maxWidth: DelveDesktop.detailColumn,
            top: DelveTokens.space3,
            children: [
              Text(
                text.isEmpty
                    ? l.personaNothing
                    : l.personaChars(general ? text.length : p.blockChars),
                style: context.text.bodySmall!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
              const SizedBox(height: DelveTokens.space3),
              Container(
                padding: const EdgeInsets.all(DelveTokens.space3),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
                ),
                child: SelectableText(
                  text.isEmpty ? l.personaPreviewEmpty : text,
                  style: DelveText.monoSmall.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      case _:
        break;
    }
    // the overview: what the page is for and its rules
    final muted = context.text.bodyMedium!.copyWith(
      color: context.delve.textMuted,
    );
    return DesktopPage(
      key: const Key('persona.overview'),
      title: l.personaTitle,
      child: DesktopPageBody(
        maxWidth: DelveDesktop.detailColumn,
        top: DelveTokens.space3,
        children: [
          Text(l.personaHint, style: muted),
          if (!p.available) ...[
            const SizedBox(height: DelveTokens.space4),
            StatusBanner(
              key: const Key('persona.noStore'),
              kind: StatusKind.warn,
              icon: DelveIcons.warning,
              text: l.personaNoStore,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: DelveTokens.space4),
            StatusBanner(
              key: const Key('persona.stale'),
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.personaLoadFailed(apiErrorText(l, error)),
            ),
          ],
          const SizedBox(height: DelveTokens.space4),
          StatusBanner(
            key: const Key('persona.cloudRule'),
            kind: StatusKind.info,
            icon: DelveIcons.cloud,
            text: l.personaCloudRule,
          ),
          const SizedBox(height: DelveTokens.space5),
          Text(l.personaCore, style: context.text.titleSmall),
          const SizedBox(height: DelveTokens.space1),
          Text(l.personaCoreNote, style: muted),
          const SizedBox(height: DelveTokens.space4),
          Text(l.personaTopics, style: context.text.titleSmall),
          const SizedBox(height: DelveTokens.space1),
          Text(l.personaTopicsNote, style: muted),
          const SizedBox(height: DelveTokens.space4),
          Text(l.personaNewChats, style: muted),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AppLocalizations l,
    Persona p,
    Object? error,
  ) {
    final muted = context.text.bodyMedium!.copyWith(
      color: context.delve.textMuted,
    );
    const side = EdgeInsets.symmetric(horizontal: DelveTokens.space4);
    final editable = p.available;
    return ListView(
      key: const Key('persona.list'),
      padding: const EdgeInsets.only(
        top: DelveTokens.space4,
        bottom: DelveTokens.space8,
      ),
      children: [
        Padding(
          padding: side,
          child: Text(l.personaHint, style: muted),
        ),
        if (!p.available)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space4,
              DelveTokens.space4,
              0,
            ),
            child: StatusBanner(
              key: const Key('persona.noStore'),
              kind: StatusKind.warn,
              icon: DelveIcons.warning,
              text: l.personaNoStore,
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space4,
              DelveTokens.space4,
              0,
            ),
            child: StatusBanner(
              key: const Key('persona.stale'),
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.personaLoadFailed(apiErrorText(l, error)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space4,
            DelveTokens.space4,
            0,
          ),
          child: StatusBanner(
            key: const Key('persona.cloudRule'),
            kind: StatusKind.info,
            icon: DelveIcons.cloud,
            text: l.personaCloudRule,
          ),
        ),
        _Header(l.personaCore),
        Padding(
          padding: side,
          child: Text(l.personaCoreNote, style: muted),
        ),
        if (p.sections.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space3,
              DelveTokens.space4,
              0,
            ),
            child: Text(
              l.personaNoSections,
              key: const Key('persona.noSections'),
              style: muted,
            ),
          ),
        for (final (i, s) in p.sections.indexed)
          ListTile(
            key: Key('persona.section.$i'),
            title: Text(s.title),
            subtitle: Text(
              _firstLine(s.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _CloudSwitch(
              switchKey: Key('persona.section.$i.general'),
              value: s.general,
              onChanged: editable
                  ? (on) => unawaited(_sectionGeneral(p, i, on: on))
                  : null,
            ),
            enabled: editable,
            onTap: () => unawaited(_editSection(p, i)),
          ),
        ListTile(
          key: const Key('persona.addSection'),
          leading: const SymbolIcon(DelveIcons.add),
          title: Text(l.personaAddSection),
          enabled: editable && p.sections.length < kPersonaSectionsMax,
          onTap: () => unawaited(_editSection(p, null)),
        ),
        _Header(l.personaTopics),
        Padding(
          padding: side,
          child: Text(l.personaTopicsNote, style: muted),
        ),
        if (p.topics.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space3,
              DelveTokens.space4,
              0,
            ),
            child: Text(
              l.personaNoTopics,
              key: const Key('persona.noTopics'),
              style: muted,
            ),
          ),
        for (final t in p.topics)
          ListTile(
            key: Key('persona.topic.${t.name}'),
            title: Text(t.title),
            subtitle: Text(
              t.summary.isEmpty ? '${t.name}.md' : t.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _CloudSwitch(
              switchKey: Key('persona.topic.${t.name}.general'),
              value: t.general,
              onChanged: editable
                  ? (on) => unawaited(_topicGeneral(t, on: on))
                  : null,
            ),
            enabled: editable,
            onTap: () => unawaited(_editTopic(p, t)),
          ),
        ListTile(
          key: const Key('persona.addTopic'),
          leading: const SymbolIcon(DelveIcons.add),
          title: Text(l.personaAddTopic),
          enabled: editable && p.topics.length < kPersonaTopicsMax,
          onTap: () => unawaited(_editTopic(p, null)),
        ),
        _Header(l.personaSent),
        ListTile(
          key: const Key('persona.toAgent'),
          leading: const SymbolIcon(DelveIcons.agent),
          title: Text(l.personaToAgent),
          subtitle: Text(
            p.block.isEmpty ? l.personaNothing : l.personaChars(p.blockChars),
          ),
          trailing: SymbolIcon(
            DelveIcons.chevronRight,
            size: DelveTokens.iconMd,
            color: context.delve.textMuted,
          ),
          onTap: () => _preview(l.personaPreviewAgent, p.block),
        ),
        ListTile(
          key: const Key('persona.toGeneral'),
          leading: const SymbolIcon(DelveIcons.cloud),
          title: Text(l.personaToGeneral),
          subtitle: Text(
            p.generalText.isEmpty
                ? l.personaNothing
                : l.personaChars(p.generalText.length),
          ),
          trailing: SymbolIcon(
            DelveIcons.chevronRight,
            size: DelveTokens.iconMd,
            color: context.delve.textMuted,
          ),
          onTap: () => _preview(l.personaPreviewGeneral, p.generalText),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space4,
            DelveTokens.space4,
            0,
          ),
          child: Text(l.personaNewChats, style: muted),
        ),
      ],
    );
  }
}

/// What follows a desktop editor's save or delete.
typedef PersonaEditorDone = void Function({required bool deleted});

/// An item of the desktop's About me list column (`?item=`): `s3` a core
/// section, `t:<name>` a topic file, `new-section`, `new-topic`, `agent` /
/// `general` what is sent; null the overview.
sealed class PersonaItem {
  const PersonaItem();

  static PersonaItem? of(String? item) => switch (item) {
    null => null,
    'new-section' => const PersonaNewSection(),
    'new-topic' => const PersonaNewTopic(),
    'agent' => const PersonaSent(general: false),
    'general' => const PersonaSent(general: true),
    final String t when t.startsWith('t:') => PersonaTopicItem(t.substring(2)),
    final String s when s.startsWith('s') => switch (int.tryParse(
      s.substring(1),
    )) {
      final i? when i >= 0 => PersonaSectionItem(i),
      _ => null,
    },
    _ => null,
  };
}

class PersonaSectionItem extends PersonaItem {
  const PersonaSectionItem(this.index);
  final int index;
}

class PersonaNewSection extends PersonaItem {
  const PersonaNewSection();
}

class PersonaTopicItem extends PersonaItem {
  const PersonaTopicItem(this.name);
  final String name;
}

class PersonaNewTopic extends PersonaItem {
  const PersonaNewTopic();
}

class PersonaSent extends PersonaItem {
  const PersonaSent({required this.general});
  final bool general;
}

/// The desktop's list column of About me (27W-10): the core's sections and
/// the topic files (Cloud where they also go to the General chats), Add,
/// and what is sent; the open item selected.
class PersonaNav extends ConsumerWidget {
  const PersonaNav({super.key, this.item});

  final String? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(personaProvider).persona;
    void open(String? to) => context.open(Routes.aboutAt(to));
    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: context.delve.textMuted,
        ),
      ),
    );
    final editable = p?.available ?? false;
    return TopLevelPage(
      key: const Key('persona.nav'),
      title: l.personaTitle,
      background: context.colors.surfaceContainerLow,
      actions: [
        IconButton(
          key: const Key('persona.refresh'),
          tooltip: l.personaRefresh,
          onPressed: () =>
              unawaited(ref.read(personaProvider.notifier).refresh()),
          icon: const SymbolIcon(
            DelveIcons.refresh,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(top: 2, bottom: DelveTokens.space4),
        children: [
          SectionRow(
            key: const Key('persona.nav.overview'),
            label: l.desktopPersonaOverview,
            icon: DelveIcons.person,
            selected: item == null,
            onTap: () => open(null),
          ),
          if (p != null) ...[
            eyebrow(l.personaCore),
            for (final (i, s) in p.sections.indexed)
              SectionRow(
                key: Key('persona.nav.s$i'),
                label: s.title,
                icon: DelveIcons.note,
                trailing: s.general ? l.personaCloud : null,
                selected: item == 's$i',
                onTap: () => open('s$i'),
              ),
            if (editable && p.sections.length < kPersonaSectionsMax)
              SectionRow(
                key: const Key('persona.nav.newSection'),
                label: l.personaAddSection,
                icon: DelveIcons.add,
                selected: item == 'new-section',
                onTap: () => open('new-section'),
              ),
            eyebrow(l.personaTopics),
            for (final t in p.topics)
              SectionRow(
                key: Key('persona.nav.t.${t.name}'),
                label: t.title,
                icon: DelveIcons.file,
                trailing: t.general ? l.personaCloud : null,
                selected: item == 't:${t.name}',
                onTap: () => open('t:${t.name}'),
              ),
            if (editable && p.topics.length < kPersonaTopicsMax)
              SectionRow(
                key: const Key('persona.nav.newTopic'),
                label: l.personaAddTopic,
                icon: DelveIcons.add,
                selected: item == 'new-topic',
                onTap: () => open('new-topic'),
              ),
            eyebrow(l.personaSent),
            SectionRow(
              key: const Key('persona.nav.agent'),
              label: l.personaToAgent,
              icon: DelveIcons.agent,
              selected: item == 'agent',
              onTap: () => open('agent'),
            ),
            SectionRow(
              key: const Key('persona.nav.general'),
              label: l.personaToGeneral,
              icon: DelveIcons.cloud,
              selected: item == 'general',
              onTap: () => open('general'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The first line of a section without its list marker.
String _firstLine(String text) {
  final line = text.split('\n').first.trim();
  return line.startsWith('- ') ? line.substring(2) : line;
}

/// The switch of a row with its meaning beside it: on = this item also goes
/// to the General chats (a cloud model). The agent gets every item either
/// way.
class _CloudSwitch extends StatelessWidget {
  const _CloudSwitch({
    required this.switchKey,
    required this.value,
    this.onChanged,
  });

  final Key switchKey;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.personaCloud,
          style: context.text.labelMedium!.copyWith(
            color: value ? context.colors.primary : context.delve.textMuted,
          ),
        ),
        const SizedBox(width: DelveTokens.space2),
        Switch(key: switchKey, value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      DelveTokens.space6,
      DelveTokens.space4,
      DelveTokens.space2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium!.copyWith(
          color: context.colors.primary,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}

/// The frame of the two editors: a close button, Save, the fields, and
/// Delete for an existing item. Saving happens here, so a failure leaves the
/// page open with what was typed.
class _EditorPage extends StatefulWidget {
  const _EditorPage({
    required this.title,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.deleteName,
    this.onDone,
  });

  final String title;
  final List<Widget> children;

  /// The desktop: what follows a save or a delete (the page stays in the
  /// content); null: the page closes.
  final PersonaEditorDone? onDone;

  /// null: what is typed cannot be saved yet (the fields say why).
  final Future<void> Function()? Function() onSave;
  final Future<void> Function()? onDelete;
  final String? deleteName;

  @override
  State<_EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<_EditorPage> {
  bool _busy = false;

  /// The desktop: holds the focus for Ctrl+S while no field has it.
  final _keys = FocusNode(debugLabel: 'persona.editor');

  @override
  void initState() {
    super.initState();
    // the shell keeps the focus otherwise (autofocus does not reach here)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && DesktopLayout.of(context)) _keys.requestFocus();
    });
  }

  @override
  void dispose() {
    _keys.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() work, {bool delete = false}) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await work();
      if (!mounted) return;
      final done = widget.onDone;
      if (done == null) {
        unawaited(Navigator.of(context).maybePop());
      } else {
        if (!delete) _snack(l.desktopPersonaSaved);
        done(deleted: delete);
      }
    } on Object catch (e) {
      _snack(l.personaSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final work = widget.onSave();
    if (work != null) await _run(work);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final work = widget.onDelete;
    if (work == null) return;
    if (DesktopLayout.of(context)) {
      final ok = await showDesktopConfirm(
        context,
        title: l.personaDeleteTitle(widget.deleteName ?? ''),
        body: l.personaDeleteBody,
        action: l.personaDelete,
        destructive: true,
      );
      if (ok && mounted) await _run(work, delete: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.personaDeleteTitle(widget.deleteName ?? '')),
        content: Text(l.personaDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('persona.delete.confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.personaDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(work, delete: true);
  }

  List<Widget> get _deleteButton => [
    if (widget.onDelete != null)
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('persona.delete'),
          onPressed: _busy ? null : () => unawaited(_delete()),
          icon: SymbolIcon(DelveIcons.delete, color: context.delve.alertFg),
          label: Text(
            AppLocalizations.of(context).personaDelete,
            style: TextStyle(color: context.delve.alertFg),
          ),
        ),
      ),
  ];

  /// The desktop (27W-10): a 48 px header with Save (Ctrl+S), the fields
  /// in a 680 column.
  Widget _desktop(AppLocalizations l) => Scaffold(
    backgroundColor: context.colors.surface,
    body: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (!_busy) unawaited(_save());
        },
      },
      child: Focus(
        focusNode: _keys,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaneHeader(
              title: widget.title,
              actions: [
                FilledButton(
                  key: const Key('persona.save'),
                  onPressed: _busy ? null : () => unawaited(_save()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.personaSave),
                      const SizedBox(width: 6),
                      const KeyCap('Ctrl+S'),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: DesktopPageBody(
                key: const Key('persona.editor'),
                maxWidth: DelveDesktop.detailColumn,
                top: DelveTokens.space4,
                children: [...widget.children, ..._deleteButton],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (widget.onDone != null && DesktopLayout.of(context)) {
      // the list's keys stay out of the editor (N515)
      return EditorScope(child: _desktop(l));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const SymbolIcon(DelveIcons.close),
        ),
        title: Text(widget.title),
        actions: [
          TextButton(
            key: const Key('persona.save'),
            onPressed: _busy ? null : () => unawaited(_save()),
            child: Text(l.personaSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space4,
          DelveTokens.space8,
        ),
        children: [...widget.children, ..._deleteButton],
      ),
    );
  }
}

/// One section of the core: title, text, and whether it may go to the
/// General chats.
class PersonaSectionEditor extends StatefulWidget {
  const PersonaSectionEditor({
    super.key,
    required this.original,
    required this.onSave,
    this.onDelete,
    this.onDone,
  });

  /// null: a new section.
  final PersonaSection? original;
  final Future<void> Function(PersonaSection section) onSave;
  final Future<void> Function()? onDelete;

  /// The desktop: the editor is a page of the content (see [_EditorPage]).
  final PersonaEditorDone? onDone;

  @override
  State<PersonaSectionEditor> createState() => _PersonaSectionEditorState();
}

class _PersonaSectionEditorState extends State<PersonaSectionEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.original?.title ?? '',
  );
  late final TextEditingController _text = TextEditingController(
    text: widget.original?.text ?? '',
  );
  late bool _general = widget.original?.general ?? false;
  bool _checked = false;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> Function()? _save() {
    setState(() => _checked = true);
    final title = _title.text.trim();
    final text = _text.text.trim();
    if (title.isEmpty || text.isEmpty) return null;
    return () => widget.onSave(
      PersonaSection(title: title, text: text, general: _general),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _EditorPage(
      title: widget.original == null
          ? l.personaSectionNew
          : l.personaSectionEdit,
      onSave: _save,
      onDelete: widget.onDelete,
      deleteName: widget.original?.title,
      onDone: widget.onDone,
      children: [
        TextField(
          key: const Key('persona.field.title'),
          controller: _title,
          autofocus: widget.original == null,
          maxLength: kPersonaTitleMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l.personaFieldTitle,
            errorText: _checked && _title.text.trim().isEmpty
                ? l.personaTitleEmpty
                : null,
          ),
        ),
        const SizedBox(height: DelveTokens.space3),
        TextField(
          key: const Key('persona.field.text'),
          controller: _text,
          minLines: 6,
          maxLines: null,
          maxLength: kPersonaSectionTextMax,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.personaFieldText,
            alignLabelWithHint: true,
            errorText: _checked && _text.text.trim().isEmpty
                ? l.personaTextEmpty
                : null,
          ),
        ),
        SwitchListTile(
          key: const Key('persona.field.general'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.personaGeneralSwitch),
          subtitle: Text(l.personaGeneralSwitchSub),
          value: _general,
          onChanged: (on) => setState(() => _general = on),
        ),
      ],
    );
  }
}

/// One topic file: title, the one-line summary the agent sees, the text, and
/// whether it may go to the General chats. A new file is named after its
/// title.
class PersonaTopicEditor extends StatefulWidget {
  const PersonaTopicEditor({
    super.key,
    required this.original,
    required this.taken,
    required this.onSave,
    this.onDelete,
    this.onDone,
  });

  /// null: a new file.
  final PersonaTopic? original;

  /// The desktop: the editor is a page of the content (see [_EditorPage]).
  final PersonaEditorDone? onDone;

  /// The names of the files there are.
  final Set<String> taken;
  final Future<void> Function(PersonaTopic topic) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<PersonaTopicEditor> createState() => _PersonaTopicEditorState();
}

class _PersonaTopicEditorState extends State<PersonaTopicEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.original?.title ?? '',
  );
  late final TextEditingController _summary = TextEditingController(
    text: widget.original?.summary ?? '',
  );
  late final TextEditingController _text = TextEditingController(
    text: widget.original?.text ?? '',
  );
  late bool _general = widget.original?.general ?? false;
  bool _checked = false;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _text.dispose();
    super.dispose();
  }

  /// An existing file keeps its name; a new one gets it from the title.
  String get _name => widget.original?.name ?? topicNameOf(_title.text);

  String? _titleError(AppLocalizations l) {
    if (_title.text.trim().isEmpty) return l.personaTitleEmpty;
    if (widget.original != null) return null;
    if (_name.isEmpty) return l.personaNameEmpty;
    if (widget.taken.contains(_name)) return l.personaNameTaken;
    return null;
  }

  Future<void> Function()? _save() {
    final l = AppLocalizations.of(context);
    setState(() => _checked = true);
    final text = _text.text.trim();
    if (_titleError(l) != null || text.isEmpty) return null;
    final topic = PersonaTopic(
      name: _name,
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      text: text,
      general: _general,
    );
    return () => widget.onSave(topic);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _name;
    return _EditorPage(
      title: widget.original == null ? l.personaTopicNew : l.personaTopicEdit,
      onSave: _save,
      onDelete: widget.onDelete,
      deleteName: widget.original?.title,
      onDone: widget.onDone,
      children: [
        TextField(
          key: const Key('persona.field.title'),
          controller: _title,
          autofocus: widget.original == null,
          maxLength: kPersonaTitleMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}), // the file's name follows it
          decoration: InputDecoration(
            labelText: l.personaFieldTitle,
            helperText: name.isEmpty ? null : l.personaFile(name),
            errorText: _checked ? _titleError(l) : null,
          ),
        ),
        const SizedBox(height: DelveTokens.space3),
        TextField(
          key: const Key('persona.field.summary'),
          controller: _summary,
          maxLength: kPersonaSummaryMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l.personaFieldSummary,
            helperText: l.personaFieldSummaryHelper,
          ),
        ),
        const SizedBox(height: DelveTokens.space3),
        TextField(
          key: const Key('persona.field.text'),
          controller: _text,
          minLines: 6,
          maxLines: null,
          maxLength: kPersonaTopicTextMax,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.personaFieldText,
            alignLabelWithHint: true,
            errorText: _checked && _text.text.trim().isEmpty
                ? l.personaTextEmpty
                : null,
          ),
        ),
        SwitchListTile(
          key: const Key('persona.field.general'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.personaGeneralSwitch),
          subtitle: Text(l.personaGeneralSwitchSub),
          value: _general,
          onChanged: (on) => setState(() => _general = on),
        ),
      ],
    );
  }
}
