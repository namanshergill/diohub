import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Overview tab for an organization profile.
///
/// Users have contribution graphs and activity timelines; organizations
/// instead expose profile details, membership/repository counts and pinned
/// repositories.
class OrganizationAboutScreen extends StatelessWidget {
  const OrganizationAboutScreen(
    this.organization, {
    required this.pinnedRepositories,
    super.key,
  });

  final GuserInfoData_repositoryOwner__asOrganization organization;
  final List<GrepositoryFields> pinnedRepositories;

  Future<void> _openUrl(final Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(final BuildContext context) {
    final String? description = organization.description?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        InfoCard(
          title: 'About',
          leading: InfoCard.leadingIcon(icon: Icons.info_outline_rounded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              description != null && description.isNotEmpty
                  ? description
                  : 'This organization has not added a description yet.',
              style: context.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: description != null && description.isNotEmpty
                    ? context.colorScheme.onSurface
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        InfoCard.children(
          title: 'Details',
          leading: InfoCard.leadingIcon(icon: Octicons.organization),
          children: <Widget>[
            _OrganizationInfoRow(
              icon: Octicons.people,
              label: 'Members',
              value: '${organization.membersWithRole.totalCount}',
            ),
            _OrganizationInfoRow(
              icon: Octicons.repo,
              label: 'Repositories',
              value: '${organization.repositories.totalCount}',
            ),
            _OrganizationInfoRow(
              icon: Octicons.eye,
              label: 'Visibility',
              value: '${organization.publicRepositories.totalCount} public'
                  '${organization.privateRepositories.totalCount > 0 ? ' · ${organization.privateRepositories.totalCount} private' : ''}',
            ),
            if (organization.isVerified)
              const _OrganizationInfoRow(
                icon: Octicons.verified,
                label: 'Verified',
                value: 'Verified organization',
              ),
            if (organization.viewerIsAMember)
              _OrganizationInfoRow(
                icon: Octicons.shield_check,
                label: 'Your role',
                value: organization.viewerCanAdminister
                    ? 'Owner / admin'
                    : 'Member',
              ),
            if (organization.location != null)
              _OrganizationInfoRow(
                icon: Octicons.location,
                label: 'Location',
                value: organization.location!,
              ),
            if (organization.websiteUrl != null)
              _OrganizationInfoRow(
                icon: Octicons.link,
                label: 'Website',
                value: organization.websiteUrl!.toString(),
                onTap: () => _openUrl(organization.websiteUrl!),
              ),
            if (organization.twitterUsername != null)
              _OrganizationInfoRow(
                icon: Octicons.mark_github,
                label: 'Twitter',
                value: '@${organization.twitterUsername}',
                onTap: () => _openUrl(
                  Uri.parse(
                    'https://twitter.com/${organization.twitterUsername}',
                  ),
                ),
              ),
            if (organization.email != null && organization.email!.isNotEmpty)
              _OrganizationInfoRow(
                icon: Octicons.mail,
                label: 'Email',
                value: organization.email!,
                onTap: () => _openUrl(
                  Uri(scheme: 'mailto', path: organization.email),
                ),
              ),
            _OrganizationInfoRow(
              icon: Octicons.calendar,
              label: 'Created',
              value: getDate(
                organization.createdAt.toString(),
                shorten: false,
              ),
            ),
          ],
        ),
        if (pinnedRepositories.isNotEmpty) ...[
          const SizedBox(height: 8),
          InfoCard.children(
            title: 'Pinned Repositories',
            leading: InfoCard.leadingIcon(icon: Octicons.pin),
            children: pinnedRepositories
                .map(
                  (final GrepositoryFields repository) => SizeExpandedSection(
                    child: RepositoryCard(
                      RepoCardDataModel.fromGraphQL(repository),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _OrganizationInfoRow extends StatelessWidget {
  const _OrganizationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: context.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      );
}
