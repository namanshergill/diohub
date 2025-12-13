import 'dart:async';

import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/code/browser_list_tiles.dart';
import 'package:diohub/view/repository/code/commit_browser.dart';
import 'package:diohub/view/repository/code/commit_info_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class CodeBrowser extends StatefulWidget {
  const CodeBrowser({this.showCommitHistory = false, super.key});

  final bool showCommitHistory;

  @override
  CodeBrowserState createState() => CodeBrowserState();
}

class CodeBrowserState extends State<CodeBrowser>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final Duration timeStamp) {
      if (widget.showCommitHistory) {
        showCommitHistory(
          context,
          context.read<RepoBranchProvider>().currentSHA,
        );
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Column(
        // physics: const NeverScrollableScrollPhysics(),
        // shrinkWrap: true,
        children: <Widget>[
          const SizedBox(
            height: 16,
          ),
          Consumer<CodeProvider>(
            builder: (
              final BuildContext context,
              final CodeProvider value,
              final _,
            ) =>
                Column(
              children: <Widget>[
                if (context.read<RepoBranchProvider>().isCommit &&
                    value.tree.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPathWidget(value, context),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: value.status == Status.loaded
                      ? _buildCommitButton(context, value)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: context.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const LoadingIndicator(),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          ProviderLoadingProgressWrapper<CodeProvider>(
            childBuilder:
                (final BuildContext context, final CodeProvider value) =>
                    Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Visibility(
                  visible: value.tree.length > 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HighlightedContainer(
                          highlightColor: context.colorScheme.primary,
                          borderRadius: 12,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: value.tree.length,
                              separatorBuilder: (final BuildContext context,
                                      final int index) =>
                                  Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: context.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                              ),
                              itemBuilder: (final BuildContext context,
                                      final int index) =>
                                  Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (index != value.tree.length - 1) {
                                      Provider.of<CodeProvider>(
                                        context,
                                        listen: false,
                                      ).popTreeUntil(value.tree[index]);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Center(
                                      child: Text(
                                        index == 0
                                            ? Provider.of<RepositoryProvider>(
                                                    context)
                                                .data
                                                .name!
                                            : value
                                                .tree[index - 1]
                                                .tree![
                                                    value.pathIndex[index - 1]]
                                                .path!,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: index == value.tree.length - 1
                                              ? context.colorScheme.primary
                                              : context
                                                  .colorScheme.onSurfaceVariant,
                                          fontWeight:
                                              index == value.tree.length - 1
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
                ),
                SizeExpandedSection(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HighlightedContainer(
                      highlightColor: context.colorScheme.primary,
                      borderRadius: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemBuilder:
                              (final BuildContext context, final int index) =>
                                  BrowserListTile(
                            value.tree.last.tree![index],
                            Provider.of<RepositoryProvider>(
                              context,
                              listen: false,
                            ).data.url.toString(),
                            index,
                          ),
                          separatorBuilder:
                              (final BuildContext context, final int index) =>
                                  Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 60,
                            color: context.colorScheme.surfaceContainerHighest,
                          ),
                          itemCount: value.tree.last.tree!.length,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            loadingBuilder: (final BuildContext context) => Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitButton(
    final BuildContext context,
    final CodeProvider value,
  ) {
    return HighlightedContainer(
      highlightColor: context.colorScheme.primary,
      borderRadius: 12,
      child: Material(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            showCommitHistory(
              context,
              value.tree.last.commit!.sha,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CommitInfoButton(),
          ),
        ),
      ),
    );
  }

  SizeExpandedSection _buildPathWidget(
    final CodeProvider value,
    final BuildContext context,
  ) =>
      SizeExpandedSection(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HighlightedContainer(
            highlightColor: context.colorScheme.primary,
            borderRadius: 12,
            child: Material(
              color: context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: value.status == Status.loaded
                    ? () {
                        context.read<RepoBranchProvider>().reloadBranch();
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Octicons.git_commit,
                          size: 20,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Currently browsing commit',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                Text(
                                  Provider.of<RepoBranchProvider>(context)
                                      .currentSHA
                                      .substring(0, 7),
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '·',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Tap to load latest commits',
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: context.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

void showCommitHistory(final BuildContext context, final String? currentSHA) {
  final String? repoUrl =
      context.read<RepositoryProvider>().data.url.toString();

  final String branchName = context.read<RepoBranchProvider>().currentSHA;

  final String path = context.read<CodeProvider>().getPath();

  final bool isLocked = context.read<RepoBranchProvider>().isCommit;
  unawaited(
    showScrollableBottomSheet(
      context,
      headerBuilder: (final BuildContext context, final StateSetter setState) =>
          Column(
        children: <Widget>[
          Text(
            'Commit History',
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Octicons.git_branch,
                size: 14,
              ),
              const SizedBox(
                width: 4,
              ),
              Text(branchName),
            ],
          ),
        ],
      ),
      scrollableBodyBuilder: (
        final BuildContext context,
        final StateSetter setState,
        final ScrollController scrollController,
      ) =>
          CommitBrowser(
        controller: scrollController,
        currentSHA: currentSHA,
        isLocked: isLocked,
        repoURL: repoUrl,
        path: path,
        branchName: branchName,
        onSelected: (final String sha) {
          Provider.of<RepoBranchProvider>(context, listen: false)
              .setBranch(sha, isCommitSha: true);
        },
      ),
    ),
  );
}
