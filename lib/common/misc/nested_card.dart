import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A generic nested card widget that displays content in a nested card layout.
/// The nested card has a subtle background color to distinguish it from the parent.
/// Can optionally display a header above the nested card content.
class NestedCard extends StatelessWidget {
  const NestedCard({
    required this.child,
    this.header,
    this.trailing,
    this.padding,
    this.headerPadding,
    super.key,
  });

  final Widget child;
  final Widget? header;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? headerPadding;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (header != null || trailing != null) ...[
            Padding(
              padding: headerPadding ??
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (header != null)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[header!],
                      ),
                    ),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: trailing!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: context.colorScheme.brightness == Brightness.dark
                ? Color.alphaBlend(
                    Colors.white.withOpacity(0.08),
                    context.colorScheme.surface,
                  )
                : Color.alphaBlend(
                    Colors.black.withOpacity(0.06),
                    context.colorScheme.surface,
                  ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
