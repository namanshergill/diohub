import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/events.dart';
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
import 'package:diohub/models/users/profile_owner.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/providers/users/user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/organization/organization_about_screen.dart';
import 'package:diohub/view/profile/organization/organization_members.dart';
import 'package:diohub/view/profile/organizations/user_organizations.dart';
import 'package:diohub/view/profile/repositories/user_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart' as provider;
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen(this.login, {super.key});

  final String login;

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  GuserInfoData_repositoryOwner? data;

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
    GuserInfoData_repositoryOwner userData,
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

  Widget _buildCollapsedHeader(
      BuildContext context, GuserInfoData_repositoryOwner userData) {
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
                userData.nameOrLogin,
                style: context.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
              if (userData.displayName != null)
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

  Widget _buildExpandedHeader(BuildContext context, GuserInfoData_repositoryOwner userData,
      DynamicTabsController? tabController) {
    const double leadingWidth = 56.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Profile name
          Padding(
            padding: EdgeInsets.only(left: leadingWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        userData.nameOrLogin,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (userData.isOrganization) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Octicons.organization,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                    if (userData.isVerifiedOrganization) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Octicons.verified,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${userData.login}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        //   const SizedBox(height: 16),
        //   // Detail tiles section
        //   _buildDetailTilesSection(context, userData),
        //   const SizedBox(height: 16),
        //   // Action buttons
        //   _buildActionButtons(context, userData, tabController),
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(
      BuildContext context, GuserInfoData_repositoryOwner userData) {
    return userData.when(
      user: (user) => _buildUserDetailTiles(context, user),
      organization: (organization) =>
          _buildOrganizationDetailTiles(context, organization),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildUserDetailTiles(
      BuildContext context, GuserInfoData_repositoryOwner__asUser userData) {
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
      onExpandChanged: (isExpanded) {},
    );
  }

  Widget _buildOrganizationDetailTiles(
    BuildContext context,
    GuserInfoData_repositoryOwner__asOrganization organization,
  ) {
    final List<Widget> alwaysVisibleTiles = [];

    // About / description
    final String? description = organization.description?.trim();
    if (description != null && description.isNotEmpty) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'About',
          actionType: DetailTileActionType.none,
          child: DetailTileText(description),
        ),
      );
    }

    // Location
    if (organization.location != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Location',
          actionType: DetailTileActionType.none,
          child: DetailTileText(organization.location!),
        ),
      );
    }

    // Created date
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Created',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(organization.createdAt.toString(), shorten: false),
        ),
      ),
    );

    // Members
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Members',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          '${organization.membersWithRole.totalCount} '
          '${organization.membersWithRole.totalCount == 1 ? 'member' : 'members'}',
        ),
      ),
    );

    // Repository visibility breakdown
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Repositories',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          '${organization.publicRepositories.totalCount} public'
          '${organization.privateRepositories.totalCount > 0 ? ' · ${organization.privateRepositories.totalCount} private' : ''}',
        ),
      ),
    );

    final List<Widget> expandableTiles = [];

    // Verified status
    if (organization.isVerified) {
      expandableTiles.add(
        const DetailTile(
          title: 'Verified',
          actionType: DetailTileActionType.none,
          child: DetailTileText('Verified organization'),
        ),
      );
    }

    // Viewer's membership
    if (organization.viewerIsAMember) {
      expandableTiles.add(
        DetailTile(
          title: 'Your role',
          actionType: DetailTileActionType.none,
          child: DetailTileText(
            organization.viewerCanAdminister ? 'Owner / admin' : 'Member',
          ),
        ),
      );
    }

    // Twitter
    if (organization.twitterUsername != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Twitter',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            await launchUrl(
              Uri.parse(
                'https://twitter.com/${organization.twitterUsername}',
              ),
              mode: LaunchMode.externalApplication,
            );
          },
          child: DetailTileText('@${organization.twitterUsername}'),
        ),
      );
    }

    // Website
    if (organization.websiteUrl != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Website',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            await launchUrl(
              organization.websiteUrl!,
              mode: LaunchMode.externalApplication,
            );
          },
          child: DetailTileText(organization.websiteUrl!.toString()),
        ),
      );
    }

    // Public email
    final String? email = organization.email;
    if (email != null && email.isNotEmpty) {
      expandableTiles.add(
        DetailTile(
          title: 'Email',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            await launchUrl(
              Uri(scheme: 'mailto', path: email),
            );
          },
          child: DetailTileText(email),
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
      onExpandChanged: (isExpanded) {},
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    GuserInfoData_repositoryOwner userData,
    DynamicTabsController? tabController,
  ) {
    final List<ActionButtonData> primaryActions = [];
    final List<ActionButtonData> secondaryActions = [];

    userData.when(
      user: (final GuserInfoData_repositoryOwner__asUser user) {
        // Follow/Unfollow button (only for other users)
        if (!user.isViewer && user.viewerCanFollow) {
          primaryActions.add(
            MinorActionButton(
              icon: Octicons.person_add,
              label: user.viewerIsFollowing ? 'Unfollow' : 'Follow',
              trailing: buildActionButtonTrailingCount(
                context,
                user.followers.totalCount,
              ),
              onTap: () async {
                // TODO: Implement follow/unfollow logic
                // Use UserInfoService.changeFollowStatus
              },
            ),
          );
        }

        primaryActions.add(
          MinorActionButton(
            icon: Octicons.repo,
            label: 'Repositories',
            trailing: buildActionButtonTrailingCount(
              context,
              user.repositories.totalCount,
            ),
            actionType: ActionButtonActionType.tab,
            onTap: () => tabController?.openTab('Repositories'),
          ),
        );

        primaryActions.add(
          MinorActionButton(
            icon: Octicons.people,
            label: 'Followers',
            trailing: buildActionButtonTrailingCount(
              context,
              user.followers.totalCount,
            ),
            onTap: () {
              // TODO: Navigate to followers list
            },
          ),
        );

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
      organization: (final GuserInfoData_repositoryOwner__asOrganization org) {
        primaryActions.add(
          MinorActionButton(
            icon: Octicons.repo,
            label: 'Repositories',
            trailing: buildActionButtonTrailingCount(
              context,
              org.repositories.totalCount,
            ),
            actionType: ActionButtonActionType.tab,
            onTap: () => tabController?.openTab('Repositories'),
          ),
        );

        primaryActions.add(
          MinorActionButton(
            icon: Octicons.people,
            label: 'People',
            trailing: buildActionButtonTrailingCount(
              context,
              org.membersWithRole.totalCount,
            ),
            actionType: ActionButtonActionType.tab,
            onTap: () => tabController?.openTab('People'),
          ),
        );

        secondaryActions.add(
          MinorActionButton(
            icon: Icons.open_in_new_rounded,
            label: 'GitHub',
            onTap: () async {
              await launchUrl(
                org.url,
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        );
      },
      orElse: () {},
    );

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
      onExpandChanged: (isExpanded) {},
    );
  }

  List<ActionButtonData> _buildToolbarActions(
    BuildContext context,
    GuserInfoData_repositoryOwner userData,
    DynamicTabsController? tabController,
  ) {
    final bool isOrganization = userData.isOrganization;
    final String currentTab = tabController?.activeIdentifier ??
        (isOrganization ? 'Overview' : 'Activity');

    // Get pinned repositories
    final List<GrepositoryFields> pinnedRepos = userData.pinnedRepositories;
    final int pinnedReposCount = pinnedRepos.length;

    return <ActionButtonData>[
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
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
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

      // Organization overview
      if (isOrganization)
        MinorActionButton(
          icon: Icons.info_outline_rounded,
          label: 'Overview',
          category: 'Primary',
          actionType: ActionButtonActionType.tab,
          visibilityState: currentTab == 'Overview'
              ? ActionButtonVisibilityState.none
              : ActionButtonVisibilityState.both,
          onTap: () => tabController?.openTab('Overview'),
        ),

      // Time range selector - only visible on Activity tab
      if (!isOrganization)
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

      // Activity is only available for users. Organizations have an Overview.
      if (!isOrganization)
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
          userData.repositoryCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Repositories'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Repositories'),
      ),

      // People - organizations only
      if (isOrganization)
        MinorActionButton(
          icon: Octicons.people,
          label: 'People',
          category: 'Primary',
          trailing: buildActionButtonTrailingCount(
            context,
            userData.organizationMemberCount,
          ),
          actionType: ActionButtonActionType.tab,
          visibilityState: currentTab == 'People'
              ? ActionButtonVisibilityState.none
              : ActionButtonVisibilityState.both,
          onTap: () => tabController?.openTab('People'),
        ),

      // The remaining tabs only make sense for user profiles.
      if (!isOrganization) ...[
        MinorActionButton(
          icon: Octicons.star,
          label: 'Stars',
          category: 'Primary',
          iconColor: const Color(0xFFFFC107)
              .withOpacity(0.65), // Amber/Yellow for stars
          trailing: buildActionButtonTrailingCount(
            context,
            userData.starredRepositoryCount,
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
          trailing: userData.isUser
              ? buildActionButtonTrailingCount(context, userData.gistCount)
              : null,
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
            userData.pullRequestCount,
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
            userData.issueCount,
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
          trailing: buildActionButtonTrailingCount(
            context,
            userData.organizationCount,
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
            userData.followersCount,
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
          trailing: buildActionButtonTrailingCount(
            context,
            userData.followingCount,
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
        MinorActionButton(
          icon: Octicons.history,
          label: 'Feed',
          category: 'Primary',
          actionType: ActionButtonActionType.tab,
          visibilityState: currentTab == 'Activity Feed'
              ? ActionButtonVisibilityState.none
              : ActionButtonVisibilityState.both,
          onTap: () => tabController?.openTab('Activity Feed'),
        ),
      ],
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
      data: (result) => result.viewModel.contributionYears,
      loading: () => contributionsAsync.when(
        data: (result) => result.viewModel.contributionYears,
        loading: () => <int>[],
        error: (_, __) => <int>[],
      ),
      error: (_, __) => contributionsAsync.when(
        data: (result) => result.viewModel.contributionYears,
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

    // Year options (sorted in descending order - newest first)
    if (availableYears.isNotEmpty) {
      final sortedYears = List<int>.from(availableYears)
        ..sort((a, b) => b.compareTo(a));
      for (final year in sortedYears) {
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
        borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
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

  final GuserInfoData_repositoryOwner userData;
  final TickerProvider parentState;
  final Widget Function(BuildContext, GuserInfoData_repositoryOwner) buildCollapsedHeader;
  final Widget Function(
    BuildContext,
    GuserInfoData_repositoryOwner,
    DynamicTabsController?,
  ) buildExpandedHeader;
  final List<ActionButtonData> Function(
    BuildContext,
    GuserInfoData_repositoryOwner,
    DynamicTabsController?,
  ) buildToolbarActions;
  final Widget Function(
    BuildContext,
    GuserInfoData_repositoryOwner,
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
    final GuserInfoData_repositoryOwner userData = widget.userData;

    final List<DynamicTab> tabs = userData.isOrganization
        ? <DynamicTab>[
            DynamicTab(
              identifier: 'Overview',
              isDismissible: false,
              isFocusedOnInit: true,
              tabViewBuilder: (final BuildContext context) =>
                  OrganizationAboutScreen(
                userData.asOrganization!,
                pinnedRepositories: userData.pinnedRepositories,
              ),
            ),
            DynamicTab(
              identifier: 'Repositories',
              tabViewBuilder: (final BuildContext context) => UserRepositories(
                userData.login,
                isOrganization: true,
              ),
            ),
            DynamicTab(
              identifier: 'People',
              tab: TabBarItem(label: 'People'),
              tabViewBuilder: (final BuildContext context) =>
                  OrganizationMembers(userData.login),
            ),
          ]
        : <DynamicTab>[
            DynamicTab(
              identifier: 'Activity',
              isDismissible: false,
              isFocusedOnInit: true,
              tabViewBuilder: (final BuildContext context) => UserAboutScreen(
                userData.asUser!,
                selectedYear: widget.selectedYear,
                customFromDate: widget.customFromDate,
                customToDate: widget.customToDate,
                useCustomRange: widget.useCustomRange,
                onYearChanged: widget.onYearChanged,
                onCustomRangeChanged: widget.onCustomRangeChanged,
              ),
            ),
            DynamicTab(
              identifier: 'Activity Feed',
              tab: TabBarItem(label: 'Feed'),
              tabViewBuilder: (final BuildContext context) => Events(
                privateEvents: false,
                specificUser: userData.login,
              ),
            ),
            DynamicTab(
              identifier: 'Repositories',
              // isDismissible: false,
              tabViewBuilder: (final BuildContext context) => UserRepositories(
                userData.login,
                currentUser: userData.isViewer,
              ),
            ),
            DynamicTab(
              identifier: 'Gists',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Gists tab
            ),
            DynamicTab(
              identifier: 'Organizations',
              tabViewBuilder: (final BuildContext context) =>
                  UserOrganizations(userData.login),
            ),
            DynamicTab(
              identifier: 'Followers',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Followers tab
            ),
            DynamicTab(
              identifier: 'Following',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Following tab
            ),
            DynamicTab(
              identifier: 'Stars',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Stars tab
            ),
            DynamicTab(
              identifier: 'Packages',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Packages tab
            ),
            DynamicTab(
              identifier: 'Pull Requests',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Pull Requests tab
            ),
            DynamicTab(
              identifier: 'Issues',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Issues tab
            ),
            DynamicTab(
              identifier: 'Projects',
              tabViewBuilder: (final BuildContext context) =>
                  const SizedBox.shrink(), // TODO: Implement Projects tab
            ),
            DynamicTab(
              identifier: 'Sponsors',
              tabViewBuilder: (final BuildContext context) =>
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
              title: widget.userData.nameOrLogin,
              subtitle: widget.userData.displayName != null
                  ? widget.userData.login
                  : null,
              scrollNotificationNotifier: scrollNotificationNotifier,
              onExpandChanged: (isExpanded) {},
            );
          },
        );
      },
      child: tabController != null
          ? DynamicTabsParent(
              controller: tabController!,
              builder: (context, tabBar, tabView) => DynamicScroll(
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
