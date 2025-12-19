import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying pull requests in timeline using BaseEventCard pattern
class TimelinePullRequestCard extends StatelessWidget {
  const TimelinePullRequestCard({
    required this.prData,
    required this.userLogin,
    required this.userAvatarUrl,
    super.key,
  });

  final PullRequestCardDataModel prData;
  final String userLogin;
  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    // Convert to PullRequestModel for SimplePullCard compatibility
    final prModel = PullRequestModel(
      title: prData.title,
      number: prData.number,
      state: prData.state == 'OPEN'
          ? IssueState.OPEN
          : (prData.merged == true
              ? IssueState.OPEN // SimplePullCard handles merged separately
              : IssueState.CLOSED),
      body: prData.body,
      url: prData.url,
      merged: prData.merged,
      mergedAt: prData.mergedAt,
      createdAt: prData.createdAt,
      updatedAt: prData.updatedAt,
    );

    return BaseEventCard.singular(
      isInTimeline: true,
      eventType: null, // SimplePullCard handles its own styling
      actor: userLogin,
      avatarUrl: userAvatarUrl,
      date: prData.createdAt,
      useNestedCard: false,
      headerText: [
        TextSpan(
          text: '${prData.action} a pull request in ',
        ),
        TextSpan(
          text: '${prData.repositoryOwner}/${prData.repositoryName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // PR card (without description for timeline)
          SimplePullCard(
            prModel,
            showRepoName: true,
            showDescription: false,
          ),
          // Description if available
          if (prData.body != null && prData.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TrimmableMarkdownContent(
                text: prData.body!.trim(),
                repo: prData.repositoryName,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
