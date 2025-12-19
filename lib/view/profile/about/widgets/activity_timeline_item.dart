import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:diohub/view/profile/about/widgets/timeline_commit_content.dart';
import 'package:diohub/view/profile/about/widgets/timeline_issue_content.dart';
import 'package:diohub/view/profile/about/widgets/timeline_pull_request_content.dart';
import 'package:diohub/view/profile/about/widgets/timeline_repository_content.dart';
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
    String actionText;
    DateTime? eventDate;

    switch (event.type) {
      case ActivityEventType.commit:
        if (event.commitData != null) {
          card = TimelineCommitContent(
            commitData: event.commitData!,
            userLogin: userLogin,
            // TODO: Get user email from user profile if available
            userEmail: null,
          );
          eventDate = event.commitData!.date;
          // Build action text for commits
          actionText = 'pushed';
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.issue:
        if (event.issueData != null) {
          card = TimelineIssueContent(
            issueData: event.issueData!,
          );
          eventDate = event.issueData!.createdAt;
          // Build action text for issues
          final state =
              event.issueData!.state == 'CLOSED' ? 'closed' : 'opened';
          actionText = '$state an issue';
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.pullRequest:
        if (event.pullRequestData != null) {
          card = TimelinePullRequestContent(
            prData: event.pullRequestData!,
          );
          eventDate = event.pullRequestData!.createdAt;
          // Build action text for pull requests
          actionText = '${event.pullRequestData!.action} a pull request';
        } else {
          return const SizedBox.shrink();
        }
        break;
      case ActivityEventType.repositoryCreated:
        if (event.repositoryData != null) {
          card = TimelineRepositoryContent(
            repoData: event.repositoryData!,
          );
          eventDate = event.date;
          // Build action text for repository creation
          actionText = 'created ${event.repositoryData!.name}';
        } else {
          return const SizedBox.shrink();
        }
        break;
    }

    // Wrap with TimelineTile for visual timeline
    final iconData = _getEventIcon(event.type);
    final iconColor = _getEventIconColor(context, event.type);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 24,
        height: 24,
        // indicatorXY: 0.5,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action text and timestamp outside the card
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildActionText(context, actionText),
                  ),
                  if (eventDate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      eventDate.toRelativeDate(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Card content
            card,
          ],
        ),
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

  /// Build action text with proper formatting (action verb + bold name)
  Widget _buildActionText(BuildContext context, String? actionText) {
    if (actionText == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    // Format: "action verb name" (e.g., "created repository-name", "pushed")
    final words = actionText.split(' ');
    if (words.length >= 2) {
      final action = words[0];
      final name = words.sublist(1).join(' ');
      return Text.rich(
        TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
          children: [
            TextSpan(text: '$action '),
            TextSpan(
              text: name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Fallback: plain text
    return Text(
      actionText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 12,
      ),
    );
  }
}
