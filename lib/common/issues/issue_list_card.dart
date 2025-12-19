import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart' hide State;
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class IssueListCard extends StatelessWidget {
  const IssueListCard(
    this.item, {
    this.showRepoName = true,
    this.commentsSince,
    this.showDescription = true,
    super.key,
  });

  final IssueCardDataModel item;
  final DateTime? commentsSince;
  final bool showRepoName;
  final bool showDescription;

  // Helper getters to access data
  String get _title => item.title;
  String? get _url => item.url;
  IssueState get _state =>
      item.state == 'OPEN' ? IssueState.OPEN : IssueState.CLOSED;
  int get _number => item.number;
  int get _comments => item.commentCount ?? 0;
  String? get _body => item.body;
  String? get _bodyHtml => item.bodyHtml;
  UserInfoModel? get _user => item.author;

  // Extract repo name from repository data
  String? get _repoName => '${item.repositoryOwner}/${item.repositoryName}';

  @override
  Widget build(final BuildContext context) {
    // Title-first hierarchy: Title first, then context, then metadata
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Issue title (most prominent - first)
        Text(
          _title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
                height: 1.3,
              ),
        ),
        // Context row: Repo name + Issue number + State icon (grouped together)
        // OR Author + Comments (when showRepoName is false)
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Repo name (only if showRepoName is true)
            if (showRepoName && _repoName != null)
              Text(
                _repoName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            // Author and Comments (only if showRepoName is false)
            if (!showRepoName) ...[
              // Creator
              if (_user?.login != null) ...[
                Text(
                  _user!.login ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.75),
                      ),
                ),
                if (_comments != 0)
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
              if (_comments != 0)
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
                      '$_comments',
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
                Opacity(
                  opacity: 0.6,
                  child: getIcon(_state!),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_number',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            // Comments
            if (_comments != 0)
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
                    '$_comments',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
          ],
        ),
        // Issue body preview with markdown rendering
        if (showDescription &&
            (_bodyHtml ?? _body ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TrimmableMarkdownContent(
              text: _body,
              textHtml: _bodyHtml,
              repo: _repoName,
            ),
          ),
        ],
      ],
    );

    return InkPot(
      onTap: _url != null
          ? () async {
              await AutoRouter.of(context)
                  .push(issuePullScreenRoute(PathData.fromURL(_url!)));
            }
          : null,
      child: SizedBox(
        width: double.infinity,
        child: content,
      ),
    );
  }
}

Widget getIcon(final IssueState state) => switch (state) {
      IssueState.CLOSED => const Icon(
          Octicons.issue_closed,
          size: 14,
          color: Colors.red,
        ),
      IssueState.OPEN => const Icon(
          Octicons.issue_opened,
          size: 14,
          color: Colors.green,
        ),
      IssueState.REOPENED => const Icon(
          Octicons.issue_reopened,
          size: 14,
          color: Colors.green,
        ),
    };

class IssueLoadingCard extends StatelessWidget {
  const IssueLoadingCard(
    this.url, {
    this.showRepoName = true,
    super.key,
  });

  final String url;
  final bool showRepoName;

  @override
  Widget build(final BuildContext context) => APIWrapper<IssueModel>.deferred(
        apiCall: ({required final bool refresh}) async =>
            IssuesService.getIssueInfo(fullUrl: url, refresh: refresh),
        builder: (final BuildContext context, final IssueModel data) =>
            IssueListCard(
          IssueCardDataModel.fromIssueModel(data),
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
              // Body preview shimmer (optional, may or may not appear)
              const SizedBox(height: 10),
              ShimmerWidget.container(
                height: 14,
                width: double.infinity,
              ),
              const SizedBox(height: 4),
              ShimmerWidget.container(
                height: 14,
                width: double.infinity,
              ),
            ],
          ),
        ),
      );
}
