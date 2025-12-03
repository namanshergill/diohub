import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/menu_button.dart';
import 'package:diohub/common/misc/tappable_card.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flex_list/flex_list.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

class WrappedCollection extends StatelessWidget {
  const WrappedCollection({
    required this.children,
    super.key,
    this.spacing = 8,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(final BuildContext context) => FlexList(
        verticalSpacing: spacing,
        horizontalSpacing: spacing,
        children: children,
      );
}

class InfoCard extends StatelessWidget {
  InfoCard({
    required final Widget child,
    final VoidCallback? onTap,
    this.trailing,
    super.key,
    this.title,
    this.leading,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    final VoidCallback? onHeaderTap,
    this.headerColor,
    this.elevation,
    final EdgeInsets? childPadding,
    // this.titleTextStyle,
    // this.leadingIconColor,
  })  : onHeaderTap = onHeaderTap ?? onTap,
        children = <Widget>[
          Builder(
            builder: (final BuildContext context) => InkPot(
              onTap: onTap,
              borderRadius: BasicCard.getLinkedBorder(
                context,
                cardLinkType: CardLinkType.atTop,
              ),
              child: Padding(
                padding: childPadding ??
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
        assert(
          title != null || leading != null,
          'Provide at least one descriptor.',
        );

  const InfoCard.children({
    required this.children,
    this.trailing,
    super.key,
    this.title,
    this.leading,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.onHeaderTap,
    this.headerColor,
    this.elevation,
    // this.titleTextStyle,
    // this.leadingIconColor,
  }) : assert(
          title != null || leading != null,
          'Provide at least one descriptor.',
        );

  final List<Widget> children;
  final VoidCallback? onHeaderTap;
  final Widget? trailing;
  final String? title;
  final Widget? leading;
  final EdgeInsets headerPadding;
  final Color? headerColor;
  final double? elevation;

  static Icon get dropdownTrailingIcon => const Icon(
        Icons.arrow_drop_down_rounded,
      );

  static Widget leadingIcon({
    required final IconData icon,
    final Color? color,
  }) =>
      Builder(
        builder: (final BuildContext context) => Icon(
          icon,
          // size: 18,
          color: color ?? context.colorScheme.onSurfaceVariant.asHint(),
        ),
      );

  Widget _buildUI(final BuildContext context) => IntrinsicWidth(
        child: Material(
          elevation: elevation ?? 0,
          color: context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CardHeader(
                onTap: onHeaderTap,
                elevation: 0, // Remove elevation from header since parent has it
                color: headerColor,
                child: Padding(
                  padding: headerPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildDescriptors(context),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ),
              ...List<Widget>.generate(children.length, (final int index) {
                final bool isLast = index == children.length - 1;
                return Column(
                  children: <Widget>[
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: context.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    BasicCard.linked(
                      elevation: 0, // Remove elevation since parent has it
                      cardLinkType:
                          isLast ? CardLinkType.atTop : CardLinkType.both,
                      child: children[index],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );

  Row _buildDescriptors(final BuildContext context) => Row(
        children: <Widget>[
          if (leading != null)
            Theme(
              data: context.themeData.copyWith(
                iconTheme: context.themeData.iconTheme.copyWith(
                  size: 16,
                  color: context.colorScheme.primary,
                ),
              ),
              child: DefaultTextStyle(
                style: context.textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                child: leading!,
              ),
            ),
          if (title != null && leading != null)
            const SizedBox(
              width: 8,
            ),
          if (title != null)
            Text(
              title!,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
        ],
      );

  @override
  Widget build(final BuildContext context) => _buildUI(context);
}

class MenuInfoCard extends StatelessWidget {
  const MenuInfoCard({
    required this.title,
    required this.child,
    required this.menuBuilder,
    this.onTap,
    super.key,
    this.leading,
    this.headerColor,
    this.elevation,
    // this.titleTextStyle,
    // this.onTap,
  });

  final VoidCallback? onTap;
  final Widget? leading;
  final Color? headerColor;
  final double? elevation;

  // final TextStyle? titleTextStyle;
  // final VoidCallback? onTap;
  final String title;
  final List<PullDownMenuEntry> Function(BuildContext context) menuBuilder;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final List<PullDownMenuEntry> menuItems = menuBuilder.call(context);
    if (menuItems.isNotEmpty) {
      return MenuButton(
        itemBuilder: menuBuilder,
        buttonBuilder: (final BuildContext context, final showMenu) => SizedBox(
          height: 32,
          width: 32,
          child: IconButton(
            onPressed: showMenu,
            icon: Icon(
              Icons.adaptive.more_rounded,
            ),
            // padding: const EdgeInsets.all(4),
            // constraints: const BoxConstraints(),
          ),
        ),
        builder:
            (final BuildContext context, final Widget button, final showMenu) =>
                GestureDetector(
          onLongPress: showMenu,
          child: InfoCard(
            trailing: button,
            headerColor: headerColor,
            headerPadding: const EdgeInsets.only(
              left: 12,
              bottom: 2,
              top: 2,
            ),
            elevation: elevation,
            onTap: onTap,
            onHeaderTap: showMenu,
            title: title,
            leading: leading,
            // titleTextStyle: titleTextStyle,
            child: child,
          ),
        ),
      );
    }
    return InfoCard(
      onTap: onTap,
      title: title,
      elevation: elevation,
      headerColor: headerColor,
      leading: leading,
      child: child,
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader({
    required this.child,
    super.key,
    this.cardLinkType = CardLinkType.atBottom,
    this.menuItems = const <PullDownMenuItem>[],
    this.onTap,
    this.color,
    this.elevation,
    // this.padding = const EdgeInsets.all(8),
  });

  final Color? color;
  final double? elevation;

  // final EdgeInsets padding;
  final CardLinkType cardLinkType;
  final Widget child;
  final List<PullDownMenuItem> menuItems;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => BasicCard.linked(
        cardLinkType: cardLinkType,
        elevation: elevation,
        // color: color ?? context.colorScheme.surfaceVariant.asHint(),
        // color: color ?? context.colorScheme.secondaryContainer,
        // elevation: 0,
        onTap: onTap,

        child: DefaultTextStyle(
          style: context.textTheme.bodySmall!.copyWith(
            color: context.colorScheme.onSecondaryContainer,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              // color: context.colorScheme.onSecondaryContainer,
              size: 16,
            ),
            child: child,
          ),
        ),
      );
}

// abstract class InfoCardAdapter {
//   String get title;
//
//   bool get isExpanded;
//
//   WidgetBuilder get viewBuilder;
//
//   VoidCallback? onTap(final BuildContext context);
// }

// abstract class PaginatedInfoCardAdapter<T> extends InfoCardAdapter {
//   PaginatedInfoCardAdapter({
//     required this.availableList,
//     required this.singleItemBehavior,
//     this.iconOnLengthOverrides = const <int, Icon?>{},
//     this.onTapOnLengthOverrides = const <int, VoidCallback?>{},
//   });
//
//   Icon? get trailingIcon {
//     if (onTapOnLengthOverrides.containsKey(listLength)) {
//       return iconOnLengthOverrides[listLength];
//     } else if (singleItemBehavior != null && listLength == 1) {
//       return singleItemBehavior!.icon;
//     }
//     return switch (listLength) {
//       0 => null,
//       _ => const Icon(
//           Icons.arrow_drop_down_rounded,
//         ),
//     };
//   }
//
//   BottomSheetPagination<NodeWithPaginationInfo<T>> get paginatedSheet;
//
//   @override
//   VoidCallback? onTap(final BuildContext context) {
//     if (onTapOnLengthOverrides.containsKey(listLength)) {
//       return onTapOnLengthOverrides[listLength];
//     } else if (singleItemBehavior != null && listLength == 1) {
//       return singleItemBehavior!.onTap?.call(context);
//     }
//     return switch (listLength) {
//       0 => null,
//       _ => () async => paginatedSheet.openSheet(context),
//     };
//   }
//
//   final SingleItemConfigForMultiListAdapter? singleItemBehavior;
//
//   /// Overrides the cards onTap behaviour for specific list lengths.
//   final Map<int, VoidCallback?> onTapOnLengthOverrides;
//
//   /// Overrides the cards onTap behaviour for specific list lengths.
//   final Map<int, Icon?> iconOnLengthOverrides;
//
//   final MultiItemInfoCardList<T> availableList;
//
//   List<T> get items => availableList.limitedAvailableList;
//
//   int get listLength => availableList.totalCount;
// }

class UnfinishedList<T> {
  UnfinishedList({
    required this.limitedAvailableList,
    final int? totalCount,
  }) : totalCount = totalCount ?? limitedAvailableList.length;
  final int totalCount;
  final List<T> limitedAvailableList;

  bool get isComplete => totalCount == limitedAvailableList.length;
}

class NodeWithPaginationInfo<T> {
  NodeWithPaginationInfo({
    required this.node,
    required this.cursor,
    // this.totalCount,
  });

  NodeWithPaginationInfo.pageKey({
    required this.node,
    required final int pageKey,
    // this.totalCount,
  }) : cursor = pageKey.toString();

  factory NodeWithPaginationInfo.fromEdge(final Object edge) =>
      NodeWithPaginationInfo<T>(
        // ignore: avoid_dynamic_calls
        node: (edge as dynamic).node!,
        // ignore: avoid_dynamic_calls
        cursor: (edge as dynamic).cursor,
      );

  final T node;

  // final int? totalCount;
  final String cursor;

  @Deprecated(
    'This is for backwards compatibility with the REST API pagination ONLY!',
  )
  int? get cursorAsPageKey => int.tryParse(cursor);
}
