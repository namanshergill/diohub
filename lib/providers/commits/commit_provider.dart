import 'package:diohub/graphql/queries/repositories/__generated__/commit_info.data.gql.dart';
import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/repositories/repo_services.dart';

class CommitProvider
    extends BaseDataProvider<GcommitInfoData_repository_object__asCommit> {
  CommitProvider(this.commitURL);
  final String commitURL;

  // Store files separately since GraphQL doesn't provide file details
  List<FileElement>? _files;
  List<FileElement>? get files => _files;

  @override
  Future<GcommitInfoData_repository_object__asCommit> setInitData({
    final bool isInitialisation = false,
  }) async {
    // Parse commit URL to get owner, repo, and oid
    final parsed = RepositoryServices.parseCommitURL(commitURL);

    // Fetch commit info using GraphQL
    final commitInfo = await RepositoryServices.getCommitInfo(
      owner: parsed.owner,
      repo: parsed.repo,
      oid: parsed.oid,
      refresh: !isInitialisation,
    );

    // Fetch changed files using REST API (GraphQL doesn't provide file details)
    try {
      final commitModel = await RepositoryServices.getCommit(commitURL);
      _files = commitModel.files;
    } catch (e) {
      // If fetching files fails, continue without them
      _files = null;
    }

    return commitInfo;
  }
}
