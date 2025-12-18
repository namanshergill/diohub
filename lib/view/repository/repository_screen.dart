import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/misc/app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/floating_toolbar_wrapper.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/deep_link_widget.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/misc/theme_from_image.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/providers/repository/readme_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/repository/widgets/branch_button.dart';
import 'package:diohub/view/repository/widgets/repository_tabs.dart';
import 'package:diohub/view/repository/widgets/repository_header.dart';
import 'package:diohub/view/repository/widgets/repository_action_buttons.dart';
import 'package:diohub/view/repository/widgets/tab_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
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
  TabState _getTabState(String currentTab) {
    return TabState(currentTab: currentTab);
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
    tabs = createRepositoryTabs(
      repositoryURL: widget.repositoryURL,
      pathData: widget.pathData,
      readmeStateKey: _readmeStateKey,
      onHeadingsExtracted: (headings) {
        setState(() {
          _readmeHeadings = headings;
        });
      },
      setState: setState,
      mounted: mounted,
    );
  }

  late List<DynamicTab> tabs;

  List<ActionButtonData> _buildAllActions(
    BuildContext context,
    GrepositoryInfoData_repository repo,
    TabState tabState,
  ) {
    return buildAllActions(
      context,
      repo,
      tabState,
      _readmeHeadings,
      _readmeStateKey,
      tabController,
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
                    builder: (context) => SizedBox.expand(
                      child: FloatingToolbarWrapper(
                        toolbarBuilder: (scrollNotificationNotifier) {
                          return ValueListenableBuilder<String>(
                            valueListenable:
                                tabController.activeIdentifierNotifier,
                            builder: (context, currentTab, _) {
                              final tabState = _getTabState(currentTab);
                              final ownerLogin = repo.owner.when(
                                user: (u) => u.login,
                                organization: (o) => o.login,
                                orElse: () => null,
                              );
                              return FloatingActionToolbar(
                                key: const ValueKey('repository_toolbar'),
                                // debugLogging: true,
                                actions:
                                    _buildAllActions(context, repo, tabState),
                                actionCardBuilder: buildStandardActionCard,
                                position: FloatingPosition.bottom,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                bottomPadding: 0.0,
                                title: repo.name,
                                subtitle: ownerLogin,
                                scrollNotificationNotifier:
                                    scrollNotificationNotifier,
                                onExpandChanged: (isExpanded) {
                                  if (isExpanded) {
                                    _expandAnimationController.forward();
                                  } else {
                                    _expandAnimationController.reverse();
                                  }
                                },
                              );
                            },
                          );
                        },
                        child: SafeArea(
                          child: DynamicTabsParent(
                            controller: tabController,
                            builder: (
                              final BuildContext context,
                              final PreferredSizeWidget tabs,
                              final Widget tabView,
                            ) =>
                                DynamicScroll(
                              animationController: _expandAnimationController,
                              collapsedWidget:
                                  buildCollapsedHeader(context, repo),
                              expandedWidget: buildExpandedHeader(
                                context,
                                repo,
                                tabController.activeIdentifierNotifier,
                                tabController,
                                _expandAnimationController,
                              ),
                              pinnedWidget: null,
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
