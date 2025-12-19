import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for fetching user activity timeline with typed keys.
/// Uses the same ContributionQueryKey as userContributionsProvider for consistency.
/// This provider syncs with the date range selector in UserAboutScreen.
/// Uses keepAlive to prevent refresh when widget comes back into view during scroll.
final userActivityTimelineProvider =
    FutureProvider.family<UserActivityTimelineData, ContributionQueryKey>(
  (ref, key) async {
    // Keep provider alive to prevent refresh on scroll
    ref.keepAlive();

    final (from, to) = key.dateRange.dates;

    return UserActivityService.getUserActivityTimeline(
      login: key.userName,
      from: from,
      to: to,
      refreshCache: false,
    );
  },
);
