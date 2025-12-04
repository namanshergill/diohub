import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/repositories/commit_list_model.dart';
import 'package:diohub/providers/issue_pulls/pull_provider.dart';
import 'package:diohub/services/pulls/pulls_service.dart';
import 'package:diohub/utils/http_to_api.dart';
import 'package:diohub/view/repository/code/commit_browser_tiles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PullsCommitsList extends StatelessWidget {
  const PullsCommitsList({super.key});

  @override
  Widget build(final BuildContext context) =>
      InfiniteScrollWrapper<CommitListModel>(
        future: (
          ScrollWrapperFutureArguments<CommitListModel> data,
        ) async =>
            PullsService.getPullCommits(
          Provider.of<PullProvider>(context, listen: false).data.url.toString(),
          perPage: data.pageSize,
          refresh: data.refresh,
          pageNumber: data.pageNumber,
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            const SizedBox(
          height: 16,
        ),
        builder: (
          final BuildContext context,
          final ScrollWrapperBuilderData<CommitListModel> data,
        ) =>
            Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: CommitTilesREST(
            item: data.item,
          ),
        ),
      );
}
