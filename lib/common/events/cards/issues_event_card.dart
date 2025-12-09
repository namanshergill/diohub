import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
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
        eventType: event.type,
        actor: event.actor!.login,
        headerText: <TextSpan>[
          TextSpan(text: '${event.payload!.action} $trailingHeaderText'),
        ],
        userLogin: event.actor!.login,
        date: event.createdAt,
        avatarUrl: event.actor!.avatarUrl,
        child: IssueListCard(
          event.payload!.issue!,
          commentsSince: time,
          // disableMaterial: true,
          // compact: true,
        ),
      );
}
