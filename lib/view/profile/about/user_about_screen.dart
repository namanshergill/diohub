import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/view/profile/about/widgets/chip_detail_bottom_sheet.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final GuserInfoData_repositoryOwner__asUser userData;
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
  /// Handles chip tap to show bottom sheet with details
  void _handleChipTap(
    BuildContext context,
    ContributionChipType chipType,
    ContributionQueryKey queryKey,
    ContributionCollectionResult result,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChipDetailBottomSheet(
        chipType: chipType,
        queryKey: queryKey,
        contributionResult: result,
      ),
    );
  }

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

    return contributionsAsync.when(
      data: (result) {
        return TabbedContributionSection(
          contributionResult: result,
          userName: widget.userData.login,
          selectedYear: widget.selectedYear,
          customFromDate: widget.customFromDate,
          customToDate: widget.customToDate,
          useCustomRange: widget.useCustomRange,
          createdAt: widget.userData.createdAt,
          onChipTap: (chipType) => _handleChipTap(
            context,
            chipType,
            providerKey,
            result,
          ),
        );
      },
      loading: () => const _ContributionLoadingSkeleton(),
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading contribution data: $error');
          debugPrint('Stack trace: $stackTrace');
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load contribution data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loading skeleton that mimics the contribution section layout
class _ContributionLoadingSkeleton extends StatelessWidget {
  const _ContributionLoadingSkeleton();

  /// Builds a styled divider matching the actual divider style
  Widget _buildStyledDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              colorScheme.outlineVariant.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Calendar skeleton
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerWidget.container(
                        height: 20,
                        width: 150,
                      ),
                      ShimmerWidget.container(
                        height: 20,
                        width: 100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendar grid
                  ShimmerWidget.container(
                    height: 120,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 12),
                  // Stats chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ShimmerWidget.container(height: 28, width: 80),
                      ShimmerWidget.container(height: 28, width: 70),
                      ShimmerWidget.container(height: 28, width: 75),
                      ShimmerWidget.container(height: 28, width: 65),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Divider between calendar and activity overview
            _buildStyledDivider(context),

            const SizedBox(height: 16),

            // Activity overview skeleton (radar chart section)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header skeleton
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: ShimmerWidget.container(
                      height: 24,
                      width: 180,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShimmerWidget.container(
                    height: 18,
                    width: 120,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Repositories list
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: List.generate(
                            3,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  ShimmerWidget.container(
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ShimmerWidget.container(
                                          height: 14,
                                          width: double.infinity,
                                        ),
                                        const SizedBox(height: 4),
                                        ShimmerWidget.container(
                                          height: 12,
                                          width: 80,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Radar chart
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            ShimmerWidget.container(
                              height: 14,
                              width: 80,
                            ),
                            const SizedBox(height: 12),
                            ShimmerWidget.container(
                              height: 150,
                              width: 150,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Divider before tabs
            _buildStyledDivider(context),

            // Tabs skeleton
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    ShimmerWidget.container(height: 16, width: 70),
                    const SizedBox(width: 24),
                    ShimmerWidget.container(height: 16, width: 90),
                    const SizedBox(width: 24),
                    ShimmerWidget.container(height: 16, width: 60),
                  ],
                ),
              ),
            ),

            // Tab content skeleton - takes remaining space
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget.container(
                          height: 16,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 8),
                        ShimmerWidget.container(
                          height: 14,
                          width: 150,
                        ),
                        const SizedBox(height: 4),
                        ShimmerWidget.container(
                          height: 14,
                          width: 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
