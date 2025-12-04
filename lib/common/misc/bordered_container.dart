import 'package:flutter/material.dart';

/// Enum to specify which side the border should be on
enum BorderSideType {
  top,
  bottom,
  left,
  right,
}

/// A widget that wraps a child with a colored border on one side with rounded corners.
///
/// This creates a 3D effect by adding a colored border on a specified side.
/// The border respects the borderRadius without using ClipRRect.
class BorderedContainer extends StatelessWidget {
  const BorderedContainer({
    required this.child,
    required this.borderColor,
    this.borderSide = BorderSideType.bottom,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    super.key,
  });

  /// The widget to wrap
  final Widget child;

  /// Color of the border
  final Color borderColor;

  /// Which side to show the border on
  final BorderSideType borderSide;

  /// Width of the border
  final double borderWidth;

  /// Border radius for rounded corners
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Create border with only the specified side visible
    final Border border;
    final BorderRadius clipRadius;

    switch (borderSide) {
      case BorderSideType.top:
        border = Border(
          top: BorderSide(color: borderColor, width: borderWidth),
        );
        // Clip bottom corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        );
        break;
      case BorderSideType.bottom:
        border = Border(
          bottom: BorderSide(color: borderColor, width: borderWidth),
        );
        // Clip top corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        );
        break;
      case BorderSideType.left:
        border = Border(
          left: BorderSide(color: borderColor, width: borderWidth),
        );
        // Clip right corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        );
        break;
      case BorderSideType.right:
        border = Border(
          right: BorderSide(color: borderColor, width: borderWidth),
        );
        // Clip left corners (opposite side) for consistent rounded borders
        clipRadius = BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
        );
        break;
    }

    return ClipRRect(
      borderRadius: clipRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        child: child,
      ),
    );
  }
}
