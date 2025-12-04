import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Formats size in KB to human-readable format (KB, MB, GB)
String formatSize(int? sizeInKB) {
  if (sizeInKB == null) return '';
  if (sizeInKB < 1024) {
    return '$sizeInKB KB';
  } else if (sizeInKB < 1024 * 1024) {
    return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
  } else {
    return '${(sizeInKB / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Helper function to build a trailing widget for action button showing count
Widget buildActionButtonTrailingCount(BuildContext context, int count) {
  return Text(
    count.toString(),
    style: context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Helper function to build a trailing widget for action button showing size
Widget buildActionButtonTrailingSize(BuildContext context, int sizeInKB) {
  return Text(
    formatSize(sizeInKB),
    style: context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Builds a standard action card widget with Material 3 styling.
///
/// Supports:
/// - Count display (top-right)
/// - Size display (top-right, formatted)
/// - Custom icon color
/// - Enabled/disabled state
/// - Destructive actions (red)
/// - Positive actions (green)
Widget buildStandardActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 18,
  double borderRadius = 12,
  EdgeInsets padding = const EdgeInsets.all(12),
}) {
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = context.colorScheme.error;
    textColor = context.colorScheme.onErrorContainer;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.withOpacity(0.12);
    iconColor = Colors.green.shade700;
    textColor = Colors.green.shade900;
  } else {
    // Use surfaceContainerHigh for a slightly darker, more visible background
    backgroundColor = context.colorScheme.surfaceContainerHigh;
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
  }

  // Subtle background tint based on action type for distinction
  Color? typeBackgroundColor;
  if (action.actionType != null) {
    switch (action.actionType!) {
      case ActionButtonActionType.tab:
        typeBackgroundColor = context.colorScheme.primary.withOpacity(0.08);
        break;
      case ActionButtonActionType.bottomSheet:
        typeBackgroundColor = context.colorScheme.secondary.withOpacity(0.08);
        break;
      case ActionButtonActionType.navigation:
        typeBackgroundColor = context.colorScheme.tertiary.withOpacity(0.08);
        break;
      case ActionButtonActionType.action:
        break;
    }
  }
  final finalBackgroundColor = typeBackgroundColor != null
      ? Color.alphaBlend(typeBackgroundColor, backgroundColor)
      : backgroundColor;

  return HighlightedContainer(
    highlightColor: iconColor,
    borderRadius: borderRadius,
    // elevation: 4,
    child: Material(
      color: finalBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled ? action.onTap : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (action.leading != null) ...[
                      action.leading!,
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      action.icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                    const Spacer(),
                    if (action.trailing != null)
                      DefaultTextStyle(
                        style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ) ??
                            TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                        child: action.trailing!,
                      )
                    else
                      // Reserve space for consistency when no trailing widget
                      SizedBox(
                        width: context.textTheme.titleSmall?.fontSize != null
                            ? (context.textTheme.titleSmall!.fontSize! * 2.2)
                            : 26,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds a compact action card widget (smaller, vertical layout).
///
/// Used for issue/pull action buttons that need to be more compact.
Widget buildCompactActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 18,
  double borderRadius = 10,
  EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
}) {
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = context.colorScheme.error;
    textColor = context.colorScheme.onErrorContainer;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.withOpacity(0.12);
    iconColor = Colors.green.shade700;
    textColor = Colors.green.shade900;
  } else {
    // Use surfaceContainerHigh for a slightly darker, more visible background
    backgroundColor = context.colorScheme.surfaceContainerHigh;
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
  }

  // Subtle background tint based on action type for distinction
  Color? typeBackgroundColor;
  if (action.actionType != null) {
    switch (action.actionType!) {
      case ActionButtonActionType.tab:
        typeBackgroundColor = context.colorScheme.primary.withOpacity(0.08);
        break;
      case ActionButtonActionType.bottomSheet:
        typeBackgroundColor = context.colorScheme.secondary.withOpacity(0.08);
        break;
      case ActionButtonActionType.navigation:
        typeBackgroundColor = context.colorScheme.tertiary.withOpacity(0.08);
        break;
      case ActionButtonActionType.action:
        break;
    }
  }
  final finalBackgroundColor = typeBackgroundColor != null
      ? Color.alphaBlend(typeBackgroundColor, backgroundColor)
      : backgroundColor;

  return HighlightedContainer(
    highlightColor: iconColor,
    borderRadius: borderRadius,
    // elevation: 4,
    child: Material(
      color: finalBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled ? action.onTap : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: iconSize,
                  color: iconColor,
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
