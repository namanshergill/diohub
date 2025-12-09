import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RepoEventCard extends StatelessWidget {
  const RepoEventCard(
    this.event,
    this.eventTextMiddle, {
    this.eventTextEnd,
    this.branch,
    this.repo,
    this.refresh = false,
    super.key,
    required this.isInTimeline,
  });
  final EventsModel event;
  final String eventTextMiddle;
  final RepositoryModel? repo;
  final String? eventTextEnd;
  final String? branch;
  final bool refresh;
  final bool isInTimeline;

  @override
  Widget build(final BuildContext context) => BaseEventCard.singular(
        isInTimeline: isInTimeline,
        eventType: event.type,
        actor: event.actor!.login,
        headerText: <TextSpan>[
          TextSpan(text: eventTextMiddle),
          if (eventTextEnd != null) TextSpan(text: ' $eventTextEnd'),
        ],
        userLogin: event.actor!.login,
        date: event.createdAt,
        avatarUrl: event.actor!.avatarUrl,
        child: RepoCardLoading(
          repo != null ? repo!.url : event.repo!.url,
          repo != null ? repo!.name : event.repo!.name,
          // elevation: 0,
          branch: branch,
          refresh: refresh,
        ),
      );
}
