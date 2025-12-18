import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for fetching user contributions with customizable date ranges
/// Uses a simple string key format: "userName:fromYear:toYear" or "userName:lastYear"
/// This ensures stable keys that only change when the year actually changes
final userContributionsProvider = FutureProvider.autoDispose
    .family<GuserContributionsData_user, String>((ref, key) async {
  // Parse key: "userName:fromYear:toYear" or "userName:lastYear"
  final parts = key.split(':');
  final userName = parts[0];

  DateTime? from;
  DateTime? to;

  if (parts.length == 2 && parts[1] == 'lastYear') {
    // Default: last year from today
    final now = DateTime.now();
    to = DateTime(now.year, now.month, now.day);
    from = DateTime(to.year - 1, to.month, to.day);
  } else if (parts.length == 3) {
    // Specific year range
    final fromYear = int.parse(parts[1]);
    final toYear = int.parse(parts[2]);
    from = DateTime(fromYear, 1, 1);
    to = DateTime(toYear, 12, 31);
  }

  return UserInfoService.getUserContributions(
    userName,
    from: from,
    to: to,
  );
});
