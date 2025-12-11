import 'package:diohub/common/misc/header_card.dart';
import 'package:diohub/common/misc/nested_card.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A widget that combines HeaderCard with NestedCard.
/// The header card and nested card colors can be flipped when flipColors is true:
/// - Header card gets lighter color
/// - Nested card gets darker color (default Material surface)
class NestedCardWithHeader extends StatelessWidget {
  const NestedCardWithHeader({
    required this.child,
    this.header,
    this.trailing,
    this.padding,
    this.headerPadding,
    this.childPadding,
    this.spacing,
    this.flipColors = false,
    this.useMaxWidth = true,
    super.key,
  });

  /// The main content to display in the nested card
  final Widget child;

  /// Header content displayed on the left side
  final Widget? header;

  /// Trailing content displayed on the right side (e.g., timestamp)
  final Widget? trailing;

  /// Padding around the entire card (default: EdgeInsets.symmetric(horizontal: 8, vertical: 8))
  final EdgeInsetsGeometry? padding;

  /// Padding around the header row (default: EdgeInsets.symmetric(horizontal: 4, vertical: 2))
  final EdgeInsetsGeometry? headerPadding;

  /// Padding inside the nested card for child content (default: EdgeInsets.all(8))
  final EdgeInsetsGeometry? childPadding;

  /// Spacing between header and nested card (default: 8)
  final double? spacing;

  /// Whether to flip colors: header card gets lighter color, nested card gets darker color (default: false)
  final bool flipColors;

  /// Whether to use max width constraints (default: true)
  /// When false, the widget will size to its content instead of expanding to fill available width
  final bool useMaxWidth;

  @override
  Widget build(final BuildContext context) {
    // Calculate colors based on flipColors
    final Color? headerCardColor = flipColors
        ? (context.colorScheme.brightness == Brightness.dark
            ? Color.alphaBlend(
                Colors.white.withOpacity(0.08),
                context.colorScheme.surface,
              )
            : Color.alphaBlend(
                Colors.black.withOpacity(0.06),
                context.colorScheme.surface,
              ))
        : null; // null means use default Material card color

    final cardWidget = HeaderCard(
      padding: padding,
      headerPadding: headerPadding,
      spacing: spacing,
      color: headerCardColor,
      margin: flipColors ? EdgeInsets.zero : null,
      header: header,
      trailing: trailing,
      child: NestedCard(
        padding: childPadding ?? const EdgeInsets.all(8),
        swapColors: flipColors,
        child: child,
      ),
    );

    // When useMaxWidth is true (default), return the widget as-is
    // It will expand to fill available width
    return cardWidget;
  }
}
