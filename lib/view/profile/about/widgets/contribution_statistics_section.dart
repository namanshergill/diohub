import 'package:diohub/common/charts/stat_card_widget.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A section widget that displays contribution statistics in a grid.
///
/// Shows key metrics like commits, PRs, issues, and reviews
/// in an easy-to-scan card layout.
class ContributionStatisticsSection extends StatelessWidget {
  const ContributionStatisticsSection({
    required this.commits,
    required this.pullRequests,
    required this.issues,
    this.reviews,
    this.onStatTap,
    super.key,
  });

  /// Number of commits
  final int commits;

  /// Number of pull requests
  final int pullRequests;

  /// Number of issues
  final int issues;

  /// Optional number of reviews
  final int? reviews;

  /// Callback when a stat card is tapped
  final void Function(String statType)? onStatTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = <StatCardData>[
      StatCardData(
        icon: Octicons.git_commit,
        value: _formatNumber(commits),
        label: 'Commits',
        color: Colors.green.shade400,
        onTap: onStatTap != null ? () => onStatTap!('commits') : null,
      ),
      StatCardData(
        icon: Octicons.git_pull_request,
        value: _formatNumber(pullRequests),
        label: 'Pull Requests',
        color: Colors.blue.shade400,
        onTap: onStatTap != null ? () => onStatTap!('pullRequests') : null,
      ),
      StatCardData(
        icon: Octicons.issue_opened,
        value: _formatNumber(issues),
        label: 'Issues',
        color: Colors.purple.shade400,
        onTap: onStatTap != null ? () => onStatTap!('issues') : null,
      ),
      if (reviews != null)
        StatCardData(
          icon: Octicons.check,
          value: _formatNumber(reviews!),
          label: 'Reviews',
          color: Colors.orange.shade400,
          onTap: onStatTap != null ? () => onStatTap!('reviews') : null,
        ),
    ];

    return NestedCardWithHeader(
      header: Row(
        children: [
          Icon(
            Octicons.graph,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Contribution Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatCardGrid(
          stats: stats,
          crossAxisCount: stats.length.clamp(2, 4),
          spacing: 8.0,
          runSpacing: 8.0,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

/// Loading state for contribution statistics section
class ContributionStatisticsSectionLoading extends StatelessWidget {
  const ContributionStatisticsSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedCardWithHeader(
      header: Row(
        children: [
          ShimmerWidget.container(
            height: 16,
            width: 16,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(width: 8),
          ShimmerWidget.container(
            height: 20,
            width: 180,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 120).floor().clamp(2, 4);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => ShimmerWidget.container(
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
      ),
    );
  }
}
