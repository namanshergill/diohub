import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';

/// Convenience accessors shared by user and organization profiles.
///
/// The `userInfo` query resolves a [GuserInfoData_repositoryOwner], which is
/// either a User or an Organization. The profile screen has to display both,
/// so these helpers keep the type checks in one place.
extension ProfileOwnerExtensions on GuserInfoData_repositoryOwner {
  bool get isUser => G__typename == 'User';

  bool get isOrganization => G__typename == 'Organization';

  GuserInfoData_repositoryOwner__asUser? get asUser =>
      this is GuserInfoData_repositoryOwner__asUser
          ? this as GuserInfoData_repositoryOwner__asUser
          : null;

  GuserInfoData_repositoryOwner__asOrganization? get asOrganization =>
      this is GuserInfoData_repositoryOwner__asOrganization
          ? this as GuserInfoData_repositoryOwner__asOrganization
          : null;

  String? get displayName => when<String?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) => user.name,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.name,
        orElse: () => null,
      );

  /// Name if one is set, otherwise the login.
  String get nameOrLogin {
    final String? name = displayName?.trim();
    return name != null && name.isNotEmpty ? name : login;
  }

  String? get description => when<String?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) => user.bio,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.description,
        orElse: () => null,
      );

  String? get location => when<String?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.location,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.location,
        orElse: () => null,
      );

  Uri? get websiteUrl => when<Uri?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.websiteUrl,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.websiteUrl,
        orElse: () => null,
      );

  String? get twitterUsername => when<String?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.twitterUsername,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.twitterUsername,
        orElse: () => null,
      );

  String? get email => when<String?>(
        user: (final GuserInfoData_repositoryOwner__asUser user) => user.email,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.email,
        orElse: () => null,
      );

  DateTime get createdAt => when<DateTime>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.createdAt,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.createdAt,
        orElse: () => DateTime.now(),
      );

  DateTime get updatedAt => when<DateTime>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.updatedAt,
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.updatedAt,
        orElse: () => DateTime.now(),
      );

  int get repositoryCount => repositories.totalCount;

  bool get isVerifiedOrganization => asOrganization?.isVerified ?? false;

  bool get isViewerOrganizationMember =>
      asOrganization?.viewerIsAMember ?? false;

  bool get viewerCanAdministerOrganization =>
      asOrganization?.viewerCanAdminister ?? false;

  int get organizationMemberCount =>
      asOrganization?.membersWithRole.totalCount ?? 0;

  int get organizationPublicRepositoryCount =>
      asOrganization?.publicRepositories.totalCount ?? 0;

  int get organizationPrivateRepositoryCount =>
      asOrganization?.privateRepositories.totalCount ?? 0;

  int get followersCount => asUser?.followers.totalCount ?? 0;

  int get followingCount => asUser?.following.totalCount ?? 0;

  int get organizationCount => asUser?.organizations.totalCount ?? 0;

  int get gistCount => asUser?.gists.totalCount ?? 0;

  int get starredRepositoryCount => asUser?.starredRepositories.totalCount ?? 0;

  int get pullRequestCount => asUser?.pullRequests.totalCount ?? 0;

  int get issueCount => asUser?.issues.totalCount ?? 0;

  bool get isViewer => asUser?.isViewer ?? false;

  bool get viewerCanFollow => asUser?.viewerCanFollow ?? false;

  bool get viewerIsFollowing => asUser?.viewerIsFollowing ?? false;

  String? get company => asUser?.company;

  String? get pronouns => asUser?.pronouns;

  String? get statusMessage => asUser?.status?.message;

  String? get statusEmoji => asUser?.status?.emoji;

  bool get isHireable => asUser?.isHireable ?? false;

  /// Pinned repositories selected by this profile owner.
  List<GrepositoryFields> get pinnedRepositories =>
      when<List<GrepositoryFields>>(
        user: (final GuserInfoData_repositoryOwner__asUser user) =>
            user.pinnedItems.edges
                ?.map(
                  (
                    final GuserInfoData_repositoryOwner__asUser_pinnedItems_edges?
                        edge,
                  ) =>
                      edge?.node?.when<GrepositoryFields?>(
                    repository: (
                      final GuserInfoData_repositoryOwner__asUser_pinnedItems_edges_node__asRepository
                          repository,
                    ) =>
                        repository,
                    orElse: () => null,
                  ),
                )
                .whereType<GrepositoryFields>()
                .toList() ??
            const <GrepositoryFields>[],
        organization: (
          final GuserInfoData_repositoryOwner__asOrganization organization,
        ) =>
            organization.pinnedItems.edges
                ?.map(
                  (
                    final GuserInfoData_repositoryOwner__asOrganization_pinnedItems_edges?
                        edge,
                  ) =>
                      edge?.node?.when<GrepositoryFields?>(
                    repository: (
                      final GuserInfoData_repositoryOwner__asOrganization_pinnedItems_edges_node__asRepository
                          repository,
                    ) =>
                        repository,
                    orElse: () => null,
                  ),
                )
                .whereType<GrepositoryFields>()
                .toList() ??
            const <GrepositoryFields>[],
        orElse: () => const <GrepositoryFields>[],
      );
}
