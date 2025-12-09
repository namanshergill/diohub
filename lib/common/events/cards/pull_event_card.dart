import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/pulls/pull_list_card.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:flutter/material.dart';

class PullEventCard extends StatelessWidget {
  const PullEventCard(this.event, {super.key, required this.isInTimeline});
  final EventsModel event;
  final bool isInTimeline;

  @override
  Widget build(final BuildContext context) => BaseEventCard.singular(
        isInTimeline: isInTimeline,
        eventType: event.type,
        actor: event.actor!.login,
        headerText: <TextSpan>[
          TextSpan(text: '${event.payload!.action} a pull request in '),
          TextSpan(
            text: event.repo!.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        userLogin: event.actor!.login,
        date: event.createdAt,
        avatarUrl: event.actor!.avatarUrl,
        child: PullListCard(
          event.payload!.pullRequest!,
          showRepoName: false,
        ),
      );
}
