import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_data_converter.dart';
import 'package:diohub/view/profile/about/widgets/contribution_statistics_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen that includes user details, contribution graph, and pinned repos
class UserAboutScreen extends ConsumerStatefulWidget {
  const UserAboutScreen(
    this.userData, {
    super.key,
  });

  final GuserInfoData_user userData;

  @override
  ConsumerState<UserAboutScreen> createState() => _UserAboutScreenState();
}

class _UserAboutScreenState extends ConsumerState<UserAboutScreen> {
  int? _selectedYear; // null means current year (default)
  DateTime? _customFromDate;
  DateTime? _customToDate;
  bool _useCustomRange = false;

  /// Builds a stable provider key based on selected year or custom date range
  /// Only recalculates when date range changes, not on every build
  String _getProviderKey() {
    if (_useCustomRange && _customFromDate != null && _customToDate != null) {
      // Normalize dates to day level for stable keys
      final from = DateTime(
          _customFromDate!.year, _customFromDate!.month, _customFromDate!.day);
      final to = DateTime(
          _customToDate!.year, _customToDate!.month, _customToDate!.day);
      // Use date-only format (YYYY-MM-DD) to avoid colons in ISO string breaking key parsing
      final fromStr = formatDateOnly(from);
      final toStr = formatDateOnly(to);
      return '${widget.userData.login}:custom:$fromStr:$toStr';
    }

    final selectedYear = _selectedYear;
    if (selectedYear == null) {
      // Use "lastYear" for default (current year)
      return '${widget.userData.login}:lastYear';
    } else {
      // Use specific year range
      return '${widget.userData.login}:$selectedYear:$selectedYear';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinnedItems = widget.userData.pinnedItems.edges?.toList() ??
        <GuserInfoData_user_pinnedItems_edges?>[];

    // Fetch contributions data using Riverpod with stable string key
    // Key only changes when year changes, preventing unnecessary rebuilds
    final providerKey = _getProviderKey();

    final contributionsAsync = ref.watch(
      userContributionsProvider(providerKey),
    );

    // Build contribution widgets based on async state
    final contributionWidgets = contributionsAsync.when(
      data: (contributionsData) {
        // Handle both single-year (GuserContributionsData_user) and multi-year (CombinedContributionsData)
        if (contributionsData is CombinedContributionsData) {
          // Multi-year combined data - use directly, no need for extraction
          final combined = contributionsData;

          return <Widget>[
            // Animated calendar section with fade-in
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 400),
              child: ContributionCalendarSection(
                weeks: combined.weeks,
                totalContributions: combined.totalContributions,
                colors: combined.colors,
                availableYears: combined.contributionYears,
                selectedYear: _selectedYear,
                customFromDate: _customFromDate,
                customToDate: _customToDate,
                useCustomRange: _useCustomRange,
                createdAt: widget.userData.createdAt,
                onYearChanged: (year) {
                  setState(() {
                    _selectedYear = year;
                    _useCustomRange = false;
                    _customFromDate = null;
                    _customToDate = null;
                  });
                },
                onCustomRangeChanged: (from, to) {
                  setState(() {
                    if (from == null && to == null) {
                      // Reset to last year
                      _selectedYear = null;
                      _useCustomRange = false;
                      _customFromDate = null;
                      _customToDate = null;
                    } else {
                      _customFromDate = from;
                      _customToDate = to;
                      _useCustomRange = from != null && to != null;
                      if (_useCustomRange) {
                        _selectedYear = null;
                      }
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            // Animated statistics section with staggered delay
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: ContributionStatisticsSection(
                commits: combined.totalCommitContributions,
                pullRequests: combined.totalPullRequestContributions,
                issues: combined.totalIssueContributions,
                reviews: combined.totalPullRequestReviewContributions,
              ),
            ),
            const SizedBox(height: 8),
            // Animated activity overview with more delay
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 400),
              child: ActivityOverviewSection(
                repositories: combined.commitContributionsByRepository,
                commits: combined.totalCommitContributions,
                issues: combined.totalIssueContributions,
                pullRequests: combined.totalPullRequestContributions,
                reviews: combined.totalPullRequestReviewContributions,
                onRepositoryTap: (repo) async {
                  final uri = Uri.parse(repo.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ];
        } else if (contributionsData is GuserContributionsData_user) {
          // Single-year data
          final contributionsCollection =
              contributionsData.contributionsCollection;

          // Contribution Calendar Section
          final weeks = ContributionDataConverter.convertWeeks(
            contributionsCollection.contributionCalendar.weeks.toList(),
          );
          final colors = ContributionDataConverter.convertColors(
            contributionsCollection.contributionCalendar.colors.toList(),
          );
          final totalContributions =
              contributionsCollection.contributionCalendar.totalContributions;
          final availableYears =
              contributionsCollection.contributionYears.toList();

          // Convert repositories for Activity Overview
          final repositories = ContributionDataConverter.convertRepositories(
            contributionsCollection.commitContributionsByRepository.toList(),
          );

          return <Widget>[
            // Animated calendar section with fade-in
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 400),
              child: ContributionCalendarSection(
                weeks: weeks,
                totalContributions: totalContributions,
                colors: colors,
                availableYears: availableYears,
                selectedYear: _selectedYear,
                customFromDate: _customFromDate,
                customToDate: _customToDate,
                useCustomRange: _useCustomRange,
                createdAt: widget.userData.createdAt,
                onYearChanged: (year) {
                  setState(() {
                    _selectedYear = year;
                    _useCustomRange = false;
                    _customFromDate = null;
                    _customToDate = null;
                  });
                },
                onCustomRangeChanged: (from, to) {
                  setState(() {
                    if (from == null && to == null) {
                      // Reset to last year
                      _selectedYear = null;
                      _useCustomRange = false;
                      _customFromDate = null;
                      _customToDate = null;
                    } else {
                      _customFromDate = from;
                      _customToDate = to;
                      _useCustomRange = from != null && to != null;
                      if (_useCustomRange) {
                        _selectedYear = null;
                      }
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            // Animated statistics section with staggered delay
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: ContributionStatisticsSection(
                commits: contributionsCollection.totalCommitContributions,
                pullRequests:
                    contributionsCollection.totalPullRequestContributions,
                issues: contributionsCollection.totalIssueContributions,
                reviews:
                    contributionsCollection.totalPullRequestReviewContributions,
              ),
            ),
            const SizedBox(height: 8),
            // Animated activity overview with more delay
            _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 400),
              child: ActivityOverviewSection(
                repositories: repositories,
                commits: contributionsCollection.totalCommitContributions,
                issues: contributionsCollection.totalIssueContributions,
                pullRequests:
                    contributionsCollection.totalPullRequestContributions,
                reviews:
                    contributionsCollection.totalPullRequestReviewContributions,
                onRepositoryTap: (repo) async {
                  final uri = Uri.parse(repo.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ];
        } else {
          // Unknown type - should not happen
          return <Widget>[
            NestedCardWithHeader(
              header: Text(
                'Contribution Graph',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Unexpected data type',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ),
          ];
        }
      },
      loading: () => [
        ContributionCalendarSectionLoading(),
        const SizedBox(height: 8),
        ContributionStatisticsSectionLoading(),
        const SizedBox(height: 8),
        ActivityOverviewSectionLoading(),
      ],
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading contribution data: $error');
          debugPrint('Stack trace: $stackTrace');
        }

        return [
          NestedCardWithHeader(
            header: Text(
              'Contribution Graph',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load contribution data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${error.toString()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );

    final List<Widget> children = [
      ...contributionWidgets,
    ];

    // Pinned Repositories
    if (pinnedItems.isNotEmpty) {
      children.add(
        SizedBox(height: 8),
      );
      children.add(
        NestedCardWithHeader(
          header: Text(
            'Pinned Repositories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(
              pinnedItems.length,
              (final int index) {
                final node = pinnedItems[index]?.node;
                // Check if it's a repository by __typename and cast to GrepositoryFields
                if (node == null || node.G__typename != 'Repository') {
                  return const SizedBox.shrink();
                }
                final repo = node as GrepositoryFields;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < pinnedItems.length - 1 ? 12 : 0,
                  ),
                  child: RepositoryCard(
                    RepoCardDataModel.fromGraphQL(repo),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No content available.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: children,
    );
  }
}

/// Widget that provides a delayed fade-in animation
class _DelayedFadeAnimation extends StatefulWidget {
  const _DelayedFadeAnimation({
    required this.delay,
    required this.duration,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Widget child;

  @override
  State<_DelayedFadeAnimation> createState() => _DelayedFadeAnimationState();
}

class _DelayedFadeAnimationState extends State<_DelayedFadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}
