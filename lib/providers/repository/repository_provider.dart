import 'dart:async';

import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class RepositoryProvider
    extends BaseDataProvider<GrepositoryInfoData_repository> {
  RepositoryProvider(this.url);
  String url;

  late final RepositoryServices _repoServices;

  @override
  Future<GrepositoryInfoData_repository> setInitData({
    final bool isInitialisation = false,
  }) async {
    final ({String owner, String repo}) parsed =
        RepositoryServices.parseRepoURL(url);
    _repoServices = RepositoryServices(owner: parsed.owner, name: parsed.repo);
    return await _repoServices.fetchRepositoryGraphQL(
      owner: parsed.owner,
      repo: parsed.repo,
    );
  }
}

extension RepoProvider on BuildContext {
  RepositoryProvider repoProvider({final bool listen = true}) =>
      Provider.of<RepositoryProvider>(this, listen: listen);
}
