import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/pulls/pull_loading_card.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/http_to_api.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/basic_event_card.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:diohub/view/repository/code/commit_browser_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PaddingWrap extends StatelessWidget {
  const PaddingWrap({
    required this.child,
    super.key,
  });

  final Widget child;

  // final double? elevation;
  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: child,
      );
}

class TimelineItem extends StatelessWidget {
  const TimelineItem(
    this.timelineItem, {
    required this.onQuote,
    super.key,
    this.pullNodeID,
  });

  final dynamic timelineItem;
  final String? pullNodeID;
  final VoidCallback onQuote;

  String getReviewState(final GPullRequestReviewState state) => switch (state) {
        GPullRequestReviewState.APPROVED => 'Approved this.',
        GPullRequestReviewState.CHANGES_REQUESTED => 'Requested Changes.',
        GPullRequestReviewState.COMMENTED => 'Reviewed this.',
        GPullRequestReviewState.DISMISSED => 'Dismissed this.',
        GPullRequestReviewState.PENDING => 'Review Pending.',
        GPullRequestReviewState() => throw UnimplementedError(),
      };

  @override
  Widget build(final BuildContext context) {
    final dynamic item = timelineItem;
    Widget child = switch (item) {
      final Gassigned item => _buildBasicEventAssignedCard(item),
      final GbaseRefChanged item => _buildBaseRefChangedCard(item),
      final GbaseRefDeleted item => _buildRefDeletedCard(item),
      final GbaseRefForcePushed item => _buildForcePushedCard(item),
      final Gclosed item => _buildClosedCard(item),
      final GconvertedToDraft item => _buildConvertedToDraftCard(item),
      final GcrossReference item => _buildCrossReferenceCard(item),
      final GdeMileStoned item => _buildDemilestonedCard(item),
      final GheadRefDeleted item => _buildHeadRefDeletedCard(item),
      final GheadRefForcePushed item => _buildHeadRefForcePushedCard(item),
      final GheadRefRestored item => _buildHeadRefRestoredCard(item),
      final GissueComment item => _buildBaseComment(item),
      final Glabeled item => _buildLabeledItem(item),
      final Glocked item => _buildLockedCard(item),
      final GmarkedAsDuplicate item => _buildMarkedAsDuplicateCard(item),
      final Gmerged item => _buildMergedCard(item),
      final GmileStoned item => _buildMilestonedCard(item),
      final Gpinned item => _buildPinned(item),
      final GpullRequestCommit item => _buildPullRequestCommitCard(item),
      final GpullRequestReview item =>
        _buildPullRequestReviewCard(item, context),
      final GreadyForReview item => _buildReadForReviewCard(item),
      final GrenamedTitle item => _buildRenamedTitleCard(item, context),
      final Greopened item => _buildReopenedCard(item),
      final GgetTimelineData_repository_issueOrPullRequest__asPullRequest_timelineItems_edges_node__asReviewRequestedEvent
        item =>
        _buildReviewRequestedCard(item),
      final Gunassigned item => _buildUnassignedCard(item),
      final Gunlabeled item => _buildUnlabeledCard(item),
      final Gunlocked item => _buildUnlockedCard(item),
      final GunmarkedAsDuplicate item => _buildUnmarkedAsDuplicateCard(item),
      final Gunpinned item => _buildUnpinnedCard(item),
      _ => const Text('Unimplemented.'),
    };

    if (item is! GissueComment) {
      child = Card(
        margin: EdgeInsets.zero,
        elevation: 0.7,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      );
    }

    return PaddingWrap(child: child);
  }

  BasicEventTextCard _buildUnpinnedCard(final Gunpinned item) =>
      BasicEventTextCard(
        user: item.actor,
        leading: const Icon(MdiIcons.pinOff),
        date: item.createdAt,
        textContent: 'Unpinned this.',
      );

  BasicEventTextCard _buildUnmarkedAsDuplicateCard(
    final GunmarkedAsDuplicate item,
  ) =>
      BasicEventTextCard(
        textContent: 'Marked this as not a duplicate of',
        footer: switch (item) {
          final GunmarkedAsDuplicate_canonical__asIssue item =>
            IssueLoadingCard(
              toRepoAPIResource(
                item.url.toString(),
              ),
              padding: EdgeInsets.zero,
            ),
          final GunmarkedAsDuplicate_canonical__asPullRequest item =>
            PullLoadingCard(
              toRepoAPIResource(
                item.url.toString(),
                isPull: true,
              ),
              compact: true,
            ),
          GunmarkedAsDuplicate() => null,
        },
        user: item.actor,
        leading: const Icon(Octicons.link_external),
        date: item.createdAt,
      );

  BasicEventTextCard _buildUnlockedCard(final Gunlocked item) =>
      BasicEventTextCard(
        textContent: 'Unlocked this.',
        user: item.actor,
        date: item.createdAt,
        leading: const Icon(MdiIcons.lockOff),
      );

  BasicEventLabeledCard _buildUnlabeledCard(final Gunlabeled item) =>
      BasicEventLabeledCard(
        actor: item.actor,
        content: item.label,
        added: false,
        date: item.createdAt,
      );

  BasicEventAssignedCard _buildUnassignedCard(final Gunassigned item) =>
      BasicEventAssignedCard(
        actor: item.actor,
        assignee: item.assignee as Gactor?,
        createdAt: item.createdAt,
        isAssigned: false,
      );

  BasicEventCard _buildReviewRequestedCard(
      final GgetTimelineData_repository_issueOrPullRequest__asPullRequest_timelineItems_edges_node__asReviewRequestedEvent
          item) {
    print(item
        is GgetTimelineData_repository_issueOrPullRequest__asPullRequest_timelineItems_edges_node__asReviewRequestedEvent);
    print(item.requestedReviewer.runtimeType);
    return BasicEventCard(
      user: item.actor,
      date: item.createdAt,
      leading: const Icon(Icons.remove_red_eye_rounded),
      content: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Requested a review from'),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ProfileTile.login(
              avatarUrl: item.requestedReviewer!.when<String>(
                user: actorAvatarStringUri,
                team: (final p0) => p0.avatar.toString(),
                orElse: unimplementedString,
              ),
              size: 20,
              padding: EdgeInsets.zero,
              // textStyle: cont,
              userLogin: item.requestedReviewer!.when<String>(
                user: actorLogin,
                team: (
                  final p0,
                ) =>
                    p0.name,
                orElse: unimplementedString,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BasicEventTextCard _buildReopenedCard(final Greopened item) =>
      BasicEventTextCard(
        textContent: 'Reopened this.',
        user: item.actor,
        leading: const Icon(Octicons.issue_reopened, color: Colors.green),
        date: item.createdAt,
      );

  BasicEventCard _buildRenamedTitleCard(
    final GrenamedTitle item,
    final BuildContext context,
  ) =>
      BasicEventCard(
        user: item.actor,
        leading: const Icon(Octicons.pencil),
        date: item.createdAt,
        content: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(text: 'Renamed this.\n'),
              TextSpan(
                text: '${item.previousTitle}\n',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              TextSpan(text: item.currentTitle),
            ],
          ),
          // style: Theme.of(context).textTheme.b,
        ),
      );

  BasicEventTextCard _buildReadForReviewCard(final GreadyForReview item) =>
      BasicEventTextCard(
        user: item.actor,
        date: item.createdAt,
        leading: const Icon(Icons.mark_chat_read_rounded),
        textContent: 'Marked this as ready for review.',
      );

  BaseComment _buildPullRequestReviewCard(
    final GpullRequestReview item,
    final BuildContext context,
  ) =>
      BaseComment(
        resourceUri: Uri.parse('asdhbj'),
        description: getReviewState(item.state),
        onQuote: onQuote,
        leading: Icons.remove_red_eye_rounded,
        isMinimized: false,
        reactions: item.reactionGroups!.toList(),
        viewerCanDelete: item.viewerCanDelete,
        viewerCanMinimize: false,
        viewerCannotUpdateReasons: item.viewerCannotUpdateReasons.toList(),
        viewerCanReact: item.viewerCanReact,
        viewerCanUpdate: item.viewerCanUpdate,
        viewerDidAuthor: item.viewerDidAuthor,
        author: item.author,
        authorAssociation: item.authorAssociation,
        body: item.body,
        bodyHTML: item.bodyHTML,
        createdAt: item.createdAt,
        lastEditedAt: item.lastEditedAt,
        footer: item.comments.totalCount > 0
            ? StringButton(
                onTap: () async {
                  await AutoRouter.of(context).push(
                    PRReviewRoute(
                      nodeID: item.id,
                      pullNodeID: pullNodeID!,
                    ),
                  );
                },
                title: '${item.comments.totalCount} Comments',
                // color: Provider.of<PaletteSettings>(context)
                //     .currentSetting
                //     .primary,
                trailingIcon: const Icon(Icons.arrow_right_rounded),
              )
            : null,
      );

  BasicEventTextCard _buildPullRequestCommitCard(
    final GpullRequestCommit item,
  ) =>
      BasicEventTextCard(
        user: item.commit.author?.user,
        date: item.commit.authoredDate,
        leading: const Icon(Octicons.git_commit),
        footer: CommitTilesGQL(
          item: item.commit,
          // backgroundColor: Provider.of<PaletteSettings>(context)
          //     .currentSetting
          //     .primary,
        ),
        textContent: 'Made a commit.',
      );

  BasicEventTextCard _buildPinned(final Gpinned item) => BasicEventTextCard(
        user: item.actor,
        leading: const Icon(MdiIcons.pin),
        date: item.createdAt,
        textContent: 'Pinned this.',
      );

  BasicEventTextCard _buildMilestonedCard(final GmileStoned item) =>
      BasicEventTextCard(
        textContent: 'Added this to milestone ${item.milestoneTitle}.',
        user: item.actor,
        leading: const Icon(Icons.delete_rounded),
        date: item.createdAt,
      );

  BasicEventTextCard _buildMergedCard(final Gmerged item) => BasicEventTextCard(
        user: item.actor,
        date: item.createdAt,

        leading: const Icon(Octicons.git_merge, color: Colors.green),
        // iconColor: deepPurple,
        textContent: 'Merged this.',
      );

  BasicEventTextCard _buildMarkedAsDuplicateCard(
    final GmarkedAsDuplicate item,
  ) =>
      BasicEventTextCard(
        textContent: 'Marked this as a duplicate of',
        footer: Builder(
          builder: (final BuildContext context) => item.canonical!.when(
            issue: (final GmarkedAsDuplicate_canonical__asIssue p0) =>
                IssueLoadingCard(
              toRepoAPIResource(
                p0.url.toString(),
              ),
              padding: EdgeInsets.zero,
            ),
            pullRequest:
                (final GmarkedAsDuplicate_canonical__asPullRequest p0) =>
                    PullLoadingCard(
              toRepoAPIResource(
                p0.url.toString(),
                isPull: true,
              ),
              compact: true,
            ),
            orElse: unimplemented,
          ),
        ),
        user: item.actor,
        leading: const Icon(Octicons.link_external),
        date: item.createdAt,
      );

  BasicEventTextCard _buildLockedCard(final Glocked item) => BasicEventTextCard(
        textContent:
            'Locked this ${item.lockReason != null ? 'as ${item.lockReason} ' : ''}and limited conversation to collaborators',
        user: item.actor,
        date: item.createdAt,
        leading: const Icon(MdiIcons.lock),
      );

  BasicEventLabeledCard _buildLabeledItem(final Glabeled item) =>
      BasicEventLabeledCard(
        actor: item.actor,
        content: item.label,
        added: true,
        date: item.createdAt,
      );

  BasicEventTextCard _buildHeadRefRestoredCard(
    final GheadRefRestored item,
  ) =>
      BasicEventTextCard(
        textContent: 'Restored head ref.',
        user: item.actor,
        leading: const Icon(Icons.delete_rounded),
        date: item.createdAt,
      );

  BasicEventTextCard _buildHeadRefForcePushedCard(
    final GheadRefForcePushed item,
  ) =>
      BasicEventTextCard(
        textContent:
            'Force pushed to head ref ${item.ref?.name}, from ${item.beforeCommit?.abbreviatedOid} to ${item.afterCommit?.abbreviatedOid}.',
        user: item.actor,
        leading: const Icon(Octicons.repo_push),
        date: item.createdAt,
      );

  BasicEventTextCard _buildHeadRefDeletedCard(final GheadRefDeleted item) =>
      BasicEventTextCard(
        textContent: 'Deleted head ref ${item.headRefName}.',
        user: item.actor,
        leading: const Icon(Icons.delete_rounded),
        date: item.createdAt,
      );

  BasicEventTextCard _buildDemilestonedCard(final GdeMileStoned item) =>
      BasicEventTextCard(
        textContent: 'Removed this from milestone ${item.milestoneTitle}.',
        user: item.actor,
        leading: const Icon(Icons.delete_rounded),
        date: item.createdAt,
      );

  BasicEventTextCard _buildConvertedToDraftCard(
    final GconvertedToDraft item,
  ) =>
      BasicEventTextCard(
        textContent: 'Marked this as draft.',
        user: item.actor,
        leading: const Icon(MdiIcons.pencilCircle),
        date: item.createdAt,
      );

  BasicEventTextCard _buildClosedCard(final Gclosed item) => BasicEventTextCard(
        textContent: 'Closed this.',
        user: item.actor,
        leading: const Icon(
          Octicons.issue_closed,
          color: Colors.red,
        ),
        date: item.createdAt,
      );

  BasicEventTextCard _buildForcePushedCard(
    final GbaseRefForcePushed item,
  ) =>
      BasicEventTextCard(
        textContent:
            'Force pushed to base ref ${item.ref?.name}, from ${item.beforeCommit?.abbreviatedOid} to ${item.afterCommit?.abbreviatedOid}.',
        user: item.actor,
        leading: const Icon(Octicons.repo_push),
        date: item.createdAt,
      );

  BasicEventTextCard _buildRefDeletedCard(final GbaseRefDeleted item) =>
      BasicEventTextCard(
        textContent: 'Deleted base ref ${item.baseRefName}.',
        user: item.actor,
        leading: const Icon(Octicons.repo_push),
        date: item.createdAt,
      );

  BasicEventTextCard _buildBaseRefChangedCard(final GbaseRefChanged item) =>
      BasicEventTextCard(
        textContent:
            'Changed base ref from ${item.previousRefName} to ${item.currentRefName}.',
        user: item.actor,
        leading: const Icon(Octicons.repo_push),
        date: item.createdAt,
      );

  BasicEventAssignedCard _buildBasicEventAssignedCard(
    final Gassigned item,
  ) =>
      BasicEventAssignedCard(
        actor: item.actor,
        assignee: item.assignee as Gactor?,
        createdAt: item.createdAt,
        isAssigned: true,
      );

  BaseComment _buildBaseComment(final GissueComment item) => BaseComment(
        isMinimized: item.isMinimized,
        onQuote: onQuote,
        resourceUri: item.url,
        reactions: item.reactionGroups!.toList(),
        minimizedReason: item.minimizedReason,
        viewerCanDelete: item.viewerCanDelete,
        viewerCanMinimize: item.viewerCanMinimize,
        viewerCannotUpdateReasons: item.viewerCannotUpdateReasons.toList(),
        viewerCanReact: item.viewerCanReact,
        viewerCanUpdate: item.viewerCanUpdate,
        viewerDidAuthor: item.viewerDidAuthor,
        author: item.author,
        authorAssociation: item.authorAssociation,
        body: item.body,
        bodyHTML: item.bodyHTML,
        createdAt: item.createdAt,
        lastEditedAt: item.lastEditedAt,
      );

  BasicEventTextCard _buildCrossReferenceCard(final GcrossReference item) {
    {
      // TODO(ns): Change after fixed- https://github.com/gql-dart/ferry/issues/543
      String str;
      final String repoNameWithOwner =
          (item.source as dynamic).repository.nameWithOwner;
      str = item.isCrossRepository
          ? 'Referenced this in $repoNameWithOwner.'
          : 'Referenced this.';

      return BasicEventTextCard(
        textContent: str,
        footer: Builder(
          builder: (final BuildContext context) =>
              switch (item.source.G__typename) {
            'Issue' => IssueLoadingCard(
                toRepoAPIResource((item.source as dynamic).url.toString()),
                padding: EdgeInsets.zero,
              ),
            'PullRequest' => PullLoadingCard(
                toRepoAPIResource(
                  (item.source as dynamic).url.toString(),
                  isPull: true,
                ),
                compact: true,
              ),
            _ => unimplemented(),
          },
        ),
        user: item.actor,
        leading: const Icon(Octicons.link_external),
        date: item.createdAt,
      );
    }
  }
}
