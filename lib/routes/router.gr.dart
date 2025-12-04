// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i15;
import 'package:diohub/adapters/deep_linking_handler.dart' as _i17;
import 'package:diohub/common/search_overlay/search_overlay.dart' as _i13;
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_templates.data.gql.dart'
    as _i18;
import 'package:diohub/view/authentication/auth_screen.dart' as _i1;
import 'package:diohub/view/home/home.dart' as _i5;
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart' as _i6;
import 'package:diohub/view/issues_pulls/widgets/p_r_review_screen.dart'
    as _i10;
import 'package:diohub/view/landing/widgets/landing_loading_screen.dart' as _i7;
import 'package:diohub/view/landing/widgets/place_holder_screen.dart' as _i11;
import 'package:diohub/view/profile/other_user_profile_screen.dart' as _i9;
import 'package:diohub/view/repository/code/file_viewer.dart' as _i4;
import 'package:diohub/view/repository/commits/commit_info_screen.dart' as _i3;
import 'package:diohub/view/repository/commits/widgets/changes_viewer.dart'
    as _i2;
import 'package:diohub/view/repository/issues/new_issue_screen.dart' as _i8;
import 'package:diohub/view/repository/repository_screen.dart' as _i12;
import 'package:diohub/view/repository/wiki/wiki_viewer.dart' as _i14;
import 'package:flutter/material.dart' as _i16;

/// generated route for
/// [_i1.AuthScreen]
class AuthRoute extends _i15.PageRouteInfo<AuthRouteArgs> {
  AuthRoute({
    _i16.Key? key,
    _i16.VoidCallback? onAuthenticated,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          AuthRoute.name,
          args: AuthRouteArgs(key: key, onAuthenticated: onAuthenticated),
          initialChildren: children,
        );

  static const String name = 'AuthRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthRouteArgs>(
        orElse: () => const AuthRouteArgs(),
      );
      return _i1.AuthScreen(
        key: args.key,
        onAuthenticated: args.onAuthenticated,
      );
    },
  );
}

class AuthRouteArgs {
  const AuthRouteArgs({this.key, this.onAuthenticated});

  final _i16.Key? key;

  final _i16.VoidCallback? onAuthenticated;

  @override
  String toString() {
    return 'AuthRouteArgs{key: $key, onAuthenticated: $onAuthenticated}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthRouteArgs) return false;
    return key == other.key && onAuthenticated == other.onAuthenticated;
  }

  @override
  int get hashCode => key.hashCode ^ onAuthenticated.hashCode;
}

/// generated route for
/// [_i2.ChangesViewer]
class ChangesViewer extends _i15.PageRouteInfo<ChangesViewerArgs> {
  ChangesViewer({
    required String? patch,
    required String? contentURL,
    required String? fileType,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          ChangesViewer.name,
          args: ChangesViewerArgs(
            patch: patch,
            contentURL: contentURL,
            fileType: fileType,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'ChangesViewer';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChangesViewerArgs>();
      return _i2.ChangesViewer(
        args.patch,
        args.contentURL,
        args.fileType,
        key: args.key,
      );
    },
  );
}

class ChangesViewerArgs {
  const ChangesViewerArgs({
    required this.patch,
    required this.contentURL,
    required this.fileType,
    this.key,
  });

  final String? patch;

  final String? contentURL;

  final String? fileType;

  final _i16.Key? key;

  @override
  String toString() {
    return 'ChangesViewerArgs{patch: $patch, contentURL: $contentURL, fileType: $fileType, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChangesViewerArgs) return false;
    return patch == other.patch &&
        contentURL == other.contentURL &&
        fileType == other.fileType &&
        key == other.key;
  }

  @override
  int get hashCode =>
      patch.hashCode ^ contentURL.hashCode ^ fileType.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i3.CommitInfoScreen]
class CommitInfoRoute extends _i15.PageRouteInfo<CommitInfoRouteArgs> {
  CommitInfoRoute({
    required String commitURL,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          CommitInfoRoute.name,
          args: CommitInfoRouteArgs(commitURL: commitURL, key: key),
          initialChildren: children,
        );

  static const String name = 'CommitInfoRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommitInfoRouteArgs>();
      return _i3.CommitInfoScreen(commitURL: args.commitURL, key: args.key);
    },
  );
}

class CommitInfoRouteArgs {
  const CommitInfoRouteArgs({required this.commitURL, this.key});

  final String commitURL;

  final _i16.Key? key;

  @override
  String toString() {
    return 'CommitInfoRouteArgs{commitURL: $commitURL, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommitInfoRouteArgs) return false;
    return commitURL == other.commitURL && key == other.key;
  }

  @override
  int get hashCode => commitURL.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i4.FileViewerAPI]
class FileViewerAPI extends _i15.PageRouteInfo<FileViewerAPIArgs> {
  FileViewerAPI({
    required String? sha,
    String? repoURL,
    String? fileName,
    String? branch,
    String? repoName,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          FileViewerAPI.name,
          args: FileViewerAPIArgs(
            sha: sha,
            repoURL: repoURL,
            fileName: fileName,
            branch: branch,
            repoName: repoName,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'FileViewerAPI';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FileViewerAPIArgs>();
      return _i4.FileViewerAPI(
        args.sha,
        repoURL: args.repoURL,
        fileName: args.fileName,
        branch: args.branch,
        repoName: args.repoName,
        key: args.key,
      );
    },
  );
}

class FileViewerAPIArgs {
  const FileViewerAPIArgs({
    required this.sha,
    this.repoURL,
    this.fileName,
    this.branch,
    this.repoName,
    this.key,
  });

  final String? sha;

  final String? repoURL;

  final String? fileName;

  final String? branch;

  final String? repoName;

  final _i16.Key? key;

  @override
  String toString() {
    return 'FileViewerAPIArgs{sha: $sha, repoURL: $repoURL, fileName: $fileName, branch: $branch, repoName: $repoName, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileViewerAPIArgs) return false;
    return sha == other.sha &&
        repoURL == other.repoURL &&
        fileName == other.fileName &&
        branch == other.branch &&
        repoName == other.repoName &&
        key == other.key;
  }

  @override
  int get hashCode =>
      sha.hashCode ^
      repoURL.hashCode ^
      fileName.hashCode ^
      branch.hashCode ^
      repoName.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i15.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i16.Key? key,
    _i17.PathData? deepLinkData,
    dynamic buildThemePZero,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            key: key,
            deepLinkData: deepLinkData,
            buildThemePZero: buildThemePZero,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>(
        orElse: () => const HomeRouteArgs(),
      );
      return _i5.HomeScreen(
        key: args.key,
        deepLinkData: args.deepLinkData,
        buildThemePZero: args.buildThemePZero,
      );
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.deepLinkData, this.buildThemePZero});

  final _i16.Key? key;

  final _i17.PathData? deepLinkData;

  final dynamic buildThemePZero;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, deepLinkData: $deepLinkData, buildThemePZero: $buildThemePZero}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key &&
        deepLinkData == other.deepLinkData &&
        buildThemePZero == other.buildThemePZero;
  }

  @override
  int get hashCode =>
      key.hashCode ^ deepLinkData.hashCode ^ buildThemePZero.hashCode;
}

/// generated route for
/// [_i6.IssuePullScreen]
class IssuePullRoute extends _i15.PageRouteInfo<IssuePullRouteArgs> {
  IssuePullRoute({
    required int number,
    required String repoName,
    required String ownerName,
    _i16.Key? key,
    DateTime? commentsSince,
    int initialIndex = 0,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          IssuePullRoute.name,
          args: IssuePullRouteArgs(
            number: number,
            repoName: repoName,
            ownerName: ownerName,
            key: key,
            commentsSince: commentsSince,
            initialIndex: initialIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'IssuePullRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<IssuePullRouteArgs>();
      return _i6.IssuePullScreen(
        number: args.number,
        repoName: args.repoName,
        ownerName: args.ownerName,
        key: args.key,
        commentsSince: args.commentsSince,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class IssuePullRouteArgs {
  const IssuePullRouteArgs({
    required this.number,
    required this.repoName,
    required this.ownerName,
    this.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final int number;

  final String repoName;

  final String ownerName;

  final _i16.Key? key;

  final DateTime? commentsSince;

  final int initialIndex;

  @override
  String toString() {
    return 'IssuePullRouteArgs{number: $number, repoName: $repoName, ownerName: $ownerName, key: $key, commentsSince: $commentsSince, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IssuePullRouteArgs) return false;
    return number == other.number &&
        repoName == other.repoName &&
        ownerName == other.ownerName &&
        key == other.key &&
        commentsSince == other.commentsSince &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      number.hashCode ^
      repoName.hashCode ^
      ownerName.hashCode ^
      key.hashCode ^
      commentsSince.hashCode ^
      initialIndex.hashCode;
}

/// generated route for
/// [_i7.LandingLoadingScreen]
class LandingLoadingRoute extends _i15.PageRouteInfo<LandingLoadingRouteArgs> {
  LandingLoadingRoute({
    _i16.Key? key,
    Uri? initLink,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          LandingLoadingRoute.name,
          args: LandingLoadingRouteArgs(key: key, initLink: initLink),
          initialChildren: children,
        );

  static const String name = 'LandingLoadingRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LandingLoadingRouteArgs>(
        orElse: () => const LandingLoadingRouteArgs(),
      );
      return _i7.LandingLoadingScreen(key: args.key, initLink: args.initLink);
    },
  );
}

class LandingLoadingRouteArgs {
  const LandingLoadingRouteArgs({this.key, this.initLink});

  final _i16.Key? key;

  final Uri? initLink;

  @override
  String toString() {
    return 'LandingLoadingRouteArgs{key: $key, initLink: $initLink}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LandingLoadingRouteArgs) return false;
    return key == other.key && initLink == other.initLink;
  }

  @override
  int get hashCode => key.hashCode ^ initLink.hashCode;
}

/// generated route for
/// [_i8.NewIssueScreen]
class NewIssueRoute extends _i15.PageRouteInfo<NewIssueRouteArgs> {
  NewIssueRoute({
    required String repo,
    required String owner,
    _i16.Key? key,
    _i18.GissueTemplatesData_repository_issueTemplates? template,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          NewIssueRoute.name,
          args: NewIssueRouteArgs(
            repo: repo,
            owner: owner,
            key: key,
            template: template,
          ),
          initialChildren: children,
        );

  static const String name = 'NewIssueRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewIssueRouteArgs>();
      return _i8.NewIssueScreen(
        repo: args.repo,
        owner: args.owner,
        key: args.key,
        template: args.template,
      );
    },
  );
}

class NewIssueRouteArgs {
  const NewIssueRouteArgs({
    required this.repo,
    required this.owner,
    this.key,
    this.template,
  });

  final String repo;

  final String owner;

  final _i16.Key? key;

  final _i18.GissueTemplatesData_repository_issueTemplates? template;

  @override
  String toString() {
    return 'NewIssueRouteArgs{repo: $repo, owner: $owner, key: $key, template: $template}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewIssueRouteArgs) return false;
    return repo == other.repo &&
        owner == other.owner &&
        key == other.key &&
        template == other.template;
  }

  @override
  int get hashCode =>
      repo.hashCode ^ owner.hashCode ^ key.hashCode ^ template.hashCode;
}

/// generated route for
/// [_i9.OtherUserProfileScreen]
class OtherUserProfileRoute
    extends _i15.PageRouteInfo<OtherUserProfileRouteArgs> {
  OtherUserProfileRoute({
    required String login,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          OtherUserProfileRoute.name,
          args: OtherUserProfileRouteArgs(login: login, key: key),
          initialChildren: children,
        );

  static const String name = 'OtherUserProfileRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtherUserProfileRouteArgs>();
      return _i9.OtherUserProfileScreen(args.login, key: args.key);
    },
  );
}

class OtherUserProfileRouteArgs {
  const OtherUserProfileRouteArgs({required this.login, this.key});

  final String login;

  final _i16.Key? key;

  @override
  String toString() {
    return 'OtherUserProfileRouteArgs{login: $login, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtherUserProfileRouteArgs) return false;
    return login == other.login && key == other.key;
  }

  @override
  int get hashCode => login.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i10.PRReviewScreen]
class PRReviewRoute extends _i15.PageRouteInfo<PRReviewRouteArgs> {
  PRReviewRoute({
    required String nodeID,
    required String pullNodeID,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          PRReviewRoute.name,
          args: PRReviewRouteArgs(
            nodeID: nodeID,
            pullNodeID: pullNodeID,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'PRReviewRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PRReviewRouteArgs>();
      return _i10.PRReviewScreen(
        args.nodeID,
        pullNodeID: args.pullNodeID,
        key: args.key,
      );
    },
  );
}

class PRReviewRouteArgs {
  const PRReviewRouteArgs({
    required this.nodeID,
    required this.pullNodeID,
    this.key,
  });

  final String nodeID;

  final String pullNodeID;

  final _i16.Key? key;

  @override
  String toString() {
    return 'PRReviewRouteArgs{nodeID: $nodeID, pullNodeID: $pullNodeID, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PRReviewRouteArgs) return false;
    return nodeID == other.nodeID &&
        pullNodeID == other.pullNodeID &&
        key == other.key;
  }

  @override
  int get hashCode => nodeID.hashCode ^ pullNodeID.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i11.PlaceHolderScreen]
class PlaceHolderRoute extends _i15.PageRouteInfo<void> {
  const PlaceHolderRoute({List<_i15.PageRouteInfo>? children})
      : super(PlaceHolderRoute.name, initialChildren: children);

  static const String name = 'PlaceHolderRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i11.PlaceHolderScreen();
    },
  );
}

/// generated route for
/// [_i12.RepositoryScreen]
class RepositoryRoute extends _i15.PageRouteInfo<RepositoryRouteArgs> {
  RepositoryRoute({
    required String repositoryURL,
    String? branch,
    int index = 0,
    _i17.PathData? deepLinkData,
    _i16.Key? key,
    String? initSHA,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          RepositoryRoute.name,
          args: RepositoryRouteArgs(
            repositoryURL: repositoryURL,
            branch: branch,
            index: index,
            deepLinkData: deepLinkData,
            key: key,
            initSHA: initSHA,
          ),
          initialChildren: children,
        );

  static const String name = 'RepositoryRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RepositoryRouteArgs>();
      return _i12.RepositoryScreen(
        args.repositoryURL,
        branch: args.branch,
        index: args.index,
        deepLinkData: args.deepLinkData,
        key: args.key,
        initSHA: args.initSHA,
      );
    },
  );
}

class RepositoryRouteArgs {
  const RepositoryRouteArgs({
    required this.repositoryURL,
    this.branch,
    this.index = 0,
    this.deepLinkData,
    this.key,
    this.initSHA,
  });

  final String repositoryURL;

  final String? branch;

  final int index;

  final _i17.PathData? deepLinkData;

  final _i16.Key? key;

  final String? initSHA;

  @override
  String toString() {
    return 'RepositoryRouteArgs{repositoryURL: $repositoryURL, branch: $branch, index: $index, deepLinkData: $deepLinkData, key: $key, initSHA: $initSHA}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RepositoryRouteArgs) return false;
    return repositoryURL == other.repositoryURL &&
        branch == other.branch &&
        index == other.index &&
        deepLinkData == other.deepLinkData &&
        key == other.key &&
        initSHA == other.initSHA;
  }

  @override
  int get hashCode =>
      repositoryURL.hashCode ^
      branch.hashCode ^
      index.hashCode ^
      deepLinkData.hashCode ^
      key.hashCode ^
      initSHA.hashCode;
}

/// generated route for
/// [_i13.SearchOverlayScreen]
class SearchOverlayRoute extends _i15.PageRouteInfo<SearchOverlayRouteArgs> {
  SearchOverlayRoute({
    required _i13.SearchData searchData,
    required bool multiHero,
    required _i16.ValueChanged<_i13.SearchData> onSubmit,
    String? message,
    String heroTag = 'search_bar',
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          SearchOverlayRoute.name,
          args: SearchOverlayRouteArgs(
            searchData: searchData,
            multiHero: multiHero,
            onSubmit: onSubmit,
            message: message,
            heroTag: heroTag,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchOverlayRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchOverlayRouteArgs>();
      return _i13.SearchOverlayScreen(
        args.searchData,
        multiHero: args.multiHero,
        onSubmit: args.onSubmit,
        message: args.message,
        heroTag: args.heroTag,
        key: args.key,
      );
    },
  );
}

class SearchOverlayRouteArgs {
  const SearchOverlayRouteArgs({
    required this.searchData,
    required this.multiHero,
    required this.onSubmit,
    this.message,
    this.heroTag = 'search_bar',
    this.key,
  });

  final _i13.SearchData searchData;

  final bool multiHero;

  final _i16.ValueChanged<_i13.SearchData> onSubmit;

  final String? message;

  final String heroTag;

  final _i16.Key? key;

  @override
  String toString() {
    return 'SearchOverlayRouteArgs{searchData: $searchData, multiHero: $multiHero, onSubmit: $onSubmit, message: $message, heroTag: $heroTag, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchOverlayRouteArgs) return false;
    return searchData == other.searchData &&
        multiHero == other.multiHero &&
        onSubmit == other.onSubmit &&
        message == other.message &&
        heroTag == other.heroTag &&
        key == other.key;
  }

  @override
  int get hashCode =>
      searchData.hashCode ^
      multiHero.hashCode ^
      onSubmit.hashCode ^
      message.hashCode ^
      heroTag.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i14.WikiViewer]
class WikiViewer extends _i15.PageRouteInfo<WikiViewerArgs> {
  WikiViewer({
    _i16.Key? key,
    String? repoURL,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          WikiViewer.name,
          args: WikiViewerArgs(key: key, repoURL: repoURL),
          initialChildren: children,
        );

  static const String name = 'WikiViewer';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WikiViewerArgs>(
        orElse: () => const WikiViewerArgs(),
      );
      return _i14.WikiViewer(key: args.key, repoURL: args.repoURL);
    },
  );
}

class WikiViewerArgs {
  const WikiViewerArgs({this.key, this.repoURL});

  final _i16.Key? key;

  final String? repoURL;

  @override
  String toString() {
    return 'WikiViewerArgs{key: $key, repoURL: $repoURL}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WikiViewerArgs) return false;
    return key == other.key && repoURL == other.repoURL;
  }

  @override
  int get hashCode => key.hashCode ^ repoURL.hashCode;
}
