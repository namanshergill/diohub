import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/file_tree_view.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commit_info.data.gql.dart';
import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/commits/commit_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/commits/widgets/changed_files.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class CommitInfoScreen extends StatefulWidget {
  const CommitInfoScreen({required this.commitURL, super.key});
  final String commitURL;

  @override
  CommitInfoScreenState createState() => CommitInfoScreenState();
}

class CommitInfoScreenState extends State<CommitInfoScreen>
    with TickerProviderStateMixin {
  late DynamicTabsController dynamicTabsController;

  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void dispose() {
    dynamicTabsController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      ChangeNotifierProvider<CommitProvider>(
        create: (final _) => CommitProvider(widget.commitURL),
        builder: (final BuildContext context, final Widget? value) {
          final provider = Provider.of<CommitProvider>(context);

          // Initialize controller with provider once provider is available
          dynamicTabsController = DynamicTabsController(
            tabs: _buildTabs(provider),
            vsync: this,
          );

          return SafeArea(
            child: Scaffold(
              body: provider.status != Status.loaded
                  ? ProviderLoadingProgressWrapper<CommitProvider>(
                      childBuilder: (context, value) => const SizedBox.shrink(),
                    )
                  : _buildDynamicTabsParent(context, provider),
            ),
          );
        },
      );

  Widget _buildDynamicTabsParent(
      BuildContext context, CommitProvider provider) {
    final commit = provider.data;

    return DynamicTabsParent(
      controller: dynamicTabsController,
      builder: (
        final BuildContext context,
        final PreferredSizeWidget tabBar,
        final Widget tabView,
      ) =>
          Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await provider.loadData();
          },
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          child: DynamicScroll(
            animationController: _expandAnimationController,
            collapsedWidget: _buildCollapsedHeader(commit),
            expandedWidget: _buildExpandedHeader(commit, provider),
            bottom: SizeExpandedSection(
              expand: dynamicTabsController.activeLength > 1,
              child: _buildTabsView(tabBar),
            ),
            body: tabView,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(
      GcommitInfoData_repository_object__asCommit commit) {
    final repoName = commit.repository.nameWithOwner;
    return Row(
      children: [
        const Icon(
          Octicons.git_commit,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${commit.abbreviatedOid} • $repoName',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(
    GcommitInfoData_repository_object__asCommit commit,
    CommitProvider provider,
  ) {
    const double leadingWidth = 56.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // SHA and verification badge
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: leadingWidth),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Octicons.git_commit,
                            size: 12,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            commit.abbreviatedOid,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (commit.signature?.isValid == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Octicons.verified,
                              size: 12,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Detail Tiles
          _buildDetailTilesSection(commit, provider),
          const SizedBox(height: 16),
          // Action Buttons
          _buildActionButtons(commit),
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(
    GcommitInfoData_repository_object__asCommit commit,
    CommitProvider provider,
  ) {
    final List<Widget> alwaysVisibleTiles = [
      if (commit.author != null)
        DetailTile(
          title: 'Author',
          actionType: commit.author?.user != null
              ? DetailTileActionType.navigation
              : DetailTileActionType.none,
          onTap: commit.author?.user != null
              ? () => AutoRouter.of(context).push(
                    UserProfileRoute(login: commit.author!.user!.login),
                  )
              : null,
          child: DetailTileUser(
            avatarUrl: commit.author!.avatarUrl.toString(),
            login:
                commit.author?.user?.login ?? commit.author?.name ?? 'Unknown',
          ),
        ),
      // Show committer if different from author
      if (commit.committer != null && !commit.authoredByCommitter)
        DetailTile(
          title: 'Committer',
          actionType: commit.committer?.user != null
              ? DetailTileActionType.navigation
              : DetailTileActionType.none,
          onTap: commit.committer?.user != null
              ? () => AutoRouter.of(context).push(
                    UserProfileRoute(login: commit.committer!.user!.login),
                  )
              : null,
          child: DetailTileUser(
            avatarUrl: commit.committer!.avatarUrl.toString(),
            login: commit.committer?.user?.login ??
                commit.committer?.name ??
                'Unknown',
          ),
        ),
      // Show authored date if different from committed date
      if (commit.author?.date != null &&
          commit.author!.date != commit.committedDate)
        DetailTile(
          title: 'Authored',
          actionType: DetailTileActionType.none,
          child: DetailTileText(
            getDate(
              commit.author!.date!.toString(),
              shorten: false,
            ),
          ),
        ),
      DetailTile(
        title: 'Committed',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(
            commit.committedDate.toString(),
            shorten: false,
          ),
        ),
      ),
      // Show signature details if available
      if (commit.signature != null && commit.signature!.isValid)
        DetailTile(
          title: 'Signature',
          actionType: DetailTileActionType.none,
          child: DetailTileContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Octicons.verified,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      commit.signature!.wasSignedByGitHub
                          ? 'Signed by GitHub'
                          : 'Verified',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (commit.signature!.signer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${commit.signature!.signer!.name ?? ''}${commit.signature!.signer!.email.isNotEmpty ? ' <${commit.signature!.signer!.email}>' : ''}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      // Tree reference
      DetailTile(
        title: 'Tree',
        actionType: DetailTileActionType.navigation,
        onTap: () => AutoRouter.of(context).push(
          RepositoryRoute(
            repositoryURL: commit.repository.url.toString(),
            initSHA: commit.tree.oid,
            index: 2,
          ),
        ),
        child: DetailTileContent(
          child: Row(
            children: [
              Icon(
                Octicons.file_directory,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                commit.tree.abbreviatedOid,
                style: context.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      DetailTile(
        title: 'Changes',
        actionType: DetailTileActionType.none,
        child: DetailTileContent(
          child: Row(
            children: [
              Text(
                '+${commit.additions}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-${commit.deletions}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                  '${provider.files?.length ?? commit.changedFilesIfAvailable ?? 0} files'),
            ],
          ),
        ),
      ),
      DetailTile(
        title: 'Repository',
        actionType: DetailTileActionType.navigation,
        onTap: () => AutoRouter.of(context).push(
          RepositoryRoute(
            repositoryURL: commit.repository.url.toString(),
          ),
        ),
        child: DetailTileText(commit.repository.nameWithOwner),
      ),
    ];

    final List<Widget> expandableTiles = [
      if (commit.parents.edges != null && commit.parents.edges!.isNotEmpty)
        DetailTile(
          title: 'Parents',
          actionType: DetailTileActionType.none,
          child: DetailTileContent(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  commit.parents.edges!.where((edge) => edge?.node != null).map(
                (edge) {
                  final parent = edge!.node!;
                  return InkWell(
                    onTap: () => AutoRouter.of(context).push(
                      CommitInfoRoute(commitURL: parent.commitUrl.toString()),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colorScheme.outlineVariant
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Octicons.git_commit,
                            size: 12,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            parent.abbreviatedOid,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
    ];

    return CollapsibleDetailTiles(
      alwaysVisibleTiles: alwaysVisibleTiles,
      expandableTiles: expandableTiles,
      visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
        defaultVisibleCount: 2, // Show 2 tiles by default
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

  Widget _buildActionButtons(
      GcommitInfoData_repository_object__asCommit commit) {
    final primaryActions = <ActionButtonData>[
      MinorActionButton(
        icon: Octicons.code,
        label: 'Browse Files',
        onTap: () => AutoRouter.of(context).push(
          RepositoryRoute(
            repositoryURL: commit.repository.url.toString(),
            initSHA: commit.oid,
            index: 2,
          ),
        ),
      ),
      MinorActionButton(
        icon: Octicons.link_external,
        label: 'View on GitHub',
        onTap: () async {
          final url = commit.commitUrl;
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
      ),
    ];

    final secondaryActions = <ActionButtonData>[
      if (commit.comments.totalCount > 0)
        MinorActionButton(
          icon: Octicons.comment,
          label: 'Comments',
          trailing: buildActionButtonTrailingCount(
            context,
            commit.comments.totalCount,
          ),
          onTap: () {
            // Navigate to comments
          },
        ),
    ];

    return CollapsibleActionButtons(
      primaryActions: primaryActions,
      secondaryActions: secondaryActions,
      actionCardBuilder: (context, action) =>
          buildAppBarActionCard(context, action),
      visibilityConfig: ActionButtonsVisibilityConfig.fixedCount(
        defaultVisibleCount:
            2, // Show 2 actions by default (Browse Files, View on GitHub)
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

  List<DynamicTab> _buildTabs(CommitProvider provider) => [
        DynamicTab(
          identifier: 'About',
          isDismissible: false,
          isFocusedOnInit: true,
          tabViewBuilder: (context) => _buildAboutTab(provider),
        ),
        DynamicTab(
          identifier: 'Files',
          tabViewBuilder: (context) => const ChangedFiles(),
        ),
      ];

  Widget _buildAboutTab(CommitProvider provider) {
    final commit = provider.data;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commit message headline
                  Text(
                    commit.messageHeadline,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Total changes stats
                  _buildTotalChangesStats(commit, provider),
                  const SizedBox(height: 16),
                  // Associated Pull Requests
                  if (commit.associatedPullRequests?.edges?.isNotEmpty ==
                      true) ...[
                    _buildAssociatedPRs(commit),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          // Changed Files Tree View (handles both tree and flat views internally)
          if (provider.files != null && provider.files!.isNotEmpty)
            FileTreeView(
              files: provider.files!,
              onFileTap: (file) async {
                if (file.patch != null) {
                  await AutoRouter.of(context).push(
                    ChangesViewer(
                      patch: file.patch!,
                      contentURL: file.contentsUrl ?? '',
                      fileType: file.filename?.split('.').last ?? '',
                    ),
                  );
                }
              },
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Commit message body (if multi-line, show full)
                  if (commit.messageBody.isNotEmpty) ...[
                    Card(
                      color: context.colorScheme.surfaceContainerLow,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Message',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              commit.messageBody,
                              style: context.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalChangesStats(
    GcommitInfoData_repository_object__asCommit commit,
    CommitProvider provider,
  ) {
    final files = provider.files;
    final totalAdditions = commit.additions;
    final totalDeletions = commit.deletions;
    final fileCount = files?.length ?? commit.changedFilesIfAvailable ?? 0;

    return Card(
      color: Color.lerp(
        context.colorScheme.surfaceContainer,
        Colors.black,
        0.1,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Octicons.diff,
                  size: 16,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Changes',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Octicons.diff_added,
                    label: 'Additions',
                    value: totalAdditions.toString(),
                    color: Colors.green.shade400,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Octicons.diff_removed,
                    label: 'Deletions',
                    value: totalDeletions.toString(),
                    color: Colors.red.shade400,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Octicons.file_diff,
                    label: 'Files',
                    value: fileCount.toString(),
                    color: context.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAssociatedPRs(
    GcommitInfoData_repository_object__asCommit commit,
  ) {
    final pullRequests = commit.associatedPullRequests;
    if (pullRequests == null) return const SizedBox.shrink();

    final edges = pullRequests.edges;
    if (edges == null || edges.isEmpty) return const SizedBox.shrink();

    final prs = edges
        .where((edge) => edge?.node != null)
        .map((edge) => edge!.node!)
        .toList();

    if (prs.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Color.lerp(
        context.colorScheme.surfaceContainer,
        Colors.black,
        0.1,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Octicons.git_pull_request,
                  size: 16,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Associated Pull Requests',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prs.map((pr) {
              Color stateColor;
              IconData stateIcon;
              String stateText;

              if (pr.isDraft) {
                stateColor = Colors.grey;
                stateIcon = Octicons.git_pull_request_draft;
                stateText = 'Draft';
              } else {
                switch (pr.state) {
                  case GPullRequestState.OPEN:
                    stateColor = Colors.green.shade400;
                    stateIcon = Octicons.git_pull_request;
                    stateText = 'Open';
                    break;
                  case GPullRequestState.CLOSED:
                    stateColor = Colors.red.shade400;
                    stateIcon = Octicons.git_pull_request_closed;
                    stateText = 'Closed';
                    break;
                  case GPullRequestState.MERGED:
                    stateColor = Colors.deepPurple.shade400;
                    stateIcon = Octicons.git_merge;
                    stateText = 'Merged';
                    break;
                  default:
                    stateColor = context.colorScheme.onSurfaceVariant;
                    stateIcon = Octicons.git_pull_request;
                    stateText = 'Unknown';
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => launchUrl(Uri.parse(pr.url.toString())),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  stateIcon,
                                  size: 12,
                                  color: stateColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '#${pr.number}',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: stateColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pr.title,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stateText,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: stateColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Column _buildTabsView(final PreferredSizeWidget tabBar) => Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[tabBar],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      );
}
