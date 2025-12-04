import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/app_bar.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
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
import 'package:diohub/models/popup/popup_type.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/providers/repository/issue_templates_provider.dart';
import 'package:diohub/providers/repository/pinned_issues_provider.dart';
import 'package:diohub/providers/repository/readme_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
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
  late IssueTemplateProvider issueTemplateProvider;
  late RepositoryProvider repositoryProvider;
  late PinnedIssuesProvider pinnedIssuesProvider;

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

  void _setupProviders() {
    repositoryProvider = RepositoryProvider(widget.repositoryURL);
    repoBranchProvider = RepoBranchProvider(
      initialBranch: initBranch,
      initCommitSHA: widget.initSHA,
    );
    codeProvider = CodeProvider(repoURL: widget.repositoryURL);
    readmeProvider = RepoReadmeProvider(widget.repositoryURL);
    issueTemplateProvider = IssueTemplateProvider();
    pinnedIssuesProvider = PinnedIssuesProvider();
  }

  void _setupTabs() {
    tabs = <DynamicTab>[
      DynamicTab(
        identifier: 'Readme',
        isDismissible: false,
        isFocusedOnInit: true, // Set Readme as default tab
        tabViewBuilder: (final BuildContext context) =>
            RepositoryReadme(context.repoProvider(listen: false).url),
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
                      .hasWiki!) {
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

  Widget _buildCollapsedHeader(BuildContext context, RepositoryModel repo) {
    return Row(
      children: <Widget>[
        ProfileTile.avatar(
          avatarUrl: repo.owner?.avatarUrl,
          userLogin: repo.owner?.login,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: context.textTheme.bodyLarge,
              children: <InlineSpan>[
                TextSpan(text: '${repo.owner!.login}/'),
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

  Widget _buildExpandedHeader(BuildContext context, RepositoryModel repo) {
    const double leadingWidth =
        56.0; // Standard Material Design back button width
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
          _buildActionButtons(context, repo),
        ],
      ),
    );
  }

  Widget _buildDetailTilesSection(BuildContext context, RepositoryModel repo) {
    // Always visible tiles (essential information)
    final List<Widget> alwaysVisibleTiles = [];

    // Owner
    if (repo.owner != null) {
      alwaysVisibleTiles.add(
        DetailTile(
          title: 'Owner',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            navigateToProfile(
              login: repo.owner!.login!,
              context: context,
            );
          },
          child: DetailTileUser(
            avatarUrl: repo.owner!.avatarUrl ?? '',
            login: repo.owner!.login ?? '',
          ),
        ),
      );
    }

    // Language
    if (repo.language != null) {
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
                  color: Color(getLangColor(repo.language)),
                  shape: BoxShape.circle,
                ),
                height: 12,
                width: 12,
              ),
              const SizedBox(width: 6),
              DetailTileText(repo.language!),
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
    if (repo.license != null) {
      expandableTiles.add(
        DetailTile(
          title: 'License',
          child: DetailTileText(repo.license!.name ?? 'Unknown'),
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
            DetailTileText('${repo.openIssuesCount ?? 0} open issues'),
            const SizedBox(height: 4),
            DetailTileText('${repo.forksCount ?? 0} forks'),
            const SizedBox(height: 4),
            DetailTileText('${repo.watchersCount ?? 0} watchers'),
          ],
        ),
      ),
    );

    // Forked from
    if (repo.fork == true && repo.source != null) {
      expandableTiles.add(
        DetailTile(
          title: 'Forked from',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            // Navigate to source repo
          },
          child: DetailTileText(
            '${repo.source!.owner!.login}/${repo.source!.name}',
          ),
        ),
      );
    }

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

  Widget _buildDescriptionAndStats(BuildContext context, RepositoryModel repo) {
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

  Widget _buildRepositoryStats(BuildContext context, RepositoryModel repo) {
    final stargazersCount = repo.stargazersCount ?? 0;
    final forksCount = repo.forksCount ?? 0;
    final watchersCount = repo.watchersCount ?? 0;
    final openIssuesCount = repo.openIssuesCount ?? 0;

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
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Octicons.issue_opened,
                      label: 'Issues',
                      value: openIssuesCount.toString(),
                      color: Colors.green.shade400,
                      onTap: () {
                        tabController.openTab('Issues');
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

  Widget _buildActionButtons(BuildContext context, RepositoryModel repo) {
    // All actions - show all in primary to ensure minColumns is respected
    final primaryActions = <ActionButtonData>[
      ActionButtonData(
        icon: Octicons.file_code,
        label: repo.language ?? 'Code',
        iconColor:
            repo.language != null ? Color(getLangColor(repo.language)) : null,
        trailing: repo.size != null
            ? buildActionButtonTrailingSize(context, repo.size!)
            : null,
        actionType: ActionButtonActionType.tab,
        onTap: () => tabController.openTab('Code'),
      ),
      ActionButtonData(
        icon: Octicons.issue_opened,
        label: 'Issues',
        trailing: repo.openIssuesCount != null
            ? buildActionButtonTrailingCount(context, repo.openIssuesCount!)
            : null,
        actionType: ActionButtonActionType.tab,
        onTap: () => tabController.openTab('Issues'),
      ),
      ActionButtonData(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        trailing: repo.openIssuesCount != null
            ? buildActionButtonTrailingCount(context, repo.openIssuesCount!)
            : null, // Note: using openIssuesCount as placeholder
        actionType: ActionButtonActionType.tab,
        onTap: () => tabController.openTab('Pull Requests'),
      ),
      ActionButtonData(
        icon: Icons.menu_rounded,
        label: 'More',
        actionType: ActionButtonActionType.tab,
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
          ChangeNotifierProxyProvider<RepositoryProvider,
              IssueTemplateProvider>(
            create: (final _) => issueTemplateProvider,
            update: (final _, final RepositoryProvider repo, final __) =>
                issueTemplateProvider..updateProvider(repo),
            lazy: false,
          ),
          ChangeNotifierProxyProvider<RepositoryProvider, PinnedIssuesProvider>(
            create: (final _) => pinnedIssuesProvider,
            update: (final _, final RepositoryProvider repo, final __) =>
                pinnedIssuesProvider..updateProvider(repo),
            lazy: false,
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
        builder: (final BuildContext context, final _) => SafeArea(
          child: Scaffold(
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
                    final RepositoryModel repo = value.data;
                    return ThemeFromImage(
                      // imageUri: repo.owner?.avatarUrl,
                      builder: (context) => DynamicTabsParent(
                        controller: tabController,
                        builder: (
                          final BuildContext context,
                          final PreferredSizeWidget tabs,
                          final Widget tabView,
                        ) =>
                            DynamicScroll(
                          contentVersion: 0,
                          animationController: _expandAnimationController,
                          collapsedWidget: _buildCollapsedHeader(context, repo),
                          expandedWidget: _buildExpandedHeader(context, repo),
                          pinnedWidget: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: BranchButton(repo: repo),
                          ),
                          actions: repo.htmlUrl != null
                              ? <Widget>[ShareButton(repo.htmlUrl!)]
                              : null,
                          bottom: AnimatedTabBar(
                            showTabBar: tabController.activeLength > 1,
                            tabBar: tabs,
                            defaultPadding: const EdgeInsets.only(bottom: 8),
                            topSpacing: 4.0,
                          ),
                          body: loading
                              ? const Center(child: CircularProgressIndicator())
                              : tabView,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
}
