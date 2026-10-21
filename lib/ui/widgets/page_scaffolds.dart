import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';

/// Top-level screen (inside the bottom-nav shell): a Jost headline instead of
/// an app bar.
class TopLevelPage extends StatelessWidget {
  const TopLevelPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space4,
              DelveTokens.space2,
              DelveTokens.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.text.headlineMedium),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Sub-page (pushed on the root navigator, no bottom nav): app bar with back.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(title),
        actions: actions,
      ),
      body: child,
    );
  }
}

/// Body of a screen that a later step fills in.
class NotBuiltYet extends StatelessWidget {
  const NotBuiltYet({super.key, required this.icon, this.step});

  final IconData icon;

  /// Plan step that builds the screen, e.g. "A4".
  final String? step;

  @override
  Widget build(BuildContext context) {
    final muted = context.delve.textMuted;
    final label = AppLocalizations.of(context).notBuiltYet;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: muted),
          const SizedBox(height: DelveTokens.space3),
          Text(
            step == null ? label : '$label · $step',
            style: context.text.bodyMedium!.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// Rounded Material Symbol with the design's fill rule (1 = active/status).
class SymbolIcon extends StatelessWidget {
  const SymbolIcon(
    this.icon, {
    super.key,
    this.size = DelveTokens.iconLg,
    this.filled = false,
    this.color,
  });

  final IconData icon;
  final double size;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    icon,
    size: size,
    fill: filled ? 1 : 0,
    weight: 400,
    grade: 0,
    opticalSize: 24,
    color: color,
  );
}

/// Icons used across the shell (Material Symbols Rounded).
abstract final class DelveIcons {
  static const IconData chats = Symbols.chat_bubble_rounded;
  static const IconData dashboard = Symbols.dashboard_rounded;
  static const IconData approvals = Symbols.gpp_maybe_rounded;
  static const IconData more = Symbols.more_horiz_rounded;
  static const IconData system = Symbols.memory_rounded;
  static const IconData schedules = Symbols.schedule_rounded;
  static const IconData observability = Symbols.monitoring_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData chevronRight = Symbols.chevron_right_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData edit = Symbols.edit_square_rounded;
  static const IconData link = Symbols.link_rounded;
  static const IconData lock = Symbols.lock_rounded;
  static const IconData hourglass = Symbols.hourglass_top_rounded;
  static const IconData offline = Symbols.wifi_off_rounded;
  static const IconData error = Symbols.error_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData ok = Symbols.check_circle_rounded;
  static const IconData server = Symbols.dns_rounded;
  static const IconData device = Symbols.smartphone_rounded;
  static const IconData thinking = Symbols.psychology_rounded;
  static const IconData app = Symbols.apps_rounded;
  static const IconData api = Symbols.api_rounded;
  static const IconData agent = Symbols.smart_toy_rounded;
  static const IconData unpair = Symbols.link_off_rounded;
  static const IconData copy = Symbols.content_copy_rounded;
  static const IconData refresh = Symbols.refresh_rounded;
  static const IconData updateServer = Symbols.system_update_rounded;
  static const IconData sync = Symbols.sync_rounded;
  static const IconData syncProblem = Symbols.sync_problem_rounded;
  static const IconData cloudOff = Symbols.cloud_off_rounded;
  static const IconData keyOff = Symbols.key_off_rounded;
  static const IconData log = Symbols.receipt_long_rounded;
  static const IconData history = Symbols.history_rounded;
  static const IconData search = Symbols.search_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData archive = Symbols.archive_rounded;
  static const IconData unarchive = Symbols.unarchive_rounded;
  static const IconData forum = Symbols.forum_rounded;
  static const IconData moreVert = Symbols.more_vert_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData send = Symbols.arrow_upward_rounded;
  static const IconData stop = Symbols.stop_rounded;
  static const IconData schedule = Symbols.schedule_rounded;
  static const IconData scheduleSend = Symbols.schedule_send_rounded;
  static const IconData expandMore = Symbols.expand_more_rounded;
  static const IconData expandLess = Symbols.expand_less_rounded;
  static const IconData progress = Symbols.progress_activity_rounded;
  static const IconData cancel = Symbols.cancel_rounded;
  static const IconData block = Symbols.block_rounded;
  static const IconData timerOff = Symbols.timer_off_rounded;
  static const IconData gppBad = Symbols.gpp_bad_rounded;
  static const IconData water = Symbols.waves_rounded;
  static const IconData arrowDown = Symbols.arrow_downward_rounded;
  static const IconData arrowUp = Symbols.arrow_upward_rounded;
  static const IconData arrowFlat = Symbols.trending_flat_rounded;
  static const IconData brief = Symbols.wb_twilight_rounded;
  static const IconData notificationsOff = Symbols.notifications_off_rounded;
  static const IconData power = Symbols.power_settings_new_rounded;
  static const IconData play = Symbols.play_arrow_rounded;
}
