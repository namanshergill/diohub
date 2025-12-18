import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/services/pulls/pulls_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class SimplePullCard extends StatelessWidget {
  const SimplePullCard(
    this.item, {
    this.showRepoName = true,
    super.key,
  });

  final PullRequestModel item;
  final bool showRepoName;

  @override
  Widget build(final BuildContext context) {
    // Extract repo name from URL
    final String? repoName = item.url != null
        ? item.url!
            .replaceAll('https://api.github.com/repos/', '')
            .split('/')
            .sublist(0, 2)
            .join('/')
        : null;

    // Title-first hierarchy: Title first, then context, then metadata
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Pull request title (most prominent - first)
        Text(
          item.title ?? '',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
                height: 1.3,
              ),
        ),
        // Context row: Repo name + PR number + State icon (grouped together)
        // OR Author + Comments (when showRepoName is false)
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Repo name (only if showRepoName is true)
            if (showRepoName && repoName != null)
              Text(
                repoName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            // Author and Comments (only if showRepoName is false)
            if (!showRepoName) ...[
              // Creator
              if (item.user?.login != null) ...[
                Text(
                  item.user!.login ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.75),
                      ),
                ),
                if (item.comments != null && item.comments! > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 1,
                      height: 12,
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.2),
                    ),
                  ),
              ],
              // Comments
              if (item.comments != null && item.comments! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Octicons.comment,
                      size: 13,
                      color: context.colorScheme.onSurfaceVariant
                          .withOpacity(0.75),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.comments}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.75),
                          ),
                    ),
                  ],
                ),
            ],
            // Pull request number and state icon
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Opacity(
                  opacity: 0.6,
                  child: _getPullIcon(item.state, item.mergedAt),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.number}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            // Comments
            if (item.comments != null && item.comments! > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Octicons.comment,
                    size: 13,
                    color:
                        context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.comments}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    return InkPot(
      onTap: () async {
        if (item.url != null) {
          await AutoRouter.of(context)
              .push(issuePullScreenRoute(PathData.fromURL(item.url!)));
        }
      },
      child: SizedBox(
        width: double.infinity,
        child: content,
      ),
    );
  }

  Widget _getPullIcon(IssueState? state, DateTime? mergedAt) {
    if (state == IssueState.CLOSED && mergedAt != null) {
      return const Icon(
        Octicons.git_merge,
        size: 14,
        color: Color(0xFF9C27B0), // Purple for merged
      );
    } else if (state == IssueState.CLOSED) {
      return const Icon(
        Octicons.git_pull_request,
        size: 14,
        color: Color(0xFFF44336), // Red for closed
      );
    }
    return const Icon(
      Octicons.git_pull_request,
      size: 14,
      color: Color(0xFF4CAF50), // Green for open
    );
  }
}

class SimplePullLoadingCard extends StatelessWidget {
  const SimplePullLoadingCard(
    this.url, {
    this.padding = const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
    this.showRepoName = true,
    super.key,
  });

  final String url;
  final EdgeInsets padding;
  final bool showRepoName;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: padding,
        child: APIWrapper<PullRequestModel>.deferred(
          apiCall: ({required final bool refresh}) async =>
              PullsService.getPullInformation(fullUrl: url, refresh: refresh),
          builder: (final BuildContext context, final PullRequestModel data) =>
              SimplePullCard(
            data,
            showRepoName: showRepoName,
          ),
          loadingBuilder: (final BuildContext context) => SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title shimmer
                ShimmerWidget.container(
                  height: 18,
                  width: double.infinity,
                ),
                const SizedBox(height: 10),
                // Context row shimmer (repo + number + comments)
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: <Widget>[
                    if (showRepoName) ...[
                      ShimmerWidget.container(
                        height: 14,
                        width: 120,
                      ),
                    ],
                    ShimmerWidget.container(
                      height: 14,
                      width: 40,
                    ),
                    ShimmerWidget.container(
                      height: 14,
                      width: 35,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
