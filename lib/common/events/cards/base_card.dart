import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
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
    this.padding,
    this.headerPadding,
    this.childPadding,
    this.spacing,
    this.useNestedCard = true,
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
    this.padding,
    this.headerPadding,
    this.childPadding,
    this.spacing,
    this.useNestedCard = true,
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
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? childPadding;
  final double? spacing;
  final bool useNestedCard;

  @override
  Widget build(final BuildContext context) {
    // Modern feed-style design with prominent icon and clean hierarchy
    final Widget headerRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Actor avatar with event icon badge
        if (avatarUrl != null && actor != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: userLogin != null
                    ? () {
                        navigateToProfile(
                          context: context,
                          login: userLogin!,
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ShimmerWidget(
                      child: Container(
                        width: 32,
                        height: 32,
                        color: context.colorScheme.surfaceVariant,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 32,
                      height: 32,
                      color: context.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Event icon badge
              if (eventType != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getEventIconColor(context, eventType)
                          .withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getEventIcon(eventType),
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        if (avatarUrl != null && actor != null) const SizedBox(width: 8),
        // Actor name and action text in title/subtitle layout
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title: Actor name
              if (actor != null)
                GestureDetector(
                  onTap: userLogin != null
                      ? () {
                          navigateToProfile(
                            context: context,
                            login: userLogin!,
                          );
                        }
                      : null,
                  child: Text(
                    actor!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                  ),
                ),
              // Subtitle: Action description
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        // fontWeight: FontWeight.w400,
                        color: context.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                  children: headerText,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget? trailingWidget = date != null
        ? Text(
            getDate(date.toString()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 10,
                ),
          )
        : null;

    final Widget childWidget = children.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(
              children.length,
              (final int index) => Row(
                children: [
                  Flexible(child: children[index]),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    if (useNestedCard) {
      return NestedCardWithHeader(
        padding: padding,
        headerPadding: headerPadding,
        childPadding: childPadding,
        spacing: spacing,
        header: headerRow,
        trailing: trailingWidget,
        child: childWidget,
      );
    }

    return HeaderCard(
      padding: padding,
      headerPadding: headerPadding,
      spacing: spacing,
      header: headerRow,
      trailing: trailingWidget,
      child: children.isNotEmpty
          ? Padding(
              padding: childPadding ?? const EdgeInsets.all(8),
              child: childWidget,
            )
          : childWidget,
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
