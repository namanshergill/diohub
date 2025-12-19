import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
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

  // Memoize callbacks to prevent unnecessary rebuilds
  late final void Function(int) _onYearChanged = (year) {
    setState(() {
      _selectedYear = year;
      _useCustomRange = false;
      _customFromDate = null;
      _customToDate = null;
    });
  };

  late final void Function(DateTime?, DateTime?) _onCustomRangeChanged =
      (from, to) {
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
  };

  /// Builds a typed provider key based on selected year or custom date range
  /// Only recalculates when date range changes, not on every build
  ContributionQueryKey _getProviderKey() {
    if (_useCustomRange && _customFromDate != null && _customToDate != null) {
      // Normalize dates to day level for stable keys
      final from = DateTime(
          _customFromDate!.year, _customFromDate!.month, _customFromDate!.day);
      final to = DateTime(
          _customToDate!.year, _customToDate!.month, _customToDate!.day);
      return ContributionQueryKey.customRange(
        userName: widget.userData.login,
        from: from,
        to: to,
      );
    }

    final selectedYear = _selectedYear;
    if (selectedYear == null) {
      // Default: last year from today
      return ContributionQueryKey.lastYear(widget.userData.login);
    } else {
      // Specific year
      return ContributionQueryKey.year(widget.userData.login, selectedYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pinned items rarely change, but toList() is cheap - no need to cache
    final pinnedItems = widget.userData.pinnedItems.edges?.toList() ??
        <GuserInfoData_user_pinnedItems_edges?>[];

    // Fetch contributions data using Riverpod with typed key
    // Key only changes when date range changes, preventing unnecessary rebuilds
    final providerKey = _getProviderKey();

    final contributionsAsync = ref.watch(
      userContributionsProvider(providerKey),
    );

    // Build contribution widgets based on async state
    // Always receive unified ContributionViewModel - no runtime type checking needed
    final contributionWidgets = contributionsAsync.when(
      data: (viewModel) {
        return <Widget>[
          // Animated calendar section with fade-in
          _DelayedFadeAnimation(
            delay: const Duration(milliseconds: 0),
            duration: const Duration(milliseconds: 400),
            child: ContributionCalendarSection(
              weeks: viewModel.weeks,
              totalContributions: viewModel.totalContributions,
              colors: viewModel.colors,
              availableYears: viewModel.contributionYears,
              selectedYear: _selectedYear,
              customFromDate: _customFromDate,
              customToDate: _customToDate,
              useCustomRange: _useCustomRange,
              createdAt: widget.userData.createdAt,
              onYearChanged: _onYearChanged,
              onCustomRangeChanged: _onCustomRangeChanged,
            ),
          ),
          const SizedBox(height: 8),
          // Animated statistics section with staggered delay
          _DelayedFadeAnimation(
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 400),
            child: ContributionStatisticsSection(
              commits: viewModel.totalCommitContributions,
              pullRequests: viewModel.totalPullRequestContributions,
              issues: viewModel.totalIssueContributions,
              reviews: viewModel.totalPullRequestReviewContributions,
            ),
          ),
          const SizedBox(height: 8),
          // Animated activity overview with more delay
          _DelayedFadeAnimation(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 400),
            child: ActivityOverviewSection(
              repositories: viewModel.commitContributionsByRepository,
              commits: viewModel.totalCommitContributions,
              issues: viewModel.totalIssueContributions,
              pullRequests: viewModel.totalPullRequestContributions,
              reviews: viewModel.totalPullRequestReviewContributions,
              onRepositoryTap: (repo) async {
                final uri = Uri.parse(repo.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          // Animated activity timeline with delay
          _DelayedFadeAnimation(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 400),
            child: ActivityTimelineSection(
              userName: widget.userData.login,
              selectedYear: _selectedYear,
              customFromDate: _customFromDate,
              customToDate: _customToDate,
              useCustomRange: _useCustomRange,
            ),
          ),
        ];
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
