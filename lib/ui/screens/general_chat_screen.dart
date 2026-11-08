import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/image_prep.dart';
import '../../attachments/picker.dart';
import '../../general/general_database.dart';
import '../../general/general_images.dart';
import '../../general/general_providers.dart';
import '../../general/model_catalog.dart';
import '../../general/openrouter_errors.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/attachments.dart' show AttachSource;
import '../chat/composer.dart';
import '../general/general_format.dart';
import '../general/general_widgets.dart';
import '../general/model_picker.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 24 General chat: the phone talks to OpenRouter directly. [chatId] is null
/// for a new chat: its first message creates it (on this phone), with the
/// model and thinking chosen before. [kindSwitch] (Agent / General) shows
/// above a new chat until it has a message.
class GeneralChatScreen extends ConsumerStatefulWidget {
  const GeneralChatScreen({super.key, required this.chatId, this.kindSwitch});

  final String? chatId;
  final Widget? kindSwitch;

  @override
  ConsumerState<GeneralChatScreen> createState() => _GeneralChatScreenState();
}

class _GeneralChatScreenState extends ConsumerState<GeneralChatScreen> {
  String? _chatId;
  late final TextEditingController _text = TextEditingController();
  final LocalImageApi _local = LocalImageApi();
  late final ComposerAttachments _attachments;

  // a new chat before its first message
  String? _newModel;
  bool _newReasoning = true;
  String? _newEffort;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    _attachments = ComposerAttachments(
      api: () => _local,
      prep: ref.read(imagePrepProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(generalChatServiceProvider).settleOnce());
      unawaited(_refreshModels());
    });
  }

  @override
  void didUpdateWidget(GeneralChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId && widget.chatId != null) {
      _chatId = widget.chatId;
    }
  }

  @override
  void dispose() {
    _attachments.dispose();
    _text.dispose();
    super.dispose();
  }

  /// The cached list when it is fresh; a missing or old one is fetched.
  Future<void> _refreshModels() async {
    final client = ref.read(openRouterClientProvider);
    if (client == null) return;
    try {
      await ref.read(modelCatalogProvider).refresh(client);
    } on GeneralFailure {
      // the picker says it; the chat keeps the cached list
    }
  }

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        action == null
            ? SnackBar(content: Text(text))
            : SnackBar(
                content: Text(text),
                action: action,
                persist: false,
                duration: DelveTokens.undoSnack,
              ),
      );
  }

  String _failureText(AppLocalizations l, Object e) => switch (e) {
    GeneralNoKey() => l.generalNoKeyShort,
    GeneralModelUnavailable() || GeneralNoProvider() => l.generalErrNoProvider,
    GeneralFailure(:final message) => message,
    _ => '$e',
  };

  /// Runs a service call; what it throws becomes a snackbar.
  Future<void> _guard(Future<void> Function() f) async {
    final l = AppLocalizations.of(context);
    try {
      await f();
    } on GeneralFailure catch (e) {
      if (mounted) _snack(l.generalNotSent(_failureText(l, e)));
    } on StateError catch (e) {
      if (mounted) _snack(l.generalNotSent(e.message));
    }
  }

  // --- sending ---------------------------------------------------------------

  Future<void> _send(String text, String modelId) async {
    final service = ref.read(generalChatServiceProvider);
    final images = _local.take(_attachments.ready);
    _attachments.clear();
    var id = _chatId;
    if (id == null) {
      id = await service.createChat(
        modelId: modelId,
        reasoning: _newReasoning,
        effort: _newEffort,
      );
      if (!mounted) return;
      setState(() => _chatId = id);
    }
    final chatId = id;
    // the answer streams on; the composer is free once the message is in
    unawaited(_guard(() => service.send(chatId, text, images: images)));
  }

  void _onErrorAction(GeneralErrorAction a, String modelId) {
    final id = _chatId;
    switch (a) {
      case GeneralErrorAction.openSettings:
        unawaited(context.push(Routes.generalSettings));
      case GeneralErrorAction.retry:
        if (id != null) {
          unawaited(
            _guard(() => ref.read(generalChatServiceProvider).retry(id)),
          );
        }
      case GeneralErrorAction.pickModel:
        unawaited(_pickModel(modelId, null));
    }
  }

  // --- model, thinking ---------------------------------------------------------

  Future<void> _pickModel(String current, GeneralChatRow? chat) async {
    final l = AppLocalizations.of(context);
    final title = chat?.title?.trim();
    final picked = await showModelPicker(
      context,
      current: current,
      subtitle: l.pickerSub(title == null || title.isEmpty ? l.newChat : title),
    );
    if (picked == null || !mounted) return;
    final id = _chatId;
    if (id == null) {
      setState(() => _newModel = picked);
      return;
    }
    await _guard(
      () => ref.read(generalChatServiceProvider).setModel(id, picked),
    );
  }

  Future<void> _setReasoning(bool on) async {
    final id = _chatId;
    if (id == null) {
      setState(() => _newReasoning = on);
      return;
    }
    await ref.read(generalChatServiceProvider).setReasoning(id, on: on);
  }

  Future<void> _pickEffort(OrModelRow model, String? current) async {
    final spec = model.reasoningSpec;
    final choice = await showEffortSheet(
      context,
      model: model.shortName,
      efforts: spec.choosableEfforts,
      defaultEffort: spec.defaultEffort,
      current: current,
    );
    if (choice == null || !mounted) return;
    final id = _chatId;
    if (id == null) {
      setState(() {
        _newEffort = choice.effort;
        if (choice.effort != null) _newReasoning = true;
      });
      return;
    }
    await ref.read(generalChatServiceProvider).setEffort(id, choice.effort);
  }

  // --- images --------------------------------------------------------------------

  Future<void> _addImages(OrModelRow? model, String modelId) async {
    final l = AppLocalizations.of(context);
    final room = _attachments.room;
    if (room <= 0) {
      _snack(l.attachLimit(kMaxAttachments));
      return;
    }
    final readsImages = model?.readsImages ?? false;
    final choice = await _showAddSheet(
      context,
      model: modelShortName(modelId, model),
      readsImages: readsImages,
    );
    if (choice == null || !mounted) return;
    if (choice == _AddChoice.switchModel) {
      final chat = _chatId == null
          ? null
          : ref.read(generalChatProvider(_chatId!)).value;
      await _pickModel(modelId, chat);
      return;
    }
    final picker = ref.read(attachmentPickerProvider);
    final List<PickedAttachment> picked;
    try {
      picked = switch (choice) {
        _AddChoice.photos => await picker.photos(limit: room),
        _AddChoice.camera => [?await picker.camera()],
        _ => await picker.files(limit: room),
      };
    } on Exception catch (e) {
      if (mounted) _snack(l.attachPickFailed('$e'));
      return;
    }
    if (!mounted || picked.isEmpty) return;
    final images = [
      for (final p in picked)
        if (p.kind == 'image') p,
    ];
    if (images.length < picked.length) _snack(l.generalImagesOnly);
    final left = _attachments.addAll(images);
    if (left > 0) _snack(l.attachLeftOut(left, kMaxAttachments));
  }

  // --- chat menu -----------------------------------------------------------------

  Future<void> _rename(GeneralChatRow chat) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: chat.title ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.generalRenameTitle),
        content: TextField(
          key: const Key('general.rename.field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('general.rename.save'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l.generalRenameSave),
          ),
        ],
      ),
    );
    // not disposed here: the dialog still builds its field while it closes
    if (title == null || !mounted) return;
    await ref.read(generalChatServiceProvider).rename(chat.id, title);
  }

  Future<void> _archive(GeneralChatRow chat) async {
    final l = AppLocalizations.of(context);
    final service = ref.read(generalChatServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    await service.archive(chat.id);
    if (!mounted) return;
    unawaited(Navigator.of(context).maybePop());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.chatsArchived),
          persist: false,
          duration: DelveTokens.undoSnack,
          action: SnackBarAction(
            label: l.chatsUndo,
            onPressed: () =>
                unawaited(service.archive(chat.id, archived: false)),
          ),
        ),
      );
  }

  Future<void> _delete(GeneralChatRow chat) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.generalDeleteTitle),
        content: Text(l.generalDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('general.delete.confirm'),
            style: TextButton.styleFrom(foregroundColor: context.delve.alertFg),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.generalMenuDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(generalChatServiceProvider).deleteChat(chat.id);
    if (!mounted) return;
    unawaited(Navigator.of(context).maybePop());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.generalDeleted)));
  }

  // --- build -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = ref.watch(generalKeyProvider);
    final hasKey = key.value != null;
    final noKey = !hasKey && !key.isLoading;
    final chatId = _chatId;
    final chat = chatId == null
        ? null
        : ref.watch(generalChatProvider(chatId)).value;
    final messages = chatId == null
        ? const <GeneralMessageRow>[]
        : ref.watch(generalMessagesProvider(chatId)).value ??
              const <GeneralMessageRow>[];
    final images = chatId == null
        ? const <GeneralImageRef>[]
        : ref.watch(generalImagesProvider(chatId)).value ??
              const <GeneralImageRef>[];
    final models = ref.watch(generalModelsProvider).value ?? const [];
    final byId = {for (final m in models) m.id: m};
    final defaultModel = ref.watch(generalDefaultModelProvider);
    final modelId = chat?.modelId ?? _newModel ?? defaultModel;
    final model = byId[modelId];
    final name = modelShortName(modelId, model);
    // a loaded list without this model (or without a zero-retention
    // provider for it): “Pick a model”
    final usable = model != null && model.selectable;
    final chipName = models.isEmpty || usable ? name : null;
    final showTokens =
        ref.watch(generalMetaProvider(GeneralMetaKeys.showTokens)).value == '1';
    final streaming = messages.any((m) => m.status == 'streaming');
    final warning = messages
        .where((m) => m.providerWarning == 'pending')
        .lastOrNull;
    final title = chat?.title?.trim();
    final shownTitle = title == null || title.isEmpty ? l.newChat : title;

    final imagesBy = <String, List<GeneralImageRef>>{};
    for (final img in images) {
      imagesBy.putIfAbsent(img.messageId, () => []).add(img);
    }
    final items = <Widget>[
      for (final m in messages)
        switch (m.role) {
          'user' => GeneralUserMessage(
            key: ValueKey('general.msg.${m.id}'),
            text: m.content,
            images: imagesBy[m.id] ?? const [],
            onOpenImage: (img) =>
                unawaited(GeneralImageViewer.open(context, img)),
          ),
          'switch' => SwitchMarker(
            key: ValueKey('general.msg.${m.id}'),
            model: modelShortName(m.modelId ?? modelId, byId[m.modelId]),
            at: m.createdAt,
          ),
          _ => GeneralAnswer(
            key: ValueKey('general.msg.${m.id}'),
            message: m,
            modelName: modelShortName(m.modelId ?? modelId, byId[m.modelId]),
            showTokens: showTokens,
            onErrorAction: (a) => _onErrorAction(a, modelId),
          ),
        },
    ];

    // thinking
    final spec = model?.reasoningSpec;
    final on = chat?.reasoning ?? _newReasoning;
    final effort = chat == null ? _newEffort : chat.reasoningEffort;
    final validEffort =
        spec != null && effort != null && spec.choosableEfforts.contains(effort)
        ? effort
        : null;
    final locked = spec?.mandatory ?? false;
    final pill = spec == null || !spec.supported
        ? null
        : GeneralThinkingPill(
            on: on || locked,
            locked: locked,
            label: validEffort != null && (on || locked)
                ? l.generalThinkingEffort(effortLabel(l, validEffort))
                : l.composerThinking,
            lockedTip: l.generalAlwaysThinks(name),
            onChanged: (v) => unawaited(_setReasoning(v)),
            onLongPress: spec.choosableEfforts.isEmpty
                ? null
                : () => unawaited(_pickEffort(model!, effort)),
          );

    final unreadImages = model != null && !model.readsImages
        ? images.length
        : 0;

    return Scaffold(
      appBar: AppBar(
        key: const Key('general.topBar'),
        // the page colour, as the agent chat's bar
        backgroundColor: context.colors.surface,
        notificationPredicate: (_) => false,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(
          shownTitle,
          key: const Key('general.title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium,
        ),
        actions: [
          ModelChip(
            name: chipName,
            pct: chat == null ? null : generalContextPct(chat),
            onTap: () => unawaited(_pickModel(modelId, chat)),
          ),
          if (chat != null)
            PopupMenuButton<String>(
              key: const Key('general.menu'),
              tooltip: l.generalMenu,
              icon: const SymbolIcon(DelveIcons.moreVert),
              onSelected: (v) {
                switch (v) {
                  case 'effort':
                    if (model != null) {
                      unawaited(_pickEffort(model, effort));
                    }
                  case 'rename':
                    unawaited(_rename(chat));
                  case 'archive':
                    unawaited(_archive(chat));
                  case 'delete':
                    unawaited(_delete(chat));
                }
              },
              itemBuilder: (_) => [
                if (spec != null && spec.choosableEfforts.isNotEmpty)
                  PopupMenuItem(
                    key: const Key('general.menu.effort'),
                    value: 'effort',
                    child: Text(l.generalMenuEffort),
                  ),
                PopupMenuItem(
                  key: const Key('general.menu.rename'),
                  value: 'rename',
                  child: Text(l.generalMenuRename),
                ),
                PopupMenuItem(
                  key: const Key('general.menu.archive'),
                  value: 'archive',
                  child: Text(l.generalMenuArchive),
                ),
                PopupMenuItem(
                  key: const Key('general.menu.delete'),
                  value: 'delete',
                  child: Text(l.generalMenuDelete),
                ),
              ],
            )
          else
            const SizedBox(width: DelveTokens.space3),
        ],
      ),
      body: Column(
        children: [
          if (chatId == null && widget.kindSwitch != null) widget.kindSwitch!,
          Expanded(
            child: UnderBarFade(
              fadeKey: const Key('general.fade'),
              child: items.isEmpty
                  ? (noKey ? const SizedBox.shrink() : _Intro(model: name))
                  : ListView.separated(
                      key: const Key('general.list'),
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(
                        DelveTokens.space4,
                        UnderBarFade.height,
                        DelveTokens.space4,
                        DelveTokens.space4,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: DelveTokens.space4),
                      itemBuilder: (_, i) => items[items.length - 1 - i],
                    ),
            ),
          ),
          if (warning != null)
            _Banner(
              child: StatusBanner(
                key: const Key('general.providerWarning'),
                kind: StatusKind.warn,
                icon: DelveIcons.shield,
                text: l.generalProviderWarning(warning.provider ?? '?'),
                actionLabel: l.generalAcknowledge,
                onAction: () => unawaited(
                  ref
                      .read(generalChatServiceProvider)
                      .acknowledgeWarning(warning.id),
                ),
              ),
            ),
          if (unreadImages > 0 && warning == null)
            _Banner(
              child: StatusBanner(
                key: const Key('general.noImages'),
                kind: StatusKind.info,
                icon: DelveIcons.imageGone,
                text: l.generalNoImages(name, unreadImages),
              ),
            ),
          if (noKey)
            _NoKey(onAdd: () => context.push(Routes.generalSettings))
          else
            Composer(
              controller: _text,
              onSend: (text) => _send(text, modelId),
              onStop: streaming && chatId != null
                  ? () => ref.read(generalChatServiceProvider).stop(chatId)
                  : null,
              leading: [?pill],
              attachments: _attachments,
              onAdd: hasKey
                  ? () => unawaited(_addImages(model, modelId))
                  : null,
              hintText: l.generalComposerHint(name),
              sendBlocked: streaming || warning != null || !usable || !hasKey,
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space3,
      0,
      DelveTokens.space3,
      DelveTokens.space2,
    ),
    child: child,
  );
}

/// The empty General chat: cloud, the model's name, where it goes.
class _Intro extends StatelessWidget {
  const _Intro({required this.model});

  final String model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    return Center(
      child: SingleChildScrollView(
        key: const Key('general.intro'),
        padding: const EdgeInsets.all(DelveTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(DelveIcons.cloud, size: 36, color: cs.onSurfaceVariant),
            const SizedBox(height: DelveTokens.space2),
            Text(
              model,
              key: const Key('general.intro.model'),
              textAlign: TextAlign.center,
              style: context.text.displaySmall!.copyWith(
                fontSize: 32,
                height: 40 / 32,
              ),
            ),
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.generalIntroVia,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DelveTokens.space3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolIcon(
                  DelveIcons.shield,
                  size: DelveTokens.iconSm,
                  color: muted,
                ),
                const SizedBox(width: DelveTokens.space1),
                Flexible(
                  child: Text(
                    l.generalIntroShield,
                    style: context.text.labelMedium!.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// No key yet: in place of the composer, what General is and the way to
/// Settings → General.
class _NoKey extends StatelessWidget {
  const _NoKey({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        key: const Key('general.noKey'),
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space6,
          DelveTokens.space4,
          DelveTokens.space6,
          DelveTokens.space8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(
              DelveIcons.key,
              size: 40,
              color: context.delve.textMuted,
            ),
            const SizedBox(height: DelveTokens.space3),
            Text(
              l.generalNoKeyTitle,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.generalNoKeyBody,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DelveTokens.space5),
            FilledButton.icon(
              key: const Key('general.addKey'),
              onPressed: onAdd,
              icon: const SymbolIcon(DelveIcons.key, size: DelveTokens.iconMd),
              label: Text(l.generalAddKey),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AddChoice { photos, camera, files, switchModel }

/// The General “+” (design 24): Photos · Camera · Files, images only. A
/// model that reads no images: the rows are disabled under an info banner
/// with Switch model.
Future<_AddChoice?> _showAddSheet(
  BuildContext context, {
  required String model,
  required bool readsImages,
}) => showModalBottomSheet<_AddChoice>(
  context: context,
  showDragHandle: true,
  backgroundColor: context.colors.surfaceContainerHigh,
  builder: (context) {
    final l = AppLocalizations.of(context);
    Widget tile(_AddChoice c, AttachSource s, IconData icon, String label) =>
        SizedBox(
          height: 60,
          child: ListTile(
            key: Key('attach.${s.name}'),
            enabled: readsImages,
            leading: SymbolIcon(icon),
            title: Text(label),
            onTap: () => Navigator.of(context).pop(c),
          ),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space6,
              0,
              DelveTokens.space6,
              DelveTokens.space3,
            ),
            child: Text(l.generalAddTitle, style: context.text.titleLarge),
          ),
          if (!readsImages)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                0,
                DelveTokens.space4,
                DelveTokens.space2,
              ),
              child: StatusBanner(
                key: const Key('general.add.noImages'),
                kind: StatusKind.info,
                icon: DelveIcons.imageGone,
                text: l.generalNoImageInput(model),
                actionLabel: l.generalSwitchModel,
                onAction: () =>
                    Navigator.of(context).pop(_AddChoice.switchModel),
              ),
            ),
          tile(
            _AddChoice.photos,
            AttachSource.photos,
            DelveIcons.photos,
            l.attachPhotos,
          ),
          tile(
            _AddChoice.camera,
            AttachSource.camera,
            DelveIcons.camera,
            l.attachCamera,
          ),
          tile(
            _AddChoice.files,
            AttachSource.file,
            DelveIcons.attachFile,
            l.attachFile,
          ),
          const SizedBox(height: DelveTokens.space2),
        ],
      ),
    );
  },
);
