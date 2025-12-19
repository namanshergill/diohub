import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:flutter/material.dart';

/// Simple card content for issue events in timeline (no nested cards)
class TimelineIssueContent extends StatelessWidget {
  const TimelineIssueContent({
    required this.issueData,
    super.key,
  });

  final IssueCardDataModel issueData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Issue card (without description for timeline) - use card data model directly
          IssueListCard(
            issueData,
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
