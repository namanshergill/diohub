import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/common/wrappers/scroll_to_top_wrapper.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/readme_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart';
import 'package:provider/provider.dart';

class RepositoryReadme extends StatefulWidget {
  const RepositoryReadme(
    this.repoURL, {
    super.key,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
  });

  final String? repoURL;
  final void Function(List<({String text, String id, int level})> headings)?
      onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;

  @override
  RepositoryReadmeState createState() => RepositoryReadmeState();
}

class RepositoryReadmeState extends State<RepositoryReadme>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // GlobalKey to access MarkdownBody state for scrolling to anchors
  final GlobalKey<MarkdownBodyState> _markdownBodyKey =
      GlobalKey<MarkdownBodyState>();

  // Expose scroll function
  void scrollToAnchor(String anchorId) {
    print('[RepositoryReadmeState] ====== scrollToAnchor CALLED ======');
    print('[RepositoryReadmeState] anchorId: "$anchorId"');
    print(
        '[RepositoryReadmeState] _markdownBodyKey: ${_markdownBodyKey.toString()}');
    print(
        '[RepositoryReadmeState] _markdownBodyKey.currentState is ${_markdownBodyKey.currentState != null ? "not null" : "null"}');
    if (_markdownBodyKey.currentState != null) {
      print(
          '[RepositoryReadmeState] ✓ MarkdownBodyState found, calling scrollToAnchor');
      print(
          '[RepositoryReadmeState] MarkdownBodyState type: ${_markdownBodyKey.currentState.runtimeType}');
      _markdownBodyKey.currentState!.scrollToAnchor(anchorId);
      print(
          '[RepositoryReadmeState] scrollToAnchor call to MarkdownBodyState completed');
    } else {
      print(
          '[RepositoryReadmeState] ✗ ERROR: _markdownBodyKey.currentState is null');
      print(
          '[RepositoryReadmeState] This means MarkdownBody widget may not be mounted yet');
    }
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ProviderLoadingProgressWrapper<RepoReadmeProvider>(
        loadingBuilder: (final BuildContext context) => const Padding(
          padding: EdgeInsets.only(top: 48),
          child: LoadingIndicator(),
        ),
        childBuilder:
            (final BuildContext context, final RepoReadmeProvider value) {
          final RepositoryProvider repoProvider =
              Provider.of<RepositoryProvider>(context);

          return ScrollToTopWrapper(
            builder: (
              final BuildContext context,
              final ScrollViewProperties properties,
            ) =>
                SingleChildScrollView(
              child: MarkdownRenderAPI(
                value.data!.content!,
                markdownBodyKey: _markdownBodyKey,
                repoContext: repoProvider.data.nameWithOwner,
                branch: Provider.of<RepoBranchProvider>(context).currentSHA,
                onHeadingsExtracted: (headings) {
                  // Pass headings to parent callback
                  widget.onHeadingsExtracted?.call(headings);
                },
                onScrollToAnchor: widget.onScrollToAnchor,
              ),
            ),
          );
        },
      ),
    );
  }
}
