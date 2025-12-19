import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
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
    this.selectedYear,
    this.customFromDate,
    this.customToDate,
    this.useCustomRange = false,
    this.onYearChanged,
    this.onCustomRangeChanged,
    super.key,
  });

  final GuserInfoData_user userData;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final void Function(int)? onYearChanged;
  final void Function(DateTime?, DateTime?)? onCustomRangeChanged;

  @override
  ConsumerState<UserAboutScreen> createState() => _UserAboutScreenState();
}

class _UserAboutScreenState extends ConsumerState<UserAboutScreen> {
  /// Builds a typed provider key based on selected year or custom date range
  /// Only recalculates when date range changes, not on every build
  ContributionQueryKey _getProviderKey() {
    if (widget.useCustomRange &&
        widget.customFromDate != null &&
        widget.customToDate != null) {
      // Normalize dates to day level for stable keys
      final from = DateTime(widget.customFromDate!.year,
          widget.customFromDate!.month, widget.customFromDate!.day);
      final to = DateTime(widget.customToDate!.year, widget.customToDate!.month,
          widget.customToDate!.day);
      return ContributionQueryKey.customRange(
        userName: widget.userData.login,
        from: from,
        to: to,
      );
    }

    final selectedYear = widget.selectedYear;
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
    // Fetch contributions data using Riverpod with typed key
    // Key only changes when date range changes, preventing unnecessary rebuilds
    final providerKey = _getProviderKey();

    final contributionsAsync = ref.watch(
      userContributionsProvider(providerKey),
    );

    // Build contribution slivers based on async state
    // Always receive unified ContributionViewModel - no runtime type checking needed
    final contributionSlivers = contributionsAsync.when(
      data: (viewModel) {
        return <Widget>[
          // Animated calendar section with fade-in
          SliverToBoxAdapter(
            child: _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 400),
              child: ContributionCalendarSection(
                weeks: viewModel.weeks,
                totalContributions: viewModel.totalContributions,
                colors: viewModel.colors,
                availableYears: viewModel.contributionYears,
                selectedYear: widget.selectedYear,
                customFromDate: widget.customFromDate,
                customToDate: widget.customToDate,
                useCustomRange: widget.useCustomRange,
                createdAt: widget.userData.createdAt,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Animated statistics section with staggered delay
          SliverToBoxAdapter(
            child: _DelayedFadeAnimation(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: ContributionStatisticsSection(
                commits: viewModel.totalCommitContributions,
                pullRequests: viewModel.totalPullRequestContributions,
                issues: viewModel.totalIssueContributions,
                reviews: viewModel.totalPullRequestReviewContributions,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Animated activity overview with more delay
          SliverToBoxAdapter(
            child: _DelayedFadeAnimation(
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
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Activity timeline section (now returns slivers with staggered animations)
          ActivityTimelineSection(
            userName: widget.userData.login,
            selectedYear: widget.selectedYear,
            customFromDate: widget.customFromDate,
            customToDate: widget.customToDate,
            useCustomRange: widget.useCustomRange,
          ),
          SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15)),
        ];
      },
      loading: () => [
        const SliverToBoxAdapter(child: ContributionCalendarSectionLoading()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ContributionStatisticsSectionLoading()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ActivityOverviewSectionLoading()),
      ],
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading contribution data: $error');
          debugPrint('Stack trace: $stackTrace');
        }

        return [
          SliverToBoxAdapter(
            child: NestedCardWithHeader(
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
          ),
        ];
      },
    );

    final List<Widget> slivers = [
      ...contributionSlivers,
    ];

    if (slivers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No content available.'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        16,
        8,
        0,
      ),
      child: CustomScrollView(
        slivers: slivers,
      ),
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
