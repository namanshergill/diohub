import 'package:diohub/common/misc/expandable_info_card.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Builds the description and stats section for the repository header
Widget buildDescriptionAndStats(
  BuildContext context,
  GrepositoryInfoData_repository repo,
) {
  final description = repo.description;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Description card
      if (description != null && description.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HighlightedContainer(
            highlightColor: Theme.of(context).colorScheme.primary,
            borderRadius: 12,
            child: ExpandableInfoCard(
              title: 'Description',
              expandedContent: Text(description),
              initiallyExpanded: false,
            ),
          ),
        ),
      ],
      // Stats card
      buildRepositoryStats(context, repo),
    ],
  );
}

/// Builds the repository stats card
Widget buildRepositoryStats(
  BuildContext context,
  GrepositoryInfoData_repository repo,
) {
  final stargazersCount = repo.stargazerCount;
  final forksCount = repo.forkCount;
  final watchersCount = repo.watchers.totalCount;

  return HighlightedContainer(
    highlightColor: Theme.of(context).colorScheme.primary,
    borderRadius: 12,
    child: Material(
      color: Color.lerp(
        Theme.of(context).colorScheme.surfaceContainer,
        Colors.black,
        0.1,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Octicons.graph,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stats',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Octicons.star,
                    label: 'Stars',
                    value: stargazersCount.toString(),
                    color: Colors.amber.shade400,
                    onTap: () {
                      // TODO: Navigate to stargazers list or execute action
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Octicons.repo_forked,
                    label: 'Forks',
                    value: forksCount.toString(),
                    color: Colors.blue.shade400,
                    onTap: () {
                      // TODO: Navigate to forks list or execute action
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Octicons.eye,
                    label: 'Watchers',
                    value: watchersCount.toString(),
                    color: Colors.purple.shade400,
                    onTap: () {
                      // TODO: Navigate to watchers list or execute action
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Builds a single stat item widget
Widget _buildStatItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  VoidCallback? onTap,
}) {
  if (onTap == null) {
    // Non-tappable stat item
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  // Tappable stat item with visual feedback
  return Material(
    color:
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
