import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_templates.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/providers/proxy_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/services/repositories/repo_services.dart';

class PinnedIssuesProvider extends ProxyProvider<
    GpinnedIssuesData_repository_pinnedIssues, RepositoryProvider> {
  late final RepositoryServices _repositoryServices = RepositoryServices(
    name: parentProvider.data.name,
    owner: parentProvider.data.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => '',
    ),
  );

  @override
  Future<GpinnedIssuesData_repository_pinnedIssues> setInitData({
    final bool isInitialisation = false,
  }) async =>
      _repositoryServices.getPinnedIssues();
}
