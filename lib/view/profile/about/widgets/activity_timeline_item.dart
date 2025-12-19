import 'package:diohub/common/activity/timeline_commit_card.dart';
import 'package:diohub/common/activity/timeline_issue_card.dart';
import 'package:diohub/common/activity/timeline_pull_request_card.dart';
import 'package:diohub/common/activity/timeline_repository_card.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:timeline_tile/timeline_tile.dart';

/// Widget that displays a single activity timeline event using unified card widgets
/// Includes TimelineTile for visual timeline with icons and connecting lines
class ActivityTimelineItem extends StatelessWidget {
  const ActivityTimelineItem({
    required this.event,
    required this.userLogin,
    required this.userAvatarUrl,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final ActivityTimelineEvent event;
  final String userLogin;
  final String? userAvatarUrl;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    Widget card;

    switch (event.type) {
      case ActivityEventType.commit:
        if (event.commitData != null) {
          card = TimelineCommitCard(
            commitData: event.commitData!,
            userLogin: userLogin,
            userAvatarUrl: userAvatarUrl,
          );
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.issue:
        if (event.issueData != null) {
          card = TimelineIssueCard(
            issueData: event.issueData!,
            userLogin: userLogin,
            userAvatarUrl: userAvatarUrl,
          );
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.pullRequest:
        if (event.pullRequestData != null) {
          card = TimelinePullRequestCard(
            prData: event.pullRequestData!,
            userLogin: userLogin,
            userAvatarUrl: userAvatarUrl,
          );
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.repositoryCreated:
        if (event.repositoryData != null) {
          card = TimelineRepositoryCard(
            repoData: event.repositoryData!,
            userLogin: userLogin,
            userAvatarUrl: userAvatarUrl,
            date: event.date,
          );
        } else {
          return const SizedBox.shrink();
        }
        break;
      default:
        return const SizedBox.shrink();
    }

    // Wrap with TimelineTile for visual timeline
    final iconData = _getEventIcon(event.type);
    final iconColor = _getEventIconColor(context, event.type);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 20,
        height: 20,
        indicatorXY: 0.5,
        drawGap: true,
        indicator: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.surface,
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            iconData,
            size: 12,
            color: iconColor,
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        thickness: 1,
        color: context.colorScheme.outlineVariant.withOpacity(0.3),
      ),
      afterLineStyle: LineStyle(
        thickness: 1,
        color: context.colorScheme.outlineVariant.withOpacity(0.3),
      ),
      endChild: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: card,
      ),
    );
  }

  IconData _getEventIcon(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.commit:
        return Octicons.git_commit;
      case ActivityEventType.pullRequest:
        return Octicons.git_pull_request;
      case ActivityEventType.issue:
        return Octicons.issue_opened;
      case ActivityEventType.repositoryCreated:
        return Octicons.repo;
    }
  }

  Color _getEventIconColor(BuildContext context, ActivityEventType type) {
    switch (type) {
      case ActivityEventType.commit:
        return const Color(0xFF2196F3); // Blue
      case ActivityEventType.pullRequest:
        return const Color(0xFF9C27B0); // Purple
      case ActivityEventType.issue:
        return const Color(0xFF4CAF50); // Green
      case ActivityEventType.repositoryCreated:
        return const Color(0xFF009688); // Teal
    }
  }
}
