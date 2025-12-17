import 'package:auto_route/annotations.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/link_text.dart';
import 'package:diohub/common/misc/patch_viewer.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/pr_review_comment.data.gql.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/pulls/pulls_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/comment_box.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PRReviewScreen extends StatelessWidget {
  const PRReviewScreen(this.nodeID, {required this.pullNodeID, super.key});

  final String nodeID;
  final String pullNodeID;

  @override
  Widget build(final BuildContext context) => SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Review'),
          ),
          // Check if user has pending reviews to disable reply button accordingly.
          // See https://github.com/NamanShergill/diohub/issues/18 for info.
          body: APIWrapper<bool>.deferred(
            apiCall: ({required final bool refresh}) async =>
                PullsService.hasPendingReviews(
              pullNodeID,
              context.read<CurrentUserProvider>().data.login!,
            ),
            builder: (
              final BuildContext context,
              final bool repliesEnabled,
            ) =>
                InfiniteScrollWrapper<GPRReviewComments_comments_edges?>(
              future: (
                data,
              ) async =>
                  PullsService.getPRReview(
                nodeID,
                refresh: data.refresh,
                cursor: data.lastItem?.cursor,
              ),
              separatorBuilder: (final BuildContext context, final int index) =>
                  const Divider(
                height: 32,
              ),
              builder: (
                final BuildContext context,
                final data,
              ) {
                final GPRReviewComments_comments_edges_node comment =
                    data.item!.node!;
                return ChangeNotifierProvider<CommentProvider>(
                  create: (final _) => CommentProvider(),
                  builder: (final BuildContext context, final Widget? child) {
                    Future<void> openCommentSheet() async {
                      await showCommentSheet(
                        context,
                        onSubmit: () async {
                          await PullsService.replyToReviewComment(
                            context.read<CommentProvider>().data,
                            id: comment.databaseId!,
                            owner: comment.repository.owner.login,
                            repo: comment.repository.name,
                            pullNumber: comment.pullRequest.number,
                          );
                          if (context.mounted) {
                            context.read<CommentProvider>().clearData();
                          }
                          return;
                        },
                        type: 'Reply',
                        initialData: context.read<CommentProvider>().data,
                        onChanged: (final String value) {
                          Provider.of<CommentProvider>(context, listen: false)
                              .updateData(value);
                        },
                        owner: comment.repository.owner.login,
                        repoName: comment.repository.name,
                      );
                    }

                    Widget replyButton({
                      required final bool repliesEnabled,
                    }) =>
                        Row(
                          children: <Widget>[
                            Button(
                              onTap: () async {
                                if (repliesEnabled) {
                                  await showDialog(
                                    context: context,
                                    builder: (final BuildContext context) =>
                                        AlertDialog(
                                      title: Text(
                                        'Cannot reply.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      content: DefaultTextStyle(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!,
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              'Cannot add a reply to other review comments when you have a pending review on the PR.',
                                            ),
                                            LinkText(
                                              'https://github.com/NamanShergill/diohub/issues/18',
                                              text:
                                                  'See this for more information.',
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        MaterialButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Okay'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  await openCommentSheet();
                                }
                              },
                              // color: Provider.of<PaletteSettings>(context)
                              //     .currentSetting
                              //     .primary,
                              stretch: false,
                              child: const Icon(Icons.reply),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                          ],
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Material(
                          color: context.colorScheme.primary,
                          // shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.vertical(
                          //         top: AppThemeBorderRadius.medBorderRadius.topLeft)),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    comment.path,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ).merge(context.textTheme.bodySmall),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        PatchViewer(
                          patch: comment.diffHunk,
                          isWidget: true,
                          limitLines: 4,
                          initLoading: false,
                          fileType: comment.path.split('.').last,
                          waitBeforeLoad: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: BaseComment(
                            resourceUri: Uri.parse('uri'),
                            isMinimized: comment.isMinimized,
                            reactions: comment.reactionGroups!.toList(),
                            viewerCanDelete: comment.viewerCanDelete,
                            viewerCanMinimize: comment.viewerCanMinimize,
                            onQuote: openCommentSheet,
                            viewerCannotUpdateReasons:
                                comment.viewerCannotUpdateReasons.toList(),
                            viewerCanReact: comment.viewerCanReact,
                            viewerCanUpdate: comment.viewerCanUpdate,
                            viewerDidAuthor: comment.viewerDidAuthor,
                            createdAt: comment.createdAt,
                            author: comment.author,
                            body: comment.body,
                            lastEditedAt: comment.lastEditedAt,
                            bodyHTML: comment.bodyHTML,
                            authorAssociation: comment.authorAssociation,
                            footerPadding:
                                const EdgeInsets.only(left: 8, right: 8),
                            footer: APIWrapper<
                                GreviewThreadFirstCommentQueryData_repository_pullRequest_reviewThreads_edges?>.deferred(
                              apiCall: ({required final bool refresh}) async =>
                                  PullsService.getPRReviewThreadID(
                                comment.id,
                                name: comment.repository.name,
                                owner: comment.repository.owner.login,
                                number: comment.pullRequest.number,
                                refresh: refresh,
                                cursor: null,
                              ),
                              loadingBuilder: (final BuildContext context) =>
                                  Row(
                                children: <Widget>[
                                  replyButton(repliesEnabled: repliesEnabled),
                                  const Expanded(
                                    child: StringButton(
                                      onTap: null,
                                      loading: true,
                                      // color:
                                      // Provider.of<PaletteSettings>(context)
                                      //     .currentSetting
                                      //     .primary,
                                      title: 'Replies',
                                      trailingIcon:
                                          Icon(Icons.arrow_right_rounded),
                                    ),
                                  ),
                                ],
                              ),
                              builder: (
                                final BuildContext context,
                                final GreviewThreadFirstCommentQueryData_repository_pullRequest_reviewThreads_edges?
                                    data,
                              ) {
                                if (data != null) {
                                  return Row(
                                    children: <Widget>[
                                      replyButton(
                                        repliesEnabled: repliesEnabled,
                                      ),
                                      _buildRepliesButton(
                                        context,
                                        data,
                                        comment,
                                        openCommentSheet,
                                      ),
                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

  Expanded _buildRepliesButton(
    final BuildContext context,
    final GreviewThreadFirstCommentQueryData_repository_pullRequest_reviewThreads_edges
        edgeData,
    final GPRReviewComments_comments_edges_node comment,
    final void Function() openCommentSheet,
  ) =>
      Expanded(
        child: StringButton(
          key: const ValueKey<String>('loaded'),
          onTap: () async {
            await showScrollableBottomSheet(
              context,
              headerBuilder:
                  (final BuildContext context, final StateSetter setState) =>
                      const BottomSheetHeaderText(
                headerText: 'Replies',
              ),
              scrollableBodyBuilder: (
                final BuildContext context,
                final StateSetter setState,
                final ScrollController scrollController,
              ) =>
                  ListenableProvider<CommentProvider>.value(
                value: Provider.of<CommentProvider>(context),
                builder: (final BuildContext context, final Widget? child) =>
                    InfiniteScrollWrapper<
                        GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges?>(
                  scrollController: scrollController,
                  separatorBuilder:
                      (final BuildContext context, final int index) =>
                          const SizedBox(
                    height: 8,
                  ),
                  future: (
                    final data,
                  ) =>
                      PullsService.getReviewThreadReplies(
                    edgeData.node!.id,
                    data.lastItem?.cursor,
                    refresh: data.refresh,
                  ),
                  filterFn: (
                    final List<
                            GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges?>
                        items,
                  ) {
                    final List<
                            GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges?>
                        temp =
                        <GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges?>[];
                    for (final GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges? item
                        in items) {
                      if (item!.node!.id != comment.id) {
                        temp.add(item);
                      }
                    }
                    return temp;
                  },
                  builder: (
                    final BuildContext context,
                    final data,
                  ) {
                    final GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges_node
                        reply = data.item!.node!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: BaseComment(
                        resourceUri: Uri.parse('uri'),
                        isMinimized: reply.isMinimized,
                        onQuote: () {
                          Navigator.pop(context);
                          openCommentSheet();
                        },
                        reactions: reply.reactionGroups!.toList(),
                        viewerCanDelete: reply.viewerCanDelete,
                        viewerCanMinimize: reply.viewerCanMinimize,
                        viewerCannotUpdateReasons:
                            reply.viewerCannotUpdateReasons.toList(),
                        viewerCanReact: reply.viewerCanReact,
                        viewerCanUpdate: reply.viewerCanUpdate,
                        viewerDidAuthor: reply.viewerDidAuthor,
                        createdAt: reply.createdAt,
                        author: reply.author,
                        body: reply.body,
                        lastEditedAt: reply.lastEditedAt,
                        bodyHTML: reply.bodyHTML,
                        authorAssociation: reply.authorAssociation,
                      ),
                    );
                  },
                ),
              ),
            );
          },
          // color: Provider.of<PaletteSettings>(context).currentSetting.primary,
          title:
              '${edgeData.node!.comments.totalCount > 1 ? (edgeData.node!.comments.totalCount - 1).toString() : 'No'} Replies',
          trailingIcon: edgeData.node!.comments.totalCount > 1
              ? const Icon(Icons.arrow_right_rounded)
              : null,
        ),
      );
}
