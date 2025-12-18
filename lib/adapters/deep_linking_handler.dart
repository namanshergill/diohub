import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/misc/app_dialog.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:diohub/utils/regex.dart';
import 'package:diohub/utils/string_compare.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';

String get _chars => '([^/\\s]+)';

String get _any => '([^\\s]+)';

String get _slash => '(/)';

String get _digit => '(\\d+)';

Future<String?> initUniLink() async {
  final String? initialLink = await AppLinks().getInitialLinkString();
  return initialLink;
}

void uniLinkStream() {
  AppLinks().stringLinkStream.listen(
    (final String? link) async {
      if (link != null) {
        await deepLinkNavigate(
          Uri.parse(link),
        );
      }
    },
  );
}

Future<void> deepLinkNavigate(final Uri link) async {
  if (link.toString().startsWith(_themeLinkPattern)) {
    // AutoRouter.of(Global.currentContext).replaceAll([LandingScreenRoute()]);
    await showDialog(
      context: currentContext,
      builder: (final BuildContext context) => AppDialog(
        title: 'Load theme?',
        actions: <Widget>[
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          MaterialButton(
            onPressed: () {
              // loadTheme(
              //   context,
              //   link.queryParameters,
              // );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  } else if (_getRoutes(link)?.isNotEmpty ?? false) {
    if (_getRoutes(link)?.first is HomeRoute) {
      AutoRouter.of(currentContext)
          .popUntil((final Route<dynamic> route) => false);
    }
    // AutoRouter.of(Global.currentContext).replaceAll(getRoutes(link)!);
    await AutoRouter.of(currentContext).pushAll(_getRoutes(link)!);
  }
}

String githubURLtoPath(final String link) {
  String str = link;
  if (str.endsWith('/')) {
    str = str.substring(0, str.length - 1);
  }
  return str.toLowerCase().replaceFirst(
        RegExp('((http(s)?)(:(//)))?${regexORCases(
          <String>[
            'www.',
            'api.',
          ],
        )}?(github.com)(/)?'),
        '',
      );
}

bool isDeepLink(final String link) =>
    link.startsWith(_deepLinkPattern) &&
    !githubURLtoPath(link).startsWith(_exceptionURLPatterns);

bool isAPILink(final String link) => link.startsWith(_apiLinkPattern);

RegExp get _apiLinkPattern =>
    RegExp('((http(s)?)(:(//)))?(api.)(github.com)(/)?');

RegExp get _deepLinkPattern =>
    RegExp('((http(s)?)(:(//)))?(www.)?(github.com)(/)?');

RegExp get _themeLinkPattern =>
    RegExp('((http(s)?)(:(//)))?(theme.felix.diohub)');

List<PageRouteInfo>? _getRoutes(final Uri uri) {
  final Uri link = uri;

  if (link.pathSegments.isEmpty) {
    return null;
  }

  late final String path;
  if (link.path.startsWith('/')) {
    path = link.path.substring(1);
  } else {
    path = link.path;
  }
  final StringFunctions relPath = StringFunctions(path);
  final List<PageRouteInfo> temp = <PageRouteInfo>[];
  if (relPath.regexCompleteMatch(_exceptionURLPatterns)) {
    unawaited(openInAppBrowser(link));
  } else if (relPath.regexCompleteMatch(_landingPageURLPattern)) {
    temp.add(HomeRoute(deepLinkData: relPath.toPathData));
  } else if (relPath.regexCompleteMatch(_issuePageURLPattern) ||
      relPath.regexCompleteMatch(_pullPageURLPattern)) {
    temp.add(issuePullScreenRoute(relPath.toPathData));
  } else if (relPath.regexCompleteMatch(_commitPageURLPattern)) {
    temp.add(
      CommitInfoRoute(
        commitURL:
            '${_urlWithPrefix('repos/${relPath.toPathData.components.sublist(0, 2).join('/')}')}/commits/${PathData(relPath.string).component(3)!}',
      ),
    );
  } else if (relPath.regexCompleteMatch(_repoPageURLPattern)) {
    temp.add(
      RepositoryRoute(
        repositoryURL: _urlWithPrefix(
          'repos/${relPath.toPathData.components.sublist(0, 2).join('/')}',
        ),
        deepLinkData: relPath.toPathData,
      ),
    );
  } else if (relPath.regexCompleteMatch(
    RegExp(_chars),
  )) {
    temp.add(
      UserProfileRoute(
        login: relPath.string,
      ),
    );
  } else {
    unawaited(openInAppBrowser(link));
  }
  return temp;
}

class AppLinkHandler {
  AppLinkHandler({required this.uri});

  AppLinkHandler.fromString({
    required final String uri,
  }) : uri = Uri.parse(
          uri,
        );

  URLActions urlActions({
    final String? shareDescription,
    final bool showOpenAction = true,
  }) =>
      URLActions(
        uri: uri,
        shareDescription: shareDescription,
        showOpenAction: showOpenAction,
      );
  final Uri uri;

  Future<void> openInBrowser() async => urlActions().launchURLInBrowser();
}

String _urlWithPrefix(final String url) => 'https://api.github.com/$url';

RegExp get _exceptionURLPatterns => RegExp(
      regexORCases(
        <String>[
          'login/device',
          regexPattern(
            <String>[
              'settings/',
              _any,
            ],
          ),
        ],
      ),
    );

RegExp get _landingPageURLPattern => RegExp(
      regexORCases(
        <String>[
          'search',
          'notifications',
          regexPattern(
            <String>[
              regexORCases(
                <String>[
                  'issues',
                  'pulls',
                ],
              ),
              optionalRegex(
                regexPattern(
                  <String>[
                    _slash,
                    regexORCases(
                      <String>[
                        'assigned',
                        'mentioned',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

RegExp get _issuePageURLPattern => RegExp(
      regexPattern(
        <String>[
          _chars,
          _slash,
          _chars,
          _slash,
          'issues',
          _slash,
          _digit,
        ],
      ),
    );

RegExp get _pullPageURLPattern => RegExp(
      regexPattern(
        <String>[
          _chars,
          _slash,
          _chars,
          _slash,
          'pull',
          _slash,
          _digit,
        ],
      ),
    );

RegExp get _commitPageURLPattern => RegExp(
      regexPattern(
        <String>[
          _chars,
          _slash,
          _chars,
          '/commit/',
          _chars,
        ],
      ),
    );

RegExp get _repoPageURLPattern => RegExp(
      regexPattern(
        <String>[
          _chars,
          _slash,
          _chars,
          optionalRegex(
            regexORCases(
              <String>[
                regexPattern(
                  <String>[
                    '/commits',
                    optionalRegex(regexPattern(<String>[_slash, _chars])),
                  ],
                ),
                regexPattern(
                  <String>[
                    _slash,
                    regexORCases(<String>['tree', 'blob']),
                    _slash,
                    _chars,
                    // optionalRegex(
                    //   regexPattern(
                    //     [_slash, _any],
                    //   ),
                    // ),
                  ],
                ),
                '/issues',
                '/pulls',
                '/wiki',
              ],
            ),
          ),
        ],
      ),
    );

class PathData {
  PathData(this.path, {this.isAPIPath = false});

  PathData.fromURL(final String url)
      : path = githubURLtoPath(url),
        isAPIPath = isAPILink(url);
  final String path;
  final bool isAPIPath;

  // final Map? parameters;
  // final Map? extData;

  List<String> get components => path.split('/');

  String? component(final int index) {
    if (components.length > index) {
      return components[index];
    }
    return null;
  }

  bool componentIs(final int index, final String data) =>
      component(index) == data;

  @override
  String toString() => path;
}

extension on StringFunctions {
  PathData get toPathData => PathData(string);
}

/*
abstract class DioHubNavigator {
  DioHubNavigator(this.uri);

  final Uri uri;

  Future<void> navigate();

  String? getSegment(final int index) =>
      uri.pathSegments.length > index ? uri.pathSegments[index] : null;

  bool segmentMatch(final int index, final String value) =>
      getSegment(index) == value;
}

class HomeNavigator extends DioHubNavigator {
  HomeNavigator(super.uri);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the home screen
  }
}

class ExploreNavigator extends HomeNavigator {
  ExploreNavigator(super.uri);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the Explore screen
  }
}

class TrendingNavigator extends HomeNavigator {
  TrendingNavigator(super.uri);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the Trending screen
  }
}

class NotificationsNavigator extends HomeNavigator {
  NotificationsNavigator(super.uri);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the Notifications screen
  }
}

class ProfileNavigator extends HomeNavigator {
  ProfileNavigator(super.uri);

  String get username => getSegment(1) ?? '';

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to a user's profile
  }
}

class SettingsNavigator extends HomeNavigator {
  SettingsNavigator(super.uri);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the Settings screen
  }
}

class RepositoryNavigator extends DioHubNavigator {
  RepositoryNavigator(super.uri);

  // Constructor for creating a RepositoryNavigator from values
  RepositoryNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    final String? branch,
    final String? filePath,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[
              repoOwner,
              repoName,
              if (branch != null) 'tree' else 'blob',
              branch ?? '',
              filePath ?? '',
            ],
          ),
        );

  String get repoOwner => getSegment(1) ?? '';

  String get repoName => getSegment(2) ?? '';

  String? get branch => getSegment(3);

  String? get filePath => getSegment(4);

  @override
  Future<void> navigate() async {
    // Default navigation logic for repository
  }
}

class GistNavigator extends DioHubNavigator {
  GistNavigator(super.uri);

  // Constructor for creating a GistNavigator from values
  GistNavigator.fromValues({
    required final String gistId,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'gist.github.com',
            pathSegments: <String>[gistId],
          ),
        );

  String get gistId => getSegment(1) ?? '';

  @override
  Future<void> navigate() async {
    // Custom navigation logic for Gist
  }
}

class DiscussionNavigator extends DioHubNavigator {
  DiscussionNavigator(super.uri);

  // Constructor for creating a DiscussionNavigator from values
  DiscussionNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    required final String discussionSlug,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[
              repoOwner,
              repoName,
              'discussions',
              discussionSlug,
            ],
          ),
        );

  String get discussionSlug => getSegment(2) ?? '';

  @override
  Future<void> navigate() async {
    // Custom navigation logic for Discussions
  }
}

class IssueNavigator extends RepositoryNavigator {
  IssueNavigator(super.uri);

  // Constructor for creating an IssueNavigator from values
  IssueNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    required final int number,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[
              repoOwner,
              repoName,
              'issues',
              number.toString(),
            ],
          ),
        );

  int? get issueNumber =>
      getSegment(3) != null ? int.tryParse(getSegment(3)!) : null;

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to an issue
  }
}

class PullRequestNavigator extends RepositoryNavigator {
  PullRequestNavigator(super.uri);

  // Constructor for creating a PullRequestNavigator from values
  PullRequestNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    required final int number,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[
              repoOwner,
              repoName,
              'pull',
              number.toString(),
            ],
          ),
        );

  int? get pullRequestNumber =>
      getSegment(3) != null ? int.tryParse(getSegment(3)!) : null;

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to a pull request
  }
}

class ActionsNavigator extends RepositoryNavigator {
  ActionsNavigator(super.uri);

  // Constructor for creating an ActionsNavigator from values
  ActionsNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[repoOwner, repoName, 'actions'],
          ),
        );

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to the Actions screen
  }
}

class CommitNavigator extends RepositoryNavigator {
  CommitNavigator(super.uri);

  // Constructor for creating a CommitNavigator from values
  CommitNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    required final String commitHash,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[repoOwner, repoName, 'commit', commitHash],
          ),
        );

  String? get commitHash => getSegment(3);

  @override
  Future<void> navigate() async {
    // Custom navigation logic for commits
  }
}

class CodeFileNavigator extends RepositoryNavigator {
  CodeFileNavigator(super.uri);

  // Constructor for creating a CodeFileNavigator from values
  CodeFileNavigator.fromValues({
    required final String repoOwner,
    required final String repoName,
    final String? branch,
    final String? filePath,
  }) : super(
          Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: <String>[
              repoOwner,
              repoName,
              'blob',
              branch ?? '',
              filePath ?? '',
            ],
          ),
        );

  // Add additional parameters as needed

  @override
  Future<void> navigate() async {
    // Custom navigation logic for navigating to a code file
  }
}

DioHubNavigator? parseGitHubLink(final String link) {
  Uri uri = Uri.parse(link);

  if (uri.host != 'github.com') {
    // Handle cases where the link is not a valid GitHub link
  }

  switch (uri.pathSegments.length) {
    case 0:
      // Home
      return HomeNavigator(uri);
    case 1:
      // Explore
      return ExploreNavigator(uri);
    case 2:
      // Trending, Notifications, Profile, or Settings
      switch (uri.pathSegments[1]) {
        case 'trending':
          return TrendingNavigator(uri);
        case 'notifications':
          return NotificationsNavigator(uri);
        case 'settings':
          return SettingsNavigator(uri);
        default:
          return ProfileNavigator(uri);
      }
    case 3:
      // Repositories or Users
      if (segmentMatch(1, 'repos')) {
        return RepositoryNavigator(uri);
      } else {
        return UserNavigator(uri);
      }
    case 4:
      // Actions or Discussions or Commits or Gists
      switch (uri.pathSegments[2]) {
        case 'actions':
          return ActionsNavigator(uri);
        case 'discussions':
          return DiscussionNavigator(uri);
        case 'commit':
          return CommitNavigator(uri);
        case 'gist':
          return GistNavigator(uri);
        default:
          // Add more cases as needed
          break;
      }
      break;
    case 5:
      // Repositories with branch or Code files
      if (segmentMatch(2, 'tree')) {
        return RepositoryNavigator(uri);
      } else if (segmentMatch(2, 'blob')) {
        return CodeFileNavigator(uri);
      }
      break;
    default:
      print('Unsupported GitHub link: $link');
      break;
  }

  return DioHubNavigator(uri);
}
*/
