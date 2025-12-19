import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_activity_timeline_provider.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section widget that displays user activity timeline grouped by month
class ActivityTimelineSection extends ConsumerWidget {
  const ActivityTimelineSection({
    required this.userName,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    super.key,
  });

  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;

  /// Builds typed provider key (same format as userContributionsProvider)
  ContributionQueryKey _getProviderKey() {
    if (useCustomRange && customFromDate != null && customToDate != null) {
      final from = DateTime(
        customFromDate!.year,
        customFromDate!.month,
        customFromDate!.day,
      );
      final to = DateTime(
        customToDate!.year,
        customToDate!.month,
        customToDate!.day,
      );
      return ContributionQueryKey.customRange(
        userName: userName,
        from: from,
        to: to,
      );
    }

    if (selectedYear == null) {
      return ContributionQueryKey.lastYear(userName);
    } else {
      return ContributionQueryKey.year(userName, selectedYear!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = _getProviderKey();
    final timelineAsync = ref.watch(userActivityTimelineProvider(providerKey));

    return timelineAsync.when(
      data: (timelineData) {
        if (timelineData.events.isEmpty) {
          return const SizedBox.shrink();
        }

        // Feed-like layout without header card
        return _buildTimelineContent(context, timelineData);
      },
      loading: () => const ActivityTimelineSectionLoading(),
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading activity timeline: $error');
          debugPrint('Stack trace: $stackTrace');
        }
        return _buildErrorWidget(context, error, ref, providerKey);
      },
    );
  }

  Widget _buildTimelineContent(
    BuildContext context,
    UserActivityTimelineData timelineData,
  ) {
    // Use the flat events list directly - it's already sorted and has flags set
    final events = timelineData.events;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final eventWithFlags = events[index];
          final event = eventWithFlags.event;
          final isLast = index == events.length - 1;

          // Check if we need spacing after this event (between months)
          final needsSpacing =
              !isLast && _needsSpacingAfter(event, events[index + 1].event);

          // If event has monthHeader, render header + event together
          if (eventWithFlags.monthHeader != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(
                  context,
                  eventWithFlags.monthHeader!.year,
                  eventWithFlags.monthHeader!.month,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ActivityTimelineItem(
                    event: event,
                    userLogin: userName,
                    userAvatarUrl: null, // TODO: Get from userData if available
                    isFirst: eventWithFlags.isFirst,
                    isLast: eventWithFlags.isLast,
                  ),
                ),
                if (needsSpacing) const SizedBox(height: 16),
              ],
            );
          }

          // Regular event
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActivityTimelineItem(
                  event: event,
                  userLogin: userName,
                  userAvatarUrl: null, // TODO: Get from userData if available
                  isFirst: eventWithFlags.isFirst,
                  isLast: eventWithFlags.isLast,
                ),
              ),
              if (needsSpacing) const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Check if we need spacing between this event and the next one
  bool _needsSpacingAfter(
    ActivityTimelineEvent current,
    ActivityTimelineEvent next,
  ) {
    // Need spacing if we're moving to a different month/year
    return current.date.year != next.date.year ||
        current.date.month != next.date.month;
  }

  Widget _buildMonthHeader(BuildContext context, int year, int month) {
    final theme = Theme.of(context);
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${monthNames[month - 1]} $year',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    WidgetRef ref,
    ContributionQueryKey providerKey,
  ) {
    final theme = Theme.of(context);
    final errorMessage = error.toString();

    // Extract phase information if available
    String displayMessage = 'Unable to load activity timeline';
    if (errorMessage.contains('Phase 1 failed')) {
      displayMessage = 'Failed to fetch activity data (Phase 1)';
    } else if (errorMessage.contains('Phase 2 failed')) {
      displayMessage = 'Failed to fetch activity data (Phase 2)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Button(
            onTap: () {
              // Refresh the provider to retry
              ref.invalidate(userActivityTimelineProvider(providerKey));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Loading state for activity timeline section
class ActivityTimelineSectionLoading extends StatelessWidget {
  const ActivityTimelineSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.container(
              height: 60,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
