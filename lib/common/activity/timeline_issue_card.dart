import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying issues in timeline using BaseEventCard pattern
class TimelineIssueCard extends StatelessWidget {
  const TimelineIssueCard({
    required this.issueData,
    required this.userLogin,
    required this.userAvatarUrl,
    super.key,
  });

  final IssueCardDataModel issueData;
  final String userLogin;
  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    // Convert to IssueModel for IssueListCard compatibility
    final issueModel = IssueModel(
      title: issueData.title,
      number: issueData.number,
      state: issueData.state == 'OPEN' ? IssueState.OPEN : IssueState.CLOSED,
      body: issueData.body,
      url: issueData.url,
      comments: issueData.commentCount ?? 0,
      createdAt: issueData.createdAt,
      updatedAt: issueData.updatedAt,
    );

    return BaseEventCard.singular(
      isInTimeline: true,
      eventType: null, // IssueListCard handles its own styling
      actor: userLogin,
      avatarUrl: userAvatarUrl,
      date: issueData.createdAt,
      useNestedCard: false,
      headerText: [
        TextSpan(
          text:
              '${issueData.state == 'CLOSED' ? 'closed' : 'opened'} an issue in ',
        ),
        TextSpan(
          text: '${issueData.repositoryOwner}/${issueData.repositoryName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Issue card (without description for timeline)
          IssueListCard(
            issueModel,
            showRepoName: true,
            showDescription: false,
          ),
          // Description if available
          if (issueData.body != null && issueData.body!.trim().isNotEmpty) ...[
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
                text: issueData.body!.trim(),
                repo: issueData.repositoryName,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
