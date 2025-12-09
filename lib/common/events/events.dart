import 'package:diohub/common/events/cards/added_event_card.dart';
import 'package:diohub/common/events/cards/issues_event_card.dart';
import 'package:diohub/common/events/cards/pull_event_card.dart';
import 'package:diohub/common/events/cards/push_event_card.dart';
import 'package:diohub/common/events/cards/watch_event_card.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/activity/events_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';

class Events extends StatelessWidget {
  const Events({
    this.privateEvents = true,
    this.specificUser,
    super.key,
    this.isTimeline = true,
  });

  final bool privateEvents;
  final String? specificUser;
  final bool isTimeline;

  @override
  Widget build(final BuildContext context) {
    final CurrentUserProvider user = Provider.of<CurrentUserProvider>(context);
    return InfiniteScrollWrapper<EventsModel>(
      padding:  EdgeInsets.only(top: 4),
      // separatrBuilder: (final BuildContext context, final int index) =>
      //     const Divider(
      //   height: 16,
      // ),
      // header: (final BuildContext context) => Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 16),
      //   child: Column(
      //     children: <Widget>[
      //       // SizedBox(
      //       //   height: 8,
      //       // ),
      //       Card(
      //         margin: EdgeInsets.zero,
      //         child: ListTile(
      //           title: const Text('Organizations'),
      //           leading: const Icon(
      //             Octicons.organization,
      //             // color: Colors.,
      //           ),
      //           trailing: InfoCard.leadingIcon(
      //             icon: Icons.arrow_right_rounded,
      //           ),
      //           // child: const Text('1'),
      //         ),
      //       ),
      //       const SizedBox(
      //         height: 8,
      //       ),
      //       Card(
      //         margin: EdgeInsets.zero,
      //         child: ListTile(
      //           subtitle: const Text('2 open'),
      //           title: const Text('Pull Requests'),
      //           leading: const Icon(
      //             Octicons.git_pull_request,
      //             color: Colors.deepPurple,
      //           ),
      //           trailing: InfoCard.leadingIcon(
      //             icon: Icons.arrow_right_rounded,
      //           ),
      //           // child: const Text('7 Open'),
      //         ),
      //       ),
      //       const SizedBox(
      //         height: 8,
      //       ),
      //       Card(
      //         margin: EdgeInsets.zero,
      //         child: ListTile(
      //           leading: const Icon(
      //             Octicons.issue_opened,
      //             color: Colors.green,
      //           ),
      //           title: const Text('Issues'),
      //           trailing: InfoCard.leadingIcon(
      //             icon: Icons.arrow_right_rounded,
      //           ),
      //           subtitle: const Text('27 Open'),
      //           // child: const Text('27 Open'),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
  
      filterFn: (final List<EventsModel> items) {
        final List<EventsModel> temp = <EventsModel>[];
        for (final EventsModel item in items) {
          if (<EventsType>{
            // EventsType.CommitCommentEvent,
            EventsType.CreateEvent,
            EventsType.DeleteEvent,
            EventsType.ForkEvent,
            // EventsType.GollumEvent,
            EventsType.IssueCommentEvent,
            EventsType.IssuesEvent,
            EventsType.MemberEvent,
            EventsType.PublicEvent,
            EventsType.PullRequestEvent,
            // EventsType.PullRequestReviewCommentEvent,
            EventsType.PushEvent,
            // EventsType.ReleaseEvent,
            // EventsType.SponsorshipEvent,
            EventsType.WatchEvent,
          }.contains(item.type)) {
            temp.add(item);
          }
        }

        return temp;
      },
      future: (
        final ScrollWrapperFutureArguments<EventsModel> data,
      ) async {
        if (specificUser != null) {
          return EventsService.getUserEvents(
            specificUser,
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        } else if (privateEvents) {
          return EventsService.getReceivedEvents(
            user.data.login,
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        } else {
          return EventsService.getPublicEvents(
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        }
      },
      builder: (
        final BuildContext context,
        final ScrollWrapperBuilderData<EventsModel> data,
      ) {
        final EventsModel item = data.item;
        Widget child = buildCard(item, data);
        if (isTimeline) {
          final IconData eventIcon = _getEventIcon(item.type);
          final Color iconColor = _getEventIconColor(context, item.type);

          child = TimelineTile(
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
                  eventIcon,
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
              child: child,
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            // vertical: isTimeline ? 0 : 2,
          ),
          child: child,
        );
      },
    );
  }

  Builder buildCard(
    final EventsModel item,
    final ScrollWrapperBuilderData<EventsModel> data,
  ) {
    return Builder(
      builder: (final BuildContext context) {
        if (item.type == EventsType.PushEvent) {
          return PushEventCard(
            isInTimeline: isTimeline,
            item,
            item.payload!,
          );
        } else if (item.type == EventsType.WatchEvent) {
          return RepoEventCard(
            isInTimeline: isTimeline,
            item,
            'starred',
            refresh: data.refresh,
          );
        } else if (item.type == EventsType.CreateEvent) {
          if (item.payload!.refType == RefType.REPOSITORY) {
            return RepoEventCard(
              isInTimeline: isTimeline,
              item,
              'created',
              refresh: data.refresh,
            );
          } else if (item.payload!.refType == RefType.BRANCH) {
            return RepoEventCard(
              isInTimeline: isTimeline,
              item,
              "created a new branch '${item.payload!.ref}'",
              branch: item.payload!.ref,
              refresh: data.refresh,
            );
          }
          // Fallback for other CreateEvent types
          return Padding(
            padding: const EdgeInsets.all(42),
            child: Center(
              child: Text(
                'Unimplemented: ${eventsValues.reverse![item.type]}',
              ),
            ),
          );
        } else if (item.type == EventsType.PublicEvent) {
          return RepoEventCard(
            isInTimeline: isTimeline,
            item,
            'made',
            eventTextEnd: 'public',
            refresh: data.refresh,
          );
        } else if (item.type == EventsType.MemberEvent) {
          return AddedEventCard(
            isInTimeline: isTimeline,
            item,
            '${item.payload!.action} ${item.payload!.member!.login} to',
          );
        } else if (item.type == EventsType.DeleteEvent) {
          return RepoEventCard(
            isInTimeline: isTimeline,
            item,
            "deleted a ${refTypeValues.reverse![item.payload!.refType]} '${item.payload!.ref}'",
            refresh: data.refresh,
          );
        } else if (item.type == EventsType.PullRequestEvent) {
          return PullEventCard(
            isInTimeline: isTimeline,
            item,
          );
        } else if (item.type == EventsType.ForkEvent) {
          return RepoEventCard(
            isInTimeline: isTimeline,
            item,
            'forked',
            repo: item.payload!.forkee,
            refresh: data.refresh,
          );
        } else if (item.type == EventsType.IssuesEvent) {
          return IssuesEventCard(
            isInTimeline: isTimeline,
            item,
            'an issue',
          );
        } else if (item.type == EventsType.IssueCommentEvent) {
          return IssuesEventCard(
            isInTimeline: isTimeline,
            item,
            'a comment',
            time: item.createdAt,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(
            42,
          ),
          child: Center(
            child: Text(
              'Unimplemented: ${eventsValues.reverse![item.type]}',
            ),
          ),
        );
      },
    );
  }

  IconData _getEventIcon(EventsType? type) {
    switch (type) {
      case EventsType.PushEvent:
        return Octicons.git_commit;
      case EventsType.PullRequestEvent:
        return Octicons.git_pull_request;
      case EventsType.IssuesEvent:
        return Octicons.issue_opened;
      case EventsType.IssueCommentEvent:
        return Octicons.comment;
      case EventsType.WatchEvent:
        return Octicons.star;
      case EventsType.ForkEvent:
        return Octicons.repo_forked;
      case EventsType.CreateEvent:
        return Octicons.plus;
      case EventsType.DeleteEvent:
        return Octicons.trash;
      case EventsType.PublicEvent:
        return Octicons.globe;
      case EventsType.MemberEvent:
        return Octicons.person_add;
      default:
        return Octicons.circle;
    }
  }

  Color _getEventIconColor(BuildContext context, EventsType? type) {
    // Custom colors for event type icons
    switch (type) {
      case EventsType.PushEvent:
        return const Color(0xFF2196F3); // Blue
      case EventsType.PullRequestEvent:
        return const Color(0xFF9C27B0); // Purple
      case EventsType.IssuesEvent:
        return const Color(0xFF4CAF50); // Green
      case EventsType.IssueCommentEvent:
        return const Color(0xFF00ACC1); // Cyan/Teal for comments
      case EventsType.WatchEvent:
        return const Color(0xFFFFC107); // Amber/Yellow
      case EventsType.ForkEvent:
        return const Color(0xFF00BCD4); // Cyan
      case EventsType.CreateEvent:
        return const Color(0xFF009688); // Teal
      case EventsType.DeleteEvent:
        return const Color(0xFFF44336); // Red
      case EventsType.PublicEvent:
        return const Color(0xFF3F51B5); // Indigo
      case EventsType.MemberEvent:
        return const Color(0xFFFF9800); // Orange
      default:
        return context.colorScheme.onSurfaceVariant;
    }
  }
}
