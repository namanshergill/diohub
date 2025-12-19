import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_contributions_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for fetching user contributions with typed keys.
/// Returns a unified ContributionViewModel for both single-year and multi-year queries.
/// Cache is maintained per unique ContributionQueryKey and kept alive to prevent
/// redundant fetches when navigating away and back.
final userContributionsProvider =
    FutureProvider.family<ContributionViewModel, ContributionQueryKey>(
  (ref, key) async {
    // Keep provider alive to prevent refetch on navigation
    ref.keepAlive();
    return UserContributionsService.fetchContributions(key);
  },
);
