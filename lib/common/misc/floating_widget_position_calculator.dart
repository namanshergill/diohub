import 'package:diohub/common/misc/floating_expandable_widget.dart';
import 'package:flutter/material.dart';

/// Behavior type for floating widget positioning.
enum FloatingWidgetBehavior {
  /// Widget snaps to edges when drag ends
  snapToEdges,

  /// Widget can be freely dragged without snapping
  freeDrag,

  /// Custom behavior (uses provided calculator methods)
  custom,
}

/// Calculates positioning and layout for floating widgets.
///
/// This class encapsulates all positioning logic, making it modular, testable,
/// and extensible. Subclasses can override methods to customize behavior.
///
/// **Usage:**
/// ```dart
/// // Default behavior (snaps to edges)
/// final calculator = FloatingWidgetPositionCalculator(
///   position: FloatingPosition.bottom,
///   alignment: FloatingAlignment.right,
/// );
///
/// // Free drag behavior
/// final calculator = FloatingWidgetPositionCalculator(
///   position: FloatingPosition.bottom,
///   behavior: FloatingWidgetBehavior.freeDrag,
/// );
///
/// // Custom initial position
/// final calculator = FloatingWidgetPositionCalculator(
///   position: FloatingPosition.bottom,
///   initialPosition: Offset(100, 200),
/// );
/// ```
class FloatingWidgetPositionCalculator {
  /// Creates a position calculator with the given configuration.
  const FloatingWidgetPositionCalculator({
    required this.position,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.edgePadding = 8.0,
    this.bottomPadding = 0.0,
    this.initialPosition,
    this.behavior = FloatingWidgetBehavior.snapToEdges,
  });

  /// Position of the widget
  final FloatingPosition position;

  /// Horizontal alignment of the widget
  final FloatingAlignment? alignment;

  /// Padding around the widget content
  final EdgeInsets padding;

  /// Minimum padding from screen edges
  final double edgePadding;

  /// Additional bottom padding to account for app-level UI elements (e.g., tab bars)
  /// This is added on top of system UI padding (viewPadding.bottom)
  final double bottomPadding;

  /// Custom initial position (center point). If null, uses default position calculation.
  final Offset? initialPosition;

  /// Behavior type for this calculator
  final FloatingWidgetBehavior behavior;

  /// Gets the effective alignment (uses defaults if not specified)
  FloatingAlignment getEffectiveAlignment() {
    return alignment ??
        (position == FloatingPosition.top
            ? FloatingAlignment.center
            : FloatingAlignment.right);
  }

  /// Gets the bottom inset value (max of safeArea.bottom and viewPadding.bottom).
  ///
  /// This is a shared helper method used consistently across all calculations.
  double getBottomInset(MediaQueryData mediaQuery) {
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    return safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
  }

  /// Gets the top inset value (safeArea.top).
  ///
  /// This is a shared helper method used consistently across all calculations.
  double getTopInset(MediaQueryData mediaQuery) {
    return mediaQuery.padding.top;
  }

  /// Gets the left inset value (safeArea.left).
  double getLeftInset(MediaQueryData mediaQuery) {
    return mediaQuery.padding.left;
  }

  /// Gets the right inset value (safeArea.right).
  double getRightInset(MediaQueryData mediaQuery) {
    return mediaQuery.padding.right;
  }

  /// Calculates the effective bottom edge position.
  ///
  /// Returns the Y coordinate of the effective bottom edge, accounting for:
  /// - System UI (bottom inset)
  /// - App-level UI (bottomPadding)
  /// - Edge padding
  double getEffectiveBottomEdge(MediaQueryData mediaQuery) {
    final screenSize = mediaQuery.size;
    final bottomInset = getBottomInset(mediaQuery);
    return screenSize.height - bottomInset - bottomPadding;
  }

  /// Calculates the effective top edge position.
  ///
  /// Returns the Y coordinate of the effective top edge, accounting for:
  /// - System UI (top inset)
  /// - Edge padding
  double getEffectiveTopEdge(MediaQueryData mediaQuery) {
    return getTopInset(mediaQuery);
  }

  /// Calculates the default position when widget is not being dragged.
  ///
  /// Returns a record with left, top, right, bottom values (some may be null).
  ({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) calculateDefaultPosition({
    required MediaQueryData mediaQuery,
    required Size widgetSize,
  }) {
    // If custom initial position is provided, convert it to position record
    if (initialPosition != null) {
      return _offsetToPositionRecord(
        offset: initialPosition!,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
      );
    }

    final effectiveAlignment = getEffectiveAlignment();

    double? left, right;

    // Calculate horizontal position
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        left = padding.left + getLeftInset(mediaQuery) + edgePadding;
        break;
      case FloatingAlignment.right:
        right = getRightInset(mediaQuery) + edgePadding;
        break;
      case FloatingAlignment.center:
        // Don't set left/right - let Align widget handle centering
        break;
    }

    // Calculate vertical position
    double? top, bottom;
    switch (position) {
      case FloatingPosition.top:
        top = padding.top + getTopInset(mediaQuery) + edgePadding;
        break;
      case FloatingPosition.bottom:
        final bottomInset = getBottomInset(mediaQuery);
        bottom = bottomInset + edgePadding;
        break;
    }

    return (left: left, top: top, right: right, bottom: bottom);
  }

  /// Converts an Offset (center point) to a position record.
  ({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) _offsetToPositionRecord({
    required Offset offset,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
  }) {
    final effectiveAlignment = getEffectiveAlignment();
    double? left, right, top, bottom;

    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        left = offset.dx - widgetSize.width / 2;
        break;
      case FloatingAlignment.right:
        right = mediaQuery.size.width - offset.dx - widgetSize.width / 2;
        break;
      case FloatingAlignment.center:
        // Center alignment - don't set left/right
        break;
    }

    switch (position) {
      case FloatingPosition.top:
        top = offset.dy - widgetSize.height / 2;
        break;
      case FloatingPosition.bottom:
        bottom = mediaQuery.size.height - offset.dy - widgetSize.height / 2;
        break;
    }

    return (left: left, top: top, right: right, bottom: bottom);
  }

  /// Calculates the initial position when drag starts.
  ///
  /// Returns the center point (Offset) of the widget.
  Offset calculateInitialDragPosition({
    required MediaQueryData mediaQuery,
    required Size widgetSize,
  }) {
    // If custom initial position is provided, use it
    if (initialPosition != null) {
      return initialPosition!;
    }

    final screenSize = mediaQuery.size;
    double initialX;
    double initialY;

    final widgetWidth = widgetSize.width;
    final widgetHeight = widgetSize.height;

    final effectiveAlignment = getEffectiveAlignment();

    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        initialX = padding.left + getLeftInset(mediaQuery) + widgetWidth / 2;
        break;
      case FloatingAlignment.right:
        initialX = screenSize.width -
            getRightInset(mediaQuery) -
            edgePadding -
            widgetWidth / 2;
        break;
      case FloatingAlignment.center:
        initialX = screenSize.width / 2;
        break;
    }

    switch (position) {
      case FloatingPosition.top:
        initialY = padding.top + getTopInset(mediaQuery) + widgetHeight / 2;
        break;
      case FloatingPosition.bottom:
        initialY =
            getEffectiveBottomEdge(mediaQuery) - edgePadding - widgetHeight / 2;
        break;
    }

    return Offset(initialX, initialY);
  }

  /// Calculates the position when widget is being dragged.
  ///
  /// Returns a record with left, top, right, bottom values (some may be null).
  ({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) calculateDraggedPosition({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
  }) {
    final screenSize = mediaQuery.size;
    final widgetWidth = widgetSize.width;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    // Calculate left position from center point
    var left = currentCenterPosition.dx - widgetWidth / 2;

    // Clamp to ensure widget stays on screen with edge padding
    final minLeft = getLeftInset(mediaQuery) + edgePadding;
    final maxLeft = screenSize.width -
        getRightInset(mediaQuery) -
        widgetWidth -
        edgePadding;

    // Ensure maxLeft is valid (widget might be wider than screen)
    if (maxLeft < minLeft) {
      // Widget is too wide, center it
      left = (screenSize.width - widgetWidth) / 2;
    } else {
      left = left.clamp(minLeft, maxLeft);
    }

    // Calculate top position from center point
    final calculatedTop = currentCenterPosition.dy - effectiveHeight / 2;
    final minTop = getTopInset(mediaQuery) + edgePadding;
    final maxTop =
        getEffectiveBottomEdge(mediaQuery) - effectiveHeight - edgePadding;
    final top = calculatedTop.clamp(minTop, maxTop);

    return (left: left, top: top, right: null, bottom: null);
  }

  /// Calculates the snap position to the nearest edge.
  ///
  /// Returns the center point (Offset) where the widget should snap to.
  /// Returns null if behavior is freeDrag (no snapping).
  Offset? calculateSnapPosition({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
  }) {
    // Don't snap if behavior is freeDrag
    if (behavior == FloatingWidgetBehavior.freeDrag) {
      return null;
    }

    final screenSize = mediaQuery.size;
    final widgetWidth = widgetSize.width;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    // Determine which edge to snap to (top or bottom)
    // Calculate distances from widget's CENTER to screen edges (not from widget's top/bottom)
    final currentY = currentCenterPosition.dy;
    final topEdgeY = getTopInset(mediaQuery) + edgePadding;
    final bottomEdgeY = getEffectiveBottomEdge(mediaQuery) - edgePadding;
    final distanceToTop = currentY - topEdgeY;
    final distanceToBottom = bottomEdgeY - currentY;
    final snappingToTop = distanceToTop < distanceToBottom;

    double targetX;
    // When snapping to top, always center horizontally
    // When snapping to bottom, use the configured alignment
    if (snappingToTop) {
      targetX = screenSize.width / 2;
    } else {
      final effectiveAlignment = getEffectiveAlignment();

      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          targetX = widgetWidth / 2 +
              padding.left +
              getLeftInset(mediaQuery) +
              edgePadding;
          break;
        case FloatingAlignment.right:
          targetX = screenSize.width -
              getRightInset(mediaQuery) -
              edgePadding -
              widgetWidth / 2;
          break;
        case FloatingAlignment.center:
          targetX = screenSize.width / 2;
          break;
      }
    }

    // Ensure targetX keeps widget on screen
    final minX = widgetWidth / 2 + getLeftInset(mediaQuery) + edgePadding;
    final maxX = screenSize.width -
        widgetWidth / 2 -
        getRightInset(mediaQuery) -
        edgePadding;

    if (maxX < minX) {
      // Widget is too wide, center it
      targetX = screenSize.width / 2;
    } else {
      targetX = targetX.clamp(minX, maxX);
    }

    double targetY;

    if (snappingToTop) {
      targetY = getTopInset(mediaQuery) + edgePadding + effectiveHeight / 2;
    } else {
      final bottomEdge = getEffectiveBottomEdge(mediaQuery);
      targetY = bottomEdge - edgePadding - effectiveHeight / 2;
    }

    // Ensure targetY keeps widget on screen
    final minY = getTopInset(mediaQuery) + edgePadding + effectiveHeight / 2;
    final maxY =
        getEffectiveBottomEdge(mediaQuery) - edgePadding - effectiveHeight / 2;
    targetY = targetY.clamp(minY, maxY);

    return Offset(targetX, targetY);
  }

  /// Calculates the effective height of the widget.
  ///
  /// Handles cases where widget was measured while expanded but is now collapsed.
  double calculateEffectiveHeight({
    required Size widgetSize,
    required bool isExpanded,
  }) {
    if (!isExpanded && widgetSize.height > 200) {
      return 100.0; // Widget was measured while expanded, but is now collapsed
    }
    return widgetSize.height;
  }

  /// Calculates the center position when widget expands.
  ///
  /// Returns the center point (Offset) where the widget should be positioned.
  /// The center is calculated from the expanded widget's center, not from its top.
  Offset calculateExpandedCenterPosition({
    required MediaQueryData mediaQuery,
    required Size expandedWidgetSize,
  }) {
    final screenSize = mediaQuery.size;
    final centerX = screenSize.width / 2;

    // Calculate available height for centering
    final availableHeight = screenSize.height -
        getTopInset(mediaQuery) -
        getBottomInset(mediaQuery) -
        bottomPadding;

    // Center Y should position the expanded widget's center at the screen center
    // This ensures the expanded widget is visually centered, not positioned from its top
    final centerY = getTopInset(mediaQuery) + availableHeight / 2;

    return Offset(centerX, centerY);
  }

  /// Calculates distances to edges for auto-expand/collapse logic.
  ///
  /// Returns a record with distances and whether widget is near top.
  ({
    double distanceToTopEdge,
    double distanceToBottomEdge,
    double distanceToNearestEdge,
    bool isNearTop,
  }) calculateEdgeDistances({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
  }) {
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    final distanceToTopEdge = currentCenterPosition.dy -
        getTopInset(mediaQuery) -
        effectiveHeight / 2;
    final distanceToBottomEdge = getEffectiveBottomEdge(mediaQuery) -
        currentCenterPosition.dy -
        effectiveHeight / 2;
    final distanceToNearestEdge = distanceToTopEdge < distanceToBottomEdge
        ? distanceToTopEdge
        : distanceToBottomEdge;
    final isNearTop = distanceToTopEdge < distanceToBottomEdge;

    return (
      distanceToTopEdge: distanceToTopEdge,
      distanceToBottomEdge: distanceToBottomEdge,
      distanceToNearestEdge: distanceToNearestEdge,
      isNearTop: isNearTop,
    );
  }

  /// Calculates the edge threshold distance for auto-expand/collapse.
  ///
  /// Returns the distance threshold based on available screen height.
  double calculateEdgeThreshold({
    required MediaQueryData mediaQuery,
    double thresholdPercent = 0.15,
  }) {
    final screenSize = mediaQuery.size;
    final topInset = getTopInset(mediaQuery);
    final bottomInset = getBottomInset(mediaQuery);
    final availableHeight = screenSize.height - topInset - bottomInset;
    return availableHeight * thresholdPercent;
  }

  /// Determines if widget should auto-expand based on position.
  ///
  /// Returns true if widget should expand, false otherwise.
  bool shouldAutoExpand({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
    double thresholdPercent = 0.15,
  }) {
    if (isExpanded) return false;

    final edgeDistances = calculateEdgeDistances(
      currentCenterPosition: currentCenterPosition,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    final threshold = calculateEdgeThreshold(
      mediaQuery: mediaQuery,
      thresholdPercent: thresholdPercent,
    );

    return edgeDistances.distanceToNearestEdge > threshold;
  }

  /// Determines if widget should auto-collapse based on position.
  ///
  /// Returns true if widget should collapse, false otherwise.
  bool shouldAutoCollapse({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
    double thresholdPercent = 0.15,
  }) {
    if (!isExpanded) return false;

    final edgeDistances = calculateEdgeDistances(
      currentCenterPosition: currentCenterPosition,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    final threshold = calculateEdgeThreshold(
      mediaQuery: mediaQuery,
      thresholdPercent: thresholdPercent,
    );

    return edgeDistances.distanceToNearestEdge <= threshold;
  }

  /// Clamps a position to ensure widget stays on screen.
  ///
  /// Returns the clamped center position.
  Offset clampPosition({
    required Offset position,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
  }) {
    final screenSize = mediaQuery.size;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );
    final widgetWidth = widgetSize.width;

    final minX = widgetWidth / 2 + edgePadding;
    final maxX = screenSize.width - widgetWidth / 2 - edgePadding;
    final clampedX = position.dx.clamp(minX, maxX);

    final minY = getTopInset(mediaQuery) + effectiveHeight / 2 + edgePadding;
    final maxY =
        getEffectiveBottomEdge(mediaQuery) - effectiveHeight / 2 - edgePadding;
    final clampedY = position.dy.clamp(minY, maxY);

    return Offset(clampedX, clampedY);
  }

  /// Calculates the center Y coordinate of the screen's available area.
  ///
  /// The center Y is calculated as:
  /// - [safeArea.top]: Top safe area insets (status bar, notch, etc.)
  /// - [availableHeight / 2]: Half of the available height between top and bottom safe areas
  ///
  /// This represents the vertical center point where widgets typically expand to.
  double calculateScreenCenterY({
    required MediaQueryData mediaQuery,
  }) {
    final screenSize = mediaQuery.size;
    final topInset = getTopInset(mediaQuery);
    final bottomInset = getBottomInset(mediaQuery);
    final availableHeight = screenSize.height - topInset - bottomInset;
    return topInset + availableHeight / 2;
  }

  /// Determines if a position is near the top of the screen.
  ///
  /// Compares the Y coordinate against the screen's center line:
  /// - If [currentCenterPosition] is null, returns true if widget's default position is top
  /// - Otherwise compares Y coordinate to [calculateScreenCenterY]
  ///
  /// Returns true if the position is above the center line (near top).
  bool isPositionNearTop({
    required Offset? currentCenterPosition,
    required MediaQueryData mediaQuery,
  }) {
    if (currentCenterPosition == null) {
      return position == FloatingPosition.top;
    }
    final centerY = calculateScreenCenterY(mediaQuery: mediaQuery);
    return currentCenterPosition.dy < centerY;
  }

  /// Determines which position (top or bottom) the widget is near.
  ///
  /// Returns FloatingPosition.top or FloatingPosition.bottom.
  FloatingPosition determineNearPosition({
    required Offset? currentCenterPosition,
    required MediaQueryData mediaQuery,
    bool? expandedFromTop,
  }) {
    if (currentCenterPosition == null) {
      return position;
    }

    if (expandedFromTop != null) {
      return expandedFromTop ? FloatingPosition.top : FloatingPosition.bottom;
    }

    final isNearTop = isPositionNearTop(
      currentCenterPosition: currentCenterPosition,
      mediaQuery: mediaQuery,
    );

    return isNearTop ? FloatingPosition.top : FloatingPosition.bottom;
  }

  /// Calculates the top padding for center-aligned widgets positioned at the top.
  ///
  /// The padding consists of:
  /// - [padding.top]: Content padding from widget configuration
  /// - [safeArea.top]: Safe area insets (status bar, notch, etc.)
  /// - [edgePadding]: Minimum padding from screen edges
  ///
  /// Returns 0 if widget is not positioned at the top.
  double calculateTopPaddingForCenterAlignment({
    required MediaQueryData mediaQuery,
  }) {
    if (position != FloatingPosition.top) {
      return 0.0;
    }
    // Content padding + safe area + edge padding
    return padding.top + getTopInset(mediaQuery) + edgePadding;
  }

  /// Calculates the bottom padding for center-aligned widgets positioned at the bottom.
  ///
  /// The padding consists of:
  /// - [viewPadding.bottom]: View padding (includes navigation bar, system UI)
  /// - [edgePadding]: Minimum padding from screen edges
  ///
  /// Returns 0 if widget is not positioned at the bottom.
  double calculateBottomPaddingForCenterAlignment({
    required MediaQueryData mediaQuery,
  }) {
    if (position != FloatingPosition.bottom) {
      return 0.0;
    }
    final bottomInset = getBottomInset(mediaQuery);
    return bottomInset + bottomPadding + edgePadding;
  }

  /// Validates and adjusts position values to ensure widget fits on screen.
  ///
  /// Returns adjusted position values.
  ({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) validatePosition({
    required ({
      double? left,
      double? top,
      double? right,
      double? bottom,
    }) position,
    required MediaQueryData mediaQuery,
    Size? widgetSize,
    required bool isExpanded,
  }) {
    final screenSize = mediaQuery.size;
    double? finalLeft = position.left;
    double? finalTop = position.top;
    double? finalRight = position.right;
    double? finalBottom = position.bottom;

    if (widgetSize != null) {
      if (finalLeft != null) {
        // Verify left positioning doesn't go off-screen
        final widgetWidth = widgetSize.width;
        final maxLeft = screenSize.width -
            getRightInset(mediaQuery) -
            widgetWidth -
            edgePadding;
        if (finalLeft > maxLeft) {
          finalLeft = maxLeft;
        }
      }

      if (finalTop != null) {
        // Verify top positioning doesn't go off-screen
        final effectiveHeight = calculateEffectiveHeight(
          widgetSize: widgetSize,
          isExpanded: isExpanded,
        );
        final maxTop =
            getEffectiveBottomEdge(mediaQuery) - effectiveHeight - edgePadding;
        if (finalTop > maxTop) {
          finalTop = maxTop;
        }
      }
    }

    return (
      left: finalLeft,
      top: finalTop,
      right: finalRight,
      bottom: finalBottom,
    );
  }
}
