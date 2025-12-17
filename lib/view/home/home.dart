import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
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
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
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

  // GlobalKeys for accessing SearchScrollWrapperState
  final GlobalKey<SearchScrollWrapperState> _issuesSearchKey =
      GlobalKey<SearchScrollWrapperState>();
  final GlobalKey<SearchScrollWrapperState> _pullsSearchKey =
      GlobalKey<SearchScrollWrapperState>();

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
            searchWrapperKey: _issuesSearchKey,
          ),
        ),
        DynamicTab(
          identifier: 'Pulls',
          tab: TabBarItem(label: 'Pull Requests'),
          tabViewBuilder: (final BuildContext context) => PullsTab(
            deepLinkData: widget.deepLinkData?.components.first == 'pulls'
                ? widget.deepLinkData
                : null,
            searchWrapperKey: _pullsSearchKey,
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
              final isIssuesTab = currentTab == 'Issues';
              final isPullsTab = currentTab == 'Pulls';
              final hasSearchTab = isIssuesTab || isPullsTab;

              // Build all actions in a single list - they'll be automatically split by type
              final List<ActionButtonData> allActions = [];

              // Prominent actions (will appear above the row)
              // Always include these buttons so they can animate out smoothly when switching tabs
              // Use visibilityState to control visibility instead of conditionally adding
              final searchWrapperState = hasSearchTab
                  ? (isIssuesTab
                      ? _issuesSearchKey.currentState
                      : _pullsSearchKey.currentState)
                  : null;

              // Search bar as major action - always include, use visibilityState
              allActions.add(
                MinorActionButton(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  onTap: () async {
                    if (searchWrapperState != null) {
                      await AutoRouter.of(context).push(
                        SearchOverlayRoute(
                          message: searchWrapperState.searchBarMessage ??
                              (isIssuesTab
                                  ? 'Search in your issues'
                                  : 'Search in your pull requests'),
                          multiHero: true,
                          searchData: searchWrapperState.currentSearchData,
                          heroTag: searchWrapperState.searchHeroTag,
                          onSubmit: (final SearchData data) {
                            searchWrapperState.updateSearchData(data);
                          },
                        ),
                      );
                    }
                  },
                  visibilityState: hasSearchTab
                      ? ActionButtonVisibilityState.both
                      : ActionButtonVisibilityState.none,
                ),
              );

              // Quick Filters expandable widget
              final filters = searchWrapperState?.quickFilters;
              if (filters != null && filters.isNotEmpty) {
                // allActions.add(
                //   ExpandableActionButton(
                //     icon: Icons.filter_list_rounded,
                //     label: 'Quick Filters',
                //     expandableWidgetBuilder: (onCollapse) {
                //       return _buildQuickFiltersWidget(
                //         context,
                //         searchWrapperState!,
                //         filters,
                //         onCollapse,
                //       );
                //     },
                //     visibilityState: hasSearchTab
                //         ? ActionButtonVisibilityState.both
                //         : ActionButtonVisibilityState.none,
                //   ),
                // );
              }

              // Sort expandable widget - always include, use visibilityState
              allActions.add(
                ExpandableActionButton(
                  icon: Icons.sort_rounded,
                  label: 'Sort',
                  expandableWidgetBuilder: (onCollapse) {
                    if (searchWrapperState == null) {
                      return const SizedBox.shrink();
                    }
                    return _buildSortWidget(
                      context,
                      searchWrapperState,
                      onCollapse,
                    );
                  },
                  visibilityState: (hasSearchTab && searchWrapperState != null)
                      ? ActionButtonVisibilityState.both
                      : ActionButtonVisibilityState.none,
                ),
              );

              // Quick options as CheckboxActionButton widgets - always include, use visibilityState
              final options = searchWrapperState?.quickOptions;
              if (options != null && options.isNotEmpty) {
                final currentSearchData = searchWrapperState!.currentSearchData;
                for (final entry in options.entries) {
                  final isSelected =
                      currentSearchData.filterStrings.contains(entry.key);
                  allActions.add(
                    CheckboxActionButton(
                      icon: isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      label: entry.value,
                      value: isSelected,
                      onChanged: (bool? value) {
                        if (searchWrapperState == null) return;
                        final filters =
                            currentSearchData.visibleStrings.toList();
                        if (value == true) {
                          filters.add(entry.key);
                        } else {
                          filters.remove(entry.key);
                        }
                        final newSearchData = currentSearchData.copyWith(
                          filterStrings: filters,
                        );
                        searchWrapperState.updateSearchData(newSearchData);
                      },
                      visibilityState:
                          (hasSearchTab && searchWrapperState != null)
                              ? ActionButtonVisibilityState.both
                              : ActionButtonVisibilityState.none,
                    ),
                  );
                }
              }

              // Minor actions (will appear in the row)
              allActions.addAll([
                MinorActionButton(
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
                MinorActionButton(
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
                MinorActionButton(
                  icon: Icons.settings_rounded,
                  label: 'App Settings',
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                MinorActionButton(
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
                MinorActionButton(
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
              ]);

              return FloatingActionToolbar(
                key: const ValueKey('home_toolbar'),
                actions: allActions,
                actionCardBuilder: (context, action) =>
                    buildStandardActionCard(context, action),
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

  /// Builds the quick filters widget
  Widget _buildQuickFiltersWidget(
    BuildContext context,
    SearchScrollWrapperState searchWrapperState,
    Map<String, String> quickFilters,
    VoidCallback onCollapse,
  ) {
    final currentSearchData = searchWrapperState.currentSearchData;
    final activeQuickFilter = currentSearchData.activeQuickFilter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: quickFilters.entries.map((entry) {
        final isSelected = activeQuickFilter == entry.key;
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          selected: isSelected,
          selectedTileColor: isSelected ? context.colorScheme.primary : null,
          title: Text(
            entry.value,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.colorScheme.onPrimary,
                )
              : null,
          onTap: () {
            final newSearchData = currentSearchData.copyWith(
              quickFilter: isSelected ? null : entry.key,
            );
            searchWrapperState.updateSearchData(newSearchData);
            onCollapse();
          },
        );
      }).toList(),
    );
  }

  /// Builds the sort widget
  Widget _buildSortWidget(
    BuildContext context,
    SearchScrollWrapperState searchWrapperState,
    VoidCallback onCollapse,
  ) {
    final currentSearchData = searchWrapperState.currentSearchData;
    final sortOptions = searchWrapperState.sortOptions;
    if (sortOptions == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sortOptions.entries.map((entry) {
        final isSelected = currentSearchData.sort == entry.key;
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          selected: isSelected,
          selectedTileColor: isSelected ? context.colorScheme.primary : null,
          title: Text(
            entry.value,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.colorScheme.onPrimary,
                )
              : null,
          onTap: () {
            final newSearchData = currentSearchData.copyWith(sort: entry.key);
            searchWrapperState.updateSearchData(newSearchData);
            onCollapse();
          },
        );
      }).toList(),
    );
  }
}
