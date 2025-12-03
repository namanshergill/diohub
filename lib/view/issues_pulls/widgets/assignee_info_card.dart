import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_stack/image_stack.dart';

class AssigneeInfoCard extends StatelessWidget {
  const AssigneeInfoCard({
    required this.availableList,
    required this.titleBuilder,
    required this.fetchActorsList,
    this.onTap,
    this.trailing,
    super.key,
  });

  final UnfinishedList<NodeWithPaginationInfo<Gactor>> availableList;
  final String Function(
    UnfinishedList<NodeWithPaginationInfo<Gactor>> availableList,
  ) titleBuilder;
  final ScrollWrapperFuture<NodeWithPaginationInfo<Gactor>> fetchActorsList;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => InfoCard(
        onTap: availableList.limitedAvailableList.isEmpty
            ? null
            : () async {
                if (availableList.totalCount > 1) {
                  await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
                    paginatedListItemBuilder: _paginatedListItemBuilder,
                    paginationFuture: fetchActorsList,
                    title: titleBuilder.call(availableList),
                  ).openSheet(context);
                } else {
                  navigateToProfile(
                    login: availableList.limitedAvailableList.first.node.login,
                    context: context,
                  );
                }
              },
        trailing: _getIcon(availableList.totalCount),
        title: titleBuilder.call(availableList),
        child: _buildChild(),
      );

  Widget _buildChild() => switch (availableList.totalCount) {
        0 => Text(
            'None assigned',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        1 => ProfileTile.login(
            padding: const EdgeInsets.all(4),
            avatarUrl: availableList.limitedAvailableList.first.node.avatarUrl
                .toString(),
            userLogin: availableList.limitedAvailableList.first.node.login,
            disableTap: true,
          ),
        _ => ImageStack.widgets(
            totalCount: availableList.totalCount,
            widgetBorderColor: Colors.transparent,
            widgetBorderWidth: 0,
            children: availableList.limitedAvailableList
                .map(
                  (final NodeWithPaginationInfo<Gactor> e) =>
                      ProfileTile.avatar(
                    avatarUrl: e.node.avatarUrl.toString(),
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
      };
}

ScrollWrapperBuilder<NodeWithPaginationInfo<Gactor>>
    get _paginatedListItemBuilder => (
          final BuildContext context,
          final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
        ) =>
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                color: context.colorScheme.surface,
                child: ProfileTile.login(
                  avatarUrl: data.item.node.avatarUrl.toString(),
                  userLogin: data.item.node.login,
                  wrapperBuilder: (final Widget child) => Row(
                    children: _buildListItemChildren(data, context, child),
                  ),
                ),
              ),
            );

Icon? _getIcon(final int listLength) => switch (listLength) {
      0 => null,
      1 => Icon(Icons.adaptive.arrow_forward_rounded),
      _ => const Icon(
          Icons.arrow_drop_down_rounded,
        ),
    };

List<Widget> _buildListItemChildren(
  final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
  final BuildContext context,
  final Widget child,
) =>
    <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(
          '${data.index + 1}',
          style: context.textTheme.bodySmall,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    ];

