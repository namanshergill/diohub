import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:flutter/material.dart';

/// Simple card content for pull request events in timeline (no nested cards)
class TimelinePullRequestContent extends StatelessWidget {
  const TimelinePullRequestContent({
    required this.prData,
    super.key,
  });

  final PullRequestCardDataModel prData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // PR card (without description for timeline) - use card data model directly
          SimplePullCard(
            prData,
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

