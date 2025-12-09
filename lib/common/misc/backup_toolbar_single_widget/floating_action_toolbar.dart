import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_action_toolbar_content.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart';
import 'package:flutter/material.dart';

// Export enums for convenience
export 'package:diohub/common/misc/floating_expandable_widget.dart'
    show FloatingPosition, FloatingAlignment;

/// A floating toolbar widget with liquid glass effect and expand/collapse functionality.
///
/// Displays action buttons in a horizontal scrollable layout that floats above content.
/// Features a frosted glass background with blur effect and smooth expand/collapse animations.
///
/// **Usage:**
/// ```dart
/// Stack(
///   children: [
///     // Your content here
///     FloatingActionToolbar(
///       actions: [
///         ActionButtonData(
///           icon: Icons.code,
///           label: 'Code',
///           onTap: () {},
///         ),
///         // ... more actions
///       ],
///       actionCardBuilder: buildStandardActionCard,
///       defaultVisibleCount: 3,
///       position: FloatingPosition.bottom,
///     ),
///   ],
/// )
/// ```
class FloatingActionToolbar extends StatefulWidget {
  const FloatingActionToolbar({
    required this.actions,
    required this.actionCardBuilder,
    this.defaultVisibleCount = 3,
    this.expandedVisibleCount,
    this.onExpandChanged,
    this.onCollapseRequested,
    this.position = FloatingPosition.bottom,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.spacing = 8,
    this.maxHeight,
    this.prominentActions,
    this.prominentActionBuilder,
    this.bottomPadding = 0.0,
    this.title,
    super.key,
  });

  /// All actions to display in the toolbar
  final List<ActionButtonData> actions;

  /// Builder function to create individual action cards
  final Widget Function(BuildContext context, ActionButtonData action)
      actionCardBuilder;

  /// Prominent actions (like "Comment") that appear as expanded tiles
  final List<ActionButtonData>? prominentActions;

  /// Builder for prominent action cards (uses buildProminentActionCard by default)
  final Widget Function(BuildContext context, ActionButtonData action)?
      prominentActionBuilder;

  /// Number of actions visible when collapsed (default: 3)
  final int defaultVisibleCount;

  /// Number of actions visible when expanded (if null, shows all)
  final int? expandedVisibleCount;

  /// Callback when expand state changes
  final void Function(bool isExpanded)? onExpandChanged;

  /// Callback to collapse the toolbar (called after action tap by default)
  /// If null, defaults to collapsing the toolbar when an action is tapped
  final VoidCallback? onCollapseRequested;

  /// Position of the toolbar
  final FloatingPosition position;

  /// Horizontal alignment of the toolbar
  /// If null, defaults to center for top position, right for bottom position
  final FloatingAlignment? alignment;

  /// Padding around the toolbar content
  final EdgeInsets padding;

  /// Spacing between action buttons
  final double spacing;

  /// Maximum height of the toolbar when expanded
  final double? maxHeight;

  /// Additional bottom padding to account for app-level UI elements (e.g., tab bars)
  /// This is added on top of system UI padding (viewPadding.bottom)
  final double bottomPadding;

  /// Title to display in expanded view (e.g., username on home, repo name on repo screen)
  final String? title;

  @override
  State<FloatingActionToolbar> createState() => _FloatingActionToolbarState();
}

class _FloatingActionToolbarState extends State<FloatingActionToolbar>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final GlobalKey _toolbarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onExpandChanged(bool isExpanded) {
    setState(() {
      _isExpanded = isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onExpandChanged?.call(isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.bottom
            ? FloatingAlignment.right
            : null);

    print(
        '[FloatingActionToolbar] build: position=${widget.position}, alignment=${widget.alignment}, effectiveAlignment=$effectiveAlignment');

    return FloatingExpandableWidget(
      contentBuilder: (context, callbacks) {
        // Sync local state with callbacks
        if (_isExpanded != callbacks.isExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _onExpandChanged(callbacks.isExpanded);
            }
          });
        }
        return buildToolbarContent(
          context: context,
          callbacks: callbacks,
          actions: widget.actions,
          prominentActions: widget.prominentActions,
          defaultVisibleCount: widget.defaultVisibleCount,
          expandedVisibleCount: widget.expandedVisibleCount,
          spacing: widget.spacing,
          maxHeight: widget.maxHeight,
          position: widget.position,
          onCollapseRequested: widget.onCollapseRequested,
          prominentActionBuilder: widget.prominentActionBuilder,
          expandAnimation: _expandAnimation,
          toolbarKey: _toolbarKey,
          title: widget.title,
        );
      },
      position: widget.position,
      alignment: effectiveAlignment,
      padding: widget.padding,
      bottomPadding: widget.bottomPadding,
      onExpandChanged: _onExpandChanged,
    );
  }
}
