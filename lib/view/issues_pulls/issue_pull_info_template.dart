import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/misc/theme_from_image.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/editing_wrapper.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/providers/issue_pulls/issue_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'dart:developer';

import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:diohub/view/issues_pulls/widgets/about_tab.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class IssuePullInfoTemplate extends StatefulWidget {
  const IssuePullInfoTemplate({
    required this.number,
    required this.title,
    required this.repoInfo,
    required this.state,
    required this.bodyHTML,
    required this.labels,
    required this.createdAt,
    required this.createdBy,
    required this.body,
    required this.commentCount,
    required this.reactionGroups,
    required this.viewerCanReact,
    required this.assigneesInfo,
    required this.participantsInfo,
    required this.isPinned,
    required this.uri,
    super.key,
    this.dynamicTabs = const <DynamicTab>[],
    required this.onRefresh,
    this.additionalAboutWidgets = const <Widget>[],
    this.additionalDetailTiles = const <Widget>[],
    this.linkedIssues,
    this.linkedIssuesTrackedIn,
    this.linkedPullRequests,
  });

  final GassigneeInfo assigneesInfo;
  final String body;
  final String bodyHTML;
  final int commentCount;
  final DateTime createdAt;
  final Gactor? createdBy;
  final List<DynamicTab> dynamicTabs;
  final List<Glabel?> labels;
  final List<Widget> additionalAboutWidgets;
  final List<Widget> additionalDetailTiles;
  final int number;
  final List<GreactionGroups> reactionGroups;
  final GrepoInfo repoInfo;
  final IssuePullState state;
  final String title;
  final Uri uri;
  final bool viewerCanReact;
  final UnfinishedList<Gactor> participantsInfo;
  final bool isPinned;
  final Future<void> Function() onRefresh;
  final GissueInfo_trackedIssues? linkedIssues;
  final GissueInfo_trackedInIssues? linkedIssuesTrackedIn;
  final GpullInfo_closingIssuesReferences? linkedPullRequests;

  @override
  State<IssuePullInfoTemplate> createState() => IssuePullInfoTemplateState();
}

class IssuePullInfoTemplateState extends State<IssuePullInfoTemplate>
    with TickerProviderStateMixin {
  late EditingController<Object> assigneeEditingController;
  late EditingController<String> descEditingController;
  late final DynamicTabsController dynamicTabsController =
      DynamicTabsController(
    vsync: this,
    tabs: _buildTabs(),
  );
  late EditingController<List<Glabel?>> labelsEditingController;

  late EditingController<String> titleEditingController;
  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void initState() {
    titleEditingController = EditingController<String>(widget.title);
    labelsEditingController = EditingController<List<Glabel?>>(
      widget.labels,
      onEditTap: (final BuildContext context) => null,
    );
    descEditingController = EditingController<String>(
      widget.body,
      onEditTap: (final BuildContext context) => null,
    );
    assigneeEditingController = EditingController<Object>(
      widget.assigneesInfo,
      onEditTap: (final BuildContext context) => null,
    );
    super.initState();
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ThemeFromImage(
        builder: (
          final BuildContext context,
        ) {
          return SafeArea(
            child: buildDynamicTabsParent(),
          );
        },
      );

  // Collapsible App Bar Methods

  Widget _buildCollapsedHeader(BuildContext context) {
    return Row(
      children: [
        widget.state.icon(size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '#${widget.number} • ${widget.repoInfo.name}',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // State badge, number, and date at the top
          _buildTopMetadataRow(context),
          const SizedBox(height: 16),
          // Detail tiles
          _buildDetailTilesSection(context),
          const SizedBox(height: 16),
          // Action buttons (includes expand button)
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTopMetadataRow(BuildContext context) {
    // Account for app bar leading button (back button) - typically 56dp
    final double leadingWidth = 56.0;
    return Padding(
      padding: EdgeInsets.only(left: leadingWidth),
      child: Row(
        children: [
          // State badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.state.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.state.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.state.icon(size: 12),
                const SizedBox(width: 4),
                Text(
                  widget.state.text,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: widget.state.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Issue number
          Text(
            '#${widget.number}',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.isPinned) ...[
            const SizedBox(width: 8),
            Icon(
              Octicons.pin,
              size: 14,
              color: context.colorScheme.tertiary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(BuildContext context) {
    // Always visible tiles (essential information)
    final List<Widget> alwaysVisibleTiles = [
      // Repository
      DetailTile(
        title: 'Repository',
        actionType: DetailTileActionType.navigation,
        onTap: () async {
          await context.router.push(
            RepositoryRoute(
              repositoryURL:
                  '${widget.repoInfo.owner.login}/${widget.repoInfo.name}',
            ),
          );
        },
        child: DetailTileRepository(
          ownerAvatarUrl: widget.repoInfo.owner.avatarUrl.toString(),
          ownerLogin: widget.repoInfo.owner.login,
          repoName: widget.repoInfo.name,
        ),
      ),
      // Created date
      DetailTile(
        title: 'Created',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(widget.createdAt.toString(), shorten: false),
        ),
      ),
      // Author
      if (widget.createdBy != null)
        DetailTile(
          title: 'Author',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            navigateToProfile(
              login: widget.createdBy!.login,
              context: context,
            );
          },
          child: DetailTileUser(
            avatarUrl: widget.createdBy!.avatarUrl.toString(),
            login: widget.createdBy!.login,
          ),
        ),
      // Assignees
      if (widget.assigneesInfo.edges?.isNotEmpty ?? false)
        _buildAssigneeDetailTile(context),
    ];

    // Expandable tiles (less relevant information)
    final List<Widget> expandableTiles = [
      // Participants
      if (widget.participantsInfo.totalCount > 1)
        _buildParticipantsDetailTile(context),
      // Linked issues
      ..._buildLinkedIssuesDetailTiles(context),
      // Linked PRs
      ..._buildLinkedPullRequestsDetailTiles(context),
      // Additional detail tiles (PR-specific)
      ...widget.additionalDetailTiles,
    ];

    return CollapsibleDetailTiles(
      alwaysVisibleTiles: alwaysVisibleTiles,
      expandableTiles: expandableTiles,
      visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
        defaultVisibleCount:
            2, // Show 2 tiles by default (Assignee, Participants)
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

  Widget _buildAssigneeDetailTile(BuildContext context) {
    final List<GassigneeInfo_edges?> assignees =
        widget.assigneesInfo.edges?.toList() ?? <GassigneeInfo_edges?>[];
    final assigneeList = UnfinishedList<NodeWithPaginationInfo<Gactor>>(
      limitedAvailableList: assignees
          .map((e) => NodeWithPaginationInfo<Gactor>.fromEdge(e!))
          .toList(),
    );

    return DetailTile(
      title: assigneeList.totalCount == 1 ? 'Assignee' : 'Assignees',
      actionType: assigneeList.totalCount > 1
          ? DetailTileActionType.bottomSheet
          : assigneeList.totalCount == 1
              ? DetailTileActionType.navigation
              : DetailTileActionType.none,
      onTap: assigneeList.totalCount > 1
          ? () async {
              await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
                paginatedListItemBuilder: _paginatedListItemBuilder,
                paginationFuture: (data) async =>
                    (await context.issueProvider(listen: false).getAssignees(
                              after: data.lastItem?.cursor,
                            ))
                        .map<NodeWithPaginationInfo<Gactor>>(
                          (e) => NodeWithPaginationInfo<Gactor>.fromEdge(e!),
                        )
                        .toList(),
                title: 'Assignees',
              ).openSheet(context);
            }
          : assigneeList.totalCount == 1
              ? () {
                  navigateToProfile(
                    login: assigneeList.limitedAvailableList.first.node.login,
                    context: context,
                  );
                }
              : null,
      child: assigneeList.totalCount == 1
          ? DetailTileUser(
              avatarUrl: assigneeList.limitedAvailableList.first.node.avatarUrl
                  .toString(),
              login: assigneeList.limitedAvailableList.first.node.login,
            )
          : DetailTileUserStack(
              avatars: assigneeList.limitedAvailableList
                  .map((e) => e.node.avatarUrl.toString())
                  .toList(),
              totalCount: assigneeList.totalCount,
            ),
    );
  }

  Widget _buildParticipantsDetailTile(BuildContext context) {
    return DetailTile(
      title: 'Participants',
      actionType: DetailTileActionType.bottomSheet,
      onTap: () async {
        await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
          paginatedListItemBuilder: _paginatedListItemBuilder,
          paginationFuture: (data) async =>
              context.issueProvider(listen: false).getParticipants(
                    after: data.lastItem?.cursor,
                  ),
          title: 'Participants',
        ).openSheet(context);
      },
      child: DetailTileUserStack(
        avatars: widget.participantsInfo.limitedAvailableList
            .map((e) => e.avatarUrl.toString())
            .toList(),
        totalCount: widget.participantsInfo.totalCount,
      ),
    );
  }

  List<Widget> _buildLinkedIssuesDetailTiles(BuildContext context) {
    final List<Widget> tiles = [];

    // Tracked issues (issues that track this issue)
    if ((widget.linkedIssues?.totalCount ?? 0) > 0) {
      final nodes = widget.linkedIssues!.nodes
              ?.whereType<GissueInfo_trackedIssues_nodes>()
              .toList() ??
          [];

      if (nodes.length == 1) {
        final node = nodes.first;
        tiles.add(
          DetailTile(
            title: 'Linked issue',
            actionType: DetailTileActionType.navigation,
            onTap: () async {
              await context.router.push(
                issuePullScreenRoute(PathData.fromURL(node.url.toString())),
              );
            },
            child: DetailTileLinkedIssue(
              title: node.title,
              number: node.number,
              repositoryName: node.repository.name,
              repositoryOwner: node.repository.owner.login,
            ),
          ),
        );
      } else if (nodes.isNotEmpty) {
        tiles.add(
          DetailTile(
            title: 'Linked issues',
            actionType: DetailTileActionType.bottomSheet,
            onTap: () async {
              await BottomSheetPagination<GissueInfo_trackedIssues_nodes>(
                paginatedListItemBuilder: (context, data) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: context.colorScheme.surface,
                    child: InkWell(
                      onTap: () async {
                        await context.router.push(
                          issuePullScreenRoute(
                              PathData.fromURL(data.item.url.toString())),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DetailTileLinkedIssue(
                          title: data.item.title,
                          number: data.item.number,
                          repositoryName: data.item.repository.name,
                          repositoryOwner: data.item.repository.owner.login,
                        ),
                      ),
                    ),
                  ),
                ),
                paginationFuture: (data) async => nodes,
                title: 'Linked issues',
              ).openSheet(context);
            },
            child: DetailTileLinkedIssuesStack(
              totalCount: nodes.length,
            ),
          ),
        );
      }
    }

    // Tracked in issues (issues this issue tracks)
    if ((widget.linkedIssuesTrackedIn?.totalCount ?? 0) > 0) {
      final nodes = widget.linkedIssuesTrackedIn!.nodes
              ?.whereType<GissueInfo_trackedInIssues_nodes>()
              .toList() ??
          [];

      if (nodes.length == 1) {
        final node = nodes.first;
        tiles.add(
          DetailTile(
            title: 'Tracked in',
            actionType: DetailTileActionType.navigation,
            onTap: () async {
              await context.router.push(
                issuePullScreenRoute(PathData.fromURL(node.url.toString())),
              );
            },
            child: DetailTileLinkedIssue(
              title: node.title,
              number: node.number,
              repositoryName: node.repository.name,
              repositoryOwner: node.repository.owner.login,
            ),
          ),
        );
      } else if (nodes.isNotEmpty) {
        tiles.add(
          DetailTile(
            title: 'Tracked in',
            actionType: DetailTileActionType.bottomSheet,
            onTap: () async {
              await BottomSheetPagination<GissueInfo_trackedInIssues_nodes>(
                paginatedListItemBuilder: (context, data) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: context.colorScheme.surface,
                    child: InkWell(
                      onTap: () async {
                        await context.router.push(
                          issuePullScreenRoute(
                              PathData.fromURL(data.item.url.toString())),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DetailTileLinkedIssue(
                          title: data.item.title,
                          number: data.item.number,
                          repositoryName: data.item.repository.name,
                          repositoryOwner: data.item.repository.owner.login,
                        ),
                      ),
                    ),
                  ),
                ),
                paginationFuture: (data) async => nodes,
                title: 'Tracked in',
              ).openSheet(context);
            },
            child: DetailTileLinkedIssuesStack(
              totalCount: nodes.length,
            ),
          ),
        );
      }
    }

    return tiles;
  }

  List<Widget> _buildLinkedPullRequestsDetailTiles(BuildContext context) {
    if ((widget.linkedPullRequests?.totalCount ?? 0) == 0) {
      return [];
    }

    final nodes = widget.linkedPullRequests!.nodes
            ?.whereType<GpullInfo_closingIssuesReferences_nodes>()
            .toList() ??
        [];
    if (nodes.isEmpty) {
      return [];
    }

    if (nodes.length == 1) {
      final node = nodes.first;
      return [
        DetailTile(
          title: 'Closes',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            await context.router.push(
              issuePullScreenRoute(PathData.fromURL(node.url.toString())),
            );
          },
          child: DetailTileLinkedIssue(
            title: node.title,
            number: node.number,
            repositoryName: node.repository.name,
            repositoryOwner: node.repository.owner.login,
          ),
        ),
      ];
    } else {
      return [
        DetailTile(
          title: 'Closes',
          actionType: DetailTileActionType.bottomSheet,
          onTap: () async {
            await BottomSheetPagination<
                GpullInfo_closingIssuesReferences_nodes>(
              paginatedListItemBuilder: (context, data) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: context.colorScheme.surface,
                  child: InkWell(
                    onTap: () async {
                      await context.router.push(
                        issuePullScreenRoute(
                            PathData.fromURL(data.item.url.toString())),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DetailTileLinkedIssue(
                        title: data.item.title,
                        number: data.item.number,
                        repositoryName: data.item.repository.name,
                        repositoryOwner: data.item.repository.owner.login,
                      ),
                    ),
                  ),
                ),
              ),
              paginationFuture: (data) async => nodes,
              title: 'Closes',
            ).openSheet(context);
          },
          child: DetailTileLinkedIssuesStack(
            totalCount: nodes.length,
          ),
        ),
      ];
    }
  }

  ScrollWrapperBuilder<NodeWithPaginationInfo<Gactor>>
      get _paginatedListItemBuilder => (
            final BuildContext context,
            final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
          ) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: context.colorScheme.surface,
                  child: ProfileTile.login(
                    avatarUrl: data.item.node.avatarUrl.toString(),
                    userLogin: data.item.node.login,
                    wrapperBuilder: (final Widget child) => Row(
                      children: _buildListItemChildren(data, context, child),
                    ),
                  ),
                ),
              );

  List<Widget> _buildListItemChildren(
    final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
    final BuildContext context,
    final Widget child,
  ) =>
      <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            '${data.index + 1}',
            style: context.textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ];

  Widget _buildActionButtons(BuildContext context) {
    // Primary actions - always visible when enabled
    final primaryActions = <ActionButtonData>[
      MinorActionButton(
        icon: (widget.state.state == GIssueState.OPEN ||
                widget.state.state == GPullRequestState.OPEN)
            ? Octicons.issue_closed
            : Octicons.issue_reopened,
        label: (widget.state.state == GIssueState.OPEN ||
                widget.state.state == GPullRequestState.OPEN)
            ? 'Close'
            : 'Reopen',
        enabled: widget.viewerCanReact,
        isDestructive: (widget.state.state == GIssueState.OPEN ||
            widget.state.state == GPullRequestState.OPEN),
        isPositive: (widget.state.state != GIssueState.OPEN &&
            widget.state.state != GPullRequestState.OPEN),
        onTap: () {},
      ),
      MinorActionButton(
        icon: Octicons.pencil,
        label: 'Edit',
        enabled: widget.viewerCanReact,
        onTap: () {},
      ),
    ];

    // Secondary actions - only visible when expanded
    final secondaryActions = <ActionButtonData>[
      MinorActionButton(
        icon: Octicons.lock,
        label: 'Lock',
        enabled: widget.viewerCanReact,
        onTap: () {},
      ),
      MinorActionButton(
        icon: Octicons.pin,
        label: widget.isPinned ? 'Unpin' : 'Pin',
        enabled: widget.viewerCanReact,
        onTap: () {},
      ),
    ];

    return CollapsibleActionButtons(
      primaryActions: primaryActions,
      secondaryActions: secondaryActions,
      actionCardBuilder: (context, action) =>
          buildCompactActionCard(context, action),
      visibilityConfig: ActionButtonsVisibilityConfig.fixedCount(
        defaultVisibleCount:
            2, // Show 2 actions by default (Close/Reopen, Edit)
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

  Widget _buildConversationButton(BuildContext context) {
    // Use a StatefulWidget that listens to tab changes including swipes
    return _ConversationButtonWidget(
      dynamicTabsController: dynamicTabsController,
      commentCount: widget.commentCount,
    );
  }

  Widget buildDynamicTabsParent() => DynamicTabsParent(
        controller: dynamicTabsController,
        builder: (
          final BuildContext context,
          final PreferredSizeWidget tabBar,
          final Widget tabView,
        ) =>
            EditingWrapper(
          onSave: () {},
          editingControllers: <EditingController<dynamic>>[
            titleEditingController,
            labelsEditingController,
            descEditingController,
            assigneeEditingController,
          ],
          builder: (final BuildContext context) => Scaffold(
            body: RefreshIndicator(
              onRefresh: widget.onRefresh,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              child: DynamicScroll(
                animationController: _expandAnimationController,
                collapsedWidget: _buildCollapsedHeader(context),
                expandedWidget: _buildExpandedHeader(context),
                pinnedWidget: _buildConversationButton(context),
                bottom: AnimatedTabBar(
                  showTabBar: dynamicTabsController.activeLength > 1,
                  tabBar: buildTabsView(tabBar),
                  defaultPadding: const EdgeInsets.only(bottom: 8),
                  topSpacing: 0,
                ),
                body: tabView,
              ),
            ),
          ),
        ),
      );

  List<DynamicTab> _buildTabs() => List<DynamicTab>.from(widget.dynamicTabs)
    ..addAll(
      <DynamicTab>[
        _buildAboutTab(),
        DynamicTab(
          identifier: 'Conversation',
          keepViewAlive: true,
          tabViewBuilder: (final BuildContext context) =>
              ChangeNotifierProvider<CommentProvider>(
            create: (final _) => CommentProvider(),
            builder: (final BuildContext context, final Widget? child) =>
                IssuePullTimeline(
              number: widget.number,
              isLocked: false,
              createdAt: widget.createdAt,
              owner: widget.repoInfo.owner.login,
              repoName: widget.repoInfo.name,
              issueUrl: widget.uri,
              isPull: false,
            ),
          ),
        ),
      ],
    );

  DynamicTab _buildAboutTab() => DynamicTab(
        identifier: 'About',
        isDismissible: false,
        tabViewBuilder: (final BuildContext context) => AboutTab(
          bodyHTML: widget.bodyHTML,
          body: widget.body,
          reactionGroups: widget.reactionGroups,
          viewerCanReact: widget.viewerCanReact,
          title: widget.title,
          titleEditingController: titleEditingController,
          labels: widget.labels,
          labelsEditingController: labelsEditingController,
        ),
      );

  Column buildTabsView(final PreferredSizeWidget tabBar) => Column(
        children: <Widget>[
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              tabBar,
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      );
}

/// Widget that listens to tab changes including swipe gestures
class _ConversationButtonWidget extends StatefulWidget {
  const _ConversationButtonWidget({
    required this.dynamicTabsController,
    required this.commentCount,
  });

  final DynamicTabsController dynamicTabsController;
  final int commentCount;

  @override
  State<_ConversationButtonWidget> createState() =>
      _ConversationButtonWidgetState();
}

class _ConversationButtonWidgetState extends State<_ConversationButtonWidget> {
  String? _lastActiveIdentifier;

  @override
  void initState() {
    super.initState();
    _lastActiveIdentifier = widget.dynamicTabsController.activeIdentifier;
    widget.dynamicTabsController.addListener(_onControllerChanged);
    // Schedule periodic checks to catch tab swipes
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(_ConversationButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dynamicTabsController != widget.dynamicTabsController) {
      oldWidget.dynamicTabsController.removeListener(_onControllerChanged);
      widget.dynamicTabsController.addListener(_onControllerChanged);
      _lastActiveIdentifier = widget.dynamicTabsController.activeIdentifier;
    }
  }

  @override
  void dispose() {
    widget.dynamicTabsController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final current = widget.dynamicTabsController.activeIdentifier;
    if (_lastActiveIdentifier != current && mounted) {
      setState(() {
        _lastActiveIdentifier = current;
      });
    }
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = widget.dynamicTabsController.activeIdentifier;
      if (_lastActiveIdentifier != current) {
        setState(() {
          _lastActiveIdentifier = current;
        });
      }
      // Schedule next check
      _scheduleCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isConversationActive =
        widget.dynamicTabsController.activeIdentifier == 'Conversation';

    return SizeExpandedSection(
      expand: !isConversationActive,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: HighlightedContainer(
          highlightColor: context.colorScheme.primary,
          borderRadius: 12,
          child: Material(
            color: context.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                try {
                  widget.dynamicTabsController.openTab('Conversation');
                } catch (e, s) {
                  log(e.toString(), stackTrace: s);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onPrimaryContainer
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Octicons.comment_discussion,
                        size: 16,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thread',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.commentCount} ${widget.commentCount == 1 ? 'reply' : 'replies'}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colorScheme.onPrimaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
