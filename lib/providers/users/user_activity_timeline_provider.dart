import 'package:diohub/models/activity_timeline_progress.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for fetching user activity timeline with progress updates.
/// Uses the same ContributionQueryKey as userContributionsProvider for consistency.
/// Emits ActivityTimelineState updates as data is being fetched.
/// Uses keepAlive to prevent refresh when widget comes back into view during scroll.
final userActivityTimelineProvider =
    StreamProvider.family<ActivityTimelineState, ContributionQueryKey>(
  (ref, key) {
    // Keep provider alive to prevent refresh on scroll
    ref.keepAlive();

    final (from, to) = key.dateRange.dates;

    return UserActivityService.getUserActivityTimelineWithProgress(
      login: key.userName,
      from: from,
      to: to,
      refreshCache: false,
    );
  },
);
