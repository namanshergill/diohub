import 'package:flutter/material.dart';

/// A generic card widget that implements the common layout pattern:
/// - Outer Card with padding
/// - Header row with header content (left) and trailing (right)
/// - Spacing
/// - Direct child content (no nested card)
///
/// This is the base widget. For nested card behavior, use NestedCardWithHeader.
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    required this.child,
    this.header,
    this.trailing,
    this.padding,
    this.headerPadding,
    this.spacing,
    this.color,
    this.margin,
    super.key,
  });

  /// The main content to display
  final Widget child;

  /// Header content displayed on the left side
  final Widget? header;

  /// Trailing content displayed on the right side (e.g., timestamp)
  final Widget? trailing;

  /// Padding around the entire card (default: EdgeInsets.symmetric(horizontal: 8, vertical: 8))
  final EdgeInsetsGeometry? padding;

  /// Padding around the header row (default: EdgeInsets.symmetric(horizontal: 4, vertical: 2))
  final EdgeInsetsGeometry? headerPadding;

  /// Spacing between header and child (default: 8)
  final double? spacing;

  /// Optional color for the card background
  final Color? color;

  /// Optional margin for the card (default: null, uses Material default)
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(final BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: margin,
      color: color,
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header row with header (left) and trailing (right)
            if (header != null || trailing != null) ...[
              Padding(
                padding: headerPadding ??
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Header content in nested row
                    if (header != null)
                      Expanded(
                        child: header!,
                      ),
                    // Trailing content on the right
                    if (trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: trailing!,
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacing ?? 8),
            ],
            // Content rendered directly
            child,
          ],
        ),
      ),
    );
  }
}
