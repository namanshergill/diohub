import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A generic nested card widget that displays content in a nested card layout.
/// The nested card has a subtle background color to distinguish it from the parent.
/// Can optionally display a header above the nested card content.
class NestedCard extends StatelessWidget {
  const NestedCard({
    required this.child,
    // this.header,
    // this.trailing,
    this.padding,
    this.swapColors = false,
    super.key,
  });

  final Widget child;

  final EdgeInsetsGeometry? padding;
  final bool swapColors;

  @override
  Widget build(final BuildContext context) {
    // When swapColors is true, nested card gets the darker color (default Material surface)
    // When swapColors is false, nested card gets the lighter blended color
    final Color? nestedCardColor = swapColors
        ? null // null means use default Material surface color (darker)
        : (context.colorScheme.brightness == Brightness.dark
            ? Color.alphaBlend(
                Colors.white.withOpacity(0.08),
                context.colorScheme.surface,
              )
            : Color.alphaBlend(
                Colors.black.withOpacity(0.06),
                context.colorScheme.surface,
              ));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: nestedCardColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}
