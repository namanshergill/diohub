import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/tappable_card.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PullListCard extends StatelessWidget {
  const PullListCard(
    this.item, {
    this.compact = false,
    // this.disableMaterial = false,
    this.showRepoName = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    super.key,
  });

  final PullRequestModel item;
  final bool compact;

  // final bool disableMaterial;
  final EdgeInsets padding;
  final bool showRepoName;

  @override
  Widget build(final BuildContext context) {
    final String? href = item.links?.self?.href;
    final String repoPath = href?.replaceAll('https://api.github.com/repos/', '') ?? '';
    final List<String> pathParts = repoPath.split('/');
    final String repoName = pathParts.length >= 2 ? pathParts[1] : '';
    final String ownerName = pathParts.isNotEmpty ? pathParts[0] : '';
    
    return BasicCard(
      onTap: href != null && item.number != null
          ? () async {
              await context.router.push(
                IssuePullRoute(
                  number: item.number!,
                  repoName: repoName,
                  ownerName: ownerName,
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                GetPullIcon(item.state ?? IssueState.OPEN, item.mergedAt),
                const SizedBox(
                  width: 4,
                ),
                if (showRepoName && repoPath.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        pathParts.length >= 2
                            ? pathParts.sublist(0, 2).join('/')
                            : repoPath,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            // color: Provider.of<PaletteSettings>(context)
                            //     .currentSetting
                            //     .faded3,
                            ),
                      ),
                    ),
                  ),
                if (item.number != null)
                  Text(
                    '#${item.number}',
                    style: const TextStyle(
                        // color: Provider.of<PaletteSettings>(context)
                        //     .currentSetting
                        //     .faded3,
                        ),
                  ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            if (item.title != null)
              Text(
                item.title!,
                // style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (!compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    item.state == IssueState.CLOSED
                        ? item.mergedAt != null
                            ? 'By ${item.user?.login ?? 'Unknown'}, merged ${getDate(item.mergedAt.toString(), shorten: false)}.'
                            : 'By ${item.user?.login ?? 'Unknown'}, closed ${getDate(item.closedAt?.toString() ?? '', shorten: false)}.'
                        : 'Opened ${getDate(item.createdAt?.toString() ?? '', shorten: false)} by ${item.user?.login ?? 'Unknown'}',
                    style: context.textTheme.bodySmall?.asHint(),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  if (item.labels != null && item.labels!.isNotEmpty)
                    Wrap(
                      children: List<Widget>.generate(
                        item.labels!.length,
                        (final int index) => Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                            bottom: 8,
                          ),
                          child: IssueLabel(item.labels![index]),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class GetPullIcon extends StatelessWidget {
  const GetPullIcon(this.state, this.mergedAt, {super.key});

  final IssueState state;
  final DateTime? mergedAt;

  @override
  Widget build(final BuildContext context) {
    switch (state) {
      case IssueState.CLOSED:
        if (mergedAt == null) {
          return const Icon(
            Octicons.git_pull_request,
            // color: red,
            size: 15,
          );
        } else {
          return const Icon(
            Octicons.git_merge,
            // color: deepPurple,
            size: 15,
          );
        }
      case IssueState.OPEN:
      case IssueState.REOPENED:
        return const Icon(
          Octicons.git_pull_request,
          // color: green,
          size: 15,
        );
    }
  }
}
