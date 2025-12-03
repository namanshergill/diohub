import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/compact_expand_button.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
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
import 'dart:developer';

import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:diohub/view/issues_pulls/widgets/about_tab.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:flex_list/flex_list.dart';
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
  bool _showAllActions = false;
  bool _showAllDetailTiles = false;
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
          // Action buttons (primary actions always visible, secondary when expanded)
          _buildActionButtons(context),
          // Action buttons expand button (only show if there are secondary actions)
          Padding(
            padding: EdgeInsets.only(
              top: _showAllActions ? 16 : 8, // More space when expanded, less when collapsed
            ),
            child: SizedBox(
              width: double.infinity,
              child: CompactExpandButton(
                isExpanded: _showAllActions,
                onTap: () {
                  setState(() {
                    _showAllActions = !_showAllActions;
                  });
                  if (_showAllActions) {
                    _expandAnimationController.forward();
                  } else {
                    _expandAnimationController.reverse();
                  }
                },
              ),
            ),
          ),
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
        icon: Octicons.repo,
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
        icon: Octicons.calendar,
        child: DetailTileText(
          getDate(widget.createdAt.toString(), shorten: false),
        ),
      ),
      // Author
      if (widget.createdBy != null)
        DetailTile(
          title: 'Author',
          icon: Octicons.person,
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
      // Additional detail tiles (PR-specific)
      ...widget.additionalDetailTiles,
    ];

    final allTiles = [...alwaysVisibleTiles, ...expandableTiles];
    final visibleTiles = _showAllDetailTiles
        ? allTiles
        : alwaysVisibleTiles;

    return Card(
      color: Color.lerp(
        context.colorScheme.surfaceContainer,
        Colors.black,
        0.1,
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Visible tiles
            ...visibleTiles.asMap().entries.map((entry) {
              final int index = entry.key;
              final Widget tile = entry.value;
              return Column(
                children: [
                  tile,
                  if (index < visibleTiles.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: context.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                ],
              );
            }).toList(),
            // Expand button (only show if there are expandable tiles)
            if (expandableTiles.isNotEmpty) ...[
              if (visibleTiles.isNotEmpty)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: context.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Color.lerp(
                      context.colorScheme.surfaceContainer,
                      Colors.black,
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showAllDetailTiles = !_showAllDetailTiles;
                        });
                        if (_showAllDetailTiles) {
                          _expandAnimationController.forward();
                        } else {
                          _expandAnimationController.reverse();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: _showAllDetailTiles ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 14,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
      icon: Octicons.person_fill,
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
              avatarUrl: assigneeList
                  .limitedAvailableList.first.node.avatarUrl
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
      icon: Octicons.people,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = (constraints.maxWidth / 120).floor().clamp(3, 8);
        final double cardWidth =
            (constraints.maxWidth - (8 * (columns - 1))) / columns;

        // Primary actions - always visible when enabled
        final primaryActions = <_ActionCardData>[
          _ActionCardData(
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
          _ActionCardData(
            icon: Octicons.pencil,
            label: 'Edit',
            enabled: widget.viewerCanReact,
            onTap: () {},
          ),
        ];

        // Secondary actions - only visible when expanded
        final secondaryActions = <_ActionCardData>[
          _ActionCardData(
            icon: Octicons.lock,
            label: 'Lock',
            enabled: widget.viewerCanReact,
            onTap: () {},
          ),
          _ActionCardData(
            icon: Octicons.pin,
            label: widget.isPinned ? 'Unpin' : 'Pin',
            enabled: widget.viewerCanReact,
            onTap: () {},
          ),
        ];

        final enabledPrimaryActions = primaryActions.where((a) => a.enabled).toList();
        final disabledPrimaryActions = primaryActions.where((a) => !a.enabled).toList();
        final enabledSecondaryActions = secondaryActions.where((a) => a.enabled).toList();
        final disabledSecondaryActions = secondaryActions.where((a) => !a.enabled).toList();

        // Always show primary actions, conditionally show secondary actions
        final visibleActions = <_ActionCardData>[
          ...enabledPrimaryActions,
          ...disabledPrimaryActions,
          if (_showAllActions) ...enabledSecondaryActions,
          if (_showAllActions) ...disabledSecondaryActions,
        ];

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: visibleActions.isNotEmpty
              ? FlexList(
                  horizontalSpacing: 8,
                  verticalSpacing: 8,
                  children: visibleActions.map((action) => SizedBox(
                        width: cardWidth,
                        child: _buildActionCard(
                          context: context,
                          icon: action.icon,
                          label: action.label,
                          enabled: action.enabled,
                          isDestructive: action.isDestructive,
                          isPositive: action.isPositive,
                          onTap: action.onTap,
                        ),
                      )).toList(),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
    bool isDestructive = false,
    bool isPositive = false,
  }) {
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (!enabled) {
      backgroundColor =
          context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
      iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
      textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (isDestructive) {
      backgroundColor = context.colorScheme.errorContainer;
      iconColor = context.colorScheme.error;
      textColor = context.colorScheme.onErrorContainer;
    } else if (isPositive) {
      backgroundColor = Colors.green.withOpacity(0.12);
      iconColor = Colors.green.shade700;
      textColor = Colors.green.shade900;
    } else {
      backgroundColor = context.colorScheme.surfaceContainerHighest;
      iconColor = context.colorScheme.primary;
      textColor = context.colorScheme.onSurface;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: AbsorbPointer(
        absorbing: !enabled,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationButton(BuildContext context) {
    return Material(
      color: context.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: () {
          try {
            dynamicTabsController.openTab('Conversation');
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
                  color:
                      context.colorScheme.onPrimaryContainer.withOpacity(0.1),
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
                contentVersion: _showAllActions ? 1 : 0,
                animationController: _expandAnimationController,
                collapsedWidget: _buildCollapsedHeader(context),
                expandedWidget: _buildExpandedHeader(context),
                pinnedWidget: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildConversationButton(context),
                ),
                bottom: SizeExpandedSection(
                  expand: dynamicTabsController.activeLength > 1,
                  child: buildTabsView(tabBar),
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
              initComment: BaseComment(
                onQuote: () {},
                resourceUri: Uri.parse('uri'),
                isMinimized: false,
                reactions: widget.reactionGroups,
                viewerCanDelete: false,
                viewerCanMinimize: false,
                viewerCannotUpdateReasons: null,
                viewerCanReact: widget.viewerCanReact,
                viewerCanUpdate: false,
                viewerDidAuthor: false,
                createdAt: widget.createdAt,
                author: widget.createdBy,
                body: widget.body,
                lastEditedAt: null,
                bodyHTML: widget.bodyHTML,
                authorAssociation: GCommentAuthorAssociation.NONE,
              ),
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

class _ActionCardData {
  const _ActionCardData({
    required this.icon,
    required this.label,
    required this.enabled,
    this.isDestructive = false,
    this.isPositive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool isDestructive;
  final bool isPositive;
  final VoidCallback? onTap;
}

