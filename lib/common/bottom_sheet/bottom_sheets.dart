import 'dart:io';

import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/utils/extensions.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part 'bottom_sheet_actions.dart';
part 'bottom_sheet_bodies.dart';
part 'bottom_sheet_headers.dart';

Future<T?> showDHBottomSheet<T>(
  final BuildContext context, {
  required final WidgetBuilder builder,
  final bool enableDrag = true,
  final bool isScrollControlled = false,
  final bool useRootNavigator = false,
}) =>
    showModalBottomSheet<T>(
      backgroundColor: Colors.transparent,
      enableDrag: enableDrag,
      isDismissible: true,
      // Notch obstructs sheet, https://github.com/flutter/flutter/issues/39205
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: builder,
    );

Future<T?> showScrollableBottomSheet<T>(
  final BuildContext context, {
  required final StatefulWidgetBuilder headerBuilder,
  required final ScrollBuilder scrollableBodyBuilder,
  final bool enableDrag = true,
}) =>
    showDHBottomSheet<T>(
      context,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (final BuildContext context) => DHBottomSheet(
        headerBuilder: headerBuilder,
        builder: (final BuildContext context, final StateSetter setState) =>
            BottomSheetBodyScrollable(
          scrollBuilder: (
            final BuildContext context,
            final ScrollController scrollController,
          ) =>
              scrollableBodyBuilder.call(context, setState, scrollController),
        ),
      ),
    );

class DHBottomSheet extends StatelessWidget {
  const DHBottomSheet({
    required this.builder,
    super.key,
    this.headerBuilder,
    this.titlePadding = const EdgeInsets.all(16),
  });
  final StatefulWidgetBuilder? headerBuilder;
  final StatefulWidgetBuilder builder;
  final EdgeInsets titlePadding;

  @override
  Widget build(final BuildContext context) => SafeArea(
        child: StatefulBuilder(
          builder: (final BuildContext context, final StateSetter setState) =>
              Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (headerBuilder != null) ...<Widget>[
                  Padding(
                    padding: titlePadding,
                    child: headerBuilder!.call(context, setState),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colorScheme.outline.withOpacity(0.1),
                  ),
                ],
                Flexible(child: builder.call(context, setState)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
}

class BottomSheetPagination<T> {
  BottomSheetPagination({
    required this.paginatedListItemBuilder,
    required this.paginationFuture,
    required this.title,
  });

  final ScrollWrapperBuilder<T> paginatedListItemBuilder;
  final ScrollWrapperFuture<T> paginationFuture;
  final String title;

  Future<T?> openSheet(
    final BuildContext context,
  ) =>
      showScrollableBottomSheet<T>(
        context,
        headerBuilder: (
          final BuildContext context,
          final StateSetter setState,
        ) =>
            BottomSheetHeaderText(
          headerText: title,
        ),
        scrollableBodyBuilder: (
          final BuildContext context,
          final StateSetter setState,
          final ScrollController scrollController,
        ) =>
            InfiniteScrollWrapper<T>(
          future: paginationFuture,
          scrollController: scrollController,
          builder: paginatedListItemBuilder,
        ),
      );
}
