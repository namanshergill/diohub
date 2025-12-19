import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Simple card content for commit events in timeline (no nested cards)
class TimelineCommitContent extends StatelessWidget {
  const TimelineCommitContent({
    required this.commitData,
    super.key,
  });

  final CommitCardDataModel commitData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Commit count summary
          Row(
            children: [
              Icon(
                Octicons.git_commit,
                size: 16,
                color: const Color(0xFF2196F3), // Blue for commits
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${commitData.count} commit${commitData.count > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Repository list (if multiple)
          if (commitData.repositoryCount > 1) ...[
            const SizedBox(height: 8),
            ...commitData.repositories.map((repo) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Octicons.repo,
                        size: 12,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${repo.owner}/${repo.name} (${repo.count} commit${repo.count > 1 ? 's' : ''})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

