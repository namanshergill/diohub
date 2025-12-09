import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class BaseEventCard extends StatelessWidget {
  const BaseEventCard({
    required this.headerText,
    required this.children,
    this.actor,
    this.avatarUrl,
    this.userLogin,
    this.date,
    this.eventType,
    super.key,
    required this.isInTimeline,
  });

  BaseEventCard.singular({
    required this.headerText,
    required final Widget child,
    this.actor,
    this.avatarUrl,
    final VoidCallback? onTap,
    this.userLogin,
    this.date,
    this.eventType,
    super.key,
    required this.isInTimeline,
  }) : children = <Widget>[
          InkPot(onTap: onTap, child: child),
        ];

  final bool isInTimeline;
  final List<Widget> children;
  final String? avatarUrl;
  final String? actor;
  final String? userLogin;
  final List<TextSpan> headerText;
  final DateTime? date;
  final EventsType? eventType;

  @override
  Widget build(final BuildContext context) {
    // Modern feed-style design with prominent icon and clean hierarchy
    return HeaderCard(
      header: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Smaller event icon in colored container
          if (eventType != null)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _getEventIconColor(context, eventType).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getEventIcon(eventType),
                size: 12,
                color: _getEventIconColor(context, eventType),
              ),
            ),
          if (eventType != null) const SizedBox(width: 6),
          // Actor avatar
          if (avatarUrl != null && actor != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerWidget(
                  child: Container(
                    width: 18,
                    height: 18,
                    color: context.colorScheme.surfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 18,
                  height: 18,
                  color: context.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    size: 10,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (avatarUrl != null && actor != null) const SizedBox(width: 4),
          // Actor name and action text combined in RichText
          Flexible(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                children: <TextSpan>[
                  // Tappable actor name
                  if (actor != null)
                    TextSpan(
                      text: actor!,
                      recognizer: userLogin != null
                          ? (TapGestureRecognizer()
                            ..onTap = () {
                              navigateToProfile(
                                context: context,
                                login: userLogin!,
                              );
                            })
                          : null,
                          // style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  // Space between actor and action
                  if (actor != null) const TextSpan(text: ' '),
                  // Action description text - children automatically inherit parent style
                  ...headerText,
                ],
              ),
            ),
          ),
        ],
      ),
      trailing: date != null
          ? Text(
              getDate(date.toString()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 11,
                  ),
            )
          : null,
      child: children.isNotEmpty
          ? Column(
              children: List<Widget>.generate(
                children.length,
                (final int index) => Column(
                  children: <Widget>[
                    if (index > 0) const SizedBox(height: 8),
                    children[index],
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
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
