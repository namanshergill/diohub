import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/floating_toolbar_wrapper.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/providers/users/user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/repositories/user_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart' as provider;

@RoutePage()
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen(this.login, {super.key});

  final String login;

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  GuserInfoData_user? data;
  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  // Date range state for Activity tab (contribution graph)
  int? _selectedYear; // null means last year (default)
  DateTime? _customFromDate;
  DateTime? _customToDate;
  bool _useCustomRange = false;

  /// Gets the display label for the current date range selection
  String _getDateRangeLabel() {
    if (_useCustomRange && _customFromDate != null) {
      final createdAt = data?.createdAt;
      if (createdAt != null) {
        final isSinceJoining = _customFromDate!.year == createdAt.year &&
            _customFromDate!.month == createdAt.month &&
            _customFromDate!.day == createdAt.day;
        return isSinceJoining ? 'Since joining' : 'Custom';
      }
      return 'Custom';
    }
    return _selectedYear?.toString() ?? 'Last Year';
  }

  /// Handles year selection change
  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      _useCustomRange = false;
      _customFromDate = null;
      _customToDate = null;
    });
  }

  /// Handles custom date range change
  void _onCustomRangeChanged(DateTime? from, DateTime? to) {
    setState(() {
      if (from == null && to == null) {
        // Reset to last year
        _selectedYear = null;
        _useCustomRange = false;
        _customFromDate = null;
        _customToDate = null;
      } else {
        _customFromDate = from;
        _customToDate = to;
        _useCustomRange = from != null && to != null;
        if (_useCustomRange) {
          _selectedYear = null;
        }
      }
    });
  }

  /// Builds a provider key for contributions (same logic as UserAboutScreen)
  ContributionQueryKey _getContributionProviderKey(String userName) {
    if (_useCustomRange && _customFromDate != null && _customToDate != null) {
      final from = DateTime(
          _customFromDate!.year, _customFromDate!.month, _customFromDate!.day);
      final to = DateTime(
          _customToDate!.year, _customToDate!.month, _customToDate!.day);
      return ContributionQueryKey.customRange(
        userName: userName,
        from: from,
        to: to,
      );
    }

    if (_selectedYear == null) {
      return ContributionQueryKey.lastYear(userName);
    } else {
      return ContributionQueryKey.year(userName, _selectedYear!);
    }
  }

  /// Builds the expanded content for the date range selector
  Widget _buildDateRangeExpandedContent(
    BuildContext context,
    GuserInfoData_user userData,
    VoidCallback onCollapse,
  ) {
    // Use a ConsumerWidget wrapper to watch the contributions provider for available years
    return _DateRangeExpandedContent(
      userName: userData.login,
      selectedYear: _selectedYear,
      customFromDate: _customFromDate,
      customToDate: _customToDate,
      useCustomRange: _useCustomRange,
      createdAt: userData.createdAt,
      onYearChanged: _onYearChanged,
      onCustomRangeChanged: _onCustomRangeChanged,
      getProviderKey: _getContributionProviderKey,
      onCollapse: onCollapse,
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  Widget _buildCollapsedHeader(
      BuildContext context, GuserInfoData_user userData) {
    return Row(
      children: <Widget>[
        ProfileTile.avatar(
          avatarUrl: userData.avatarUrl.toString(),
          userLogin: userData.login,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userData.name ?? userData.login,
                style: context.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
              if (userData.name != null)
                Text(
                  userData.login,
                  style: context.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(BuildContext context, GuserInfoData_user userData,
      DynamicTabsController? tabController) {
    const double leadingWidth = 56.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // User name
          Padding(
            padding: EdgeInsets.only(left: leadingWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData.name ?? userData.login,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  userData.login,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Detail tiles section
          _buildDetailTilesSection(context, userData),
          const SizedBox(height: 16),
          // Action buttons
          _buildActionButtons(context, userData, tabController),
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(
      BuildContext context, GuserInfoData_user userData) {
    return userData.when(
      user: (user) => _buildUserDetailTiles(context, user),
      orElse: () => _buildOrganizationDetailTiles(context, userData),
    );
  }

  Widget _buildUserDetailTiles(
      BuildContext context, GuserInfoData_user__asUser userData) {
    final List<Widget> alwaysVisibleTiles = [];

    // Bio
    if (userData.bio != null && userData.bio!.isNotEmpty) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Bio',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.bio!),
        ),
      );
    }

    // Pronouns
    if (userData.pronouns != null && userData.pronouns!.isNotEmpty) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Pronouns',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.pronouns!),
        ),
      );
    }

    // Location
    if (userData.location != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Location',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.location!),
        ),
      );
    }

    // Company
    if (userData.company != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Company',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.company!),
        ),
      );
    }

    // Status
    if (userData.status != null && userData.status!.message != null) {
      final statusText = userData.status!.emoji != null
          ? '${userData.status!.emoji} ${userData.status!.message}'
          : userData.status!.message!;
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Status',
          actionType: DetailTileActionType.none,
          child: DetailTileText(statusText),
        ),
      );
    }

    // Available for hire
    if (userData.isHireable == true) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Available for hire',
          actionType: DetailTileActionType.none,
          child: DetailTileText('Yes'),
        ),
      );
    }

    // Joined date
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Joined',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(userData.createdAt.toString(), shorten: false),
        ),
      ),
    );

    final List<Widget> expandableTiles = [];

    // Email
    if (userData.email.isNotEmpty) {
      expandableTiles.add(
        DetailTile(
          title: 'Email',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            // Handle email tap
          },
          child: DetailTileText(userData.email),
        ),
      );
    }

    // Twitter
    if (userData.twitterUsername != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Twitter',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            // Handle Twitter tap
          },
          child: DetailTileText('@${userData.twitterUsername}'),
        ),
      );
    }

    // Blog
    if (userData.websiteUrl != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Blog',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // Handle blog tap
          },
          child: DetailTileText(userData.websiteUrl!.toString()),
        ),
      );
    }

    // Organizations
    if (userData.organizations.totalCount > 0) {
      expandableTiles.add(
        DetailTile(
          title: 'Organizations',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // TODO: Navigate to organizations list
          },
          child: DetailTileText(
            '${userData.organizations.totalCount} ${userData.organizations.totalCount == 1 ? 'organization' : 'organizations'}',
          ),
        ),
      );
    }

    // Gists
    if (userData.gists.totalCount > 0) {
      expandableTiles.add(
        DetailTile(
          title: 'Gists',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // TODO: Navigate to gists list
          },
          child: DetailTileText(
            '${userData.gists.totalCount} ${userData.gists.totalCount == 1 ? 'gist' : 'gists'}',
          ),
        ),
      );
    }

    if (alwaysVisibleTiles.isEmpty && expandableTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return CollapsibleDetailTiles(
      alwaysVisibleTiles: alwaysVisibleTiles,
      expandableTiles: expandableTiles,
      visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
        defaultVisibleCount: alwaysVisibleTiles.length.clamp(0, 3),
      ),
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _expandAnimationController.forward();
        } else {
          _expandAnimationController.reverse();
        }
      },
    );
  }

  Widget _buildOrganizationDetailTiles(
      BuildContext context, GuserInfoData_user userData) {
    final List<Widget> alwaysVisibleTiles = [];

    // Bio
    if (userData.bio != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Bio',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.bio!),
        ),
      );
    }

    // Location
    if (userData.location != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Location',
          actionType: DetailTileActionType.none,
          child: DetailTileText(userData.location!),
        ),
      );
    }

    // Created date
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Created',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(userData.createdAt.toString(), shorten: false),
        ),
      ),
    );

    final List<Widget> expandableTiles = [];

    // Twitter
    if (userData.twitterUsername != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Twitter',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            // Handle Twitter tap
          },
          child: DetailTileText('@${userData.twitterUsername}'),
        ),
      );
    }

    // Blog
    if (userData.websiteUrl != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Blog',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // Handle blog tap
          },
          child: DetailTileText(userData.websiteUrl!.toString()),
        ),
      );
    }

    if (alwaysVisibleTiles.isEmpty && expandableTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return CollapsibleDetailTiles(
      alwaysVisibleTiles: alwaysVisibleTiles,
      expandableTiles: expandableTiles,
      visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
        defaultVisibleCount: alwaysVisibleTiles.length.clamp(0, 3),
      ),
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _expandAnimationController.forward();
        } else {
          _expandAnimationController.reverse();
        }
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, GuserInfoData_user userData,
      DynamicTabsController? tabController) {
    final isViewer = userData.isViewer;

    final List<ActionButtonData> primaryActions = [];

    // Follow/Unfollow button (only for other users)
    if (!isViewer && userData.viewerCanFollow) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.person_add,
          label: userData.viewerIsFollowing ? 'Unfollow' : 'Follow',
          trailing: buildActionButtonTrailingCount(
            context,
            userData.followers.totalCount,
          ),
          onTap: () async {
            // TODO: Implement follow/unfollow logic
            // Use UserInfoService.changeFollowStatus
          },
        ),
      );
    }

    // Repositories count
    primaryActions.add(
      MinorActionButton(
        icon: Octicons.repo,
        label: 'Repositories',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.repositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        onTap: () => tabController?.openTab('Repositories'),
      ),
    );

    // Followers count
    primaryActions.add(
      MinorActionButton(
        icon: Octicons.people,
        label: 'Followers',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.followers.totalCount,
        ),
        onTap: () {
          // TODO: Navigate to followers list
        },
      ),
    );

    // Following count (only for users, not organizations)
    userData.when(
      user: (user) {
        primaryActions.add(
          MinorActionButton(
            icon: Octicons.person,
            label: 'Following',
            trailing: buildActionButtonTrailingCount(
              context,
              user.following.totalCount,
            ),
            onTap: () {
              // TODO: Navigate to following list
            },
          ),
        );
      },
      orElse: () {
        // Organizations don't have following
      },
    );

    final List<ActionButtonData> secondaryActions = [];

    // More actions can go here
    // Note: publicGists is not available in GraphQL user query
    // If needed, it can be added to the query

    if (primaryActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return CollapsibleActionButtons(
      primaryActions: primaryActions,
      secondaryActions: secondaryActions,
      actionCardBuilder: (context, action) => buildStandardActionCard(
        context,
        action,
        iconSize: 16,
        padding: const EdgeInsets.all(10),
      ),
      visibilityConfig: const ActionButtonsVisibilityConfig(
        minPerRow: 2,
        maxPerRow: 4,
      ),
      onExpandChanged: (isExpanded) {
        if (isExpanded) {
          _expandAnimationController.forward();
        } else {
          _expandAnimationController.reverse();
        }
      },
    );
  }

  List<ActionButtonData> _buildToolbarActions(BuildContext context,
      GuserInfoData_user userData, DynamicTabsController? tabController) {
    final currentTab = tabController?.activeIdentifier ?? 'Activity';

    // Get pinned repositories
    final pinnedItems = userData.pinnedItems.edges?.toList() ??
        <GuserInfoData_user_pinnedItems_edges?>[];
    final pinnedRepos = pinnedItems
        .map((edge) => edge?.node)
        .whereType<GuserInfoData_user_pinnedItems_edges_node>()
        .where((node) => node.G__typename == 'Repository')
        .map((node) => node as GrepositoryFields)
        .toList();
    final pinnedReposCount = pinnedRepos.length;

    return [
      // Pinned Repos - visible on all tabs
      if (pinnedReposCount > 0)
        ExpandableActionButton(
          icon: Octicons.pin,
          label: 'Pinned Repos',
          trailing: pinnedReposCount > 0
              ? buildModernCountBadge(context, pinnedReposCount)
              : null,
          enabled: pinnedReposCount > 0,
          category: 'Primary',
          visibilityState: ActionButtonVisibilityState.both,
          expandableWidgetBuilder: (onCollapse) => Builder(
            builder: (context) {
              if (pinnedRepos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    'No pinned repositories available',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pinnedRepos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final repo = entry.value;
                    final isLast = index == pinnedRepos.length - 1;

                    final ownerLogin = repo.owner.login;
                    final repoName = repo.name;

                    // Construct repository URL for navigation: owner/repo
                    final navigationUrl = '$ownerLogin/$repoName';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AutoRouter.of(context).push(
                            RepositoryRoute(
                              repositoryURL: navigationUrl,
                            ),
                          );
                          onCollapse();
                        },
                        borderRadius: BorderRadius.only(
                          bottomLeft:
                              isLast ? const Radius.circular(14) : Radius.zero,
                          bottomRight:
                              isLast ? const Radius.circular(14) : Radius.zero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: context.colorScheme.outline
                                          .withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      repoName,
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (repo.description != null &&
                                        repo.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        repo.description!,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: context
                                              .colorScheme.onSurfaceVariant
                                              .withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (repo.stargazerCount > 0) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Octicons.star,
                                      size: 14,
                                      color: context
                                          .colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      repo.stargazerCount.toString(),
                                      style:
                                          context.textTheme.bodySmall?.copyWith(
                                        color: context
                                            .colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      // Time range selector - only visible on Activity tab

      ExpandableActionButton(
        icon: Icons.date_range,
        label: _getDateRangeLabel(),
        subtitle: 'Time Range',
        category: 'Primary',
        visibilityState: currentTab == 'Activity'
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        expandableWidgetBuilder: (onCollapse) {
          return _buildDateRangeExpandedContent(
            context,
            userData,
            onCollapse,
          );
        },
      ),
      // Primary - always visible in collapsed state
      MinorActionButton(
        icon: Octicons.pulse,
        label: 'Activity',
        category: 'Primary',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Activity'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Activity'),
      ),
      MinorActionButton(
        icon: Octicons.repo,
        label: 'Repositories',
        category: 'Primary',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.repositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Repositories'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Repositories'),
      ),
      MinorActionButton(
        icon: Octicons.star,
        label: 'Stars',
        category: 'Primary',
        iconColor:
            const Color(0xFFFFC107).withOpacity(0.65), // Amber/Yellow for stars
        trailing: buildActionButtonTrailingCount(
          context,
          userData.starredRepositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Stars'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Stars'),
      ),
      MinorActionButton(
        icon: Octicons.code_square,
        label: 'Gists',
        category: 'Primary',
        trailing: userData.when(
          user: (user) => buildActionButtonTrailingCount(
            context,
            user.gists.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Gists'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Gists'),
      ),
      // Content - visible in expanded state only
      MinorActionButton(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        category: 'Content',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.pullRequests.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Pull Requests'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Pull Requests'),
      ),
      MinorActionButton(
        icon: Octicons.issue_opened,
        label: 'Issues',
        category: 'Content',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.issues.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Issues'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Issues'),
      ),
      MinorActionButton(
        icon: Octicons.organization,
        label: 'Organizations',
        category: 'Content',
        trailing: userData.when(
          user: (user) => buildActionButtonTrailingCount(
            context,
            user.organizations.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Organizations'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Organizations'),
      ),
      // Social - visible in expanded state only
      MinorActionButton(
        icon: Octicons.people,
        label: 'Followers',
        category: 'Social',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.followers.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Followers'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Followers'),
      ),
      MinorActionButton(
        icon: Octicons.person,
        label: 'Following',
        category: 'Social',
        trailing: userData.when(
          user: (user) => buildActionButtonTrailingCount(
            context,
            user.following.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Following'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Following'),
      ),
      // Other - visible in expanded state only
      MinorActionButton(
        icon: Octicons.package,
        label: 'Packages',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Packages'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Packages'),
      ),
      MinorActionButton(
        icon: Octicons.project,
        label: 'Projects',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Projects'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Projects'),
      ),
      MinorActionButton(
        icon: Octicons.heart,
        label: 'Sponsors',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Sponsors'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Sponsors'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider<UserProvider>(
      create: (_) => UserProvider(widget.login),
      builder: (context, _) => SafeArea(
        child: Scaffold(
          appBar: provider.Provider.of<UserProvider>(context).status !=
                  Status.loaded
              ? AppBar(elevation: 0)
              : null,
          body: ScaffoldBody(
            child: ProviderLoadingProgressWrapper<UserProvider>(
              childBuilder: (context, value) {
                data = value.data;

                return _UserProfileTabsContent(
                  userData: value.data,
                  parentState: this,
                  expandAnimationController: _expandAnimationController,
                  buildCollapsedHeader: _buildCollapsedHeader,
                  buildExpandedHeader: _buildExpandedHeader,
                  buildToolbarActions: _buildToolbarActions,
                  buildActionButtons: _buildActionButtons,
                  selectedYear: _selectedYear,
                  customFromDate: _customFromDate,
                  customToDate: _customToDate,
                  useCustomRange: _useCustomRange,
                  onYearChanged: _onYearChanged,
                  onCustomRangeChanged: _onCustomRangeChanged,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ConsumerWidget wrapper for date range expanded content
/// This allows us to watch the contributions provider for available years
class _DateRangeExpandedContent extends ConsumerWidget {
  const _DateRangeExpandedContent({
    required this.userName,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
    required this.getProviderKey,
    required this.onCollapse,
  });

  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final DateTime? createdAt;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;
  final ContributionQueryKey Function(String) getProviderKey;
  final VoidCallback onCollapse;

  /// Checks if the current custom range matches "Since joining GitHub"
  bool _isSinceJoining(DateTime? customFrom, DateTime? created) {
    if (!useCustomRange || customFrom == null || created == null) {
      return false;
    }
    return customFrom.year == created.year &&
        customFrom.month == created.month &&
        customFrom.day == created.day;
  }

  Future<void> _showCustomDateRangePicker(
    BuildContext context,
    DateTime? earliestDate,
  ) async {
    final now = DateTime.now();
    final initialFrom =
        customFromDate ?? now.subtract(const Duration(days: 365));
    final initialTo = customToDate ?? now;

    // Use createdAt as earliest date, or default to year 2000 if not available
    final earliest = earliestDate ?? DateTime(2000);

    final pickedFrom = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: earliest,
      lastDate: now,
      helpText: 'Select start date',
    );

    if (pickedFrom == null) return;

    final pickedTo = await showDatePicker(
      context: context,
      initialDate: pickedFrom.isAfter(initialTo) ? pickedFrom : initialTo,
      firstDate: pickedFrom,
      lastDate: now,
      helpText: 'Select end date',
    );

    if (pickedTo != null) {
      onCustomRangeChanged(pickedFrom, pickedTo);
      onCollapse();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final providerKey = getProviderKey(userName);
    final contributionsAsync = ref.watch(
      userContributionsProvider(providerKey),
    );

    // Watch the last year provider separately to get available years
    // This ensures years list doesn't disappear when current provider is loading
    final lastYearKey = ContributionQueryKey.lastYear(userName);
    final lastYearAsync = ref.watch(
      userContributionsProvider(lastYearKey),
    );

    // Get available years from the last year provider (which always has all years)
    // Fall back to current provider if last year provider is not available
    final availableYears = lastYearAsync.when(
      data: (viewModel) => viewModel.contributionYears,
      loading: () => contributionsAsync.when(
        data: (viewModel) => viewModel.contributionYears,
        loading: () => <int>[],
        error: (_, __) => <int>[],
      ),
      error: (_, __) => contributionsAsync.when(
        data: (viewModel) => viewModel.contributionYears,
        loading: () => <int>[],
        error: (_, __) => <int>[],
      ),
    );

    // Determine which option is currently selected
    final isLastYearSelected = !useCustomRange && selectedYear == null;
    final isSinceJoiningSelected =
        useCustomRange && _isSinceJoining(customFromDate, createdAt);
    final isCustomSelected = useCustomRange && !isSinceJoiningSelected;

    // Build all options into a list
    final List<Widget> optionTiles = [];

    // Last Year option
    optionTiles.add(
      _buildOptionTile(
        context: context,
        theme: theme,
        colorScheme: colorScheme,
        icon: Icons.calendar_today,
        title: 'Last Year',
        isSelected: isLastYearSelected,
        onTap: () {
          onCustomRangeChanged(null, null);
          onCollapse();
        },
      ),
    );

    // Year options
    if (availableYears.isNotEmpty) {
      for (final year in availableYears) {
        optionTiles.add(
          _buildOptionTile(
            context: context,
            theme: theme,
            colorScheme: colorScheme,
            icon: Icons.calendar_month,
            title: year.toString(),
            isSelected: !useCustomRange && selectedYear == year,
            onTap: () {
              onYearChanged(year);
              onCollapse();
            },
          ),
        );
      }
    }

    // Since joining GitHub option
    if (createdAt != null) {
      optionTiles.add(
        _buildOptionTile(
          context: context,
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.cake,
          title: 'Since joining GitHub',
          isSelected: isSinceJoiningSelected,
          onTap: () {
            final now = DateTime.now();
            onCustomRangeChanged(createdAt, now);
            onCollapse();
          },
        ),
      );
    }

    // Custom Range option
    optionTiles.add(
      _buildOptionTile(
        context: context,
        theme: theme,
        colorScheme: colorScheme,
        icon: Icons.date_range,
        title: 'Custom Range',
        isSelected: isCustomSelected,
        onTap: () {
          _showCustomDateRangePicker(context, createdAt);
        },
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 300),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: optionTiles.asMap().entries.map((entry) {
            final index = entry.key;
            final tile = entry.value;
            final isLast = index == optionTiles.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
              ),
              child: tile,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: colorScheme.primary.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileTabsContent extends StatefulWidget {
  const _UserProfileTabsContent({
    required this.userData,
    required this.parentState,
    required this.expandAnimationController,
    required this.buildCollapsedHeader,
    required this.buildExpandedHeader,
    required this.buildToolbarActions,
    required this.buildActionButtons,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
  });

  final GuserInfoData_user userData;
  final TickerProvider parentState;
  final AnimationController expandAnimationController;
  final Widget Function(BuildContext, GuserInfoData_user) buildCollapsedHeader;
  final Widget Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildExpandedHeader;
  final List<ActionButtonData> Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildToolbarActions;
  final Widget Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildActionButtons;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;

  @override
  State<_UserProfileTabsContent> createState() =>
      _UserProfileTabsContentState();
}

class _UserProfileTabsContentState extends State<_UserProfileTabsContent>
    with TickerProviderStateMixin {
  DynamicTabsController? tabController;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  void _initializeTabs() {
    final userData = widget.userData;

    final tabs = <DynamicTab>[
      DynamicTab(
        identifier: 'Activity',
        isDismissible: false,
        isFocusedOnInit: true,
        tabViewBuilder: (context) => UserAboutScreen(
          userData,
          selectedYear: widget.selectedYear,
          customFromDate: widget.customFromDate,
          customToDate: widget.customToDate,
          useCustomRange: widget.useCustomRange,
          onYearChanged: widget.onYearChanged,
          onCustomRangeChanged: widget.onCustomRangeChanged,
        ),
      ),
      DynamicTab(
        identifier: 'Repositories',
        // isDismissible: false,
        tabViewBuilder: (context) => UserRepositories(
          userData.login,
          currentUser: userData.isViewer,
        ),
      ),
      DynamicTab(
        identifier: 'Gists',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Gists tab
      ),
      DynamicTab(
        identifier: 'Organizations',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Organizations tab
      ),
      DynamicTab(
        identifier: 'Followers',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Followers tab
      ),
      DynamicTab(
        identifier: 'Following',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Following tab
      ),
      DynamicTab(
        identifier: 'Stars',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Stars tab
      ),
      DynamicTab(
        identifier: 'Packages',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Packages tab
      ),
      DynamicTab(
        identifier: 'Pull Requests',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Pull Requests tab
      ),
      DynamicTab(
        identifier: 'Issues',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Issues tab
      ),
      DynamicTab(
        identifier: 'Projects',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Projects tab
      ),
      DynamicTab(
        identifier: 'Sponsors',
        tabViewBuilder: (context) =>
            const SizedBox.shrink(), // TODO: Implement Sponsors tab
      ),
    ];
    tabController = DynamicTabsController(vsync: this, tabs: tabs);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingToolbarWrapper(
      toolbarBuilder: (scrollNotificationNotifier) {
        return ListenableBuilder(
          listenable: tabController ?? ValueNotifier(''),
          builder: (context, _) {
            return FloatingActionToolbar(
              key: const ValueKey('user_profile_toolbar'),
              actions: widget.buildToolbarActions(
                context,
                widget.userData,
                tabController,
              ),
              actionCardBuilder: (context, action) =>
                  buildStandardActionCard(context, action),
              position: FloatingPosition.bottom,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              bottomPadding: 0.0,
              title: widget.userData.name ?? widget.userData.login,
              subtitle:
                  widget.userData.name != null ? widget.userData.login : null,
              scrollNotificationNotifier: scrollNotificationNotifier,
              onExpandChanged: (isExpanded) {
                if (isExpanded) {
                  widget.expandAnimationController.forward();
                } else {
                  widget.expandAnimationController.reverse();
                }
              },
            );
          },
        );
      },
      child: tabController != null
          ? DynamicTabsParent(
              controller: tabController!,
              builder: (context, tabBar, tabView) => DynamicScroll(
                animationController: widget.expandAnimationController,
                collapsedWidget: widget.buildCollapsedHeader(
                  context,
                  widget.userData,
                ),
                expandedWidget: widget.buildExpandedHeader(
                  context,
                  widget.userData,
                  tabController,
                ),
                actions: <Widget>[
                  // Share button can go here
                ],
                bottom: SizeExpandedSection(
                  expand: tabController!.activeLength > 1,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[tabBar],
                      ),
                    ],
                  ),
                ),
                body: tabView,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
