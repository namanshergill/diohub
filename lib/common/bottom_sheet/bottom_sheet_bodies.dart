part of 'bottom_sheets.dart';

class BottomSheetBodyList extends StatelessWidget {
  const BottomSheetBodyList({
    required this.children,
    super.key,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });
  final EdgeInsets itemPadding;
  final List<Widget> children;
  @override
  Widget build(final BuildContext context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (final BuildContext context, final int index) => Padding(
          padding: itemPadding,
          child: children[index],
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: context.colorScheme.outline.withOpacity(0.1),
        ),
        itemCount: children.length,
      );
}

typedef ScrollBuilder = Widget Function(
  BuildContext context,
  void Function(void Function()) setState,
  ScrollController scrollController,
);

class BottomSheetBodyScrollable extends StatelessWidget {
  const BottomSheetBodyScrollable({
    required this.scrollBuilder,
    super.key,
    this.initialChildSize = 0.7,
    this.maxChildSize = 0.95,
    this.expand = false,
    this.minChildSize = 0.5,
  });
  final ScrollableWidgetBuilder scrollBuilder;
  final double initialChildSize;
  final double maxChildSize;
  final bool expand;
  final double minChildSize;
  @override
  Widget build(final BuildContext context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        expand: expand,
        minChildSize: minChildSize,
        builder: scrollBuilder.call,
      );
}
