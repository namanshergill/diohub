/// Timeline event types matching GitHub's contribution activity
enum ActivityEventType {
  commit,
  pullRequest,
  issue,
  repositoryCreated,
}

/// Represents a single activity event in the timeline
class ActivityTimelineEvent {
  final ActivityEventType type;
  final DateTime date;
  final String? title;
  final String? repositoryOwner;
  final String? repositoryName;
  final String? repositoryUrl;
  final Map<String, dynamic>? metadata;

  ActivityTimelineEvent({
    required this.type,
    required this.date,
    this.title,
    this.repositoryOwner,
    this.repositoryName,
    this.repositoryUrl,
    this.metadata,
  });

  /// Get display title based on type and metadata
  String get displayTitle {
    if (title != null) return title!;

    // Generate title based on type
    switch (type) {
      case ActivityEventType.commit:
        final count = metadata?['count'] as int? ?? 1;
        final repoCount = metadata?['repositoryCount'] as int? ?? 1;
        if (repoCount > 1) {
          return 'Created $count commit${count > 1 ? 's' : ''} in $repoCount repositories';
        }
        return 'Created $count commit${count > 1 ? 's' : ''}';
      case ActivityEventType.pullRequest:
        final action = metadata?['action'] as String? ?? 'opened';
        final number = metadata?['number'] as int?;
        if (number != null) {
          return '${_capitalize(action)} pull request #$number';
        }
        return '${_capitalize(action)} pull request';
      case ActivityEventType.issue:
        final action = metadata?['action'] as String? ?? 'opened';
        final number = metadata?['number'] as int?;
        if (number != null) {
          return '${_capitalize(action)} issue #$number';
        }
        return '${_capitalize(action)} issue';
      case ActivityEventType.repositoryCreated:
        return 'Created 1 repository';
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Container for timeline data grouped by month
class UserActivityTimelineData {
  final List<ActivityTimelineEvent> events;
  final Map<int, Map<int, List<ActivityTimelineEvent>>> eventsByMonth;

  UserActivityTimelineData({
    required this.events,
  }) : eventsByMonth = _groupByMonth(events);

  /// Group events by year and month
  static Map<int, Map<int, List<ActivityTimelineEvent>>> _groupByMonth(
    List<ActivityTimelineEvent> events,
  ) {
    final grouped = <int, Map<int, List<ActivityTimelineEvent>>>{};

    for (final event in events) {
      final year = event.date.year;
      final month = event.date.month;

      grouped.putIfAbsent(year, () => {})[month] ??= [];
      grouped[year]![month]!.add(event);
    }

    return grouped;
  }
}

