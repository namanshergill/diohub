import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/app_bar.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/deep_link_widget.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/misc/theme_from_image.dart';
import 'package:diohub/common/misc/expandable_info_card.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart' as _i2;
import 'package:diohub/models/popup/popup_type.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/providers/repository/readme_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/view/repository/code/code_browser.dart';
import 'package:diohub/view/repository/issues/issues_list.dart';
import 'package:diohub/view/repository/pulls/pulls_list.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/widgets/branch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

@RoutePage()
class RepositoryScreen extends DeepLinkWidget {
  const RepositoryScreen(
    this.repositoryURL, {
    this.branch,
    this.index = 0,
    final PathData? deepLinkData,
    super.key,
    this.initSHA,
  }) : super(pathData: deepLinkData);
  final String repositoryURL;
  final String? branch;
  final int index;
  final String? initSHA;

  @override
  RepositoryScreenState createState() => RepositoryScreenState();
}

class RepositoryScreenState extends DeepLinkWidgetState<RepositoryScreen>
    with TickerProviderStateMixin {
  bool loading = false;
  late RepoBranchProvider repoBranchProvider;
  late CodeProvider codeProvider;
  late RepoReadmeProvider readmeProvider;
  late DynamicTabsController tabController;
  late RepositoryProvider repositoryProvider;

  // Store readme headings extracted from markdown
  List<({String text, String id, int level})> _readmeHeadings = [];

  // GlobalKey to access RepositoryReadmeState for scrolling to anchors
  final GlobalKey<RepositoryReadmeState> _readmeStateKey =
      GlobalKey<RepositoryReadmeState>();

  // final ScrollController scrollController = ScrollController();
  late String? initBranch;
  late final AnimationController _expandAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void handleDeepLink(final PathData deepLinkData) {
    final PathData data = deepLinkData;
    if (_isDeepLinkCode(data)) {
      initBranch = data.component(3);
    } else if (data.componentIs(2, 'wiki')) {
      WidgetsBinding.instance
          .addPostFrameCallback((final Duration timeStamp) async {
        await AutoRouter.of(context)
            .push(WikiViewer(repoURL: widget.repositoryURL));
      });
    }
  }

  bool _isDeepLinkCode(final PathData? data) =>
      data?.component(2)?.startsWith(RegExp('(tree)|(blob)|(commits)')) ??
      false;

  bool _isDeepLinkComp(final String data) =>
      widget.pathData?.componentIs(2, data) ?? false;

  @override
  void initState() {
    _setupTabs();
    tabController = DynamicTabsController(vsync: this, tabs: tabs);
    initBranch = widget.branch;
    super.initState();
    // This HAS to be after the super initState call as some required data
    // is being set in handleDeepLink()!
    _setupProviders();
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  /// Helper method to centralize tab state information
  _TabState _getTabState(String currentTab) {
    return _TabState(currentTab: currentTab);
  }

  void _setupProviders() {
    repositoryProvider = RepositoryProvider(widget.repositoryURL);
    repoBranchProvider = RepoBranchProvider(
      initialBranch: initBranch,
      initCommitSHA: widget.initSHA,
    );
    codeProvider = CodeProvider(repoURL: widget.repositoryURL);
    readmeProvider = RepoReadmeProvider(widget.repositoryURL);
  }

  void _setupTabs() {
    tabs = <DynamicTab>[
      DynamicTab(
        identifier: 'Readme',
        isDismissible: false,
        isFocusedOnInit: true, // Set Readme as default tab
        tabViewBuilder: (final BuildContext context) => RepositoryReadme(
          context.repoProvider(listen: false).url,
          key: _readmeStateKey,
          onHeadingsExtracted: (headings) {
            // Defer setState to avoid calling during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _readmeHeadings = headings;
                });
              }
            });
          },
          onScrollToAnchor: (anchorId) {
            // Scroll callback - can be used if needed
            // The scroll is handled by RepositoryReadmeState.scrollToAnchor
          },
        ),
      ),
      DynamicTab(
        identifier: 'Code',
        isFocusedOnInit: _isDeepLinkCode(widget.pathData),
        tabViewBuilder: (final BuildContext context) => CodeBrowser(
          showCommitHistory: widget.pathData?.component(2) == 'commits',
        ),
      ),
      DynamicTab(
        identifier: 'Issues',
        isFocusedOnInit: _isDeepLinkComp('issues'),
        keepViewAlive: true,
        tabViewBuilder: (final BuildContext context) => const IssuesList(),
      ),
      DynamicTab(
        identifier: 'Pull Requests',
        isFocusedOnInit: _isDeepLinkComp('pulls'),
        keepViewAlive: true,
        tabViewBuilder: (final BuildContext context) => const PullsList(),
      ),
      DynamicTab(
        identifier: 'More',
        tabViewBuilder: (final BuildContext context) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Button(
                onTap: () async {
                  if (Provider.of<RepositoryProvider>(context, listen: false)
                      .data
                      .hasWikiEnabled) {
                    await AutoRouter.of(context).push(
                      WikiViewer(
                        repoURL: widget.repositoryURL,
                      ),
                    );
                  } else {
                    ResponseHandler.setErrorMessage(
                      AppPopupData(
                        title: 'Repository has no wiki.',
                      ),
                    );
                  }
                },
                child: const Text('Open Wiki'),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  late List<DynamicTab> tabs;

  Widget _buildCollapsedHeader(
    BuildContext context,
    GrepositoryInfoData_repository repo,
  ) {
    return Row(
      children: <Widget>[
        ProfileTile.avatar(
          avatarUrl: repo.owner.when(
            user: (u) => u.avatarUrl.toString(),
            organization: (o) => o.avatarUrl.toString(),
            orElse: () => null,
          ),
          userLogin: repo.owner.when(
            user: (u) => u.login,
            organization: (o) => o.login,
            orElse: () => null,
          ),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: context.textTheme.bodyLarge,
              children: <InlineSpan>[
                TextSpan(
                  text: '${repo.owner.when(
                    user: (u) => u.login,
                    organization: (o) => o.login,
                    orElse: () => '',
                  )}/',
                ),
                TextSpan(
                  text: repo.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(
    BuildContext context,
    GrepositoryInfoData_repository repo,
  ) {
    const double leadingWidth =
        56.0; // Standard Material Design back button width
    return ValueListenableBuilder<String>(
      valueListenable: tabController.activeIdentifierNotifier,
      builder: (context, currentTab, _) {
        final tabState = _getTabState(currentTab);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Repo name
              Padding(
                padding: EdgeInsets.only(left: leadingWidth),
                child: Text(
                  repo.name!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Detail tiles section
              _buildDetailTilesSection(context, repo),
              const SizedBox(height: 16),
              // Description and Stats section
              _buildDescriptionAndStats(context, repo),
              const SizedBox(height: 16),
              // Action buttons (includes expand button)
              _buildActionButtons(context, repo, tabState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTilesSection(
    BuildContext context,
    GrepositoryInfoData_repository repo,
  ) {
    // Always visible tiles (essential information)
    final List<Widget> alwaysVisibleTiles = [];

    // Owner
    final ownerLogin = repo.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => null,
    );
    final ownerAvatarUrl = repo.owner.when(
      user: (u) => u.avatarUrl.toString(),
      organization: (o) => o.avatarUrl.toString(),
      orElse: () => null,
    );
    if (ownerLogin != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Owner',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            navigateToProfile(
              login: ownerLogin,
              context: context,
            );
          },
          child: DetailTileUser(
            avatarUrl: ownerAvatarUrl ?? '',
            login: ownerLogin,
          ),
        ),
      );
    }

    // Language
    if (repo.primaryLanguage != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Language',
          actionType: DetailTileActionType.tab,
          onTap: () => tabController.openTab('Code'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: repo.primaryLanguage?.color != null
                      ? Color(int.parse(repo.primaryLanguage!.color!
                          .replaceFirst('#', '0xFF')))
                      : const Color(0xFF878787),
                  shape: BoxShape.circle,
                ),
                height: 12,
                width: 12,
              ),
              const SizedBox(width: 6),
              DetailTileText(repo.primaryLanguage?.name ?? ''),
            ],
          ),
        ),
      );
    }

    // Created date
    if (repo.createdAt != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Created',
          child: DetailTileText(
            getDate(repo.createdAt!.toIso8601String(), shorten: false),
          ),
        ),
      );
    }

    // Expandable tiles (less relevant information)
    final List<Widget> expandableTiles = [];

    // License
    if (repo.licenseInfo != null) {
      expandableTiles.add(
        DetailTile(
          title: 'License',
          child: DetailTileText(repo.licenseInfo!.name ?? 'Unknown'),
        ),
      );
    }

    // Stats (Open Issues, Forks, Watchers)
    expandableTiles.add(
      DetailTile(
        title: 'Stats',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailTileText('${repo.issues.totalCount} open issues'),
            const SizedBox(height: 4),
            DetailTileText('${repo.forkCount} forks'),
            const SizedBox(height: 4),
            DetailTileText('${repo.watchers.totalCount} watchers'),
          ],
        ),
      ),
    );

    return CollapsibleDetailTiles(
      alwaysVisibleTiles: alwaysVisibleTiles,
      expandableTiles: expandableTiles,
      visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
        defaultVisibleCount:
            3, // Show 3 tiles by default (Owner, Language, Created)
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

  Widget _buildDescriptionAndStats(
    BuildContext context,
    GrepositoryInfoData_repository repo,
  ) {
    final description = repo.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Description card
        if (description != null && description.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HighlightedContainer(
              highlightColor: Theme.of(context).colorScheme.primary,
              borderRadius: 12,
              child: ExpandableInfoCard(
                title: 'Description',
                expandedContent: Text(description),
                initiallyExpanded: false,
              ),
            ),
          ),
        ],
        // Stats card
        _buildRepositoryStats(context, repo),
      ],
    );
  }

  Widget _buildRepositoryStats(
    BuildContext context,
    GrepositoryInfoData_repository repo,
  ) {
    final stargazersCount = repo.stargazerCount;
    final forksCount = repo.forkCount;
    final watchersCount = repo.watchers.totalCount;

    return HighlightedContainer(
      highlightColor: Theme.of(context).colorScheme.primary,
      borderRadius: 12,
      child: Material(
        color: Color.lerp(
          Theme.of(context).colorScheme.surfaceContainer,
          Colors.black,
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Octicons.graph,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stats',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Octicons.star,
                      label: 'Stars',
                      value: stargazersCount.toString(),
                      color: Colors.amber.shade400,
                      onTap: () {
                        // TODO: Navigate to stargazers list or execute action
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Octicons.repo_forked,
                      label: 'Forks',
                      value: forksCount.toString(),
                      color: Colors.blue.shade400,
                      onTap: () {
                        // TODO: Navigate to forks list or execute action
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Octicons.eye,
                      label: 'Watchers',
                      value: watchersCount.toString(),
                      color: Colors.purple.shade400,
                      onTap: () {
                        // TODO: Navigate to watchers list or execute action
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    if (onTap == null) {
      // Non-tappable stat item
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      );
    }

    // Tappable stat item with visual feedback
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ActionButtonData> _buildAllActions(
    BuildContext context,
    GrepositoryInfoData_repository repo,
    _TabState tabState,
  ) {
    final List<ActionButtonData> allActions = [];

    // Get readme headings for "Jump to" button (stored via callback)
    final readmeHeadings = tabState.isOnReadmeTab
        ? _readmeHeadings
        : <({String text, String id})>[];
    print(
        '[RepositoryScreen] readmeHeadings count: ${readmeHeadings.length}, isOnReadmeTab: ${tabState.isOnReadmeTab}');

    // Get issue templates for "New Issue" button - use repo data directly
    final issueTemplates = repo.issueTemplates?.toList() ?? [];
    final hasTemplates = issueTemplates.isNotEmpty;
    print(
        '[RepositoryScreen] hasTemplates: $hasTemplates, templateCount: ${issueTemplates.length}');

    // Get pinned issues for "Pinned Issues" button - use repo data directly
    final pinnedIssuesNodes = repo.pinnedIssues?.nodes;
    final pinnedIssues = pinnedIssuesNodes?.toList() ??
        <GrepositoryInfoData_repository_pinnedIssues_nodes?>[];
    final filteredPinnedIssues = pinnedIssues
        .whereType<GrepositoryInfoData_repository_pinnedIssues_nodes>()
        .toList();
    print(
        '[RepositoryScreen] pinnedIssues count: ${pinnedIssues.length}, filteredPinnedIssues count: ${filteredPinnedIssues.length}');

    final jumpToButton = readmeHeadings.isNotEmpty
        ? ExpandableActionButton(
            icon: Octicons.book,
            label: 'Jump to',
            enabled: true, // Ensure button is enabled
            seedColor:
                Colors.white, // Use white as seed color for "Jump to" button
            visibilityState: tabState.isOnReadmeTab
                ? ActionButtonVisibilityState.both
                : ActionButtonVisibilityState.none,
            expandableWidgetBuilder: (onCollapse) => Builder(
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: readmeHeadings.asMap().entries.map((entry) {
                    final index = entry.key;
                    // Cast to properly typed record to access named fields
                    // Note: Dart may reorder named record fields, so we match the expected order
                    final heading =
                        entry.value as ({String id, int level, String text});
                    final isLast = index == readmeHeadings.length - 1;
                    // Calculate indentation based on heading level (h1=0, h2=16, h3=32, etc.)
                    final indent = (heading.level - 1) * 16.0;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Scroll to heading
                          print(
                              '[RepositoryScreen] ====== TAPPING HEADING ======');
                          print(
                              '[RepositoryScreen] Heading text: "${heading.text}"');
                          print(
                              '[RepositoryScreen] Heading id: "${heading.id}"');
                          print(
                              '[RepositoryScreen] Heading level: ${heading.level}');
                          print(
                              '[RepositoryScreen] Using GlobalKey to access RepositoryReadmeState...');
                          print(
                              '[RepositoryScreen] _readmeStateKey: ${_readmeStateKey.toString()}');
                          print(
                              '[RepositoryScreen] _readmeStateKey.currentState is ${_readmeStateKey.currentState != null ? "not null" : "null"}');

                          if (_readmeStateKey.currentState != null) {
                            print(
                                '[RepositoryScreen] ✓ Found RepositoryReadmeState via GlobalKey');
                            print(
                                '[RepositoryScreen] Calling _readmeStateKey.currentState!.scrollToAnchor("${heading.id}")');
                            _readmeStateKey.currentState!
                                .scrollToAnchor(heading.id);
                            print(
                                '[RepositoryScreen] scrollToAnchor call completed');
                          } else {
                            print(
                                '[RepositoryScreen] ✗ ERROR: _readmeStateKey.currentState is null');
                            print(
                                '[RepositoryScreen] This means RepositoryReadme widget may not be mounted yet');
                            print(
                                '[RepositoryScreen] Current tab: ${tabController.activeIdentifier}');
                          }

                          // Collapse the expandable widget after selection
                          onCollapse();
                        },
                        borderRadius: BorderRadius.only(
                          bottomLeft:
                              isLast ? const Radius.circular(14) : Radius.zero,
                          bottomRight:
                              isLast ? const Radius.circular(14) : Radius.zero,
                        ),
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 16 + indent,
                            right: 16,
                            top: 12,
                            bottom: 12,
                          ),
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
                              // Use different icons based on heading level for better visual hierarchy
                              Icon(
                                heading.level == 1
                                    ? Octicons.number
                                    : heading.level == 2
                                        ? Octicons.dot
                                        : heading.level == 3
                                            ? Icons.circle
                                            : Icons.fiber_manual_record,
                                size: heading.level <= 2 ? 16 : 12,
                                color: context.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  heading.text,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        : null;
    print(
        '[RepositoryScreen] Jump to button - isExpandable: ${jumpToButton is ExpandableActionButton}, expandableWidgetBuilder is ${jumpToButton is ExpandableActionButton ? "not null" : "null"}');

    final pinnedIssuesCount = repo.pinnedIssues?.totalCount ?? 0;
    final pinnedIssuesButton = filteredPinnedIssues.isNotEmpty
        ? ExpandableActionButton(
            icon: Octicons.pin,
            label: 'Pinned Issues',
            trailing: pinnedIssuesCount > 0
                ? buildModernCountBadge(context, pinnedIssuesCount)
                : null,
            enabled: pinnedIssuesCount > 0,
            visibilityState: tabState.isOnIssuesTab
                ? ActionButtonVisibilityState.both
                : ActionButtonVisibilityState.none,
            expandableWidgetBuilder: (onCollapse) => Builder(
              builder: (context) {
                // Use the pre-filtered list to avoid redundant filtering
                final filteredIssues = filteredPinnedIssues;
                print(
                    '[RepositoryScreen] Pinned Issues expandableWidgetBuilder: filteredIssues.length=${filteredIssues.length}');

                if (filteredIssues.isEmpty) {
                  print(
                      '[RepositoryScreen] WARNING: filteredIssues is empty! This should not happen since button creation checks for this.');
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Text(
                      'No pinned issues available',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                // Helper function to convert GraphQL issue state to IssueState
                IssueState? _convertGraphQLStateToIssueState(
                    _i2.GIssueState? state) {
                  if (state == null) return null;
                  if (state == _i2.GIssueState.OPEN) {
                    return IssueState.OPEN;
                  } else if (state == _i2.GIssueState.CLOSED) {
                    return IssueState.CLOSED;
                  }
                  return null;
                }

                // Helper function to convert GraphQL author to UserInfoModel
                UserInfoModel? _convertGraphQLAuthorToUserInfoModel(
                    GrepositoryInfoData_repository_pinnedIssues_nodes_issue_author?
                        author) {
                  if (author == null) return null;
                  return UserInfoModel(
                    login: author.login,
                    avatarUrl: author.avatarUrl.toString(),
                    // Other fields not available in GraphQL query
                  );
                }

                // Helper function to convert GraphQL labels to Label models
                List<Label> _convertGraphQLLabelsToLabels(
                    GrepositoryInfoData_repository_pinnedIssues_nodes_issue_labels?
                        labels) {
                  if (labels == null || labels.nodes == null) return [];
                  return labels.nodes!
                      .whereType<
                          GrepositoryInfoData_repository_pinnedIssues_nodes_issue_labels_nodes>()
                      .map((label) => Label(
                            name: label.name,
                            color: label.color,
                            // Other fields not available in GraphQL query
                          ))
                      .toList();
                }

                // Helper function to convert GraphQL pinned issue to IssueModel
                IssueModel _convertPinnedIssueToIssueModel(
                  GrepositoryInfoData_repository_pinnedIssues_nodes_issue issue,
                ) {
                  return IssueModel(
                    url: issue.url.toString(),
                    number: issue.number,
                    title: issue.title,
                    state: _convertGraphQLStateToIssueState(issue.state),
                    user: _convertGraphQLAuthorToUserInfoModel(issue.author),
                    labels: _convertGraphQLLabelsToLabels(issue.labels),
                    // Set other fields to null/defaults as they're not available in GraphQL query
                    comments: 0,
                    createdAt: null,
                    closedAt: null,
                    pullRequest: null,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: filteredIssues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final node = entry.value;
                      final issue = node.issue;
                      final issueModel = _convertPinnedIssueToIssueModel(issue);
                      final isLast = index == filteredIssues.length - 1;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await AutoRouter.of(context).push(
                              issuePullScreenRoute(
                                PathData.fromURL(issue.url.toString()),
                              ),
                            );
                            onCollapse();
                          },
                          borderRadius: BorderRadius.only(
                            bottomLeft: isLast
                                ? const Radius.circular(14)
                                : Radius.zero,
                            bottomRight: isLast
                                ? const Radius.circular(14)
                                : Radius.zero,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                            vertical: 12,
                            ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Issue number and state icon
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            issueModel.state == IssueState.OPEN
                                                ? Colors.green.withOpacity(0.12)
                                                : Colors.red.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            issueModel.state == IssueState.OPEN
                                                ? Octicons.issue_opened
                                                : Octicons.issue_closed,
                                            size: 12,
                                            color: issueModel.state ==
                                                    IssueState.OPEN
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${issue.number}',
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                              color: issueModel.state ==
                                                      IssueState.OPEN
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (issueModel.user?.login != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        issueModel.user!.login!,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: context
                                              .colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Issue title
                                Text(
                                  issue.title ?? 'Untitled',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Labels
                                if (issueModel.labels != null &&
                                    issueModel.labels!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: issueModel.labels!
                                        .map((label) => IssueLabel(label))
                                        .toList(),
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
          )
        : MajorActionButton(
            icon: Octicons.pin,
            label: 'Pinned Issues',
            trailing: pinnedIssuesCount > 0
                ? buildModernCountBadge(context, pinnedIssuesCount)
                : null,
            enabled: false,
            visibilityState: tabState.isOnIssuesTab
                ? ActionButtonVisibilityState.both
                : ActionButtonVisibilityState.none,
            onTap: null,
          );
    print(
        '[RepositoryScreen] Pinned Issues button - isExpandable: ${pinnedIssuesButton is ExpandableActionButton}, expandableWidgetBuilder is ${pinnedIssuesButton is ExpandableActionButton ? "not null" : "null"}');

    // "New Issue" button - prominent action
    // Expanded: visible everywhere
    // Collapsed: visible ONLY on Issues tab
    final newIssueButton = hasTemplates
        ? ExpandableActionButton(
            icon: Octicons.plus,
            label: 'New Issue',
            isPositive: true,
            // Visible in expanded state everywhere, but only in collapsed state on Issues tab
            visibilityState: tabState.isOnIssuesTab
                ? ActionButtonVisibilityState.both
                : ActionButtonVisibilityState.expandedOnly,
            expandableWidgetBuilder: (onCollapse) => Builder(
              builder: (context) {
                // Use issue templates from repo
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Template options
                    ...issueTemplates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final template = entry.value;
                      final isLast = index == issueTemplates.length - 1;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await AutoRouter.of(context).push(
                              NewIssueRoute(
                                owner: repo.owner.when(
                                  user: (u) => u.login,
                                  organization: (o) => o.login,
                                  orElse: () => '',
                                ),
                                repo: repo.name,
                                template: template,
                              ),
                            );
                            onCollapse();
                          },
                          borderRadius: BorderRadius.only(
                            bottomLeft: isLast && issueTemplates.length == 1
                                ? const Radius.circular(14)
                                : Radius.zero,
                            bottomRight: isLast && issueTemplates.length == 1
                                ? const Radius.circular(14)
                                : Radius.zero,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                Icon(
                                  Octicons.file,
                                  size: 18,
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    template.name,
                                    style:
                                        context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Blank issue option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AutoRouter.of(context).push(
                            NewIssueRoute(
                              owner: repo.owner.when(
                                user: (u) => u.login,
                                organization: (o) => o.login,
                                orElse: () => '',
                              ),
                              repo: repo.name,
                            ),
                          );
                          onCollapse();
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Octicons.plus,
                                size: 18,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Blank Issue',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        : MajorActionButton(
            icon: Octicons.plus,
            label: 'New Issue',
            isPositive: true,
            visibilityState: tabState.isOnIssuesTab
                ? ActionButtonVisibilityState.both
                : ActionButtonVisibilityState.expandedOnly,
            onTap: () async {
              // No templates, navigate directly
              await AutoRouter.of(context).push(
                NewIssueRoute(
                  owner: repo.owner.when(
                    user: (u) => u.login,
                    organization: (o) => o.login,
                    orElse: () => '',
                  ),
                  repo: repo.name,
                ),
              );
            },
          );
    print(
        '[RepositoryScreen] New Issue button - isExpandable: ${newIssueButton is ExpandableActionButton}, expandableWidgetBuilder is ${newIssueButton is ExpandableActionButton ? "not null" : "null"}');

    // Add prominent actions
    if (jumpToButton != null) {
      allActions.add(jumpToButton);
    }
    allActions.add(pinnedIssuesButton);
    allActions.add(newIssueButton);

    // Add minor actions (will appear in the row)
    allActions.addAll([
      MinorActionButton(
        icon: Octicons.file_code,
        label: repo.primaryLanguage?.name ?? 'Code',
        iconColor: () {
          final color = repo.primaryLanguage?.color;
          return color != null
              ? Color(int.parse(color.replaceFirst('#', '0xFF')))
              : null;
        }(),
        trailing: repo.diskUsage != null
            ? buildActionButtonTrailingSize(context, repo.diskUsage!)
            : null,
        visibilityState: tabState.isOnCodeTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Code'),
      ),
      // Always include Issues action, but hide it when on Issues tab using visibilityState
      // This keeps the list structure stable for smooth animations
      MinorActionButton(
        icon: Octicons.issue_opened,
        label: 'Issues',
        trailing: repo.issues.totalCount > 0
            ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
            : null,
        visibilityState: tabState.isOnIssuesTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Issues'),
      ),
      MinorActionButton(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        trailing: repo.issues.totalCount > 0
            ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
            : null,
        visibilityState: tabState.isOnPullRequestsTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Pull Requests'),
      ),
      MinorActionButton(
        icon: Octicons.book,
        label: 'Readme',
        visibilityState: tabState.isOnReadmeTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController.openTab('Readme'),
      ),
      MinorActionButton(
        icon: Octicons.kebab_horizontal,
        label: 'More',
        visibilityState: tabState.isOnMoreTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController.openTab('More'),
      ),
    ]);

    return allActions;
  }

  Widget _buildActionButtons(
    BuildContext context,
    GrepositoryInfoData_repository repo,
    _TabState tabState,
  ) {
    // All actions - show all in primary to ensure minColumns is respected
    final primaryActions = <ActionButtonData>[
      MinorActionButton(
        icon: Octicons.file_code,
        label: repo.primaryLanguage?.name ?? 'Code',
        iconColor: () {
          final color = repo.primaryLanguage?.color;
          return color != null
              ? Color(int.parse(color.replaceFirst('#', '0xFF')))
              : null;
        }(),
        trailing: repo.diskUsage != null
            ? buildActionButtonTrailingSize(context, repo.diskUsage!)
            : null,
        actionType: ActionButtonActionType.tab,
        visibilityState: tabState.isOnCodeTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Code'),
      ),
      MinorActionButton(
        icon: Octicons.issue_opened,
        label: 'Issues',
        trailing: repo.issues.totalCount > 0
            ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
            : null,
        actionType: ActionButtonActionType.tab,
        visibilityState: tabState.isOnIssuesTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Issues'),
      ),
      MinorActionButton(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        trailing: repo.issues.totalCount > 0
            ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
            : null, // Note: using openIssuesCount as placeholder
        actionType: ActionButtonActionType.tab,
        visibilityState: tabState.isOnPullRequestsTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController.openTab('Pull Requests'),
      ),
      MinorActionButton(
        icon: Icons.menu_rounded,
        label: 'More',
        actionType: ActionButtonActionType.tab,
        visibilityState: tabState.isOnMoreTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController.openTab('More'),
      ),
    ];

    // No secondary actions - all are primary
    final secondaryActions = <ActionButtonData>[];

    return CollapsibleActionButtons(
      primaryActions: primaryActions,
      secondaryActions: secondaryActions,
      actionCardBuilder: (context, action) => buildAppBarActionCard(
        context,
        action,
        iconSize: 16, // Smaller icon
        padding: const EdgeInsets.all(10), // Less padding for compactness
      ),
      visibilityConfig: const ActionButtonsVisibilityConfig(),
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
  Widget build(final BuildContext context) => MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RepositoryProvider>.value(
            value: repositoryProvider,
          ),
          ChangeNotifierProxyProvider<RepositoryProvider, RepoBranchProvider>(
            create: (final _) => repoBranchProvider,
            update: (
              final BuildContext context,
              final RepositoryProvider value,
              final RepoBranchProvider? previous,
            ) =>
                repoBranchProvider..updateProvider(value),
          ),
          ChangeNotifierProxyProvider<RepoBranchProvider, RepoReadmeProvider>(
            create: (final _) => readmeProvider,
            update: (final _, final RepoBranchProvider branch, final __) =>
                readmeProvider..updateProvider(branch),
          ),
          ChangeNotifierProxyProvider<RepoBranchProvider, CodeProvider>(
            create: (final _) => codeProvider,
            update: (final _, final RepoBranchProvider branch, final __) =>
                codeProvider..updateProvider(branch),
          ),
        ],
        builder: (final BuildContext context, final _) => Scaffold(
          // backgroundColor:
          // Provider.of<PaletteSettings>(context).currentSetting.primary,
          // Show a temporary app bar until the provider loads.
          appBar:
              Provider.of<RepositoryProvider>(context).status != Status.loaded
                  ? AppBar(
                      elevation: 0,
                    )
                  : PreferredSize(
                      preferredSize: Size.zero,
                      child: Container(),
                    ),
          body: WillPopScope(
            onWillPop: () async {
              // Don't pop screen if code browsing is open and not the root tree.
              if (Provider.of<CodeProvider>(context, listen: false)
                          .tree
                          .length >
                      1 &&
                  tabController.activeIdentifier == 'Code') {
                Provider.of<CodeProvider>(context, listen: false).popTree();
                return false;
              } else {
                return true;
              }
            },
            child: ScaffoldBody(
              child: ProviderLoadingProgressWrapper<RepositoryProvider>(
                childBuilder: (
                  final BuildContext context,
                  final RepositoryProvider value,
                ) {
                  final repo = value.data;
                  return ThemeFromImage(
                    // imageUri: repo.owner?.avatarUrl,
                    builder: (context) => SizedBox.expand(
                      child: Stack(
                        children: [
                          SafeArea(
                            child: DynamicTabsParent(
                              controller: tabController,
                              builder: (
                                final BuildContext context,
                                final PreferredSizeWidget tabs,
                                final Widget tabView,
                              ) =>
                                  DynamicScroll(
                                contentVersion: 0,
                                animationController: _expandAnimationController,
                                collapsedWidget:
                                    _buildCollapsedHeader(context, repo),
                                expandedWidget:
                                    _buildExpandedHeader(context, repo),
                                pinnedWidget: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                  child: BranchButton(),
                                ),
                                actions: <Widget>[
                                  ShareButton(repo.url.toString())
                                ],
                                bottom: AnimatedTabBar(
                                  showTabBar: tabController.activeLength > 1,
                                  tabBar: tabs,
                                  defaultPadding:
                                      const EdgeInsets.only(bottom: 8),
                                  topSpacing: 4.0,
                                ),
                                body: loading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : tabView,
                              ),
                            ),
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable:
                                tabController.activeIdentifierNotifier,
                            builder: (context, currentTab, _) {
                              final tabState = _getTabState(currentTab);
                              return FloatingActionToolbar(
                                // Use a stable key so the widget persists across tab changes
                                // This allows smooth animations instead of widget recreation
                                key: const ValueKey('repository_toolbar'),
                                debugLogging: true,
                                actions:
                                    _buildAllActions(context, repo, tabState),
                                actionCardBuilder: buildStandardActionCard,
                                // defaultVisibleCount: 2,
                                position: FloatingPosition.bottom,
                                // Default alignment for bottom is right (set in FloatingActionToolbar)
                                // alignment: null,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                // bottomPadding should only account for OS navigation bar, not tab bar
                                // since FloatingActionToolbar is above tab bar in widget tree
                                bottomPadding: 0.0,
                                title: repo.name,
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
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
}

/// Helper class to centralize tab state information
class _TabState {
  const _TabState({
    required this.currentTab,
  });

  final String currentTab;

  bool get isOnIssuesTab => currentTab == 'Issues';
  bool get isOnReadmeTab => currentTab == 'Readme';
  bool get isOnCodeTab => currentTab == 'Code';
  bool get isOnPullRequestsTab => currentTab == 'Pull Requests';
  bool get isOnMoreTab => currentTab == 'More';
}
