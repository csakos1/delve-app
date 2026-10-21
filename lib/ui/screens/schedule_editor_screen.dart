import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../api/rest_client.dart';
import '../../app/chat_list.dart';
import '../../app/cron_preset.dart';
import '../../app/schedules.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../schedule_text.dart';
import '../widgets/chat_row.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

enum Repeat { daily, weekly, cron }

/// 14b: a new schedule ([scheduleId] null) or an existing one. The morning
/// brief only takes its timing; a prompt schedule also its name, prompt, the
/// chat it posts to and thinking.
class ScheduleEditorScreen extends ConsumerStatefulWidget {
  const ScheduleEditorScreen({super.key, this.scheduleId});

  final String? scheduleId;

  @override
  ConsumerState<ScheduleEditorScreen> createState() =>
      _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends ConsumerState<ScheduleEditorScreen> {
  final _name = TextEditingController();
  final _prompt = TextEditingController();
  final _cron = TextEditingController();

  Repeat _repeat = Repeat.daily;
  List<ClockTime> _times = const [ClockTime(9, 0)];
  Set<int> _days = const {1, 2, 3, 4, 5};
  ClockTime _weeklyTime = const ClockTime(9, 0);
  String? _conversationId;
  String? _conversationTitle;
  bool _fixed = false;
  bool _thinking = false;
  bool _saving = false;

  /// Field errors: `name`, `timing`, `prompt`, `chat` (from the server or
  /// from a check before sending).
  final Map<String, String> _errors = {};

  Schedule? _original;

  @override
  void initState() {
    super.initState();
    final id = widget.scheduleId;
    final s = id == null ? null : ref.read(schedulesProvider).byId(id);
    _original = s;
    if (s == null) return;
    _name.text = s.name;
    _prompt.text = s.prompt ?? '';
    _cron.text = s.cron;
    _thinking = s.thinking;
    _fixed = s.conversationMode == 'fixed';
    _conversationId = s.conversationId;
    _conversationTitle = s.conversationTitle;
    switch (CronPreset.parse(s.cron)) {
      case DailyCron(:final times):
        _repeat = Repeat.daily;
        _times = times;
      case WeeklyCron(:final days, :final time):
        _repeat = Repeat.weekly;
        _days = days;
        _weeklyTime = time;
      case CustomCron():
        _repeat = Repeat.cron;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _prompt.dispose();
    _cron.dispose();
    super.dispose();
  }

  bool get _isBrief => _original?.kind == 'brief';

  CronPreset get _preset => switch (_repeat) {
    Repeat.daily => DailyCron([..._times]..sort()),
    Repeat.weekly => WeeklyCron(_days, _weeklyTime),
    Repeat.cron => CustomCron(_cron.text),
  };

  /// Why the timing cannot be saved (null: it can).
  String? _timingProblem(AppLocalizations l) => switch (_preset) {
    DailyCron(:final times) when times.isEmpty => l.schedNoTime,
    final DailyCron d when !d.sharesMinute => l.schedSameMinute,
    WeeklyCron(:final days) when days.isEmpty => l.schedNoDay,
    final p when p.toCron() == null => l.schedCronInvalid,
    _ => null,
  };

  Future<ClockTime?> _pickTime(ClockTime initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    return picked == null ? null : ClockTime(picked.hour, picked.minute);
  }

  Future<void> _addTime() async {
    final last = _times.isEmpty ? const ClockTime(9, 0) : _times.last;
    final t = await _pickTime(ClockTime((last.hour + 4) % 24, last.minute));
    if (t == null || !mounted) return;
    setState(() {
      _times = {..._times, t}.toList()..sort();
      _errors.remove('timing');
    });
  }

  Future<void> _changeTime(int index) async {
    final t = await _pickTime(_times[index]);
    if (t == null || !mounted) return;
    setState(() {
      final next = [..._times]..[index] = t;
      _times = next.toSet().toList()..sort();
      _errors.remove('timing');
    });
  }

  Future<void> _changeWeeklyTime() async {
    final t = await _pickTime(_weeklyTime);
    if (t != null && mounted) setState(() => _weeklyTime = t);
  }

  void _setRepeat(Repeat r) {
    setState(() {
      // carry the current timing over where it fits
      final cron = _preset.toCron();
      if (r == Repeat.cron && cron != null) _cron.text = cron;
      if (r == Repeat.weekly && _repeat == Repeat.daily && _times.isNotEmpty) {
        _weeklyTime = _times.first;
      }
      if (r == Repeat.daily && _repeat == Repeat.weekly) {
        _times = [_weeklyTime];
      }
      _repeat = r;
      _errors.remove('timing');
    });
  }

  Future<void> _pickChat() async {
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ChatPicker(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _conversationId = picked.$1;
      _conversationTitle = picked.$2;
      _fixed = true;
      _errors.remove('chat');
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final cron = _preset.toCron();
    final problems = <String, String>{
      'timing': ?_timingProblem(l),
      if (!_isBrief && _name.text.trim().isEmpty) 'name': l.schedErrName,
      if (!_isBrief && _prompt.text.trim().isEmpty) 'prompt': l.schedErrPrompt,
      if (!_isBrief && _fixed && _conversationId == null)
        'chat': l.schedErrChat,
    };
    if (problems.isNotEmpty || cron == null) {
      setState(() {
        _errors
          ..clear()
          ..addAll(problems);
      });
      return;
    }
    setState(() {
      _saving = true;
      _errors.clear();
    });
    final ctl = ref.read(schedulesProvider.notifier);
    final original = _original;
    try {
      if (original == null) {
        await ctl.create(
          ScheduleDraft(
            name: _name.text.trim(),
            cron: cron,
            prompt: _prompt.text.trim(),
            conversationId: _fixed ? _conversationId : null,
            thinking: _thinking,
          ),
        );
      } else {
        await ctl.change(original.id, _changes(original, cron));
      }
      if (mounted) unawaited(Navigator.of(context).maybePop());
    } on ApiRequestError catch (e) {
      final text = scheduleErrorText(l, e.code ?? '');
      final field = switch (e.code) {
        'invalid_cron' || 'too_frequent' => 'timing',
        'invalid_name' => 'name',
        'invalid_prompt' => 'prompt',
        'conversation_required' || 'conversation_not_found' => 'chat',
        _ => null,
      };
      if (!mounted) return;
      if (text != null && field != null) {
        setState(() => _errors[field] = text);
      } else {
        _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
      }
    } on Object catch (e) {
      _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Only what changed (the brief takes nothing but its timing).
  Map<String, Object?> _changes(Schedule s, String cron) {
    final out = <String, Object?>{if (cron != s.cron) 'cron': cron};
    if (_isBrief) return out.isEmpty ? {'cron': cron} : out;
    final name = _name.text.trim();
    final prompt = _prompt.text.trim();
    if (name != s.name) out['name'] = name;
    if (prompt != s.prompt) out['prompt'] = prompt;
    if (_thinking != s.thinking) out['thinking'] = _thinking;
    final mode = _fixed ? 'fixed' : 'new';
    final conv = _fixed ? _conversationId : null;
    if (mode != s.conversationMode || conv != s.conversationId) {
      out['conversation_mode'] = mode;
      out['conversation_id'] = conv;
    }
    return out.isEmpty ? {'cron': cron} : out;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final s = _original;
    if (s == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.schedDeleteTitle(s.name)),
        content: Text(l.schedDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('schedule.delete.confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.schedDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(schedulesProvider.notifier).delete(s.id);
      if (mounted) unawaited(Navigator.of(context).maybePop());
    } on Object catch (e) {
      _snack(l.schedulesSaveFailed(apiErrorText(l, e)));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final missing = widget.scheduleId != null && _original == null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const SymbolIcon(DelveIcons.close),
        ),
        title: Text(
          widget.scheduleId == null ? l.schedNewTitle : l.schedEditTitle,
        ),
        actions: [
          if (!missing)
            TextButton(
              key: const Key('schedule.save'),
              onPressed: _saving ? null : _save,
              child: Text(l.schedSave),
            ),
        ],
      ),
      body: missing
          ? Padding(
              padding: const EdgeInsets.all(DelveTokens.space4),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  kind: StatusKind.info,
                  icon: DelveIcons.info,
                  text: l.schedMissing,
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                DelveTokens.space4,
                DelveTokens.space4,
                DelveTokens.space4,
                DelveTokens.space6 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                TextField(
                  key: const Key('schedule.name'),
                  controller: _name,
                  enabled: !_isBrief,
                  maxLength: 64,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.schedName,
                    errorText: _errors['name'],
                    counterText: '',
                  ),
                ),
                const SizedBox(height: DelveTokens.space4),
                _Label(l.schedRepeats),
                SegmentedButton<Repeat>(
                  key: const Key('schedule.repeat'),
                  segments: [
                    ButtonSegment(
                      value: Repeat.daily,
                      label: Text(l.schedDaily),
                    ),
                    ButtonSegment(
                      value: Repeat.weekly,
                      label: Text(l.schedWeekly),
                    ),
                    ButtonSegment(value: Repeat.cron, label: Text(l.schedCron)),
                  ],
                  selected: {_repeat},
                  onSelectionChanged: (v) => _setRepeat(v.single),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: context.colors.primaryContainer,
                    selectedForegroundColor: context.colors.primary,
                  ),
                ),
                const SizedBox(height: DelveTokens.space3),
                ..._timingFields(l),
                const SizedBox(height: DelveTokens.space2),
                _Summary(
                  text: presetText(
                    l,
                    _preset,
                    // the server's reading fits only the cron it was made for
                    _preset.toCron() == _original?.cron
                        ? _original?.description ?? ''
                        : '',
                  ),
                  cron: _preset.toCron(),
                  error: _errors['timing'] ?? _timingProblem(l),
                ),
                if (_isBrief) ...[
                  const SizedBox(height: DelveTokens.space4),
                  StatusBanner(
                    kind: StatusKind.info,
                    icon: DelveIcons.brief,
                    text: l.schedBriefNote,
                  ),
                ] else
                  ..._promptFields(l),
              ],
            ),
    );
  }

  List<Widget> _timingFields(AppLocalizations l) => switch (_repeat) {
    Repeat.daily => [
      Wrap(
        spacing: DelveTokens.space2,
        runSpacing: DelveTokens.space2,
        children: [
          for (final (i, t) in _times.indexed)
            InputChip(
              key: Key('schedule.time.${t.text}'),
              label: Text(t.text, style: DelveText.mono),
              onPressed: () => _changeTime(i),
              onDeleted: () => setState(() {
                _times = [..._times]..removeAt(i);
                _errors.remove('timing');
              }),
              deleteButtonTooltipMessage: l.schedRemoveTime(t.text),
            ),
          ActionChip(
            key: const Key('schedule.addTime'),
            avatar: const SymbolIcon(DelveIcons.add, size: DelveTokens.iconMd),
            label: Text(l.schedAddTime),
            onPressed: _addTime,
          ),
        ],
      ),
    ],
    Repeat.weekly => [
      Wrap(
        spacing: DelveTokens.space2,
        runSpacing: DelveTokens.space2,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              key: Key('schedule.day.$d'),
              label: Text(weekdayName(d, short: true)),
              selected: _days.contains(d),
              onSelected: (on) => setState(() {
                _days = on ? {..._days, d} : ({..._days}..remove(d));
                _errors.remove('timing');
              }),
            ),
          ActionChip(
            key: const Key('schedule.weeklyTime'),
            avatar: const SymbolIcon(
              DelveIcons.schedule,
              size: DelveTokens.iconMd,
            ),
            label: Text(_weeklyTime.text, style: DelveText.mono),
            onPressed: _changeWeeklyTime,
          ),
        ],
      ),
    ],
    Repeat.cron => [
      TextField(
        key: const Key('schedule.cron'),
        controller: _cron,
        style: DelveText.mono,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(helperText: l.schedCronHelp),
        onChanged: (_) => setState(() => _errors.remove('timing')),
      ),
    ],
  };

  List<Widget> _promptFields(AppLocalizations l) => [
    const SizedBox(height: DelveTokens.space4),
    TextField(
      key: const Key('schedule.prompt'),
      controller: _prompt,
      minLines: 3,
      maxLines: 10,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: l.schedPrompt,
        alignLabelWithHint: true,
        errorText: _errors['prompt'],
      ),
    ),
    const SizedBox(height: DelveTokens.space4),
    _Label(l.schedPostTo),
    RadioGroup<bool>(
      groupValue: _fixed,
      onChanged: (v) {
        if (v == null) return;
        if (v && _conversationId == null) {
          unawaited(_pickChat());
          return;
        }
        setState(() {
          _fixed = v;
          _errors.remove('chat');
        });
      },
      child: Column(
        children: [
          RadioListTile<bool>(
            key: const Key('schedule.post.new'),
            contentPadding: EdgeInsets.zero,
            value: false,
            title: Text(l.schedNewChat),
          ),
          RadioListTile<bool>(
            key: const Key('schedule.post.fixed'),
            contentPadding: EdgeInsets.zero,
            value: true,
            title: Text(l.schedFixedChat),
            subtitle: Text(
              _errors['chat'] ?? _conversationTitle ?? l.schedPickChat,
              style: _errors['chat'] == null
                  ? null
                  : TextStyle(color: context.delve.alertFg),
            ),
            secondary: IconButton(
              key: const Key('schedule.pickChat'),
              tooltip: l.schedPickChat,
              onPressed: _pickChat,
              icon: const SymbolIcon(DelveIcons.forum),
            ),
          ),
        ],
      ),
    ),
    const Divider(height: DelveTokens.space4),
    SwitchListTile(
      key: const Key('schedule.thinking'),
      contentPadding: EdgeInsets.zero,
      secondary: const SymbolIcon(DelveIcons.thinking),
      title: Text(l.schedThinking),
      subtitle: Text(l.schedThinkingSub),
      value: _thinking,
      onChanged: (v) => setState(() => _thinking = v),
    ),
    if (_original != null) ...[
      const SizedBox(height: DelveTokens.space6),
      OutlinedButton.icon(
        key: const Key('schedule.delete'),
        onPressed: _delete,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.delve.alertFg,
          side: BorderSide(color: context.delve.alertBorder),
        ),
        icon: const SymbolIcon(DelveIcons.cancel),
        label: Text(l.schedDelete),
      ),
    ],
  ];
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DelveTokens.space2),
    child: Text(
      text,
      style: context.text.bodyMedium!.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// The timing in words with its cron on the right, or why it cannot be saved.
class _Summary extends StatelessWidget {
  const _Summary({required this.text, required this.cron, this.error});
  final String text;
  final String? cron;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final err = error;
    if (err != null) {
      return Text(
        err,
        key: const Key('schedule.timingError'),
        style: context.text.bodyMedium!.copyWith(color: context.delve.alertFg),
      );
    }
    final muted = context.colors.onSurfaceVariant;
    return Row(
      children: [
        SymbolIcon(DelveIcons.schedule, size: DelveTokens.iconMd, color: muted),
        const SizedBox(width: DelveTokens.space2),
        Expanded(
          child: Text(
            text,
            key: const Key('schedule.summary'),
            style: context.text.bodyMedium!.copyWith(color: muted),
          ),
        ),
        if (cron case final c?) ...[
          const SizedBox(width: DelveTokens.space2),
          Flexible(
            child: Text(
              c,
              key: const Key('schedule.cronText'),
              textAlign: TextAlign.end,
              style: DelveText.monoSmall.copyWith(color: muted),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet: the active chats; answers `(id, title)`.
class _ChatPicker extends ConsumerWidget {
  const _ChatPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final chats = ref.watch(chatListProvider(false)).value;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
              ),
              child: Text(l.schedPickChat, style: context.text.titleMedium),
            ),
            const SizedBox(height: DelveTokens.space2),
            if (chats == null)
              const Padding(
                padding: EdgeInsets.all(DelveTokens.space6),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (chats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(DelveTokens.space4),
                child: Text(l.schedNoChats),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in chats)
                      ListTile(
                        key: Key('pick.${c.conversation.id}'),
                        leading: const SymbolIcon(DelveIcons.forum),
                        title: Text(
                          ChatRow.titleOf(c, l.newChat),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop((
                          c.conversation.id,
                          ChatRow.titleOf(c, l.newChat),
                        )),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
