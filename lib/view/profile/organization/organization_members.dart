import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/organization_members.data.gql.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Paginated list of an organization's members.
class OrganizationMembers extends StatelessWidget {
  const OrganizationMembers(this.organization, {super.key});

  final String organization;

  static const int _pageSize = 20;

  String? _roleLabel(final GOrganizationMemberRole? role) {
    if (role == GOrganizationMemberRole.ADMIN) {
      return 'Admin';
    }
    if (role == GOrganizationMemberRole.MEMBER) {
      return 'Member';
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) => InfiniteScrollWrapper<
          GgetOrganizationMembersData_organization_membersWithRole_edges?>(
        pageSize: _pageSize,
        future: (
          final ScrollWrapperFutureArguments<
                  GgetOrganizationMembersData_organization_membersWithRole_edges?>
              data,
        ) async =>
            UserInfoService.getOrganizationMembers(
          organization,
          first: data.pageSize,
          refresh: data.refresh,
          after: data.lastItem?.cursor,
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            const Divider(height: 1, indent: 68),
        listEndIndicator: false,
        emptyBuilder: (final BuildContext context) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Icon(
                Octicons.people,
                size: 40,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No public members',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Membership of this organization is private, or it has no '
                'members to show.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        builder: (
          final BuildContext context,
          final ScrollWrapperBuilderData<
                  GgetOrganizationMembersData_organization_membersWithRole_edges?>
              data,
        ) {
          final GgetOrganizationMembersData_organization_membersWithRole_edges?
              edge = data.item;
          final GgetOrganizationMembersData_organization_membersWithRole_edges_node?
              node = edge?.node;
          if (node == null) {
            return const SizedBox.shrink();
          }
          final String? role = _roleLabel(edge?.role);

          return InkPot(
            onTap: () => AutoRouter.of(context)
                .push(UserProfileRoute(login: node.login)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  ProfileTile.avatar(
                    avatarUrl: node.avatarUrl.toString(),
                    size: 36,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          node.name?.trim().isNotEmpty == true
                              ? node.name!
                              : node.login,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@${node.login}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (node.bio != null &&
                            node.bio!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            node.bio!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (role != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer
                            .withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        role,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
