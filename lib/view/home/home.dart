import 'package:auto_route/annotations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
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
    return SizedBox.expand(
      child: Stack(
        children: [
          SafeArea(
            child: DynamicTabsParent(
              controller: tabsController,
              builder: (final BuildContext context,
                      final PreferredSizeWidget tabBar, final Widget tabView) =>
                  DynamicScroll(
                expandedByDefault: true,
                contentVersion: 0,
                animationController: _expandAnimationController,
                collapsedWidget: buildCollapsedAppBar(context),
                bottom: AnimatedTabBar(
                  showTabBar: tabsController.activeLength > 1,
                  tabBar: tabBar,
                  defaultPadding: const EdgeInsets.only(bottom: 8),
                  topSpacing: 0,
                ),
                expandedWidget: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: <Widget>[
                      buildProfileCard(context),
                    ],
                  ),
                ),
                body: tabView,
              ),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: tabsController.activeIdentifierNotifier,
            builder: (context, currentTab, _) {
              return FloatingActionToolbar(
                key: const ValueKey('home_toolbar'),
                actions: [
                  ActionButtonData(
                    icon: Octicons.issue_opened,
                    label: 'Issues',
                    trailing: buildActionButtonTrailingCount(
                      context,
                      context.viewer.issues.totalCount,
                    ),
                    actionType: ActionButtonActionType.tab,
                    visibilityState: currentTab == 'Issues'
                        ? ActionButtonVisibilityState.none
                        : ActionButtonVisibilityState.both,
                    onTap: () => tabsController.openTab('Issues'),
                  ),
                  ActionButtonData(
                    icon: Octicons.git_pull_request,
                    label: 'Pull Requests',
                    trailing: buildActionButtonTrailingCount(
                      context,
                      context.viewer.pullRequests.totalCount,
                    ),
                    actionType: ActionButtonActionType.tab,
                    visibilityState: currentTab == 'Pulls'
                        ? ActionButtonVisibilityState.none
                        : ActionButtonVisibilityState.both,
                    onTap: () => tabsController.openTab('Pulls'),
                  ),
                  ActionButtonData(
                    icon: Icons.settings_rounded,
                    label: 'App Settings',
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                  ActionButtonData(
                    icon: Octicons.organization,
                    label: 'Organizations',
                    trailing: buildActionButtonTrailingCount(
                      context,
                      context.viewer.organizations.totalCount,
                    ),
                    actionType: ActionButtonActionType.tab,
                    visibilityState: currentTab == 'orgs'
                        ? ActionButtonVisibilityState.none
                        : ActionButtonVisibilityState.expandedOnly,
                    onTap: () => tabsController.openTab('orgs'),
                  ),
                  ActionButtonData(
                    icon: Octicons.repo,
                    label: 'Repositories',
                    trailing: buildActionButtonTrailingCount(
                      context,
                      context.viewer.repositories.totalCount,
                    ),
                    visibilityState: currentTab == 'repos'
                        ? ActionButtonVisibilityState.none
                        : ActionButtonVisibilityState.expandedOnly,
                    onTap: () {
                      // tabsController.openTab('repos');
                    },
                  ),
                ],
                actionCardBuilder: (context, action) =>
                    buildStandardActionCard(context, action),
                defaultVisibleCount:
                    3, // Show Issues, PRs, and App Settings in compact mode
                position: FloatingPosition.bottom,
                // Default alignment for bottom is right (set in FloatingActionToolbar)
                // alignment: null,
                title: context.provider<CurrentUserProvider>().data.login,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onExpandChanged: (isExpanded) {
                  if (isExpanded) {
                    _expandAnimationController.forward();
                  } else {
                    _expandAnimationController.reverse();
                  }
                },
              );
            },
          ),
        ],
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
