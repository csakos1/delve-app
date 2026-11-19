import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/layout.dart';
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
    this.bar,
    this.below,
    this.background,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool tintOnScroll;

  /// The header's colour at rest (the desktop's list column); null: the page
  /// colour.
  final Color? background;

  /// Replaces the title and actions (Files' selection mode, 23d): on
  /// surface-2, the status bar included.
  final Widget? bar;

  /// What stays put under the title (Chats: the filter chips, the search
  /// field): part of the header, so it tints with it while the page scrolls.
  final Widget? below;

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
    final desktop = DesktopLayout.of(context);
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
            color: _scrolled || widget.bar != null
                ? cs.surfaceContainer
                : widget.background ?? cs.surface,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.bar ??
                    (desktop
                        // the desktop's 48 dp pane header (L2b)
                        ? Container(
                            key: const Key('page.header.bar'),
                            height: DelveDesktop.paneHeader,
                            padding: const EdgeInsets.only(left: 16, right: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DelveDesktopText.paneTitle
                                          .copyWith(color: cs.onSurface),
                                    ),
                                  ),
                                ),
                                ...widget.actions,
                              ],
                            ),
                          )
                        : Padding(
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
                          )),
                ?widget.below,
              ],
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
        leading: pageBackButton(context),
        title: Text(title),
        actions: actions,
      ),
      body: child,
    );
  }
}

/// Content under a page-colour top bar: right under the bar the page colour
/// fades out over [height], so what scrolls up dims out under the bar
/// instead of being cut at a line (design 21, the chat). Taps go through.
class UnderBarFade extends StatelessWidget {
  const UnderBarFade({
    super.key,
    required this.child,
    this.fadeKey = const Key('page.fade'),
  });

  static const double height = DelveTokens.space6;

  final Widget child;
  final Key fadeKey;

  @override
  Widget build(BuildContext context) {
    final page = context.colors.surface;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: IgnorePointer(
            child: DecoratedBox(
              key: fadeKey,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [page, page.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A sub-page bar in the page colour (it does not change when content
/// scrolls under it; [UnderBarFade] goes under it): back, title, actions.
class PageColourBar extends StatelessWidget implements PreferredSizeWidget {
  const PageColourBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(DelveTokens.topBar);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: context.colors.surface,
    notificationPredicate: (_) => false,
    leading: pageBackButton(context),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: actions,
  );
}

/// A sub-page bar's back arrow. On the phone every sub-page is pushed, so
/// it always shows; in the desktop layout an area's first page has nowhere
/// to go back to, and the arrow shows only over a page of the same area.
Widget? pageBackButton(BuildContext context) {
  if (DesktopLayout.of(context) && !Navigator.of(context).canPop()) {
    return null;
  }
  return BackButton(onPressed: () => Navigator.of(context).maybePop());
}

/// The space above a Dashboard card in the desktop's columns (L2c): 0 for a
/// column's first card, 16 for the rest. The cards put it above themselves,
/// so one with nothing to show leaves no gap; outside the columns (the
/// phone) they keep their own.
class DashSpacing extends InheritedWidget {
  const DashSpacing({super.key, required this.top, required super.child});

  final double top;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashSpacing>()?.top;

  @override
  bool updateShouldNotify(DashSpacing oldWidget) => oldWidget.top != top;
}

/// [card] with the [DashSpacing] above it (as it is without one).
Widget dashSpaced(BuildContext context, Widget card) {
  final top = DashSpacing.maybeOf(context);
  if (top == null || top == 0) return card;
  return Padding(
    padding: EdgeInsets.only(top: top),
    child: card,
  );
}

/// A card's radius: 16 on the phone, 14 in the desktop layout.
double cardRadiusOf(BuildContext context) =>
    DesktopLayout.of(context) ? DelveDesktop.cardRadius : DelveTokens.rlg;

/// A card's padding: 16 on the phone, 14 / 16 / 16 in the desktop layout.
EdgeInsets cardPaddingOf(BuildContext context) => DesktopLayout.of(context)
    ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
    : const EdgeInsets.all(DelveTokens.space4);

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
  static const IconData files = Symbols.folder_rounded;
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
  static const IconData notifications = Symbols.notifications_rounded;
  static const IconData person = Symbols.person_rounded;
  static const IconData power = Symbols.power_settings_new_rounded;
  static const IconData play = Symbols.play_arrow_rounded;
  static const IconData photos = Symbols.photo_library_rounded;
  static const IconData camera = Symbols.photo_camera_rounded;
  static const IconData file = Symbols.description_rounded;
  static const IconData note = Symbols.sticky_note_2_rounded;
  static const IconData attachFile = Symbols.attach_file_rounded;
  static const IconData imageGone = Symbols.hide_image_rounded;
  static const IconData sendAgain = Symbols.redo_rounded;
  static const IconData watches = Symbols.travel_explore_rounded;
  static const IconData newWatch = Symbols.add_comment_rounded;
  static const IconData storefront = Symbols.storefront_rounded;
  static const IconData theaters = Symbols.theaters_rounded;
  static const IconData webPage = Symbols.language_rounded;
  static const IconData quote = Symbols.format_quote_rounded;
  static const IconData filter = Symbols.filter_alt_rounded;
  static const IconData onHold = Symbols.pause_circle_rounded;
  static const IconData pause = Symbols.pause_rounded;
  static const IconData openLink = Symbols.open_in_new_rounded;
  static const IconData fillIn = Symbols.north_west_rounded;
  static const IconData terminal = Symbols.terminal_rounded;
  static const IconData fingerprint = Symbols.fingerprint_rounded;
  static const IconData verified = Symbols.verified_user_rounded;
  static const IconData policy = Symbols.policy_rounded;
  static const IconData key = Symbols.key_rounded;
  static const IconData paste = Symbols.content_paste_rounded;
  static const IconData arrowBack = Symbols.arrow_back_rounded;
  static const IconData arrowForward = Symbols.arrow_forward_rounded;
  static const IconData backspace = Symbols.backspace_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData textSize = Symbols.format_size_rounded;
  static const IconData remove = Symbols.remove_rounded;
  static const IconData tab = Symbols.tab_rounded;
  static const IconData tabClose = Symbols.tab_close_rounded;

  /// The desktop inspector's toggle (L2).
  static const IconData inspector = Symbols.view_sidebar_rounded;
  static const IconData desktop = Symbols.desktop_windows_rounded;
  static const IconData panes = Symbols.view_column_rounded;
  static const IconData rename = Symbols.edit_rounded;
  static const IconData kill = Symbols.delete_forever_rounded;
  static const IconData cloud = Symbols.cloud_rounded;
  static const IconData computer = Symbols.computer_rounded;
  static const IconData modelSwitch = Symbols.swap_horiz_rounded;
  static const IconData star = Symbols.star_rounded;
  static const IconData stopped = Symbols.stop_circle_rounded;
  static const IconData wallet = Symbols.account_balance_wallet_rounded;
  static const IconData shield = Symbols.shield_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData delete = Symbols.delete_rounded;
  static const IconData dragIndicator = Symbols.drag_indicator_rounded;
  static const IconData exportChats = Symbols.download_rounded;
  static const IconData importChats = Symbols.upload_file_rounded;
  static const IconData share = Symbols.share_rounded;
  static const IconData unfoldMore = Symbols.unfold_more_rounded;

  /// Files dragged over a chat (desktop, L2b2).
  static const IconData dropToAttach = Symbols.upload_file_rounded;

  /// A link that leaves the card (the approval's chat, desktop, L2c).
  static const IconData arrowOutward = Symbols.arrow_outward_rounded;
}
