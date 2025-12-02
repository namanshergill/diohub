import 'dart:core';
import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/animations/scale_expanded_widget.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/app_bar.dart';
import 'package:diohub/common/misc/deep_link_widget.dart';
import 'package:diohub/common/misc/editable_text.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/misc/scroll_scaffold.dart';
import 'package:diohub/common/misc/theme_from_image.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/editing_wrapper.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/providers/issue_pulls/issue_provider.dart';
import 'package:diohub/providers/issue_pulls/pull_provider.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/markdown_to_html.dart';
import 'package:diohub/utils/rich_text.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/common/misc/compact_expand_button.dart';
import 'package:diohub/view/issues_pulls/issue_screen.dart';
import 'package:diohub/view/issues_pulls/pull_screen.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_stack/image_stack.dart';
import 'package:provider/provider.dart';

IssuePullRoute issuePullScreenRoute(final PathData path) =>
    getRoute<IssuePullRoute>(
      path,
      onDeepLink: (final PathData path) => IssuePullRoute(
        ownerName: path.component(0)!,
        repoName: path.component(1)!,
        number: int.parse(path.component(3)!),
      ),
      onAPILink: (final PathData path) => IssuePullRoute(
        ownerName: path.component(1)!,
        repoName: path.component(2)!,
        number: int.parse(path.component(4)!),
      ),
    );

@RoutePage()
class IssuePullScreen extends DeepLinkWidget {
  const IssuePullScreen({
    required this.number,
    required this.repoName,
    required this.ownerName,
    super.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final DateTime? commentsSince;
  final int initialIndex;
  final int number;
  final String ownerName;
  final String repoName;

  @override
  State<IssuePullScreen> createState() => _IssuePullScreenState();
}

class _IssuePullScreenState extends DeepLinkWidgetState<IssuePullScreen> {
  final GlobalKey<
          APIWrapperState<GissuePullInfoData_repository_issueOrPullRequest>>
      key = GlobalKey<
          APIWrapperState<GissuePullInfoData_repository_issueOrPullRequest>>();

  @override
  void handleDeepLink(final PathData deepLinkData) {
    // TODO(namanshergill): implement handleDeepLink
  }

  Future<void> onRefresh() async {
    await key.currentState?.refreshData();
  }

  @override
  Widget build(final BuildContext context) =>
      APIWrapper<GissuePullInfoData_repository_issueOrPullRequest>.deferred(
        apiCall: ({required final bool refresh}) async =>
            IssuesService.getIssuePullInfo(
          widget.number,
          repo: widget.repoName,
          user: widget.ownerName,
          refresh: refresh,
        ),
        key: key,
        loadingBuilder: (final BuildContext context) => Scaffold(
          appBar: AppBar(
            elevation: 0,
          ),
          body: const LoadingIndicator(),
        ),
        errorBuilder: (final BuildContext context, final Object? data) =>
            Scaffold(
          appBar: AppBar(
            elevation: 0,
          ),
          body: Center(
            child: Text(data.toString()),
          ),
        ),
        builder: (
          final BuildContext context,
          final GissuePullInfoData_repository_issueOrPullRequest data,
        ) =>
            data.when(
          issue: (
            final GissuePullInfoData_repository_issueOrPullRequest__asIssue p0,
          ) =>
              ChangeNotifierProvider<IssueProvider>(
            create: (final BuildContext context) => IssueProvider(p0),
            lazy: false,
            builder: (final BuildContext context, final Widget? child) =>
                IssueScreen(
              p0,
              onRefresh: onRefresh,
            ),
          ),
          pullRequest: (
            final GissuePullInfoData_repository_issueOrPullRequest__asPullRequest
                p0,
          ) =>
              ChangeNotifierProvider<PullProvider>(
            create: (final BuildContext context) => PullProvider(p0),
            lazy: false,
            builder: (final BuildContext context, final Widget? child) =>
                PullScreen(
              data as GpullInfo, onRefresh: onRefresh,
              // apiWrapperController: apiWrapperController,
            ),
          ),
          orElse: unimplemented,
        ),
      );
}

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

  // final ScrollController scrollController = ScrollController();
  // final ScrollController scrollController2 = ScrollController();
  late EditingController<String> titleEditingController;

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
  Widget build(final BuildContext context) => ThemeFromImage(
        builder: (
          final BuildContext context,
        ) {
          return SafeArea(
            child: buildDynamicTabsParent(),
          );
        },
      );

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
          builder: (final BuildContext context) => ScrollScaffold(
            subHeader: SizeExpandedSection(
              expand: dynamicTabsController.activeLength > 1,
              child: buildTabsView(tabBar),
            ),
            appBar: buildAppBar(context),
            wrapperBuilder: (final BuildContext context, final Widget child) =>
                RefreshIndicator(
              onRefresh: widget.onRefresh,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              child: child,
            ),
            header: _ScreenHeader(
              widget: widget,
              titleEditingController: titleEditingController,
              labelsEditingController: labelsEditingController,
            ),
            body: tabView,
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
              // nestedScrollViewController: scrollController,
            ),
          ),
        ),
      ],
    );

  DynamicTab _buildAboutTab() => DynamicTab(
        identifier: 'About',
        isDismissible: false,
        tabViewBuilder: (final BuildContext context) => _AboutTab(
          widget: widget,
          descEditingController: descEditingController,
          assigneeEditingController: assigneeEditingController,
          dynamicTabsController: dynamicTabsController,
        ),
      );

  DHAppBar buildAppBar(final BuildContext context) => DHAppBar(
        hasEditableChildren: true,
        title: Row(
          children: <Widget>[
            widget.state.icon(),
            // const SizedBox(
            //   width: 8,
            // ),
            Expanded(
              child: richText(
                <TextSpan>[
                  TextSpan(text: ' #${widget.number} '),
                  TextSpan(
                    text: widget.repoInfo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      // color: context.palette.faded3,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          // const SizedBox(
          //   height: 8,
          // ),
        ],
      );
}

class _AboutTab extends StatefulWidget {
  const _AboutTab({
    required this.widget,
    required this.descEditingController,
    required this.dynamicTabsController,
    required this.assigneeEditingController,
  });

  final IssuePullInfoTemplate widget;
  final EditingController<String> descEditingController;
  final DynamicTabsController dynamicTabsController;
  final EditingController<Object> assigneeEditingController;

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(final BuildContext context) {
    final w = widget.widget;
    final descController = widget.descEditingController;
    final assigneeController = widget.assigneeEditingController;
    final tabsController = widget.dynamicTabsController;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 12,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: w.state.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: w.state.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    w.state.icon(size: 14),
                    const SizedBox(width: 6),
                    Text(
                      w.state.text,
                      style: TextStyle(
                        color: w.state.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (w.createdBy != null)
                ThemePZero(
                  imageUrl: w.createdBy!.avatarUrl.toString(),
                  child: ProfileTile.login(
                    avatarUrl: w.createdBy!.avatarUrl.toString(),
                    userLogin: w.createdBy!.login,
                    size: 16,
                  ),
                ),
              Text(
                getDate(w.createdAt.toString(), shorten: false),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: context.colorScheme.surfaceContainerLow,
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 8,
                ),
                ReactionBar(
                  w.reactionGroups,
                  viewerCanReact: w.viewerCanReact,
                ),
                EditWidget<String>(
                  editingController: descController,
                  builder: (
                    final BuildContext context,
                    final EditingData<String> data,
                  ) =>
                      Row(
                    children: <Widget>[
                      if (w.bodyHTML.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topCenter,
                                  child: ClipRect(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: _isDescriptionExpanded ||
                                                w.body.length <= 400
                                            ? double.infinity
                                            : 200,
                                      ),
                                      child: MarkdownBody(w.bodyHTML),
                                    ),
                                  ),
                                ),
                                if (w.body.length > 400)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: CompactExpandButton(
                                      isExpanded: _isDescriptionExpanded,
                                      onTap: () {
                                        setState(() {
                                          _isDescriptionExpanded =
                                              !_isDescriptionExpanded;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ScaleSwitch(
                        child: w.bodyHTML.isEmpty &&
                                data.currentState == EditingState.editMode
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No description provided',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : Container(),
                      ),
                      data.tools,
                    ],
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  child: InkPot(
                    onTap: () {
                      try {
                        tabsController.openTab('Conversation');
                      } catch (e, s) {
                        log(e.toString(), stackTrace: s);
                      }
                    },
                    backgroundColor: context.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.vertical(
                      bottom: context.themeData.borderRadiusTheme!
                          .medBorderRadius.bottomLeft,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: context.themeData.borderRadiusTheme!
                              .medBorderRadius.bottomLeft,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: context
                                        .colorScheme.onPrimaryContainer
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Octicons.comment_discussion,
                                    size: 16,
                                    color:
                                        context.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Conversation',
                                      style: context.textTheme.labelMedium
                                          ?.copyWith(
                                        color: context
                                            .colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${w.commentCount} ${w.commentCount == 1 ? 'reply' : 'replies'}',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: context
                                            .colorScheme.onPrimaryContainer
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              InfoCard(
                // icon: widget.state.icon(color: context.palette.faded3),
                onTap: () async {
                  await context.router
                      .push(RepositoryRoute(repositoryURL: 'repositoryURL'));
                },
                leading: InfoCard.leadingIcon(
                  icon: Octicons.repo,
                ),
                title: '${w.number}',

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ProfileTile.avatar(
                      avatarUrl: w.repoInfo.owner.avatarUrl.toString(),
                      size: 16,
                    ),
                    Flexible(
                      child: Text(
                        '${w.repoInfo.owner.login}/${w.repoInfo.name}',
                      ),
                    ),
                  ],
                ),
              ),
              // Container(
              //   width: 100,
              //   height: 30,
              //   color: red,
              // ),

              EditWidget<Object>(
                editingController: assigneeController,
                builder: (
                  final BuildContext context,
                  final EditingData<Object> data,
                ) {
                  final List<GassigneeInfo_edges?> assignees =
                      w.assigneesInfo.edges?.toList() ??
                          <GassigneeInfo_edges?>[];
                  return _AssigneeInfoCard(
                    onTap: data.editModeActive
                        ? () async => data.editingController.edit.call(context)
                        : null,
                    trailing: data.editModeActive ? data.tools : null,
                    availableList:
                        UnfinishedList<NodeWithPaginationInfo<Gactor>>(
                      limitedAvailableList: assignees
                          .map(
                            // ignore: unnecessary_lambdas
                            (final GassigneeInfo_edges? e) =>
                                NodeWithPaginationInfo<Gactor>.fromEdge(e!),
                          )
                          .toList(),
                    ),
                    titleBuilder: (
                      final UnfinishedList<NodeWithPaginationInfo<Gactor>>
                          availableList,
                    ) =>
                        switch (availableList.totalCount) {
                      1 => 'Assignee',
                      _ => 'Assignees',
                    },
                    fetchActorsList: (
                      final ScrollWrapperFutureArguments<
                              NodeWithPaginationInfo<Gactor>>
                          data,
                    ) async =>
                        (await context
                                .issueProvider(listen: false)
                                .getAssignees(
                                  after: data.lastItem?.cursor,
                                ))
                            .map<NodeWithPaginationInfo<Gactor>>(
                              (final NodeWithPaginationInfo<Gactor>? e) =>
                                  NodeWithPaginationInfo<Gactor>.fromEdge(e!),
                            )
                            .toList(),
                  );
                },
              ),

              InfoCard(
                title: switch (w.participantsInfo.totalCount) {
                  1 => 'Participant',
                  _ => 'Participants',
                },
                trailing: _getIcon(w.participantsInfo.totalCount),
                child: _buildChild(w.participantsInfo),
                onTap: () async {
                  await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
                    paginatedListItemBuilder: _paginatedListItemBuilder,
                    paginationFuture: (
                      final ScrollWrapperFutureArguments<
                              NodeWithPaginationInfo<Gactor>>
                          data,
                    ) async =>
                        context.issueProvider(listen: false).getParticipants(
                              after: data.lastItem?.cursor,
                            ),
                    title: 'Participants',
                  ).openSheet(context);
                },
              ),
              ...w.additionalAboutWidgets,
            ],
          ),
        ],
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.widget,
    required this.titleEditingController,
    required this.labelsEditingController,
  });

  final IssuePullInfoTemplate widget;
  final EditingController<String> titleEditingController;
  final EditingController<List<Glabel?>> labelsEditingController;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                if (widget.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Octicons.pin,
                            size: 14,
                            color: context.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pinned',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                EditableTextItem(
                  titleEditingController,
                  builder:
                      (final BuildContext context, final String? newValue) =>
                          MarkdownBody(
                    newValue != null ? mdToHtml(newValue) : widget.title,
                    textStyle: context.textTheme.headlineSmall,
                    // defaultBodyStyle: Style(
                    //   padding: HtmlPaddings.zero,
                    //   margin: Margins.zero,
                    //   fontSize: FontSize(
                    //     context.textTheme.headlineSmall!.fontSize!,
                    //   ),
                    //   fontWeight: context.textTheme.headlineSmall?.fontWeight,
                    // ),
                  ),
                ),
                buildLabelsWidget(),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        ],
      );

  EditWidget<List<Glabel?>> buildLabelsWidget() => EditWidget<List<Glabel?>>(
        editingController: labelsEditingController,
        builder: (
          final BuildContext context,
          final EditingData<List<Glabel?>> data,
        ) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: <Widget>[
                if (data.editingController.currentValue.isEmpty)
                  Text(
                    'No Labels',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: data.editingController.currentValue
                          .map(
                            (final Glabel? e) => IssueLabel.gql(e!),
                          )
                          .toList(),
                    ),
                  ),
                data.tools,
              ],
            ),
          );
        },
      );
}

class IssuePullState {
  IssuePullState(this.state, {this.isDraft = false})
      : assert(
          state is GPullRequestState || state is GIssueState,
          'Not a valid state!',
        );

  final bool isDraft;
  final dynamic state;

  Icon icon({
    final double size = 16,
    final Color? color,
  }) =>
      Icon(
        iconData,
        size: size,
        color: color ?? this.color,
      );

  IconData get iconData {
    if (state == GIssueState.OPEN) {
      return Octicons.issue_opened;
    } else if (state == GIssueState.CLOSED) {
      return Octicons.issue_closed;
    } else if (state == GPullRequestState.OPEN ||
        state == GPullRequestState.CLOSED) {
      return Octicons.git_pull_request;
    } else if (state == GPullRequestState.MERGED) {
      return Octicons.git_merge;
    } else {
      throw UnimplementedError();
    }
  }

  Color get color {
    if (state == GIssueState.CLOSED || state == GPullRequestState.CLOSED) {
      return Colors.red;
    } else if (isDraft) {
      return Colors.grey;
    } else if (state == GIssueState.OPEN || state == GPullRequestState.OPEN) {
      return Colors.green;
    } else if (state == GPullRequestState.MERGED) {
      return Colors.deepPurple;
    } else {
      throw UnimplementedError();
    }
  }

  String get text {
    if (state == GIssueState.CLOSED || state == GPullRequestState.CLOSED) {
      return 'Closed';
    } else if (isDraft) {
      return 'Draft';
    } else if (state == GIssueState.OPEN || state == GPullRequestState.OPEN) {
      return 'Open';
    } else if (state == GPullRequestState.MERGED) {
      return 'Merged';
    } else {
      throw UnimplementedError();
    }
  }
}

class _AssigneeInfoCard extends StatelessWidget {
  const _AssigneeInfoCard({
    required this.availableList,
    required this.titleBuilder,
    required this.fetchActorsList,
    this.onTap,
    this.trailing,
  });

  final UnfinishedList<NodeWithPaginationInfo<Gactor>> availableList;
  final String Function(
    UnfinishedList<NodeWithPaginationInfo<Gactor>> availableList,
  ) titleBuilder;
  final ScrollWrapperFuture<NodeWithPaginationInfo<Gactor>> fetchActorsList;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => InfoCard(
        onTap: availableList.limitedAvailableList.isEmpty
            ? null
            : () async {
                if (availableList.totalCount > 1) {
                  await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
                    paginatedListItemBuilder: _paginatedListItemBuilder,
                    paginationFuture: fetchActorsList,
                    title: titleBuilder.call(availableList),
                  ).openSheet(context);
                } else {
                  navigateToProfile(
                    login: availableList.limitedAvailableList.first.node.login,
                    context: context,
                  );
                }
              },
        trailing: _getIcon(availableList.totalCount),
        title: titleBuilder.call(availableList),
        child: _buildChild(),
      );

  Widget _buildChild() => switch (availableList.totalCount) {
        0 => Text(
            'None assigned',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        1 => ProfileTile.login(
            padding: const EdgeInsets.all(4),
            avatarUrl: availableList.limitedAvailableList.first.node.avatarUrl
                .toString(),
            userLogin: availableList.limitedAvailableList.first.node.login,
            disableTap: true,
          ),
        _ => ImageStack.widgets(
            totalCount: availableList.totalCount,
            // backgroundColor: context.palette.secondary,
            // widgetBorderColor: context.palette.secondary,
            // extraCountTextStyle: const TextStyle(
            //     color: context.palette.faded3,
            //     ),
            // widgetRadius: 25,
            widgetBorderColor: Colors.transparent,
            widgetBorderWidth: 0,
            children: availableList.limitedAvailableList
                .map(
                  (final NodeWithPaginationInfo<Gactor> e) =>
                      ProfileTile.avatar(
                    avatarUrl: e.node.avatarUrl.toString(),
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
      };
}

StatelessWidget _buildChild(final UnfinishedList<Gactor> availableList) =>
    switch (availableList.totalCount) {
      0 => Text(
          'No participants',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      1 => ProfileTile.login(
          // padding: EdgeInsets.all(16),
          avatarUrl:
              availableList.limitedAvailableList.first.avatarUrl.toString(),
          userLogin: availableList.limitedAvailableList.first.login,
          disableTap: true,
        ),
      _ => ImageStack.widgets(
          totalCount: availableList.totalCount,
          // backgroundColor: context.palette.secondary,
          // widgetBorderColor: context.palette.secondary,
          extraCountTextStyle: const TextStyle(
              // color: context.palette.faded3,
              ),
          widgetBorderWidth: 0,
          widgetBorderColor: Colors.transparent,
          // widgetRadius: 29,
          children: availableList.limitedAvailableList
              .map(
                (final Gactor e) => ProfileTile.avatar(
                  avatarUrl: e.avatarUrl.toString(),
                  padding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
    };

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
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildListItemChildren(data, context, child),
                  ),
                  // wrapperBuilder: ,
                ),
              ),
            );

Icon? _getIcon(final int listLength) => switch (listLength) {
      0 => null,
      1 => Icon(Icons.adaptive.arrow_forward_rounded),
      _ => const Icon(
          Icons.arrow_drop_down_rounded,
        ),
    };

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

// class ActorMultiListAdapter extends PaginatedInfoCardAdapter<Gactor> {
//   ActorMultiListAdapter({
//     required super.availableList,
//     required this.titleBuilder,
//     required this.fetchActorsList,
//   }) : super(
//           singleItemBehavior: SingleItemConfigForMultiListAdapter(
//             onTap: (final BuildContext context) => () => navigateToProfile(
//                   login: availableList.limitedAvailableList.first.login,
//                   context: context,
//                 ),
//             icon: null,
//           ),
//         );
//   final String Function(MultiItemInfoCardList<Gactor> availableList)
//       titleBuilder;
//   final ScrollWrapperFuture<NodeWithPaginationInfo<Gactor>> fetchActorsList;
//
//   @override
//   BottomSheetPagination<NodeWithPaginationInfo<Gactor>>
//       get paginatedSheet =>
//           BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
//             paginatedListItemBuilder: paginatedListItemBuilder,
//             paginationFuture: fetchActorsList,
//             title: title,
//           );
//
//   @override
//   bool get isExpanded => false;
//
//   @override
//   WidgetBuilder get viewBuilder => switch (listLength) {
//         0 => (final BuildContext context) => const Text('None'),
//         1 => (final BuildContext context) => ProfileTile.login(
//               padding: EdgeInsets.zero,
//               avatarUrl: items.first.avatarUrl.toString(),
//               userLogin: items.first.login,
//               disableTap: true,
//             ),
//         _ => (final BuildContext context) => ImageStack.widgets(
//               totalCount: availableList.totalCount,
//               backgroundColor: context.palette.secondary,
//               widgetBorderColor: context.palette.secondary,
//               extraCountTextStyle: TextStyle(
//                 color: context.palette.faded3,
//               ),
//               widgetRadius: 29,
//               children: items
//                   .map(
//                     (final Gactor e) => ProfileTile.avatar(
//                       avatarUrl: e.avatarUrl.toString(),
//                       padding: EdgeInsets.zero,
//                     ),
//                   )
//                   .toList(),
//             ),
//       };
//
//   @override
//   String get title => titleBuilder.call(availableList);
// }
