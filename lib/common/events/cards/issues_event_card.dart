import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class IssuesEventCard extends StatelessWidget {
  const IssuesEventCard(
    this.event,
    this.trailingHeaderText, {
    this.time,
    super.key,
    required this.isInTimeline,
  });
  final bool isInTimeline;
  final EventsModel event;
  final DateTime? time;
  final String trailingHeaderText;

  @override
  Widget build(final BuildContext context) => BaseEventCard.singular(
        isInTimeline: isInTimeline,
        // useNestedCard: false,
        // childPadding: EdgeInsets.zero,
        eventType: event.type,
        actor: event.actor!.login,
        headerText: <TextSpan>[
          TextSpan(text: '${event.payload!.action} $trailingHeaderText'),
        ],
        userLogin: event.actor!.login,
        date: event.createdAt,
        avatarUrl: event.actor!.avatarUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Show issue card (without description for comment events)
            IssueListCard(
              event.payload!.issue!,
              commentsSince: time,
              showRepoName: true,
              showDescription: time == null,
            ),

            // Comment body for IssueCommentEvent - focus only on comment
            if (time != null &&
                event.payload!.comment?.body != null &&
                (event.payload!.comment!.body ?? '').trim().isNotEmpty) ...[
              ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          context.colorScheme.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TrimmableMarkdownContent(
                    text: event.payload!.comment!.body!.trim(),
                    repo: event.repo?.name,
                  ),
                )
              ],
            ],
          ],
        ),
      );
}
