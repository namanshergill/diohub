import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A list tile for an organization.
///
/// Used by the home Organizations tab and the Organizations tab on user
/// profiles. Tapping it opens the full organization profile.
class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.description,
    this.repositoryCount,
    this.isVerified = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    super.key,
  });

  final String login;
  final String? avatarUrl;
  final String? name;
  final String? description;
  final int? repositoryCount;
  final bool isVerified;
  final EdgeInsets padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String displayName =
        (name?.trim().isNotEmpty ?? false) ? name!.trim() : login;

    return InkPot(
      onTap: () => AutoRouter.of(context).push(UserProfileRoute(login: login)),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl ?? 'N/A',
                height: 44,
                width: 44,
                fit: BoxFit.cover,
                placeholder: (final BuildContext context, final _) => Container(
                  height: 44,
                  width: 44,
                  color: colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (final BuildContext context, final _, final __) =>
                    Icon(
                  Octicons.organization,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Octicons.verified,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$login',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                      ),
                    ),
                  ],
                  if (repositoryCount != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Octicons.repo,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$repositoryCount '
                          '${repositoryCount == 1 ? 'repository' : 'repositories'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                Octicons.chevron_right,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
