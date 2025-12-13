import 'dart:async';

import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/proxy_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';

class RepoBranchProvider extends ProxyProvider<String, RepositoryProvider> {
  RepoBranchProvider({final String? initialBranch, final String? initCommitSHA})
      : _initialBranch = initialBranch,
        _initCommitSHA = initCommitSHA,
        super(Status.loaded);
  final String? _initialBranch;
  final String? _initCommitSHA;
  final StreamController<String> _loadBranch =
      StreamController<String>.broadcast();
  late String _currentSHA;
  String? _currentBranch;
  String get currentSHA => _currentSHA;
  bool isCommit = false;

  @override
  Future<void> disposeStreams() async {
    await super.disposeStreams();
    await _loadBranch.close();
  }

  void reloadBranch() {
    _loadBranch.add(
      _currentBranch ?? parentProvider.data.defaultBranchRef?.name ?? 'main',
    );
  }

  @override
  Future<void> updateProvider(final RepositoryProvider parentProvider) async {
    _currentBranch = _initialBranch;
    await super.updateProvider(parentProvider);
  }

  @override
  void customStreams() {
    // Listen if a new branch has been requested and fetch the same.
    _loadBranch.stream.listen(setBranch);
  }

  @override
  Future<String> setInitData({final bool isInitialisation = false}) =>
      setBranch(
        _initCommitSHA ??
            _currentBranch ??
            parentProvider.data.defaultBranchRef?.name ??
            'main',
        isCommitSha: _initCommitSHA != null,
        setState: !isInitialisation,
      );

  Future<String> setBranch(
    final String branchName, {
    final bool isCommitSha = false,
    final bool setState = true,
  }) async {
    _currentSHA = branchName;
    isCommit = isCommitSha;
    if (!isCommitSha) {
      _currentBranch = branchName;
    }
    if (setState) {
      loaded();
    }
    return _currentSHA;
  }

  // void _fetchBranch(String branch, {bool isInitial = true}) async {
  //   loading();
  //   try {
  //     _branch = await RepositoryServices.fetchBranch(
  //         '${_repositoryProvider!.repositoryModel!.url}/branches/$branch');
  //     _currentBranch = _branch!.name;
  //     loaded();
  //   } catch (e) {
  //     // If it was not the initial load, it means a branch is already loaded.
  //     // User will see a popup showing the message key of the error response
  //     // from github on why the fetch failed, so no need to dispose the
  //     // previous data.
  //     if (isInitial)
  //       error(message: e.toString());
  //     else
  //       loaded();
  //   }
  // }
}
