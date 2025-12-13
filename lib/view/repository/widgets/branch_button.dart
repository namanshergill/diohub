import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/models/repositories/branch_list_model.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class BranchButton extends StatelessWidget {
  const BranchButton({super.key});

  double get height => 55;

  @override
  Widget build(final BuildContext context) =>
      ProviderLoadingProgressWrapper<RepoBranchProvider>(
        loadingBuilder: (final BuildContext context) => Container(
          height: 48,
        ),
        childBuilder: (
          final BuildContext context,
          final RepoBranchProvider value,
        ) =>
            HighlightedContainer(
          highlightColor: context.colorScheme.primary,
          child: Material(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                try {
                  final String currentBranch =
                      context.read<RepoBranchProvider>().currentSHA;
                  Future<void> changeBranch(final String branch) async {
                    await Provider.of<RepoBranchProvider>(
                      context,
                      listen: false,
                    ).setBranch(branch);
                  }

                  await BottomSheetPagination<RepoBranchListItemModel>(
                    paginatedListItemBuilder: (
                      final BuildContext context,
                      final ScrollWrapperBuilderData<RepoBranchListItemModel>
                          data,
                    ) =>
                        Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        color: data.item.name == currentBranch
                            ? context.colorScheme.primary
                            : context.colorScheme.surface,
                        child: InkPot(
                          onTap: () async {
                            await changeBranch(data.item.name!);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: _buildListBranchItem(
                              data, currentBranch, context),
                        ),
                      ),
                    ),
                    paginationFuture: (
                      data,
                    ) async {
                      final repo = Provider.of<RepositoryProvider>(
                        context,
                        listen: false,
                      ).data;
                      return RepositoryServices.fetchBranchList(
                        repo.url.toString(),
                        data.pageNumber,
                        data.pageSize,
                        refresh: data.refresh,
                      );
                    },
                    title: () {
                      final repo = Provider.of<RepositoryProvider>(
                        context,
                        listen: false,
                      ).data;
                      final ownerLogin = repo.owner.when(
                        user: (u) => u.login,
                        organization: (o) => o.login,
                        orElse: () => '',
                      );
                      return 'Branches in $ownerLogin/${repo.name}';
                    }(),
                  ).openSheet(context);
                } on Exception {
                  rethrow;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Octicons.git_branch,
                      size: 18,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value.currentSHA,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Padding _buildListBranchItem(
    final ScrollWrapperBuilderData<RepoBranchListItemModel> data,
    final String currentBranch,
    final BuildContext context,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Row(
                children: <Widget>[
                  const Icon(Octicons.git_branch),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      data.item.name!,
                      style: TextStyle(
                        fontWeight: data.item.name == currentBranch
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final repo = Provider.of<RepositoryProvider>(
                  context,
                  listen: false,
                ).data;
                final isDefault = repo.defaultBranchRef?.name == data.item.name;
                return Visibility(
                  visible: isDefault,
                  replacement: Container(),
                  child: Text(
                    'Default',
                    style: context.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ],
        ),
      );
}

// class BranchMultiItemAdapter extends PaginatedInfoCardAdapter<BranchModel> {
//   BranchMultiItemAdapter({
//     required super.availableList,
//   }) : super(
//           singleItemBehavior: null,
//         );
//
//   @override
//   bool get isExpanded => false;
//
//   @override
//   // TODO: implement paginatedSheet
//   BottomSheetPagination<NodeWithPaginationInfo<BranchModel>>
//       get paginatedSheet => throw UnimplementedError();
//
//   @override
//   // TODO: implement title
//   String get title => throw UnimplementedError();
//
//   @override
//   // TODO: implement viewBuilder
//   WidgetBuilder get viewBuilder => throw UnimplementedError();
// }
