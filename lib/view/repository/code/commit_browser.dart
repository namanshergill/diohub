import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/repositories/commit_list_model.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/code/commit_browser_tiles.dart';
import 'package:flutter/material.dart';

class CommitBrowser extends StatefulWidget {
  const CommitBrowser({
    this.controller,
    this.currentSHA,
    this.isLocked,
    this.onSelected,
    this.path,
    this.repoURL,
    this.branchName,
    super.key,
  });

  final ScrollController? controller;
  final String? currentSHA;
  final bool? isLocked;
  final ValueChanged<String>? onSelected;
  final String? repoURL;
  final String? path;
  final String? branchName;

  @override
  CommitBrowserState createState() => CommitBrowserState();
}

class CommitBrowserState extends State<CommitBrowser> {
  bool? isLocked;
  late List<String> path;
  InfiniteScrollWrapperController controller =
      InfiniteScrollWrapperController();

  @override
  void initState() {
    path = widget.path!.split('/');
    isLocked = widget.isLocked;
    if (path.first.isEmpty || isLocked!) {
      path = <String>[];
    }
    super.initState();
  }

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Visibility(
              visible: isLocked!,
              child: Button(
                onTap: () {
                  setState(() {
                    isLocked = false;
                  });
                  controller.refresh();
                },
                child: const Text('Load latest commits.'),
              ),
            ),
            Visibility(
              visible: path.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    ' Showing history for',
                    style: TextStyle(),
                  ),
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: path.length + 1,
                      separatorBuilder:
                          (final BuildContext context, final int index) =>
                              const Center(child: Text(' /')),
                      itemBuilder:
                          (final BuildContext context, final int index) =>
                              InkPot(
                        onTap: () {
                          setState(() {
                            if (index == 0) {
                              path = <String>[];
                            } else {
                              path = path.sublist(0, index);
                            }
                          });
                          controller.refresh();
                        },
                        child: Center(
                          child: Text(
                            ' ${index == 0 ? widget.repoURL!.split('/').last : path[index - 1]}',
                            style: TextStyle(
                              color: index == path.length
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onBackground,
                              fontWeight: index == path.length
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
            Expanded(
              child: InfiniteScrollWrapper<CommitListModel>(
                controller: controller,
                // shrinkWrap: true,
                scrollController: widget.controller,
                future: (
                  data,
                ) async =>
                    RepositoryServices.getCommitsList(
                  repoURL: widget.repoURL!,
                  pageNumber: data.pageNumber,
                  pageSize: data.pageSize,
                  path: path.join('/'),
                  sha: isLocked! ? widget.currentSHA : widget.branchName,
                  refresh: data.refresh,
                ),
                separatorBuilder:
                    (final BuildContext context, final int index) =>
                        const SizedBox(
                  height: 16,
                ),
                builder: (
                  final BuildContext context,
                  final data,
                ) =>
                    CommitTilesREST(
                  highlighted: isLocked! && widget.currentSHA == data.item.sha,
                  item: data.item,
                  onSelected: (final String value) {
                    widget.onSelected!(value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      );
}
