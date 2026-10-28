import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/delve_theme.dart';

/// Top-level screen (inside the bottom-nav shell): a Jost headline instead of
/// an app bar. With [tintOnScroll], the header (status bar included) turns
/// surface-2 while the content is scrolled under it, like a scrolled app bar.
class TopLevelPage extends StatefulWidget {
  const TopLevelPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.tintOnScroll = false,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool tintOnScroll;

  @override
  State<TopLevelPage> createState() => _TopLevelPageState();
}

class _TopLevelPageState extends State<TopLevelPage> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final scrolled = n.metrics.pixels > n.metrics.minScrollExtent;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    Widget body = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: widget.child,
    );
    if (widget.tintOnScroll) {
      body = NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: body,
      );
    }
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            key: const Key('page.header'),
            duration: DelveTokens.short,
            curve: DelveTokens.shortCurve,
            color: _scrolled ? cs.surfaceContainer : cs.surface,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: Padding(
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
                      child: Text(
                        widget.title,
                        style: context.text.headlineMedium,
                      ),
                    ),
                  ),
                  ...widget.actions,
                ],
              ),
            ),
          ),
          Expanded(child: body),
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
  static const IconData photos = Symbols.photo_library_rounded;
  static const IconData camera = Symbols.photo_camera_rounded;
  static const IconData file = Symbols.description_rounded;
  static const IconData attachFile = Symbols.attach_file_rounded;
  static const IconData imageGone = Symbols.hide_image_rounded;
  static const IconData sendAgain = Symbols.redo_rounded;
}
