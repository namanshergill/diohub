import 'package:diohub/common/misc/organization_access_notice.dart';
import 'package:diohub/common/misc/organization_card.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.data.gql.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Lists the organizations the authenticated user belongs to.
class OrganizationsTab extends StatelessWidget {
  const OrganizationsTab({super.key});

  static const int _pageSize = 20;

  @override
  Widget build(final BuildContext context) =>
      InfiniteScrollWrapper<GgetViewerOrgsData_viewer_organizations_edges?>(
        pageSize: _pageSize,
        future: (
          final ScrollWrapperFutureArguments<
                  GgetViewerOrgsData_viewer_organizations_edges?>
              data,
        ) async =>
            UserInfoService.getViewerOrgs(
          refresh: data.refresh,
          after: data.lastItem?.cursor,
        ),
        header: (final BuildContext context) =>
            const OrganizationAccessNotice(),
        separatorBuilder: (final BuildContext context, final int index) =>
            const Divider(height: 1, indent: 72),
        listEndIndicator: false,
        emptyBuilder: (final BuildContext context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: <Widget>[
              Icon(
                Octicons.organization,
                size: 44,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No organizations found',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are not a member of any organizations, or this account '
                'has not been approved for them yet.',
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
                  GgetViewerOrgsData_viewer_organizations_edges?>
              data,
        ) {
          final GgetViewerOrgsData_viewer_organizations_edges_node? node =
              data.item?.node;
          if (node == null) {
            return const SizedBox.shrink();
          }
          return OrganizationCard(
            login: node.login,
            avatarUrl: node.avatarUrl.toString(),
            name: node.name,
            description: node.description,
            repositoryCount: node.repositories.totalCount,
            isVerified: node.isVerified,
          );
        },
      );
}
