import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/pulls/pull_loading_card.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart' hide State;
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class IssueListCard extends StatelessWidget {
  const IssueListCard(
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
    if (item.pullRequest != null) {
      return PullLoadingCard(
        item.pullRequest!.url!,
        issueModel: item,
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

    // Title-first hierarchy: Title first, then context, then metadata
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Issue title (most prominent - first)
        Text(
          item.title!,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
                height: 1.3,
              ),
        ),
        // Context row: Repo name + Issue number + State icon (grouped together)
        // OR Author + Comments (when showRepoName is false)
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
            // Issue number and state icon
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                getIcon(item.state!),
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
            // Date
            Text(
              getDate(
                item.state == IssueState.CLOSED
                    ? item.closedAt.toString()
                    : item.createdAt.toString(),
                shorten: true,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
            ),
          ],
        ),
        // Labels (moved up in hierarchy)
        if (item.labels!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List<Widget>.generate(
              item.labels!.length,
              (final int index) => IssueLabel(item.labels![index]),
            ),
          ),
        ],
        // Metadata row: creator, comments (only if showRepoName is true)
        if (showRepoName) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // Creator
              if (item.user?.login != null) ...[
                Text(
                  item.user!.login ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.75),
                      ),
                ),
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
          ),
        ],
      ],
    );

    return InkPot(
      onTap: () async {
        await AutoRouter.of(context)
            .push(issuePullScreenRoute(PathData.fromURL(item.url!)));
      },
      child: content,
    );
  }
}

Widget getIcon(final IssueState state) => switch (state) {
      IssueState.CLOSED => const Icon(
          Octicons.issue_closed,
          size: 15,
          color: Colors.red,
        ),
      IssueState.OPEN => const Icon(
          Octicons.issue_opened,
          size: 15,
          color: Colors.green,
        ),
      IssueState.REOPENED => const Icon(
          Octicons.issue_reopened,
          size: 15,
          color: Colors.green,
        ),
    };

class IssueLoadingCard extends StatelessWidget {
  const IssueLoadingCard(
    this.url, {
    this.padding = const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
    super.key,
  });

  final String url;
  final EdgeInsets padding;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: padding,
        child: APIWrapper<IssueModel>.deferred(
          apiCall: ({required final bool refresh}) async =>
              IssuesService.getIssueInfo(fullUrl: url, refresh: refresh),
          builder: (final BuildContext context, final IssueModel data) =>
              IssueListCard(
            data,
          ),
          loadingBuilder: (final BuildContext context) => const SizedBox(
            height: 80,
            child: Center(child: LoadingIndicator()),
          ),
        ),
      );
}
