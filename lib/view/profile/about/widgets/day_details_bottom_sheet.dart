import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows a bottom sheet with detailed information about a specific day's contributions.
///
/// This provides the enhanced UX of showing day details when tapping the calendar.
void showDayDetailsBottomSheet(
  BuildContext context,
  ContributionDay day, {
  List<DayContribution>? contributions,
}) {
  showScrollableBottomSheet(
    context,
    headerBuilder: (context, setState) => _DayDetailsHeader(day: day),
    scrollableBodyBuilder: (context, setState, scrollController) =>
        _DayDetailsBody(
      day: day,
      contributions: contributions,
      scrollController: scrollController,
    ),
  );
}

/// Header for the day details bottom sheet
class _DayDetailsHeader extends StatelessWidget {
  const _DayDetailsHeader({required this.day});

  final ContributionDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final dateStr = dateFormat.format(day.date);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            dateStr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

/// Body for the day details bottom sheet
class _DayDetailsBody extends StatelessWidget {
  const _DayDetailsBody({
    required this.day,
    this.contributions,
    required this.scrollController,
  });

  final ContributionDay day;
  final List<DayContribution>? contributions;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total contributions
          _buildTotalContributions(context),
          const SizedBox(height: 16),
          // Breakdown by type (only if we have detailed data)
          if (contributions != null && contributions!.isNotEmpty) ...[
            _buildContributionsBreakdown(context, contributions!),
          ] else if (day.count > 0) ...[
            // Show info message when we have count but no breakdown
            _buildEmptyState(context),
          ] else ...[
            // Show empty state when there are no contributions
            _buildEmptyState(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalContributions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.count} ${day.count == 1 ? 'contribution' : 'contributions'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'on this day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsBreakdown(
    BuildContext context,
    List<DayContribution> contributions,
  ) {
    // Group by type
    final commits = contributions.where((c) => c.type == 'commit').toList();
    final prs = contributions.where((c) => c.type == 'pullRequest').toList();
    final issues = contributions.where((c) => c.type == 'issue').toList();
    final reviews = contributions.where((c) => c.type == 'review').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (commits.isNotEmpty)
          _buildContributionTypeSection(
            context,
            'Commits',
            commits,
            Icons.code,
            Colors.green,
          ),
        if (prs.isNotEmpty)
          _buildContributionTypeSection(
            context,
            'Pull Requests',
            prs,
            Icons.merge_type,
            Colors.blue,
          ),
        if (issues.isNotEmpty)
          _buildContributionTypeSection(
            context,
            'Issues',
            issues,
            Icons.bug_report,
            Colors.purple,
          ),
        if (reviews.isNotEmpty)
          _buildContributionTypeSection(
            context,
            'Reviews',
            reviews,
            Icons.rate_review,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildContributionTypeSection(
    BuildContext context,
    String title,
    List<DayContribution> contributions,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                '$title: ${contributions.length}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...contributions.map((contribution) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildContributionItem(context, contribution),
              )),
        ],
      ),
    );
  }

  Widget _buildContributionItem(
    BuildContext context,
    DayContribution contribution,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: contribution.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution.title,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (contribution.repository != null)
                    Text(
                      contribution.repository!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (contribution.onTap != null)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show a helpful message when there are no contributions
    if (day.count == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No contributions on this day',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This day had no recorded activity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // If there are contributions but no detailed breakdown,
    // show a message explaining that only the count is available
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Contribution details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed breakdown by type (commits, PRs, issues) is not available for individual days. The total count shown includes all contribution types.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a single contribution on a specific day
class DayContribution {
  const DayContribution({
    required this.type,
    required this.title,
    this.repository,
    this.onTap,
  });

  final String type; // 'commit', 'pullRequest', 'issue', 'review'
  final String title;
  final String? repository;
  final VoidCallback? onTap;
}
