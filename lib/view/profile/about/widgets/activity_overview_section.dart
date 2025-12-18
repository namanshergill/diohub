import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/charts/radar_chart_widget.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data for a repository in the "Contributed to" section
class ContributedRepository {
  const ContributedRepository({
    required this.name,
    required this.owner,
    required this.url,
    required this.contributionCount,
    this.description,
    this.language,
    this.languageColor,
    this.stargazersCount,
    this.isPrivate,
    this.isFork,
  });

  final String name;
  final String owner;
  final String url;
  final int contributionCount;
  final String? description;
  final String? language;
  final String? languageColor;
  final int? stargazersCount;
  final bool? isPrivate;
  final bool? isFork;
}

/// A section widget that displays activity overview with repositories and radar chart.
///
/// This matches GitHub's "Activity overview" section with:
/// - Left: List of contributed repositories
/// - Right: Radar chart showing contribution distribution
class ActivityOverviewSection extends StatelessWidget {
  const ActivityOverviewSection({
    required this.repositories,
    required this.commits,
    required this.issues,
    required this.pullRequests,
    this.reviews,
    this.onRepositoryTap,
    super.key,
  });

  /// List of repositories user contributed to
  final List<ContributedRepository> repositories;

  /// Number of commits
  final int commits;

  /// Number of issues
  final int issues;

  /// Number of pull requests
  final int pullRequests;

  /// Optional number of reviews
  final int? reviews;

  /// Callback when a repository is tapped
  final void Function(ContributedRepository repo)? onRepositoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NestedCardWithHeader(
      header: Row(
        children: [
          Icon(
            Octicons.pulse,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Activity overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On smaller screens, stack vertically
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContributedTo(context),
                  const SizedBox(height: 16),
                  _buildCodeReviewChart(context),
                ],
              );
            }
            // On larger screens, side by side
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildContributedTo(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildCodeReviewChart(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContributedTo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (repositories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contributed to',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No contributions yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final displayRepos = repositories.take(4).toList();
    final remainingCount = repositories.length - displayRepos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contributed to',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...displayRepos.map((repo) => _buildRepositoryItem(context, repo)),
        if (remainingCount > 0)
          InkWell(
            onTap: () => _showAllRepositoriesSheet(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$remainingCount ${remainingCount == 1 ? 'other repository' : 'other repositories'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRepositoryItem(
    BuildContext context,
    ContributedRepository repo, {
    bool showCount = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onRepositoryTap != null
          ? () => onRepositoryTap!(repo)
          : () async {
              final uri = Uri.parse(repo.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: showCount ? 12 : 6, horizontal: showCount ? 4 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repository icon with container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Octicons.repo,
                size: showCount ? 18 : 14,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(width: showCount ? 12 : 8),
            Expanded(
              child: showCount
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Repository name with badges
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${repo.owner}/${repo.name}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (repo.isPrivate == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Octicons.lock,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (repo.isFork == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Octicons.repo_forked,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        // Description if available
                        if (repo.description != null &&
                            repo.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            repo.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Stats row: language, stars, contributions
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (repo.language != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: repo.languageColor != null
                                          ? parseContributionColor(repo.languageColor!)
                                          : colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    repo.language!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            if (repo.stargazersCount != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Octicons.star,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatNumber(repo.stargazersCount!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Octicons.git_commit,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${repo.contributionCount} ${repo.contributionCount == 1 ? 'contribution' : 'contributions'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${repo.owner}/${repo.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (repo.language != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: repo.languageColor != null
                                        ? parseContributionColor(repo.languageColor!)
                                        : colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  repo.language!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            if (showCount)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }


  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildCodeReviewChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code review',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 150,
            child: ContributionRadarChart(
              commits: commits,
              issues: issues,
              pullRequests: pullRequests,
              reviews: reviews,
              color: const Color(0xFF40C463), // GitHub green color
            ),
          ),
        ),
      ],
    );
  }

  void _showAllRepositoriesSheet(BuildContext context) {
    showScrollableBottomSheet(
      context,
      headerBuilder: (context, setState) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Contributed Repositories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      scrollableBodyBuilder: (context, setState, scrollController) =>
          ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: repositories.length,
        itemBuilder: (context, index) {
          final repo = repositories[index];
          // Convert ContributedRepository to RepoCardDataModel
          final repoCardData = RepoCardDataModel(
            name: repo.name,
            url: repo.url,
            description: repo.description,
            language: repo.language,
            stargazersCount: repo.stargazersCount,
            private: repo.isPrivate,
            fork: repo.isFork,
            contributionCount: repo.contributionCount,
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < repositories.length - 1 ? 12 : 0,
            ),
            child: RepositoryCard(
              repoCardData,
              contributionCount: repo.contributionCount,
            ),
          );
        },
      ),
    );
  }
}

/// Loading state for activity overview section
class ActivityOverviewSectionLoading extends StatelessWidget {
  const ActivityOverviewSectionLoading({super.key});

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
            width: 160,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contributed to section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.container(
                        height: 16,
                        width: 120,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                          4,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    ShimmerWidget.container(
                                      height: 14,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    const SizedBox(width: 6),
                                    ShimmerWidget.container(
                                      height: 14,
                                      width: 150,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Radar chart shimmer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.container(
                        height: 16,
                        width: 100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      ShimmerWidget.container(
                        height: 150,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.container(
                        height: 16,
                        width: 120,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                          4,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    ShimmerWidget.container(
                                      height: 14,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    const SizedBox(width: 6),
                                    ShimmerWidget.container(
                                      height: 14,
                                      width: 150,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.container(
                        height: 16,
                        width: 100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      ShimmerWidget.container(
                        height: 150,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
