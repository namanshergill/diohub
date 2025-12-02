import 'package:flutter/material.dart';

/// A compact button that shows only a chevron icon for expanding/collapsing content.
/// Follows Material 3 design principles with subtle styling.
class CompactExpandButton extends StatelessWidget {
  const CompactExpandButton({
    required this.isExpanded,
    required this.onTap,
    super.key,
    this.tooltip,
  });

  final bool isExpanded;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: isExpanded ? 0.5 : 0,
            child: Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

