import 'package:auto_route/annotations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/home/widgets/issues_tab.dart';
import 'package:diohub/view/home/widgets/pulls_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class _ActionCard {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  _ActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });
}

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.deepLinkData,
    this.buildThemePZero,
  });

  final dynamic buildThemePZero;
  final PathData? deepLinkData;

  // final TabController parentTabController;
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // late TabController _tabController;
  bool _showAllActions = false;
  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final DynamicTabsController tabsController = DynamicTabsController(
    vsync: this,
    tabs: _buildTabs(),
  );

  List<DynamicTab> _buildTabs() => <DynamicTab>[
        DynamicTab(
          identifier: 'Events',
          isDismissible: false,
          tabViewBuilder: (final BuildContext context) => const Events(
            isTimeline: false,
          ),
        ),
        DynamicTab(
          identifier: 'Issues',
          tabViewBuilder: (final BuildContext context) => IssuesTab(
            deepLinkData: widget.deepLinkData?.components.first == 'issues'
                ? widget.deepLinkData
                : null,
          ),
        ),
        DynamicTab(
          identifier: 'Pulls',
          tab: TabBarItem(label: 'Pull Requests'),
          tabViewBuilder: (final BuildContext context) => PullsTab(
            deepLinkData: widget.deepLinkData?.components.first == 'pulls'
                ? widget.deepLinkData
                : null,
          ),
        ),
        DynamicTab(
          identifier: 'orgs',
          tab: TabBarItem(label: 'Organizations'),
          tabViewBuilder: (final BuildContext context) => InfiniteScrollWrapper<
              GgetViewerOrgsData_viewer_organizations_edges?>(
            future: (
              final ScrollWrapperFutureArguments<
                      GgetViewerOrgsData_viewer_organizations_edges?>
                  data,
            ) async =>
                UserInfoService.getViewerOrgs(
              refresh: data.refresh,
              after: data.lastItem?.cursor,
            ),
            separatorBuilder: (final BuildContext context, final int index) =>
                const Divider(
              height: 8,
            ),
            listEndIndicator: false,
            // divider: false,
            builder: (
              final BuildContext context,
              final ScrollWrapperBuilderData<
                      GgetViewerOrgsData_viewer_organizations_edges?>
                  data,
            ) =>
                Row(
              children: <Widget>[
                Expanded(
                  child: ProfileTile.login(
                    avatarUrl: data.item?.node?.avatarUrl.toString(),
                    userLogin: data.item?.node?.login,
                    padding: const EdgeInsets.all(16),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];

  @override
  void initState() {
    // _tabController = TabController(vsync: this, length: 5, initialIndex: 0);
    // if (widget.deepLinkData?.components.first == 'issues') {
    //   _tabController.index = 1;
    // } else if (widget.deepLinkData?.components.first == 'pulls') {
    //   _tabController.index = 2;
    // }
    super.initState();
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return SafeArea(
      child: DynamicTabsParent(
        controller: tabsController,
        builder: (final BuildContext context, final PreferredSizeWidget tabBar,
                final Widget tabView) =>
            DynamicScroll(
          contentVersion: _showAllActions ? 1 : 0,
          animationController: _expandAnimationController,
          collapsedWidget: buildCollapsedAppBar(context),
          bottom: SizeExpandedSection(
            expand: tabsController.activeLength > 1,
            child: tabBar,
          ),
          expandedWidget: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: <Widget>[
                buildProfileCard(context),
                const SizedBox(
                  height: 16,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // All actions with wrap layout
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate number of columns based on available width
                            final int columns = (constraints.maxWidth / 160)
                                .floor()
                                .clamp(2, 6);
                            final double cardWidth =
                                (constraints.maxWidth - (12 * (columns - 1))) /
                                    columns;

                            // All available actions
                            final allActions = [
                              _ActionCard(
                                icon: Octicons.issue_opened,
                                label: 'Issues',
                                count: context.viewer.issues.totalCount,
                                onTap: () => tabsController.openTab('Issues'),
                              ),
                              _ActionCard(
                                icon: Octicons.git_pull_request,
                                label: 'Pull Requests',
                                count: context.viewer.pullRequests.totalCount,
                                onTap: () => tabsController.openTab('Pulls'),
                              ),
                              _ActionCard(
                                icon: Octicons.organization,
                                label: 'Organizations',
                                count: context.viewer.organizations.totalCount,
                                onTap: () => tabsController.openTab('orgs'),
                              ),
                              _ActionCard(
                                icon: Octicons.repo,
                                label: 'Repositories',
                                count: context.viewer.repositories.totalCount,
                                onTap: () {
                                  // tabsController.openTab('repos');
                                },
                              ),
                              _ActionCard(
                                icon: Icons.settings_rounded,
                                label: 'App Settings',
                                count: null,
                                onTap: () {
                                  // Navigate to settings
                                },
                              ),
                            ];

                            // Show as many cards as fit in one row
                            final int visibleCount =
                                columns.clamp(2, allActions.length);
                            final List<_ActionCard> visibleActions =
                                allActions.take(visibleCount).toList();
                            final List<_ActionCard> hiddenActions =
                                allActions.skip(visibleCount).toList();

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // Visible actions
                                ...visibleActions.map((action) => SizedBox(
                                      width: cardWidth,
                                      child: _buildQuickActionCard(
                                        context: context,
                                        icon: action.icon,
                                        label: action.label,
                                        count: action.count,
                                        onTap: action.onTap,
                                      ),
                                    )),
                                // Hidden actions (expandable)
                                if (_showAllActions)
                                  ...hiddenActions.asMap().entries.map((entry) {
                                    final action = entry.value;
                                    final isLastAndSettings =
                                        entry.key == hiddenActions.length - 1 &&
                                            action.label == 'App Settings';

                                    return SizedBox(
                                      width: isLastAndSettings
                                          ? constraints.maxWidth
                                          : cardWidth,
                                      child: _buildQuickActionCard(
                                        context: context,
                                        icon: action.icon,
                                        label: action.label,
                                        count: action.count,
                                        onTap: action.onTap,
                                      ),
                                    );
                                  }),
                                // Compact toggle button (only if there are hidden actions)
                                if (hiddenActions.isNotEmpty)
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Material(
                                      color: context
                                          .colorScheme.surfaceContainerHighest
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showAllActions = !_showAllActions;
                                          });
                                          if (_showAllActions) {
                                            _expandAnimationController
                                                .forward();
                                          } else {
                                            _expandAnimationController
                                                .reverse();
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              AnimatedRotation(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                turns:
                                                    _showAllActions ? 0.5 : 0,
                                                child: Icon(
                                                  Icons.expand_more_rounded,
                                                  size: 16,
                                                  color: context.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: tabView,
        ),
      ),
    );
  }

  Row buildProfileCard(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Row(
            children: <Widget>[
              ProfileTile.avatar(
                // fullName: context.provider<CurrentUserProvider>().data.name,
                avatarUrl: context
                    .provider<CurrentUserProvider>()
                    .data
                    .avatarUrl
                    .toString(),
                userLogin: context.provider<CurrentUserProvider>().data.login,
                padding: const EdgeInsets.all(16),
                size: 32,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.provider<CurrentUserProvider>().data.name!,
                    style: context.textTheme.titleMedium?.asBold(),
                  ),
                  Text(
                    context.provider<CurrentUserProvider>().data.login,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {},
                child: const Icon(
                  Icons.notifications_rounded,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Icon(
                  Icons.search_rounded,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int? count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: context.colorScheme.primary,
                  ),
                  const Spacer(),
                  if (count != null)
                    Text(
                      count.toString(),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row buildCollapsedAppBar(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ClipOval(
            child: InkPot(
              onTap: () {
                // widget.tabNavigators.toProfile();
              },
              child: CachedNetworkImage(
                height: 32,
                imageUrl: context.viewer.avatarUrl.toString(),
                placeholder: (final BuildContext context, final _) =>
                    ShimmerWidget(
                  child: Container(
                    color: context.colorScheme.surface,
                  ),
                ),
                // )
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            context.provider<CurrentUserProvider>().data.login,
            style: context.textTheme.bodyMedium?.asBold(),
          ),
        ],
      );
}
