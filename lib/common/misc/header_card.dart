import 'package:diohub/common/misc/nested_card.dart';
import 'package:flutter/material.dart';

/// A generic card widget that implements the common layout pattern:
/// - Outer Card with padding
/// - Header row with header content (left) and trailing (right)
/// - Spacing
/// - NestedCard for child content
///
/// This widget is used by both BaseEventCard and NestedIssueCard patterns.
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    required this.child,
    this.header,
    this.trailing,
    this.padding,
    this.headerPadding,
    this.childPadding,
    this.spacing,
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

  /// Padding around the header row (default: EdgeInsets.symmetric(horizontal: 8, vertical: 8))
  final EdgeInsetsGeometry? headerPadding;

  /// Padding inside the nested card for child content (default: EdgeInsets.all(8))
  final EdgeInsetsGeometry? childPadding;

  /// Spacing between header and nested card (default: 8)
  final double? spacing;

  @override
  Widget build(final BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    const EdgeInsets.symmetric(horizontal: 4,vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Header content in nested row
                    if (header != null)
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[header!],
                        ),
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
            // Content in nested card
            NestedCard(
              padding: childPadding ?? const EdgeInsets.all(8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
