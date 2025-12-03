import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/view/issues_pulls/issue_pull_info_template.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_changed_files_list.dart';
import 'package:diohub/view/issues_pulls/widgets/pulls_commits_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PullScreen extends StatefulWidget {
  const PullScreen(
    this.pullInfo, {
    this.initialIndex = 0,
    this.commentsSince,
    super.key,
    required this.onRefresh,
  });

  final GpullInfo pullInfo;
  final DateTime? commentsSince;
  final int initialIndex;
  final Future<void> Function() onRefresh;

  @override
  PullScreenState createState() => PullScreenState();
}

class PullScreenState extends State<PullScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    tabController = TabController(
      length: 4,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    super.initState();
  }

  final GlobalKey<IssuePullInfoTemplateState> _templateKey =
      GlobalKey<IssuePullInfoTemplateState>();

  @override
  Widget build(final BuildContext context) {
    final GpullInfo data = widget.pullInfo;
    return IssuePullInfoTemplate(
      key: _templateKey,
      number: data.number,
      isPinned: false,
      title: data.titleHTML,
      reactionGroups: data.reactionGroups!.toList(),
      viewerCanReact: data.viewerCanReact,
      commentCount: data.comments.totalCount,
      repoInfo: data.repository,
      state: IssuePullState(data.state),
      bodyHTML: data.bodyHTML,
      assigneesInfo: data.assignees,
      body: data.body,
      labels: data.labels!.nodes!.toList(),
      createdAt: data.createdAt,
      createdBy: data.author,
      participantsInfo: UnfinishedList<Gactor>(
        limitedAvailableList: data.participants.nodes!
            .map((final GpullInfo_participants_nodes? e) => e!)
            .toList(),
        totalCount: data.participants.totalCount,
      ),
      dynamicTabs: <DynamicTab>[
        DynamicTab(
          identifier: 'files_changed',
          tabViewBuilder: (final BuildContext context) =>
              const PullChangedFilesList(),
        ),
        DynamicTab(
          identifier: 'commits',
          tabViewBuilder: (final BuildContext context) =>
              const PullsCommitsList(),
        ),
      ],
      uri: data.url,
      onRefresh: widget.onRefresh,
      additionalDetailTiles: [
        // Commits
        DetailTile(
          title: 'Commits',
          icon: Octicons.git_commit,
          onTap: () {
            _templateKey.currentState?.dynamicTabsController.openTab('commits');
          },
          child: DetailTileCount(
            data.commits.totalCount,
            'commit',
            'commits',
          ),
        ),
        // Files changed
        DetailTile(
          title: 'Files changed',
          icon: Octicons.file_diff,
          onTap: () {
            _templateKey.currentState?.dynamicTabsController
                .openTab('files_changed');
          },
          child: DetailTileCount(
            data.changedFiles,
            'file',
            'files',
          ),
        ),
        // Merged date (if merged)
        if (data.merged)
          DetailTile(
            title: 'Merged',
            icon: Octicons.git_merge,
            child: DetailTileText(
              getDate(data.mergedAt.toString(), shorten: false),
              color: Colors.deepPurple,
            ),
          ),
      ],
    );
  }

}
