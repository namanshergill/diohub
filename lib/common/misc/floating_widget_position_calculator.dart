import 'package:diohub/common/misc/floating_expandable_widget.dart';
import 'package:flutter/material.dart';

/// Calculates positioning and layout for floating widgets.
///
/// This class encapsulates all positioning logic, making it modular, testable,
/// and extensible. Subclasses can override methods to customize behavior.
///
/// **Usage:**
/// ```dart
/// final calculator = FloatingWidgetPositionCalculator(
///   position: FloatingPosition.bottom,
///   alignment: FloatingAlignment.right,
///   padding: EdgeInsets.all(16),
///   edgePadding: 8.0,
/// );
///
/// final defaultPos = calculator.calculateDefaultPosition(
///   screenSize: Size(400, 800),
///   safeArea: EdgeInsets.zero,
///   viewPadding: EdgeInsets.zero,
/// );
/// ```
class FloatingWidgetPositionCalculator {
  /// Creates a position calculator with the given configuration.
  const FloatingWidgetPositionCalculator({
    required this.position,
    this.alignment,
    required this.padding,
    this.edgePadding = 8.0,
  });

  /// Position of the widget
  final FloatingPosition position;

  /// Horizontal alignment of the widget
  final FloatingAlignment? alignment;

  /// Padding around the widget content
  final EdgeInsets padding;

  /// Minimum padding from screen edges
  final double edgePadding;

  /// Gets the effective alignment (uses defaults if not specified)
  FloatingAlignment getEffectiveAlignment() {
    return alignment ??
        (position == FloatingPosition.top
            ? FloatingAlignment.center
            : FloatingAlignment.right);
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
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final effectiveAlignment = getEffectiveAlignment();

    double? left, right;

    // Calculate horizontal position
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        left = padding.left + safeArea.left + edgePadding;
        break;
      case FloatingAlignment.right:
        right = safeArea.right + edgePadding;
        break;
      case FloatingAlignment.center:
        // Don't set left/right - let Align widget handle centering
        break;
    }

    // Calculate vertical position
    double? top, bottom;
    switch (position) {
      case FloatingPosition.top:
        top = padding.top + safeArea.top + edgePadding;
        break;
      case FloatingPosition.bottom:
        // Use max of safeArea.bottom and viewPadding.bottom to account for system UI
        final bottomInset =
            safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
        bottom = bottomInset + edgePadding;
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
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    double initialX;
    double initialY;

    final widgetWidth = widgetSize.width;
    final widgetHeight = widgetSize.height;

    final effectiveAlignment = getEffectiveAlignment();

    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        initialX = padding.left + safeArea.left + widgetWidth / 2;
        break;
      case FloatingAlignment.right:
        // Position at right edge - account for SafeArea and edge padding
        initialX =
            screenSize.width - safeArea.right - edgePadding - widgetWidth / 2;
        break;
      case FloatingAlignment.center:
        initialX = screenSize.width / 2;
        break;
    }

    switch (position) {
      case FloatingPosition.top:
        initialY = padding.top + safeArea.top + widgetHeight / 2;
        break;
      case FloatingPosition.bottom:
        // Position at bottom edge - use max of safeArea.bottom and viewPadding.bottom
        final bottomInset =
            safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
        initialY =
            screenSize.height - bottomInset - edgePadding - widgetHeight / 2;
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
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final widgetWidth = widgetSize.width;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    // Calculate left position from center point
    var left = currentCenterPosition.dx - widgetWidth / 2;

    // Clamp to ensure widget stays on screen with edge padding
    // Account for SafeArea on both sides
    final minLeft = safeArea.left + edgePadding;
    final maxLeft =
        screenSize.width - safeArea.right - widgetWidth - edgePadding;

    // Ensure maxLeft is valid (widget might be wider than screen)
    if (maxLeft < minLeft) {
      // Widget is too wide, center it
      left = (screenSize.width - widgetWidth) / 2;
    } else {
      left = left.clamp(minLeft, maxLeft);
    }

    // Calculate top position from center point
    final calculatedTop = currentCenterPosition.dy - effectiveHeight / 2;
    final minTop = safeArea.top + edgePadding;
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    final maxTop =
        screenSize.height - bottomInset - effectiveHeight - edgePadding;
    final top = calculatedTop.clamp(minTop, maxTop);

    return (left: left, top: top, right: null, bottom: null);
  }

  /// Calculates the snap position to the nearest edge.
  ///
  /// Returns the center point (Offset) where the widget should snap to.
  Offset calculateSnapPosition({
    required Offset currentCenterPosition,
    required MediaQueryData mediaQuery,
    required Size widgetSize,
    required bool isExpanded,
  }) {
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final widgetWidth = widgetSize.width;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    // Determine which edge to snap to (top or bottom)
    final currentY = currentCenterPosition.dy;
    final distanceToTop = currentY - safeArea.top - effectiveHeight / 2;
    final distanceToBottom =
        screenSize.height - safeArea.bottom - currentY - effectiveHeight / 2;
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
          targetX =
              widgetWidth / 2 + padding.left + safeArea.left + edgePadding;
          break;
        case FloatingAlignment.right:
          // Position at right edge - account for SafeArea and edge padding
          // targetX is the center X coordinate, so we need widgetWidth/2 from the right edge
          targetX =
              screenSize.width - safeArea.right - edgePadding - widgetWidth / 2;
          break;
        case FloatingAlignment.center:
          targetX = screenSize.width / 2;
          break;
      }
    }

    // Ensure targetX keeps widget on screen
    final minX = widgetWidth / 2 + safeArea.left + edgePadding;
    final maxX =
        screenSize.width - widgetWidth / 2 - safeArea.right - edgePadding;

    if (maxX < minX) {
      // Widget is too wide, center it
      targetX = screenSize.width / 2;
    } else {
      targetX = targetX.clamp(minX, maxX);
    }

    double targetY;

    if (snappingToTop) {
      targetY = safeArea.top + edgePadding + effectiveHeight / 2;
    } else {
      // Calculate bottom position more carefully to prevent clipping
      // Use max of safeArea.bottom and viewPadding.bottom to account for system UI
      final bottomInset =
          safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
      final bottomEdge = screenSize.height - bottomInset;
      targetY = bottomEdge - edgePadding - effectiveHeight / 2;
    }

    // Ensure targetY keeps widget on screen
    final minY = safeArea.top + edgePadding + effectiveHeight / 2;
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    final maxY =
        screenSize.height - bottomInset - edgePadding - effectiveHeight / 2;
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
  Offset calculateExpandedCenterPosition({
    required MediaQueryData mediaQuery,
  }) {
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final centerX = screenSize.width / 2;
    // Use safeArea for top, but for bottom use max of safeArea.bottom and viewPadding.bottom
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    final availableHeight = screenSize.height - safeArea.top - bottomInset;
    final centerY = safeArea.top + availableHeight / 2;
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
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );

    final distanceToTopEdge =
        currentCenterPosition.dy - safeArea.top - effectiveHeight / 2;
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    final distanceToBottomEdge = screenSize.height -
        bottomInset -
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
    final safeArea = mediaQuery.padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
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
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final effectiveHeight = calculateEffectiveHeight(
      widgetSize: widgetSize,
      isExpanded: isExpanded,
    );
    final widgetWidth = widgetSize.width;

    final minX = widgetWidth / 2 + edgePadding;
    final maxX = screenSize.width - widgetWidth / 2 - edgePadding;
    final clampedX = position.dx.clamp(minX, maxX);

    final minY = safeArea.top + effectiveHeight / 2 + edgePadding;
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    final maxY =
        screenSize.height - bottomInset - effectiveHeight / 2 - edgePadding;
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
    final safeArea = mediaQuery.padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    return safeArea.top + availableHeight / 2;
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
    final safeArea = mediaQuery.padding;
    if (position != FloatingPosition.top) {
      return 0.0;
    }
    // Content padding + safe area + edge padding
    return padding.top + safeArea.top + edgePadding;
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
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    if (position != FloatingPosition.bottom) {
      return 0.0;
    }
    // Use max of safeArea.bottom and viewPadding.bottom to account for system UI
    final bottomInset =
        safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
    return bottomInset + edgePadding;
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
    final safeArea = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    double? finalLeft = position.left;
    double? finalTop = position.top;
    double? finalRight = position.right;
    double? finalBottom = position.bottom;

    if (widgetSize != null) {
      if (finalLeft != null) {
        // Verify left positioning doesn't go off-screen
        final widgetWidth = widgetSize.width;
        final maxLeft =
            screenSize.width - safeArea.right - widgetWidth - edgePadding;
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
        final bottomInset =
            safeArea.bottom > 0 ? safeArea.bottom : viewPadding.bottom;
        final maxTop =
            screenSize.height - bottomInset - effectiveHeight - edgePadding;
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
