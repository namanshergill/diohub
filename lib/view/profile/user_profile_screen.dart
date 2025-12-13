import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/repositories/user_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class UserProfileScreen<T extends UserInfoModel> extends StatefulWidget {
  const UserProfileScreen(this.userData, {this.isCurrentUser, super.key});

  final bool? isCurrentUser;
  final T userData;

  @override
  UserProfileScreenState<T> createState() => UserProfileScreenState<T>();
}

class UserProfileScreenState<T extends UserInfoModel>
    extends State<UserProfileScreen<T>> with TickerProviderStateMixin {
  late UserInfoModel data;
  late DynamicTabsController tabController;
  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    data = widget.userData;
    final tabs = <DynamicTab>[
      DynamicTab(
        identifier: 'About',
        isDismissible: false,
        isFocusedOnInit: true,
        tabViewBuilder: (context) => UserAboutScreen(data),
      ),
      DynamicTab(
        identifier: 'Repositories',
        isDismissible: false,
        tabViewBuilder: (context) => UserRepositories(
          data,
          currentUser: widget.isCurrentUser,
        ),
      ),
      if (data.type == Type.user)
        DynamicTab(
          identifier: 'Activity',
          isDismissible: false,
          tabViewBuilder: (context) => Events(
            specificUser: data.login,
          ),
        ),
    ];
    tabController = DynamicTabsController(vsync: this, tabs: tabs);
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  Widget _buildCollapsedHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        ProfileTile.avatar(
          avatarUrl: data.avatarUrl,
          userLogin: data.login,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            data.name ?? data.login!,
            style: context.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
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
                  data.name ?? data.login!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (data.name != null && data.login != null)
                          Text(
                            data.login!,
                            style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                ),
          const SizedBox(height: 16),
          // Detail tiles section
          _buildDetailTilesSection(context),
          const SizedBox(height: 16),
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(BuildContext context) {
    final List<Widget> alwaysVisibleTiles = [];

    // Bio
    if (data.bio != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Bio',
          actionType: DetailTileActionType.none,
          child: DetailTileText(data.bio!),
        ),
      );
    }

    // Location
    if (data.location != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Location',
          actionType: DetailTileActionType.none,
          child: DetailTileText(data.location!),
        ),
      );
    }

    // Company
    if (data.company != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Company',
          actionType: DetailTileActionType.none,
          child: DetailTileText(data.company!),
        ),
      );
    }

    // Joined date
    if (data.createdAt != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Joined',
          actionType: DetailTileActionType.none,
          child: DetailTileText(
            getDate(data.createdAt.toString(), shorten: false),
          ),
        ),
      );
    }

    final List<Widget> expandableTiles = [];

    // Email
    if (data.email != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Email',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            // Handle email tap
          },
          child: DetailTileText(data.email!),
                                  ),
      );
    }

    // Twitter
    if (data.twitterUsername != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Twitter',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            // Handle Twitter tap
          },
          child: DetailTileText('@${data.twitterUsername}'),
                            ),
      );
    }

    // Blog
    if (data.blog?.isNotEmpty ?? false) {
      expandableTiles.add(
        DetailTile(
          title: 'Blog',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // Handle blog tap
          },
          child: DetailTileText(data.blog!),
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

  Widget _buildActionButtons(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context, listen: false);
    final isCurrentUserProfile = data.login == currentUser.data.login;
    final isUser = data.type == Type.user;

    final List<ActionButtonData> primaryActions = [];

    // Follow/Unfollow button (only for other users)
    if (isUser && !isCurrentUserProfile) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.person_add,
          label: 'Follow',
          trailing: data.followers != null
              ? buildActionButtonTrailingCount(context, data.followers!)
              : null,
          onTap: () async {
            // TODO: Implement follow/unfollow logic
            // Use UserInfoService.changeFollowStatus
          },
        ),
      );
    }

    // Repositories count
    if (data.publicRepos != null) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.repo,
          label: 'Repositories',
          trailing: buildActionButtonTrailingCount(
            context,
            data.publicRepos!,
          ),
          actionType: ActionButtonActionType.tab,
          onTap: () => tabController.openTab('Repositories'),
        ),
      );
    }

    // Followers count (for users)
    if (isUser && data.followers != null) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.people,
          label: 'Followers',
          trailing: buildActionButtonTrailingCount(context, data.followers!),
          onTap: () {
            // TODO: Navigate to followers list
          },
        ),
      );
    }

    // Following count (for users)
    if (isUser && data.following != null) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.person,
          label: 'Following',
          trailing: buildActionButtonTrailingCount(context, data.following!),
          onTap: () {
            // TODO: Navigate to following list
          },
                        ),
      );
    }

    final List<ActionButtonData> secondaryActions = [];

    // More actions can go here
    if (data.publicGists != null) {
      secondaryActions.add(
        MinorActionButton(
          icon: Octicons.code_square,
          label: 'Gists',
          trailing: buildActionButtonTrailingCount(context, data.publicGists!),
          onTap: () {
            // TODO: Navigate to gists
          },
        ),
      );
    }

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

  @override
  Widget build(BuildContext context) {
    return DynamicTabsParent(
      controller: tabController,
      builder: (context, tabBar, tabView) => DynamicScroll(
        contentVersion: 0,
        animationController: _expandAnimationController,
        collapsedWidget: _buildCollapsedHeader(context),
        expandedWidget: _buildExpandedHeader(context),
        actions: data.htmlUrl != null
            ? <Widget>[
                // Share button can go here
              ]
            : null,
        bottom: SizeExpandedSection(
          expand: tabController.activeLength > 1,
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
      );
  }
}
