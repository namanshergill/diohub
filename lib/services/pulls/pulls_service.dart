import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
// TODO: Uncomment after running GraphQL code generator:
// flutter pub run build_runner build
// import 'package:diohub/graphql/queries/issues_pulls/__generated__/pull_commits_list.data.gql.dart';
// import 'package:diohub/graphql/queries/issues_pulls/__generated__/pull_commits_list.req.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/pr_review_comment.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/pr_review_comment.req.gql.dart';
import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/models/pull_requests/review_model.dart';
import 'package:diohub/models/repositories/commit_list_model.dart';
import 'package:diohub/utils/type_cast.dart';
import 'package:diohub/utils/utils.dart';

class PullsService {
  PullsService(this.temp);

  static final GraphqlHandler _gqlHandler = GraphqlHandler();
  static final RESTHandler _restHandler = RESTHandler();
  final String temp;
  // Ref: https://docs.github.com/en/rest/reference/pulls#get-a-pull-request
  static Future<PullRequestModel> getPullInformation({
    required final String fullUrl,
    required final bool refresh,
  }) async {
    final Response<TypeMap> response = await _restHandler.get<TypeMap>(
      fullUrl,
      requestHeaders: _restHandler.acceptHeader(
        'application/vnd.github.black-cat-preview+json, application/vnd.github.VERSION.html, application/vnd.github.v3+json',
      ),
      refreshCache: refresh,
    );
    return PullRequestModel.fromJson(response.data!);
  }

  // Ref: https://docs.github.com/en/rest/reference/pulls#list-reviews-for-a-pull-request
  static Future<ReviewModel> getPullReviews({
    required final String fullUrl,
  }) async {
    final Response<TypeMap> response =
        await _restHandler.get<TypeMap>('$fullUrl/reviews');
    return ReviewModel.fromJson(response.data!);
  }

  // Ref: https://docs.github.com/en/rest/reference/pulls#list-pull-requests
  static Future<List<PullRequestModel>> getRepoPulls(
    final String? repoURL, {
    required final bool refresh,
    final int? perPage,
    final int? pageNumber,
  }) async {
    final Response<List<dynamic>> response =
        await _restHandler.get<List<dynamic>>(
      '$repoURL/pulls',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': pageNumber,
        // 'sort': 'popularity',
        // 'state': 'all',
        // 'direction': 'desc',
      },
      refreshCache: refresh,
    );
    final List<dynamic> unParsedData = response.data!;
    final List<PullRequestModel> parsedData = unParsedData
        // ignore: unnecessary_lambdas
        .map((final dynamic e) => PullRequestModel.fromJson(e))
        .toList();
    return parsedData;
  }

  // Ref: https://docs.github.com/en/rest/reference/pulls#list-commits-on-a-pull-request
  static Future<List<CommitListModel>> getPullCommits(
    final String? pullURL, {
    required final bool refresh,
    final int? perPage,
    final int? pageNumber,
  }) async {
    final Response<DynamicList> response = await _restHandler.get<DynamicList>(
      '$pullURL/commits',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': pageNumber,
      },
      refreshCache: refresh,
    );
    final DynamicList unParsedData = response.data!;
    final List<CommitListModel> parsedData = unParsedData
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => CommitListModel.fromJson(e),
        )
        .toList();
    return parsedData;
  }

  // Helper to parse pull URL and extract owner, repo, and number
  // Format: https://api.github.com/repos/{owner}/{repo}/pulls/{number}
  // or: https://github.com/{owner}/{repo}/pull/{number}
  static ({String owner, String repo, int number}) parsePullURL(
    final String pullURL,
  ) {
    final List<String> parts = pullURL.split('/');
    // Check if it's an API URL or web URL
    final int reposIndex = parts.indexWhere((p) => p == 'repos');
    final int pullIndex = parts.indexWhere((p) => p == 'pull' || p == 'pulls');

    if (reposIndex != -1 && reposIndex + 4 < parts.length) {
      // API URL format
      final String owner = parts[reposIndex + 1];
      final String repo = parts[reposIndex + 2];
      final int number = int.parse(parts[reposIndex + 4]);
      return (owner: owner, repo: repo, number: number);
    } else if (pullIndex != -1 && pullIndex >= 2) {
      // Web URL format: github.com/{owner}/{repo}/pull/{number}
      final String owner = parts[pullIndex - 2];
      final String repo = parts[pullIndex - 1];
      final int number = int.parse(parts[pullIndex + 1]);
      return (owner: owner, repo: repo, number: number);
    }
    throw Exception('Invalid pull URL format');
  }

  // Get paginated pull request commits using GraphQL
  // TODO: Uncomment after running GraphQL code generator:
  // flutter pub run build_runner build
  /*
  static Future<({
    List<GpullCommitsListData_repository_pullRequest_commits_edges?> edges,
    bool hasNextPage,
    String? endCursor,
  })> getPullCommitsGQL({
    required final String owner,
    required final String repo,
    required final int number,
    required final int first,
    final String? after,
    final bool refresh = false,
  }) async {
    final GQLResponse response = await _gqlHandler.query(
      GpullCommitsListReq(
        (final GpullCommitsListReqBuilder b) => b
          ..vars.owner = owner
          ..vars.repo = repo
          ..vars.number = number
          ..vars.first = first
          ..vars.after = after,
      ),
      refreshCache: refresh,
    );
    final data = GpullCommitsListData.fromJson(response.data!)!.repository!;
    final pr = data.pullRequest;
    if (pr == null) {
      throw Exception('Pull request not found');
    }
    return (
      edges: pr.commits.edges!.toList(),
      hasNextPage: pr.commits.pageInfo.hasNextPage,
      endCursor: pr.commits.pageInfo.endCursor,
    );
  }
  */

  // Ref: https://docs.github.com/en/rest/reference/pulls#list-pull-requests-files
  static Future<List<FileElement>> getPullFiles(
    final String? pullURL, {
    required final bool refresh,
    final int? perPage,
    final int? pageNumber,
  }) async {
    final Response<DynamicList> response = await _restHandler.get<DynamicList>(
      '$pullURL/files',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': pageNumber,
      },
      refreshCache: refresh,
    );
    final DynamicList unParsedData = response.data!;
    final List<FileElement> parsedData = unParsedData
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => FileElement.fromJson(e),
        )
        .toList();
    return parsedData;
  }

  static Future<
          List<
              GgetPRReviewCommentsData_node__asPullRequestReview_comments_edges?>>
      getPRReview(
    final String id, {
    required final bool refresh,
    final String? cursor,
  }) async {
    final GQLResponse res = await _gqlHandler.query(
      GgetPRReviewCommentsReq(
        (final GgetPRReviewCommentsReqBuilder b) => b
          ..vars.cursor = cursor
          ..vars.id = id,
      ),
      refreshCache: refresh,
    );
    return GgetPRReviewCommentsData.fromJson(res.data!)!.node!.when(
          pullRequestReview:
              (final GgetPRReviewCommentsData_node__asPullRequestReview p0) =>
                  p0.comments.edges!.toList(),
          orElse: unimplemented,
        );
  }

  static Future<
          List<
              GreviewThreadCommentsQueryData_node__asPullRequestReviewThread_comments_edges?>>
      getReviewThreadReplies(
    final String nodeID,
    final String? cursor, {
    required final bool refresh,
  }) async {
    final GQLResponse res = await _gqlHandler.query(
      GreviewThreadCommentsQueryReq(
        (final GreviewThreadCommentsQueryReqBuilder b) => b
          ..vars.cursor = cursor
          ..vars.nodeID = nodeID,
      ),
      refreshCache: refresh,
    );
    return (GreviewThreadCommentsQueryData.fromJson(res.data!)!.node!
            as GreviewThreadCommentsQueryData_node__asPullRequestReviewThread)
        .comments
        .edges!
        .toList();
  }

  static Future<
          GreviewThreadFirstCommentQueryData_repository_pullRequest_reviewThreads_edges?>
      getPRReviewThreadID(
    final String commentID, {
    required final String name,
    required final String owner,
    required final int number,
    required final String? cursor,
    required final bool refresh,
  }) async {
    final GQLResponse res = await _gqlHandler.query(
      GreviewThreadFirstCommentQueryReq(
        (final GreviewThreadFirstCommentQueryReqBuilder b) => b
          ..vars.cursor = cursor
          ..vars.name = name
          ..vars.number = number
          ..vars.owner = owner,
      ),
      refreshCache: refresh,
    );
    final GreviewThreadFirstCommentQueryData parsed =
        GreviewThreadFirstCommentQueryData.fromJson(res.data!)!;

    if (parsed.repository!.pullRequest!.reviewThreads.edges!.isNotEmpty) {
      for (final GreviewThreadFirstCommentQueryData_repository_pullRequest_reviewThreads_edges? thread
          in parsed.repository!.pullRequest!.reviewThreads.edges!) {
        if (thread?.node?.comments.nodes?.first?.id == commentID) {
          return thread!;
        }
      }
      return getPRReviewThreadID(
        commentID,
        name: name,
        owner: owner,
        number: number,
        cursor:
            parsed.repository!.pullRequest!.reviewThreads.edges!.last!.cursor,
        refresh: refresh,
      );
    }
    return null;
  }

  static Future<bool> hasPendingReviews(
    final String pullNode,
    final String user,
  ) async {
    final GQLResponse res = await _gqlHandler.query(
      GcheckPendingViewerReviewsReq(
        (final GcheckPendingViewerReviewsReqBuilder b) => b
          ..vars.author = user
          ..vars.pullNodeID = pullNode,
      ),
    );
    return GcheckPendingViewerReviewsData.fromJson(res.data!)!.node!.when(
          pullRequest:
              (final GcheckPendingViewerReviewsData_node__asPullRequest p0) {
            if ((p0.reviews?.totalCount ?? 0) > 0) {
              return true;
            } else {
              return false;
            }
          },
          orElse: unimplemented,
        );
  }

  // Ref: https://docs.github.com/en/rest/reference/pulls#create-a-reply-for-a-review-comment
  static Future<bool> replyToReviewComment(
    final String body, {
    required final int id,
    required final String owner,
    required final String repo,
    required final int pullNumber,
  }) async {
    final Response<dynamic> res = await _restHandler.post(
      '/repos/$owner/$repo/pulls/$pullNumber/comments/$id/replies',
      data: <String, String>{'body': body},
    );
    if (res.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
