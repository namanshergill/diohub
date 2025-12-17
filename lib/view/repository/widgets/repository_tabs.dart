import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/models/popup/popup_type.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/repository/code/code_browser.dart';
import 'package:diohub/view/repository/issues/issues_list.dart';
import 'package:diohub/view/repository/pulls/pulls_list.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:provider/provider.dart';

/// Creates the list of tabs for the repository screen
List<DynamicTab> createRepositoryTabs({
  required String repositoryURL,
  required PathData? pathData,
  required GlobalKey<RepositoryReadmeState> readmeStateKey,
  required Function(List<({String text, String id, int level})>)
      onHeadingsExtracted,
  required StateSetter setState,
  required bool mounted,
}) {
  bool isDeepLinkCode(PathData? data) =>
      data?.component(2)?.startsWith(RegExp('(tree)|(blob)|(commits)')) ??
      false;

  bool isDeepLinkComp(String data) => pathData?.componentIs(2, data) ?? false;

  return <DynamicTab>[
    DynamicTab(
      identifier: 'Readme',
      isDismissible: false,
      isFocusedOnInit: true, // Set Readme as default tab
      tabViewBuilder: (final BuildContext context) => RepositoryReadme(
        context.repoProvider(listen: false).url,
        key: readmeStateKey,
        onHeadingsExtracted: (headings) {
          // Defer setState to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                onHeadingsExtracted(headings);
              });
            }
          });
        },
        onScrollToAnchor: (anchorId) {
          // Scroll callback - can be used if needed
          // The scroll is handled by RepositoryReadmeState.scrollToAnchor
        },
      ),
    ),
    DynamicTab(
      identifier: 'Code',
      isFocusedOnInit: isDeepLinkCode(pathData),
      tabViewBuilder: (final BuildContext context) => CodeBrowser(
        showCommitHistory: pathData?.component(2) == 'commits',
      ),
    ),
    DynamicTab(
      identifier: 'Issues',
      isFocusedOnInit: isDeepLinkComp('issues'),
      keepViewAlive: true,
      tabViewBuilder: (final BuildContext context) => const IssuesList(),
    ),
    DynamicTab(
      identifier: 'Pull Requests',
      isFocusedOnInit: isDeepLinkComp('pulls'),
      keepViewAlive: true,
      tabViewBuilder: (final BuildContext context) => const PullsList(),
    ),
    DynamicTab(
      identifier: 'More',
      tabViewBuilder: (final BuildContext context) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Button(
              onTap: () async {
                if (Provider.of<RepositoryProvider>(context, listen: false)
                    .data
                    .hasWikiEnabled) {
                  await AutoRouter.of(context).push(
                    WikiViewer(
                      repoURL: repositoryURL,
                    ),
                  );
                } else {
                  ResponseHandler.setErrorMessage(
                    AppPopupData(
                      title: 'Repository has no wiki.',
                    ),
                  );
                }
              },
              child: const Text('Open Wiki'),
            ),
          ),
        ],
      ),
    ),
  ];
}
