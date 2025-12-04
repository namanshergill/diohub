import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:flutter/material.dart';

/// An expandable info card tile that shows a title and expands to show more information when clicked.
///
/// Example usage:
/// ```dart
/// ExpandableInfoCard(
///   title: 'Description',
///   expandedContent: Text('Repository description text here...'),
///   initiallyExpanded: false,
/// )
/// ```
class ExpandableInfoCard extends StatefulWidget {
  const ExpandableInfoCard({
    required this.title,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.titleStyle,
    this.contentPadding,
    this.borderRadius = 12.0,
    super.key,
  });

  /// The title text displayed in the header
  final String title;

  /// The content widget shown when expanded
  final Widget expandedContent;

  /// Whether the card starts expanded
  final bool initiallyExpanded;

  /// Callback when expansion state changes
  final void Function(bool isExpanded)? onExpansionChanged;

  /// Optional custom style for the title
  final TextStyle? titleStyle;

  /// Padding for the expanded content
  final EdgeInsets? contentPadding;

  /// Border radius for the card
  final double borderRadius;

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextStyle defaultTitleStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontSize: 12,
                ) ??
            const TextStyle();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - clickable title with expand icon
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadius),
              topRight: Radius.circular(widget.borderRadius),
              bottomLeft: _isExpanded
                  ? Radius.zero
                  : Radius.circular(widget.borderRadius),
              bottomRight: _isExpanded
                  ? Radius.zero
                  : Radius.circular(widget.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      widget.title,
                      style: widget.titleStyle ?? defaultTitleStyle,
                    ),
                  ),
                  // Expand/collapse icon - smaller and more subtle
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          SizeExpandedSection(
            expand: _isExpanded,
            child: Container(
              width: double.infinity,
              padding: widget.contentPadding ??
                  const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                          fontSize: 13,
                        ) ??
                    const TextStyle(),
                child: widget.expandedContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
