import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Configuration for determining how many detail tiles should be visible
/// based on available width.
class DetailTilesVisibilityConfig {
  const DetailTilesVisibilityConfig({
    this.minVisibleTiles = 2,
    this.maxVisibleTiles,
    this.tileWidth = 200,
    this.useWidthBasedVisibility = false,
    this.defaultVisibleCount,
    this.minVisiblePerRow,
  });

  /// Minimum number of tiles to always show (regardless of width)
  /// Used when useWidthBasedVisibility is true
  final int minVisibleTiles;

  /// Maximum number of tiles to show before collapsing (null = no limit)
  final int? maxVisibleTiles;

  /// Estimated width per tile (used to calculate how many fit)
  final double tileWidth;

  /// Whether to use width-based visibility calculation
  /// If false, all alwaysVisibleTiles are shown (or defaultVisibleCount if set)
  final bool useWidthBasedVisibility;

  /// Number of alwaysVisibleTiles visible by default (when not using width-based)
  /// If null, all alwaysVisibleTiles are shown
  final int? defaultVisibleCount;

  /// Minimum number of tiles to show per row when using width-based visibility
  /// If null, uses minVisibleTiles
  final int? minVisiblePerRow;

  /// Default configuration: Show all alwaysVisibleTiles, no width-based logic
  static const DetailTilesVisibilityConfig defaultConfig =
      DetailTilesVisibilityConfig(
    minVisibleTiles: 2,
    maxVisibleTiles: null,
    tileWidth: 200,
    useWidthBasedVisibility: false,
    defaultVisibleCount: null,
    minVisiblePerRow: null,
  );

  /// Configuration that uses width-based visibility
  static DetailTilesVisibilityConfig widthBased({
    int minVisibleTiles = 2,
    int? maxVisibleTiles,
    double tileWidth = 200,
    int? minVisiblePerRow,
  }) =>
      DetailTilesVisibilityConfig(
        minVisibleTiles: minVisibleTiles,
        maxVisibleTiles: maxVisibleTiles,
        tileWidth: tileWidth,
        useWidthBasedVisibility: true,
        defaultVisibleCount: null,
        minVisiblePerRow: minVisiblePerRow,
      );

  /// Configuration with fixed visible count
  static DetailTilesVisibilityConfig fixedCount({
    required int defaultVisibleCount,
    int minVisibleTiles = 2,
    int? maxVisibleTiles,
    double tileWidth = 200,
  }) =>
      DetailTilesVisibilityConfig(
        minVisibleTiles: minVisibleTiles,
        maxVisibleTiles: maxVisibleTiles,
        tileWidth: tileWidth,
        useWidthBasedVisibility: false,
        defaultVisibleCount: defaultVisibleCount,
        minVisiblePerRow: null,
      );
}

/// A reusable widget that displays detail tiles with expand/collapse functionality.
///
/// Automatically handles the expand/collapse state and animation.
/// Shows an expand button when there are expandable tiles.
class CollapsibleDetailTiles extends StatefulWidget {
  const CollapsibleDetailTiles({
    required this.alwaysVisibleTiles,
    required this.expandableTiles,
    this.visibilityConfig = DetailTilesVisibilityConfig.defaultConfig,
    this.onExpandChanged,
    super.key,
  });

  /// Tiles that are always visible (essential information)
  final List<Widget> alwaysVisibleTiles;

  /// Tiles that can be expanded/collapsed (less relevant information)
  final List<Widget> expandableTiles;

  /// Configuration for determining visible tiles based on width
  final DetailTilesVisibilityConfig visibilityConfig;

  /// Callback when expand state changes (useful for triggering app bar animations)
  final void Function(bool isExpanded)? onExpandChanged;

  @override
  State<CollapsibleDetailTiles> createState() => _CollapsibleDetailTilesState();
}

class _CollapsibleDetailTilesState extends State<CollapsibleDetailTiles> {
  bool _showAllTiles = false;

  @override
  Widget build(BuildContext context) {
    final allTiles = [...widget.alwaysVisibleTiles, ...widget.expandableTiles];

    if (allTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine visible tiles based on configuration
        final List<Widget> visibleTiles;
        if (_showAllTiles) {
          visibleTiles = allTiles;
        } else if (widget.visibilityConfig.useWidthBasedVisibility) {
          // Use width-based visibility calculation
          visibleTiles = _calculateVisibleTiles(constraints);
        } else if (widget.visibilityConfig.defaultVisibleCount != null) {
          // Use fixed count if specified
          final visibleCount = widget.visibilityConfig.defaultVisibleCount!
              .clamp(0, widget.alwaysVisibleTiles.length);
          visibleTiles = widget.alwaysVisibleTiles.take(visibleCount).toList();
        } else {
          // Default: show all alwaysVisibleTiles
          visibleTiles = widget.alwaysVisibleTiles;
        }

        // Calculate if there are hidden alwaysVisibleTiles
        final bool hasHiddenAlwaysVisible = widget.visibilityConfig.useWidthBasedVisibility
            ? visibleTiles.length < widget.alwaysVisibleTiles.length
            : widget.visibilityConfig.defaultVisibleCount != null
                ? visibleTiles.length < widget.alwaysVisibleTiles.length
                : false;

        return HighlightedContainer(
          highlightColor: context.colorScheme.primary.withOpacity(0.4),
          borderSide: BorderSideType.bottom,
          borderWidth: 2.0,
          borderRadius: 12.0,
          child: Card(
          color: Color.lerp(
            context.colorScheme.surfaceContainer,
            Colors.black,
            0.1,
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                // Visible tiles
                ...visibleTiles.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Widget tile = entry.value;
                    final bool isLastTile = index == visibleTiles.length - 1;
                    // Never show divider after the last tile
                  return Column(
                    children: [
                      tile,
                        if (!isLastTile)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 12,
                          endIndent: 12,
                          color: context.colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                    ],
                  );
                }).toList(),
                // Expand button (only show if there are expandable tiles or hidden alwaysVisibleTiles)
                  if (widget.expandableTiles.isNotEmpty || hasHiddenAlwaysVisible) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Color.lerp(
                          context.colorScheme.surfaceContainer,
                          Colors.black,
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAllTiles = !_showAllTiles;
                            });
                            widget.onExpandChanged?.call(_showAllTiles);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: _showAllTiles ? 0.5 : 0,
                              child: Icon(
                                Icons.expand_more_rounded,
                                size: 14,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculates how many tiles should be visible based on available width
  List<Widget> _calculateVisibleTiles(BoxConstraints constraints) {
    final config = widget.visibilityConfig;
    final allAlwaysVisible = widget.alwaysVisibleTiles;
    
    if (allAlwaysVisible.isEmpty) {
      return [];
    }

    // Use minVisiblePerRow if specified, otherwise use minVisibleTiles
    final minPerRow = config.minVisiblePerRow ?? config.minVisibleTiles;
    
    // Ensure min <= max for clamp to work correctly
    final int safeMinPerRow = minPerRow < allAlwaysVisible.length ? minPerRow : allAlwaysVisible.length;

    // Calculate how many tiles fit based on width
    final int tilesThatFit = (constraints.maxWidth / config.tileWidth)
        .floor()
        .clamp(safeMinPerRow, allAlwaysVisible.length);
    
    // Apply maxVisibleTiles limit if set
    final int maxVisible = config.maxVisibleTiles != null
        ? (config.maxVisibleTiles! < allAlwaysVisible.length 
            ? config.maxVisibleTiles! 
            : allAlwaysVisible.length)
        : allAlwaysVisible.length;
    final int safeMaxVisible = maxVisible < safeMinPerRow ? safeMinPerRow : maxVisible;
    final int visibleCount = tilesThatFit.clamp(safeMinPerRow, safeMaxVisible);
    
    return allAlwaysVisible.take(visibleCount).toList();
  }
}

