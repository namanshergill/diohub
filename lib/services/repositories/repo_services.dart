import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_templates.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_templates.req.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/branches_list.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/branches_list.req.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commit_info.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commit_info.req.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/commits_list.req.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.req.gql.dart';
import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/models/repositories/branch_list_model.dart';
import 'package:diohub/models/repositories/branch_model.dart';
import 'package:diohub/models/repositories/commit_list_model.dart';
import 'package:diohub/models/repositories/readme_model.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/utils/type_cast.dart';

class RepositoryServices {
  RepositoryServices({
    required this.name,
    required this.owner,
  });

  final String owner;
  final String name;

  static final GraphqlHandler _gqlHandler = GraphqlHandler();
  static final RESTHandler _restHandler = RESTHandler(
      // apiLogSettings: APILoggingSettings.comprehensive(),
      );

  Future<GpinnedIssuesData_repository_pinnedIssues> getPinnedIssues() async {
    final GQLResponse response = await _gqlHandler.query(
      GpinnedIssuesReq(
        (final GpinnedIssuesReqBuilder b) => b
          ..vars.name = name
          ..vars.owner = owner,
      ),
    );

    return GpinnedIssuesData.fromJson(response.data!)!
        .repository!
        .pinnedIssues!;
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#get-a-repository
  static Future<RepositoryModel> fetchRepository(
    final String url, {
    final bool refresh = false,
  }) async {
    final Response<TypeMap> response = await _restHandler.get<TypeMap>(
      url,
      refreshCache: refresh,
    );
    return RepositoryModel.fromJson(response.data!);
  }

  // Fetch repository using GraphQL
  // Note: Requires running GraphQL code generator: flutter pub run build_runner build
  Future<GrepositoryInfoData_repository> fetchRepositoryGraphQL({
    required final String owner,
    required final String repo,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await _gqlHandler.query(
      GrepositoryInfoReq(
        (final GrepositoryInfoReqBuilder b) => b
          ..vars.owner = owner
          ..vars.name = repo,
      ),
      refreshCache: refresh,
    );
    final data = GrepositoryInfoData.fromJson(response.data!)!.repository!;
    return data;
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#get-a-repository-readme
  static Future<RepositoryReadmeModel> fetchReadme(
    final String repoUrl, {
    final String? branch,
  }) async {
    final Response<TypeMap> response = await _restHandler.get<TypeMap>(
      '$repoUrl/readme',
      queryParameters: <String, dynamic>{
        'ref': branch,
      },
    );
    return RepositoryReadmeModel.fromJson(response.data!);
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#get-a-branch
  static Future<BranchModel> fetchBranch(final String branchUrl) async {
    final Response<TypeMap> response =
        await _restHandler.get<TypeMap>(branchUrl);
    return BranchModel.fromJson(response.data!);
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#list-branches
  static Future<List<RepoBranchListItemModel>> fetchBranchList(
    final String repoURL,
    final int pageNumber,
    final int perPage, {
    final bool refresh = false,
  }) async {
    final Response<List<dynamic>> response =
        await _restHandler.get<List<dynamic>>(
      '$repoURL/branches',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': pageNumber,
      },
      refreshCache: refresh,
    );
    return response.data!
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => RepoBranchListItemModel.fromJson(e),
        )
        .toList();
  }

  // Get paginated branches list using GraphQL
  static Future<List<GbranchesListData_repository_refs_edges>>
      fetchBranchListGQL({
    required final String owner,
    required final String repo,
    required final int first,
    final String? after,
    final String? query,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await _gqlHandler.query(
      GbranchesListReq(
        (final GbranchesListReqBuilder b) => b
          ..vars.owner = owner
          ..vars.repo = repo
          ..vars.first = first
          ..vars.after = after
          ..vars.query = query,
      ),
      refreshCache: refresh,
    );
    final data = GbranchesListData.fromJson(response.data!)!.repository!;
    final edges = data.refs?.edges?.toList() ?? [];

    return edges.whereType<GbranchesListData_repository_refs_edges>().toList();
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#list-commits
  static Future<List<CommitListModel>> getCommitsList({
    required final String repoURL,
    final String? path,
    final String? sha,
    final int? pageNumber,
    final int? pageSize,
    final String? author,
    final bool refresh = false,
  }) async {
    final Map<String, dynamic> queryParams = <String, dynamic>{
      'path': path,
      'per_page': pageSize,
      'page': pageNumber,
      'sha': sha,
    };
    if (author != null) {
      queryParams['author'] = author;
    }
    final Response<DynamicList> response = await _restHandler.get<DynamicList>(
      '$repoURL/commits',
      queryParameters: queryParams,
      refreshCache: refresh,
    );
    return response.data!
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => CommitListModel.fromJson(e),
        )
        .toList();
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#get-a-commit
  static Future<CommitModel> getCommit(
    final String commitURL, {
    final bool refresh = false,
  }) async {
    final Response<TypeMap> response = await _restHandler.get<TypeMap>(
      commitURL,
      refreshCache: refresh,
    );
    return CommitModel.fromJson(response.data!);
  }

  // Helper to parse commit URL and extract owner, repo, and oid
  // Format: https://api.github.com/repos/{owner}/{repo}/commits/{oid}
  static ({String owner, String repo, String oid}) parseCommitURL(
    final String commitURL,
  ) {
    final List<String> parts = commitURL.split('/');
    // Find 'repos' index
    final int reposIndex = parts.indexWhere((p) => p == 'repos');
    if (reposIndex == -1 || reposIndex + 3 >= parts.length) {
      throw Exception('Invalid commit URL format');
    }
    final String owner = parts[reposIndex + 1];
    final String repo = parts[reposIndex + 2];
    final String oid = parts[reposIndex + 4]; // Skip 'commits'
    return (owner: owner, repo: repo, oid: oid);
  }

  // Helper to parse repo URL and extract owner and repo
  // Format: https://api.github.com/repos/{owner}/{repo}
  static ({String owner, String repo}) parseRepoURL(
    final String repoURL,
  ) {
    final List<String> parts = repoURL.split('/');
    final int reposIndex = parts.indexWhere((p) => p == 'repos');
    if (reposIndex == -1 || reposIndex + 2 >= parts.length) {
      throw Exception('Invalid repo URL format');
    }
    final String owner = parts[reposIndex + 1];
    final String repo = parts[reposIndex + 2];
    return (owner: owner, repo: repo);
  }

  // Get paginated commits list using GraphQL
  // static Future<
  //     ({
  //       List<
  //           GcommitsListData_repository_defaultBranchRef_target__asCommit_history_edges?> edges,
  //       bool hasNextPage,
  //       String? endCursor,
  //     })> getCommitsListGQL({
  //   required final String owner,
  //   required final String repo,
  //   required final int first,
  //   final String? after,
  //   final String? path,
  //   final String? ref,
  //   final String? oid,
  //   final String? authorEmail,
  //   final bool refresh = false,
  // }) async {
  //   // Determine which query to use
  //   if (oid != null) {
  //     final GQLResponse response = await _gqlHandler.query(
  //       GcommitsListByOidReq(
  //         (final GcommitsListByOidReqBuilder b) => b
  //           ..vars.owner = owner
  //           ..vars.repo = repo
  //           ..vars.oid = oid
  //           ..vars.first = first
  //           ..vars.after = after
  //           ..vars.path = path
  //           ..vars.author = authorEmail != null
  //               ? (GcommitAuthorBuilder()..email = authorEmail)
  //               : null,
  //       ),
  //       refreshCache: refresh,
  //     );
  //     final data = GcommitsListByOidData.fromJson(response.data!)!.repository!;
  //     final commit = data.object!.when(
  //       commit: (c) => c,
  //       orElse: () => throw Exception('Object is not a Commit'),
  //     );
  //     return (
  //       edges: commit.history.edges!.toList(),
  //       hasNextPage: commit.history.pageInfo.hasNextPage,
  //       endCursor: commit.history.pageInfo.endCursor,
  //     );
  //   } else if (ref != null) {
  //     final GQLResponse response = await _gqlHandler.query(
  //       GcommitsListByRefReq(
  //         (final GcommitsListByRefReqBuilder b) => b
  //           ..vars.owner = owner
  //           ..vars.repo = repo
  //           ..vars.ref = ref
  //           ..vars.first = first
  //           ..vars.after = after
  //           ..vars.path = path
  //           ..vars.author = authorEmail != null
  //               ? (GcommitAuthorBuilder()..email = authorEmail)
  //               : null,
  //       ),
  //       refreshCache: refresh,
  //     );
  //     final data = GcommitsListByRefData.fromJson(response.data!)!.repository!;
  //     final commit = data.ref!.target!.when(
  //       commit: (c) => c,
  //       orElse: () => throw Exception('Target is not a Commit'),
  //     );
  //     return (
  //       edges: commit.history.edges!.toList(),
  //       hasNextPage: commit.history.pageInfo.hasNextPage,
  //       endCursor: commit.history.pageInfo.endCursor,
  //     );
  //   } else {
  //     final GQLResponse response = await _gqlHandler.query(
  //       GcommitsListReq(
  //         (final GcommitsListReqBuilder b) => b
  //           ..vars.owner = owner
  //           ..vars.repo = repo
  //           ..vars.first = first
  //           ..vars.after = after
  //           ..vars.path = path
  //           ..vars.author = authorEmail != null
  //               ? (GcommitAuthorBuilder()..email = authorEmail)
  //               : null,
  //       ),
  //       refreshCache: refresh,
  //     );
  //     final data = GcommitsListData.fromJson(response.data!)!.repository!;
  //     final commit = data.defaultBranchRef!.target!.when(
  //       commit: (c) => c,
  //       orElse: () => throw Exception('Target is not a Commit'),
  //     );
  //     return (
  //       edges: commit.history.edges!.toList(),
  //       hasNextPage: commit.history.pageInfo.hasNextPage,
  //       endCursor: commit.history.pageInfo.endCursor,
  //     );
  //   }
  // }

  // Get commit info using GraphQL
  static Future<GcommitInfoData_repository_object__asCommit> getCommitInfo({
    required final String owner,
    required final String repo,
    required final String oid,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await _gqlHandler.query(
      GcommitInfoReq(
        (final GcommitInfoReqBuilder b) => b
          ..vars.owner = owner
          ..vars.repo = repo
          ..vars.oid = oid,
      ),
      refreshCache: refresh,
    );
    final data = GcommitInfoData.fromJson(response.data!)!.repository!;
    if (data.object == null) {
      throw Exception('Commit not found');
    }
    return data.object!.when(
      commit: (commit) => commit,
      orElse: () => throw Exception('Object is not a Commit'),
    );
  }

  // Ref: https://docs.github.com/en/rest/reference/repos#get-repository-permissions-for-a-user
  // static Future<bool> checkUserRepoPerms(String login, String? repoURL) async {
  //   final response = await request(
  //     applyBaseURL: false,
  //     showPopup: false,
  //     cacheOptions: CacheManager.defaultCache(),
  //   )
  //       .get(
  //     '$repoURL/collaborators/$login/permission',
  //     options: Options(
  //       validateStatus: (status) {
  //         return status! < 500;
  //       },
  //     ),
  //   );
  //   if (response.statusCode == 200 || response.statusCode == 304) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  static Future<BuiltList<GissueTemplatesData_repository_issueTemplates>>
      getIssueTemplates(final String name, final String owner) async {
    final GQLResponse res = await _gqlHandler.query(
      GissueTemplatesReq(
        (final GissueTemplatesReqBuilder b) => b
          ..vars.owner = owner
          ..vars.name = name,
      ),
    );
    return GissueTemplatesData.fromJson(res.data!)!.repository!.issueTemplates!;
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#check-if-a-repository-is-starred-by-the-authenticated-user
  static Future<GhasStarredData_repository> isStarred(
    final String owner,
    final String name,
  ) async {
    final GQLResponse res = await _gqlHandler.query(
      GhasStarredReq(
        (
          final GhasStarredReqBuilder b,
        ) =>
            b
              ..vars.name = name
              ..vars.owner = name,
      ),
      refreshCache: true,
    );
    return GhasStarredData.fromJson(res.data!)!.repository!;
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#star-a-repository-for-the-authenticated-user
  static Future<bool> changeStar(
    final String owner,
    final String name, {
    required final bool isStarred,
  }) async {
    final String endpoint = '/user/starred/$owner/$name';
    final Response<dynamic> res = isStarred
        ? await _restHandler.delete(endpoint)
        : await _restHandler.put(endpoint);
    if (res.statusCode == 204) {
      return !isStarred;
    } else {
      return isStarred;
    }
  }

  static Future<GhasWatchedData_repository> isSubscribed(
    final String owner,
    final String name,
  ) async =>
      GhasWatchedData.fromJson(
        (await _gqlHandler.query(
          GhasWatchedReq(
            (final GhasWatchedReqBuilder b) => b
              ..vars.owner = owner
              ..vars.name = name,
          ),
        ))
            .data!,
      )!
          .repository!;

  static Future<bool> subscribeToRepo(
    final String owner,
    final String name, {
    required final bool isSubscribing,
    final bool ignored = false,
  }) async {
    final Response<dynamic> res = isSubscribing
        ? await _restHandler.put(
            '/repos/$owner/$name/subscription',
            data: <String, bool>{
              if (ignored) 'ignored': true,
              if (!ignored) 'subscribed': true,
            },
          )
        : await _restHandler.delete(
            '/repos/$owner/$name/subscription',
          );
    if ((isSubscribing && res.statusCode == 200) ||
        (!isSubscribing && res.statusCode == 204)) {
      return !isSubscribing;
    } else {
      return isSubscribing;
    }
  }
}
