import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.req.gql.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.data.gql.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.req.gql.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/utils/type_cast.dart';

class UserInfoService {
  UserInfoService(this.login);

  static final GraphqlHandler _gqlHandler = GraphqlHandler(apiLogSettings: APILoggingSettings.comprehensive());
  final String login;
  static final RESTHandler _restHandler = RESTHandler();

  // Ref: https://docs.github.com/en/rest/reference/users#get-the-authenticated-user
  static Future<GviewerInfoData_viewer> getViewerInfo() async {
    final GQLResponse response = await _gqlHandler.query(
      GviewerInfoReq(),
    );
    return GviewerInfoData.fromJson(response.data!)!.viewer;
  }

  static Future<GgetUserRepositoriesData_user_repositories> getUserRepositories(
    final String user,
    final int first, {
    final String? after,
    final GRepositoryOrder? orderBy,
    required final bool refresh,
  }) async {
    final GQLResponse response = await _gqlHandler.query(
      GgetUserRepositoriesReq(
        (final GgetUserRepositoriesReqBuilder b) {
          b
            ..vars.user = user
            ..vars.first = first;
          if (after != null) {
            b.vars.after = after;
          }
          if (orderBy != null) {
            b.vars.orderBy..field = orderBy.field;
            b.vars.orderBy..direction = orderBy.direction;
          }
        },
      ),
      refreshCache: refresh,
    );
    return GgetUserRepositoriesData.fromJson(response.data!)!
        .user!
        .repositories;
  }

  static Future<UserInfoModel> getUserInfo(final String? login) async {
    final Response<TypeMap> response = await _restHandler.get<TypeMap>(
      '/users/$login',
    );
    return UserInfoModel.fromJson(response.data!);
  }

  static Future<GuserInfoData_user> getUserInfoGraphQL(
    final String login,
  ) async =>
      GuserInfoData.fromJson(
        (await _gqlHandler.query(
          GuserInfoReq(
            (final GuserInfoReqBuilder b) => b..vars.user = login,
          ),
        ))
            .data!,
      )!
          .user!;

  static Future<List<GgetViewerOrgsData_viewer_organizations_edges?>>
      getViewerOrgs({required final bool refresh, final String? after}) async {
    final GQLResponse res = await _gqlHandler.query(
      GgetViewerOrgsReq(
          (final GgetViewerOrgsReqBuilder b) => b..vars.cursor = after),
      refreshCache: refresh,
    );
    return GgetViewerOrgsData.fromJson(res.data!)!
        .viewer
        .organizations
        .edges!
        .toList();
  }

  static Future<GfollowStatusInfoData_user> getFollowInfo(
    final String login,
  ) async =>
      GfollowStatusInfoData.fromJson(
        (await _gqlHandler.query(
          GfollowStatusInfoReq(
            (final GfollowStatusInfoReqBuilder b) => b..vars.user = login,
          ),
        ))
            .data!,
      )!
          .user!;

  static Future<GQLResponse> changeFollowStatus(
    final String id, {
    required final bool follow,
  }) async {
    if (follow) {
      return _gqlHandler.mutation(
        GfollowUserReq(
          (final GfollowUserReqBuilder b) => b..vars.user = id,
        ),
      );
    } else {
      return _gqlHandler.mutation(
        GunfollowUserReq(
          (final GunfollowUserReqBuilder b) => b..vars.user = id,
        ),
      );
    }
  }

  /// Fetches user contribution data with customizable date range.
  ///
  /// This query is separate from getUserInfoGraphQL to allow independent
  /// updates of contribution data without refetching all user info.
  ///
  /// [from] and [to] are optional. If not provided, defaults to last year.
  static Future<GuserContributionsData_user> getUserContributions(
    final String login, {
    final DateTime? from,
    final DateTime? to,
    final bool refreshCache = false,
  }) async {
    // Default to last year if not specified
    final defaultTo = to ?? DateTime.now();
    final defaultFrom = from ??
        DateTime(
          defaultTo.year - 1,
          defaultTo.month,
          defaultTo.day,
        );

    return GuserContributionsData.fromJson(
      (await _gqlHandler.query(
        GuserContributionsReq(
          (final GuserContributionsReqBuilder b) => b
            ..vars.user = login
            ..vars.from = defaultFrom
            ..vars.to = defaultTo,
        ),
        refreshCache: refreshCache,
      ))
          .data!,
    )!
        .user!;
  }
}
