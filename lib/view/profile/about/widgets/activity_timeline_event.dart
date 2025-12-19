import 'package:diohub/graphql/__generated__/schema.schema.gql.dart' as _i2;
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';

/// Timeline event types matching GitHub's contribution activity
enum ActivityEventType {
  commit,
  pullRequest,
  issue,
  repositoryCreated,
}

/// Month header information (set on first event of each month during grouping)
class MonthHeader {
  final int year;
  final int month;

  MonthHeader(this.year, this.month);
}

/// Wrapper class that holds event with timeline flags (avoids copying events)
class TimelineEventWithFlags {
  final ActivityTimelineEvent? event;
  final bool isFirst;
  final bool isLast;
  final MonthHeader? monthHeader;
  final bool isEmpty;

  TimelineEventWithFlags({
    this.event,
    this.isFirst = false,
    this.isLast = false,
    this.monthHeader,
    this.isEmpty = false,
  });
}

/// Represents a single activity event in the timeline
class ActivityTimelineEvent {
  final ActivityEventType type;
  final DateTime date;
  final String? title;
  final String? repositoryOwner;
  final String? repositoryName;
  final String? repositoryUrl;

  // Full GraphQL node data (preserves all fields from API)
  final GuserActivityTimelineFullData_user_pullRequests_edges_node?
      pullRequestNode;
  final GuserActivityTimelineFullData_user_issues_edges_node? issueNode;
  final GuserActivityTimelineFullData_user_repositories_edges_node?
      repositoryNode;
  // For commits, we use commitData since it's aggregated from multiple repos

  // Unified data models for card widgets
  final IssueCardDataModel? issueData;
  final PullRequestCardDataModel? pullRequestData;
  final CommitCardDataModel? commitData;
  final RepoCardDataModel? repositoryData;

  ActivityTimelineEvent({
    required this.type,
    required this.date,
    this.title,
    this.repositoryOwner,
    this.repositoryName,
    this.repositoryUrl,
    this.pullRequestNode,
    this.issueNode,
    this.repositoryNode,
    this.issueData,
    this.pullRequestData,
    this.commitData,
    this.repositoryData,
  });

  /// Get display title based on type and GraphQL data
  String get displayTitle {
    if (title != null) return title!;

    // Generate title based on type using GraphQL node data
    switch (type) {
      case ActivityEventType.commit:
        final count = commitData?.count ?? 1;
        final repoCount = commitData?.repositories.length ?? 1;
        if (repoCount > 1) {
          return 'Created $count commit${count > 1 ? 's' : ''} in $repoCount repositories';
        }
        return 'Created $count commit${count > 1 ? 's' : ''}';
      case ActivityEventType.pullRequest:
        if (pullRequestNode != null) {
          final action = pullRequestData?.action ?? 'opened';
          final number = pullRequestNode!.number;
          return '${_capitalize(action)} pull request #$number';
        }
        return 'Opened pull request';
      case ActivityEventType.issue:
        if (issueNode != null) {
          final action =
              issueNode!.state == _i2.GIssueState.CLOSED ? 'closed' : 'opened';
          final number = issueNode!.number;
          return '${_capitalize(action)} issue #$number';
        }
        return 'Opened issue';
      case ActivityEventType.repositoryCreated:
        return 'Created 1 repository';
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Container for timeline data grouped by month
///
/// This class provides two views of the same event data:
/// 1. `events`: Flat list of all events with flags (sorted by date, newest first)
/// 2. `eventsByMonth`: Nested map structure (for other uses, not UI):
///    - Outer key: year (int)
///    - Inner key: month (int, 1-12)
///    - Value: List of events with flags for that month
///
/// The grouping happens automatically in the constructor to set flags.
/// Events are wrapped with flags to avoid copying.
class UserActivityTimelineData {
  final List<TimelineEventWithFlags> events;
  final Map<int, Map<int, List<TimelineEventWithFlags>>> eventsByMonth;

  // Private constructor
  UserActivityTimelineData._({
    required this.events,
    required this.eventsByMonth,
  });

  // Factory constructor that computes grouped events once
  factory UserActivityTimelineData({
    required List<ActivityTimelineEvent> events,
    required DateTime from,
    required DateTime to,
  }) {
    final grouped = _groupByMonth(events);
    return UserActivityTimelineData._(
      events: _flattenGroupedEvents(grouped, from: from, to: to),
      eventsByMonth: grouped,
    );
  }

  /// Group events by year and month and wrap with flags (avoids copying events)
  ///
  /// **Flow:**
  /// 1. Iterate through all events once
  /// 2. Extract year and month from each event's date
  /// 3. Build nested map structure: year -> month -> list of wrapped events
  /// 4. Set isFirst/isLast flags using wrapper (no event copying)
  /// 5. Set monthHeader on first event of each month
  ///
  /// **Implementation Details:**
  /// - Single pass through events
  /// - Uses wrapper class to avoid copying events
  /// - Sets timeline position flags per month group (not globally)
  /// - Sets monthHeader on first event of each month
  ///
  /// **Result:** Map structure like:
  /// ```
  /// {
  ///   2024: {
  ///     12: [TimelineEventWithFlags(event1, isFirst: true), ...],
  ///     11: [TimelineEventWithFlags(event3, isFirst: true), ...],
  ///   },
  ///   2023: {
  ///     12: [TimelineEventWithFlags(event5, isFirst: true), ...],
  ///   }
  /// }
  /// ```
  static Map<int, Map<int, List<TimelineEventWithFlags>>> _groupByMonth(
    List<ActivityTimelineEvent> events,
  ) {
    final grouped = <int, Map<int, List<TimelineEventWithFlags>>>{};
    // Track last event index per month for finalizing isLast flag
    final lastEventIndexByMonth = <String, int>{};

    // Single iteration: Extract year/month, group events, set flags using wrapper
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final year = event.date.year;
      final month = event.date.month;
      final monthKey = '$year-$month';

      // Ensure year map exists, then ensure month list exists
      final monthList = grouped.putIfAbsent(year, () => {})[month] ??= [];

      // When adding a new event to a month:
      // - If there was a previous last event, mark it as not last
      // - Add the new event wrapped with flags (no copying)
      if (monthList.isEmpty) {
        // First event in month: set isFirst, monthHeader, and isLast flag
        monthList.add(
          TimelineEventWithFlags(
            event: event, // No copy - just wrap
            isFirst: true,
            isLast: false,
            monthHeader: MonthHeader(year, month),
            isEmpty: false,
          ),
        );
      } else {
        // Not first event: mark previous last event as not last
        final previousLastIndex = lastEventIndexByMonth[monthKey];
        if (previousLastIndex != null) {
          final previousWrapper = monthList[previousLastIndex];
          monthList[previousLastIndex] = TimelineEventWithFlags(
            event: previousWrapper.event, // Same event, just update flags
            isFirst: previousWrapper.isFirst,
            isLast: false, // Update flag
            monthHeader: previousWrapper.monthHeader,
            isEmpty: previousWrapper.isEmpty,
          );
        }
        // Add new event wrapped (no monthHeader - only first event has it)
        monthList.add(
          TimelineEventWithFlags(
            event: event, // No copy - just wrap
            isFirst: false,
            isLast: false,
            isEmpty: false,
            // monthHeader stays null (default)
          ),
        );
      }

      // Track this as the current last event index for this month
      lastEventIndexByMonth[monthKey] = monthList.length - 1;
    }

    // Finalize: Mark all tracked last events as isLast
    for (final entry in lastEventIndexByMonth.entries) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthList = grouped[year]?[month];
      if (monthList != null && monthList.isNotEmpty) {
        final lastIndex = entry.value;
        final lastWrapper = monthList[lastIndex];
        if (monthList.length == 1) {
          // Single event: both first and last
          monthList[0] = TimelineEventWithFlags(
            event: lastWrapper.event,
            isFirst: true,
            isLast: true,
            monthHeader: lastWrapper.monthHeader,
            isEmpty: lastWrapper.isEmpty,
          );
        } else {
          // Mark last event
          monthList[lastIndex] = TimelineEventWithFlags(
            event: lastWrapper.event,
            isFirst: lastWrapper.isFirst,
            isLast: true, // Update flag
            monthHeader: lastWrapper.monthHeader,
            isEmpty: lastWrapper.isEmpty,
          );
        }
      }
    }

    return grouped;
  }

  /// Flatten grouped events into a single list (maintains order)
  /// Fills in empty months with "No activity" placeholders
  static List<TimelineEventWithFlags> _flattenGroupedEvents(
    Map<int, Map<int, List<TimelineEventWithFlags>>> grouped, {
    required DateTime from,
    required DateTime to,
  }) {
    final flattened = <TimelineEventWithFlags>[];

    // Generate all months in the date range (newest first)
    final allMonths = _generateMonthsInRange(from, to);
    
    // Extract months that have events
    final monthsWithEvents = _extractMonthsFromGrouped(grouped);

    // Iterate through all months and merge with events
    for (final (year, month) in allMonths) {
      if (monthsWithEvents.contains((year, month))) {
        // Month has events - add them
        final monthEvents = grouped[year]?[month] ?? [];
        flattened.addAll(monthEvents);
      } else {
        // Empty month - add placeholder
        flattened.add(
          TimelineEventWithFlags(
            event: null,
            isFirst: true,
            isLast: true,
            monthHeader: MonthHeader(year, month),
            isEmpty: true,
          ),
        );
      }
    }

    return flattened;
  }

  /// Generate all (year, month) pairs in the date range (newest first)
  static List<(int year, int month)> _generateMonthsInRange(
    DateTime from,
    DateTime to,
  ) {
    final months = <(int, int)>[];
    var current = DateTime(to.year, to.month, 1);
    final start = DateTime(from.year, from.month, 1);

    while (!current.isBefore(start)) {
      months.add((current.year, current.month));
      // Move to previous month
      if (current.month == 1) {
        current = DateTime(current.year - 1, 12, 1);
      } else {
        current = DateTime(current.year, current.month - 1, 1);
      }
    }

    return months;
  }

  /// Extract all (year, month) pairs that have events from grouped structure
  static Set<(int year, int month)> _extractMonthsFromGrouped(
    Map<int, Map<int, List<TimelineEventWithFlags>>> grouped,
  ) {
    final months = <(int, int)>{};
    for (final yearEntry in grouped.entries) {
      for (final monthEntry in yearEntry.value.entries) {
        months.add((yearEntry.key, monthEntry.key));
      }
    }
    return months;
  }
}
