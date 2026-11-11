import 'package:diohub/common/misc/organization_card.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Lists the public organizations a user belongs to.
class UserOrganizations extends StatelessWidget {
  const UserOrganizations(this.login, {super.key});

  final String login;

  static const int _pageSize = 20;

  @override
  Widget build(final BuildContext context) => InfiniteScrollWrapper<
          GgetUserOrganizationsData_user_organizations_edges?>(
        pageSize: _pageSize,
        future: (
          final ScrollWrapperFutureArguments<
                  GgetUserOrganizationsData_user_organizations_edges?>
              data,
        ) async =>
            UserInfoService.getUserOrganizations(
          login,
          refresh: data.refresh,
          after: data.lastItem?.cursor,
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            const Divider(height: 1, indent: 72),
        listEndIndicator: false,
        emptyBuilder: (final BuildContext context) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Icon(
                Octicons.organization,
                size: 40,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No organizations',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$login is not a public member of any organizations.',
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
                  GgetUserOrganizationsData_user_organizations_edges?>
              data,
        ) {
          final GgetUserOrganizationsData_user_organizations_edges_node? node =
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
