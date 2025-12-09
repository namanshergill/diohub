import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/pulls/pull_loading_card.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A widget that displays an issue card using the nested card layout,
/// similar to the event cards in the feed.
class NestedIssueCard extends StatelessWidget {
  const NestedIssueCard(
    this.item, {
    this.showRepoName = true,
    this.commentsSince,
    super.key,
  });

  final IssueModel item;
  final DateTime? commentsSince;
  final bool showRepoName;

  @override
  Widget build(final BuildContext context) {
    if (item.pullRequest != null && item.pullRequest!.url != null) {
      return PullLoadingCard(
        item.pullRequest!.url!,
        issueModel: item,
        compact: !showRepoName,
      );
    }

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
        await AutoRouter.of(context)
            .push(issuePullScreenRoute(PathData.fromURL(item.url!)));
      },
      child: HeaderCard(
        header: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Issue icon in colored container with issue number
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _getIssueIconColor(context, item.state!).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _getIssueIcon(item.state!),
                    size: 12,
                    color: _getIssueIconColor(context, item.state!),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${item.number}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getIssueIconColor(context, item.state!),
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
                if (item.comments != 0)
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
              if (item.comments != 0)
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
                ? item.closedAt.toString()
                : item.createdAt.toString(),
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
            // Issue title
            Text(
              item.title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                    height: 1.3,
                  ),
            ),
            // Labels
            if (item.labels!.isNotEmpty) ...[
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
                  if (item.comments != 0)
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

  IconData _getIssueIcon(IssueState state) {
    switch (state) {
      case IssueState.CLOSED:
        return Octicons.issue_closed;
      case IssueState.OPEN:
        return Octicons.issue_opened;
      case IssueState.REOPENED:
        return Octicons.issue_reopened;
    }
  }

  Color _getIssueIconColor(BuildContext context, IssueState state) {
    switch (state) {
      case IssueState.CLOSED:
        return const Color(0xFFF44336); // Red
      case IssueState.OPEN:
      case IssueState.REOPENED:
        return const Color(0xFF4CAF50); // Green
    }
  }
}
