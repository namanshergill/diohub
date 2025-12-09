import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/pulls/pull_list_card.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/services/pulls/pulls_service.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PullLoadingCard extends StatelessWidget {
  const PullLoadingCard(
    this.url, {
    this.compact = false,
    this.issueModel,
    // this.disableMaterial = false,
    super.key,
  });

  final String url;
  final bool compact;
  final IssueModel? issueModel;

  // final bool disableMaterial;

  @override
  Widget build(final BuildContext context) =>
      APIWrapper<PullRequestModel>.deferred(
        apiCall: ({required final bool refresh}) async =>
            PullsService.getPullInformation(fullUrl: url, refresh: refresh),
        loadingBuilder: (final BuildContext context) {
          if (issueModel != null) {
            // Extract repo name from URL
            final String? repoName = issueModel!.url != null
                ? issueModel!.url!
                    .replaceAll('https://api.github.com/repos/', '')
                    .split('/')
                    .sublist(0, 2)
                    .join('/')
                : null;

            final bool showRepoName = !compact;

            return InkPot(
              onTap: () async {
                await AutoRouter.of(context).push(
                  issuePullScreenRoute(PathData.fromURL(issueModel!.url!)),
                );
              },
              child: HeaderCard(
                header: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Pull request icon in colored container with PR number
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      height: 24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getPullIconColor(context, issueModel!.state, null)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            _getPullIcon(issueModel!.state, null),
                            size: 12,
                            color: _getPullIconColor(
                                context, issueModel!.state, null),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${issueModel!.number}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getPullIconColor(
                                          context, issueModel!.state, null),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    // Repo name (only if showRepoName is true)
                    if (showRepoName && repoName != null) ...[
                      Flexible(
                        child: Text(
                          repoName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    // Author and Comments (only if showRepoName is false)
                    if (!showRepoName) ...[
                      SizedBox(width: 4),
                      if (issueModel!.user?.login != null) ...[
                        Text(
                          issueModel!.user!.login ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
                                        .withOpacity(0.75),
                                    fontSize: 11,
                                  ),
                        ),
                        if (issueModel!.comments != null &&
                            issueModel!.comments! > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 1,
                              height: 12,
                              color: context.colorScheme.onSurfaceVariant
                                  .withOpacity(0.2),
                            ),
                          ),
                      ],
                      // Comments
                      if (issueModel!.comments != null &&
                          issueModel!.comments! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Octicons.comment,
                              size: 11,
                              color: context.colorScheme.onSurfaceVariant
                                  .withOpacity(0.75),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${issueModel!.comments}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
                                        .withOpacity(0.75),
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
                trailing: Text(
                  getDate(
                    issueModel!.state == IssueState.CLOSED
                        ? issueModel!.closedAt?.toString() ??
                            issueModel!.createdAt?.toString() ??
                            ''
                        : issueModel!.createdAt?.toString() ?? '',
                    shorten: true,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                        fontSize: 10,
                      ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Pull request title
                    Text(
                      issueModel!.title ?? '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                            height: 1.3,
                          ),
                    ),
                    // Shimmer for labels/metadata
                    if (!compact) ...[
                      const SizedBox(height: 5),
                      ShimmerWidget.container(),
                    ],
                    // Metadata: creator, comments (only if showRepoName is true)
                    if (showRepoName) ...[
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // Creator
                          if (issueModel!.user?.login != null) ...[
                            Text(
                              '${issueModel!.user!.login}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
                                        .withOpacity(0.75),
                                  ),
                            ),
                          ],
                          // Comments
                          if (issueModel!.comments != null &&
                              issueModel!.comments! > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Octicons.comment,
                                  size: 13,
                                  color: context.colorScheme.onSurfaceVariant
                                      .withOpacity(0.75),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${issueModel!.comments}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: context
                                            .colorScheme.onSurfaceVariant
                                            .withOpacity(0.75),
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return const SizedBox(
            height: 80,
            child: Center(
              child: LoadingIndicator(),
            ),
          );
        },
        builder: (final BuildContext context, final PullRequestModel data) =>
            PullListCard(
          data,
          showRepoName: !compact,
        ),
      );

  IconData _getPullIcon(IssueState? state, DateTime? mergedAt) {
    if (state == IssueState.CLOSED && mergedAt != null) {
      return Octicons.git_merge;
    }
    return Octicons.git_pull_request;
  }

  Color _getPullIconColor(
      BuildContext context, IssueState? state, DateTime? mergedAt) {
    if (state == IssueState.CLOSED) {
      if (mergedAt != null) {
        return const Color(0xFF9C27B0); // Purple for merged
      } else {
        return const Color(0xFFF44336); // Red for closed
      }
    }
    // OPEN or REOPENED
    return const Color(0xFF4CAF50); // Green
  }
}
