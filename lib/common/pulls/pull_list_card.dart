import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A widget that displays a pull request card using the nested card layout,
/// similar to the nested issue card.
class PullListCard extends StatelessWidget {
  const PullListCard(
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

    return InkPot(
      onTap: () async {
        if (item.url != null) {
          await AutoRouter.of(context)
              .push(issuePullScreenRoute(PathData.fromURL(item.url!)));
        }
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _getPullIconColor(context, item.state, item.mergedAt)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _getPullIcon(item.state, item.mergedAt),
                    size: 12,
                    color:
                        _getPullIconColor(context, item.state, item.mergedAt),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${item.number}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getPullIconColor(
                              context, item.state, item.mergedAt),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              // Creator
              SizedBox(width: 4),
              if (item.user?.login != null) ...[
                Text(
                  item.user!.login ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.75),
                        fontSize: 11,
                      ),
                ),
                if (item.comments != null && item.comments! > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      size: 11,
                      color: context.colorScheme.onSurfaceVariant
                          .withOpacity(0.75),
                    ),
                    const SizedBox(width: 2),
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
          ],
        ),
        trailing: Text(
          getDate(
            item.state == IssueState.CLOSED
                ? (item.mergedAt ?? item.closedAt)?.toString() ??
                    item.createdAt?.toString() ??
                    ''
                : item.createdAt?.toString() ?? '',
            shorten: true,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Pull request title
            Text(
              item.title ?? '',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                    height: 1.3,
                  ),
            ),
            // Labels
            if (item.labels != null && item.labels!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List<Widget>.generate(
                  item.labels!.length,
                  (final int index) => IssueLabel(item.labels![index]),
                ),
              ),
            ],
            // Metadata: creator, comments (only if showRepoName is true)
            if (showRepoName) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Creator
                  if (item.user?.login != null) ...[
                    Text(
                      '${item.user!.login}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.75),
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
                        const SizedBox(width: 2),
                        Text(
                          '${item.comments}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
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
