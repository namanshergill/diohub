import 'package:auto_route/annotations.dart';
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
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/user_provider.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/repositories/user_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

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

    return [
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
        iconColor: const Color(0xFFFFC107), // Amber/Yellow for stars
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
    return ChangeNotifierProvider<UserProvider>(
      create: (_) => UserProvider(widget.login),
      builder: (context, _) => SafeArea(
        child: Scaffold(
          appBar: Provider.of<UserProvider>(context).status != Status.loaded
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
                );
              },
            ),
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
        tabViewBuilder: (context) => UserAboutScreen(userData),
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
