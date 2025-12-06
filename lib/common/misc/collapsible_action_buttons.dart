import 'package:diohub/common/misc/compact_expand_button.dart';
import 'package:flex_list/flex_list.dart';
import 'package:flutter/material.dart';

/// Configuration for determining how many action buttons should be visible
/// based on available width.
class ActionButtonsVisibilityConfig {
  const ActionButtonsVisibilityConfig({
    this.minPerRow = 3,
    this.maxPerRow = 4,
    this.defaultVisibleCount,
  });

  /// Minimum number of buttons per row
  final int minPerRow;

  /// Maximum number of buttons per row
  final int maxPerRow;

  /// Number of primary actions visible by default
  /// If null, uses width-based calculation to show buttonsPerRow number of actions
  final int? defaultVisibleCount;

  /// Default configuration: Uses width-based calculation
  static const ActionButtonsVisibilityConfig defaultConfig =
      ActionButtonsVisibilityConfig(
    minPerRow: 3,
    maxPerRow: 4,
    defaultVisibleCount: null,
  );

  /// Configuration with fixed visible count
  /// Uses default minPerRow (3) and maxPerRow (4)
  static ActionButtonsVisibilityConfig fixedCount({
    required int defaultVisibleCount,
  }) =>
      ActionButtonsVisibilityConfig(
        minPerRow: 3,
        maxPerRow: 4,
        defaultVisibleCount: defaultVisibleCount,
      );
}

/// Type of action that will be performed when an ActionButton is tapped
enum ActionButtonActionType {
  /// Opens a tab within the current screen
  tab,

  /// Opens a bottom sheet
  bottomSheet,

  /// Navigates to a new screen
  navigation,

  /// Performs an action (default)
  action,
}

/// Visibility state for action buttons in collapsed toolbar state
enum ActionButtonVisibilityState {
  /// Always visible in collapsed state, regardless of min count
  /// These buttons are shown first, before any maybeVisible buttons
  alwaysVisible,

  /// Never visible in collapsed state, regardless of min count
  /// These buttons are only shown when expanded
  alwaysHidden,

  /// Visible in collapsed state if there's room (based on minCount/maxCount)
  /// Shown after alwaysVisible buttons, up to the specified count limit
  maybeVisible,
}

/// Data class for action button configuration
class ActionButtonData {
  const ActionButtonData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
    this.iconColor,
    this.enabled = true,
    this.isDestructive = false,
    this.isPositive = false,
    this.actionType,
    this.visibilityState = ActionButtonVisibilityState.maybeVisible,
    this.visible = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Optional widget to display on the leading side (left) of the card
  final Widget? leading;

  /// Optional widget to display on the trailing side (right) of the card
  final Widget? trailing;
  final Color? iconColor;
  final bool enabled;
  final bool isDestructive;
  final bool isPositive;

  /// Type of action this button performs (determines trailing icon if trailing is not provided)
  final ActionButtonActionType? actionType;

  /// Visibility state for collapsed toolbar state
  /// Determines when this button appears in the collapsed horizontal bar
  final ActionButtonVisibilityState visibilityState;

  /// Whether this action button is visible (can be dynamically changed to show/hide with animation)
  /// When false, the button will be hidden from both collapsed and expanded states
  final bool visible;

  /// Creates a copy of this ActionButtonData with updated properties
  ActionButtonData copyWith({
    IconData? icon,
    String? label,
    VoidCallback? onTap,
    Widget? leading,
    Widget? trailing,
    Color? iconColor,
    bool? enabled,
    bool? isDestructive,
    bool? isPositive,
    ActionButtonActionType? actionType,
    ActionButtonVisibilityState? visibilityState,
    bool? visible,
  }) {
    return ActionButtonData(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      onTap: onTap ?? this.onTap,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      isPositive: isPositive ?? this.isPositive,
      actionType: actionType ?? this.actionType,
      visibilityState: visibilityState ?? this.visibilityState,
      visible: visible ?? this.visible,
    );
  }
}

/// A reusable widget that displays action buttons with expand/collapse functionality.
///
/// Automatically handles the expand/collapse state and animation.
/// Uses a responsive grid layout based on available width.
/// Optionally shows an expand button below the buttons.
class CollapsibleActionButtons extends StatefulWidget {
  const CollapsibleActionButtons({
    required this.primaryActions,
    required this.secondaryActions,
    required this.actionCardBuilder,
    this.visibilityConfig = ActionButtonsVisibilityConfig.defaultConfig,
    this.showExpandButton = true,
    this.horizontalSpacing = 8,
    this.verticalSpacing = 8,
    this.fixedHeight,
    this.onExpandChanged,
    super.key,
  });

  /// Primary actions that are always visible (or visible based on width config)
  final List<ActionButtonData> primaryActions;

  /// Secondary actions that are shown when expanded
  final List<ActionButtonData> secondaryActions;

  /// Builder function to create individual action cards
  final Widget Function(BuildContext context, ActionButtonData action)
      actionCardBuilder;

  /// Configuration for determining visible buttons based on width
  final ActionButtonsVisibilityConfig visibilityConfig;

  /// Whether to show the expand button below the buttons
  final bool showExpandButton;

  /// Horizontal spacing between cards
  final double horizontalSpacing;

  /// Vertical spacing between cards
  final double verticalSpacing;

  /// Fixed height for all cards (optional)
  final double? fixedHeight;

  /// Callback when expand state changes (useful for triggering app bar animations)
  final void Function(bool isExpanded)? onExpandChanged;

  @override
  State<CollapsibleActionButtons> createState() =>
      _CollapsibleActionButtonsState();
}

class _CollapsibleActionButtonsState extends State<CollapsibleActionButtons> {
  bool _showAllActions = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = widget.visibilityConfig;

        // Calculate how many buttons fit per row based on screen width
        // Account for horizontal spacing between cards and add buffer to prevent overflow
        int buttonsPerRow = config.maxPerRow;
        double cardWidth = 0;

        // Find the maximum buttonsPerRow that fits without overflow
        // Use minimum card width of ~85px to ensure content fits
        // Add 2px buffer per card to account for rounding and prevent overflow
        const double overflowBuffer = 2.0;
        for (int i = config.maxPerRow; i >= config.minPerRow; i--) {
          final double totalSpacing = widget.horizontalSpacing * (i - 1);
          final double totalBuffer = overflowBuffer * i;
          final double availableWidth =
              constraints.maxWidth - totalSpacing - totalBuffer;
          final double testCardWidth = availableWidth / i;

          // Ensure minimum card width to prevent overflow
          // Use realistic minimum (~100px) to ensure content fits without overflow
          if (testCardWidth >= 100) {
            buttonsPerRow = i;
            cardWidth = testCardWidth;
            break;
          }
        }

        // If no valid width found, use minPerRow
        if (cardWidth == 0) {
          buttonsPerRow = config.minPerRow;
          final double totalSpacing =
              widget.horizontalSpacing * (buttonsPerRow - 1);
          final double totalBuffer = overflowBuffer * buttonsPerRow;
          cardWidth = (constraints.maxWidth - totalSpacing - totalBuffer) /
              buttonsPerRow;
        }

        // Split primary actions into enabled and disabled
        final enabledPrimaryActions =
            widget.primaryActions.where((a) => a.enabled).toList();
        final disabledPrimaryActions =
            widget.primaryActions.where((a) => !a.enabled).toList();

        // Split secondary actions into enabled and disabled
        final enabledSecondaryActions =
            widget.secondaryActions.where((a) => a.enabled).toList();
        final disabledSecondaryActions =
            widget.secondaryActions.where((a) => !a.enabled).toList();

        // Calculate visible actions based on configuration
        final List<ActionButtonData> visiblePrimaryActions;
        final List<ActionButtonData> hiddenPrimaryActions;

        if (config.defaultVisibleCount != null) {
          // Use fixed count if specified
          final visibleCount = config.defaultVisibleCount!
              .clamp(0, enabledPrimaryActions.length);
          visiblePrimaryActions =
              enabledPrimaryActions.take(visibleCount).toList();
          hiddenPrimaryActions =
              enabledPrimaryActions.skip(visibleCount).toList();
        } else {
          // Width-based: show as many primary actions as fit in one row
          // Use buttonsPerRow to determine how many to show
          final totalPrimaryActions = enabledPrimaryActions.length;

          // Show buttonsPerRow number of primary actions (or all if less)
          final int visibleCount = buttonsPerRow.clamp(0, totalPrimaryActions);

          visiblePrimaryActions =
              enabledPrimaryActions.take(visibleCount).toList();
          hiddenPrimaryActions =
              enabledPrimaryActions.skip(visibleCount).toList();
        }

        // Always include disabled primary actions in visible (they're always shown)
        // Combine visible and hidden primary actions based on expand state
        final visibleActions = <ActionButtonData>[
          ...visiblePrimaryActions,
          ...disabledPrimaryActions,
          if (_showAllActions) ...hiddenPrimaryActions,
          if (_showAllActions) ...enabledSecondaryActions,
          if (_showAllActions) ...disabledSecondaryActions,
        ];

        // Determine if expand button should be shown
        final hasHiddenActions = hiddenPrimaryActions.isNotEmpty ||
            widget.secondaryActions.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: visibleActions.isNotEmpty
                  ? FlexList(
                      horizontalSpacing: widget.horizontalSpacing,
                      verticalSpacing: widget.verticalSpacing,
                      children: visibleActions.map((action) {
                        final card = widget.actionCardBuilder(context, action);
                        if (widget.fixedHeight != null) {
                          return SizedBox(
                            width: cardWidth,
                            height: widget.fixedHeight,
                            child: card,
                          );
                        }
                        return SizedBox(
                          width: cardWidth,
                          child: card,
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
            // Expand button (show if there are hidden actions)
            if (widget.showExpandButton && hasHiddenActions) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: _showAllActions ? 16 : 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CompactExpandButton(
                    isExpanded: _showAllActions,
                    onTap: () {
                      setState(() {
                        _showAllActions = !_showAllActions;
                      });
                      widget.onExpandChanged?.call(_showAllActions);
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
