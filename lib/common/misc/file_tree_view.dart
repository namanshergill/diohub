import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/misc/file_tree_view_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A widget for displaying files in a tree view structure.
///
/// Supports nested directory paths and provides visual indicators for hierarchy.
/// Directory headers are pinned when scrolling to show the current path.
///
/// Uses Riverpod for state management to handle expand/collapse and view mode.
class FileTreeView extends ConsumerWidget {
  const FileTreeView({
    required this.files,
    required this.onFileTap,
    this.showToolbar = true,
    super.key,
  });

  final List<FileElement> files;
  final void Function(FileElement file)? onFileTap;
  final bool showToolbar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileTreeViewProvider(files));

    // Build slivers based on current state
    final slivers = _buildSlivers(context, ref, state);

    return MultiSliver(children: slivers);
  }

  List<Widget> _buildSlivers(
      BuildContext context, WidgetRef ref, FileTreeViewState state) {
    if (!state.showTreeView) {
      // Flat list view
      return [
        if (showToolbar)
          SliverToBoxAdapter(
            child: _buildToolbar(context, ref, state),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildFileCard(context, files[index], 0, ''),
              ),
              childCount: files.length,
            ),
          ),
        ),
      ];
    }

    // Tree view
    return _buildTreeViewSlivers(context, ref, state);
  }

  List<Widget> _buildTreeViewSlivers(
      BuildContext context, WidgetRef ref, FileTreeViewState state) {
    final root = _buildDirectoryTree();

    final slivers = <Widget>[];

    // Add toolbar if enabled
    if (showToolbar) {
      slivers.add(
        SliverToBoxAdapter(
          child: _buildToolbar(context, ref, state),
        ),
      );
    }

    // Add directory slivers
    slivers
        .addAll(_buildDirectoryNodeSlivers(context, ref, root, [], '', state));

    return slivers;
  }

  DirectoryNode _buildDirectoryTree() {
    final DirectoryNode root = DirectoryNode('');

    for (final file in files) {
      final filename = file.filename ?? '';
      final pathParts = filename.split('/');

      if (pathParts.length == 1) {
        // Root level file
        root.files.add(file);
      } else {
        // File in a directory
        DirectoryNode current = root;
        for (int i = 0; i < pathParts.length - 1; i++) {
          final dirName = pathParts[i];
          current = current.getOrCreateChild(dirName);
        }
        current.files.add(file);
      }
    }

    return root;
  }

  Widget _buildToolbar(
      BuildContext context, WidgetRef ref, FileTreeViewState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: _ExpandableToolbar(
        files: files,
        state: state,
        onExpandAll: () =>
            ref.read(fileTreeViewProvider(files).notifier).expandAll(),
        onCollapseAll: () =>
            ref.read(fileTreeViewProvider(files).notifier).collapseAll(),
        onViewModeChanged: (value) =>
            ref.read(fileTreeViewProvider(files).notifier).setViewMode(value),
        showTreeView: state.showTreeView,
      ),
    );
  }

  List<Widget> _buildDirectoryNodeSlivers(
    BuildContext context,
    WidgetRef ref,
    DirectoryNode node,
    List<String> pathParts,
    String currentPath,
    FileTreeViewState state,
  ) {
    final List<Widget> slivers = [];

    // Sort children directories
    final sortedDirs = node.children.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Add directories with sticky headers
    for (final dir in sortedDirs) {
      final newPath =
          currentPath.isEmpty ? dir.name : '$currentPath/${dir.name}';
      final newPathParts = [...pathParts, dir.name];
      final isExpanded = state.expandedPaths.contains(newPath);

      // Collect files for this directory
      final sortedFiles = dir.files.toList()
        ..sort((a, b) => (a.filename ?? '').compareTo(b.filename ?? ''));

      // Get nested subdirectories (these are already slivers)
      final nestedSubdirs = _buildDirectoryNodeSlivers(
        context,
        ref,
        dir,
        newPathParts,
        newPath,
        state,
      );

      // Combine files and nested directories into content slivers
      final List<Widget> contentSlivers = [];

      // Add files first as slivers (wrapped in animated widget)
      for (final file in sortedFiles) {
        contentSlivers.add(
          _AnimatedSliverWrapper(
            expand: isExpanded,
            child: SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 4,
                  left: 12 + (newPathParts.length * 18.0),
                  right: 12,
                ),
                child: _buildFileCard(
                  context,
                  file,
                  newPathParts.length,
                  newPath,
                ),
              ),
            ),
          ),
        );
      }

      // Add nested subdirectories (they handle their own animation via their headers)
      contentSlivers.addAll(nestedSubdirs);

      // Wrap everything in a sticky header that unpins when content scrolls out
      slivers.add(
        SliverStickyHeader(
          header: _buildDirectoryHeader(
            context,
            ref,
            newPathParts,
            newPath,
            dir,
            pathParts.length, // depth
            isExpanded,
          ),
          sliver: MultiSliver(
            children: contentSlivers,
          ),
        ),
      );
    }

    // Add root-level files (files in the current node)
    final sortedFiles = node.files.toList()
      ..sort((a, b) => (a.filename ?? '').compareTo(b.filename ?? ''));
    for (final file in sortedFiles) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: 12 + (pathParts.length * 18.0),
              right: 12,
            ),
            child: _buildFileCard(context, file, pathParts.length, currentPath),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildDirectoryHeader(
    BuildContext context,
    WidgetRef ref,
    List<String> pathParts,
    String fullPath,
    DirectoryNode node,
    int depth,
    bool isExpanded,
  ) {
    final totalFiles = node.totalFileCount;
    // Show only the directory name (last part of path)
    final displayName = pathParts.isNotEmpty ? pathParts.last : node.name;
    final notifier = ref.read(fileTreeViewProvider(files).notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 12 + (depth * 18.0),
        right: 12,
        top: 2,
        bottom: 2,
      ),
      child: HighlightedContainer(
        highlightColor: context.colorScheme.primary,
        borderRadius: 6,
        child: Material(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () => notifier.toggleDirectory(fullPath),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.folder_rounded,
                    size: 14,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          context.colorScheme.surfaceContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$totalFiles',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(
    BuildContext context,
    FileElement file,
    int depth,
    String currentPath,
  ) {
    final status = file.status;
    Color statusColor;
    IconData statusIcon;
    Widget statusTextWidget;
    String subtitleText;

    if (status == CommitStatus.ADDED) {
      statusColor = Colors.green.shade400;
      statusIcon = Octicons.diff_added;
      final additions = file.additions ?? 0;
      statusTextWidget = Text(
        '+$additions',
        style: context.textTheme.bodySmall?.copyWith(
          color: Colors.green.shade400,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      );
      subtitleText = 'File added';
    } else if (status == CommitStatus.REMOVED) {
      statusColor = Colors.red.shade400;
      statusIcon = Octicons.diff_removed;
      final deletions = file.deletions ?? 0;
      statusTextWidget = Text(
        '-$deletions',
        style: context.textTheme.bodySmall?.copyWith(
          color: Colors.red.shade400,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      );
      subtitleText = 'File removed';
    } else {
      statusColor = context.colorScheme.primary;
      statusIcon = Octicons.diff_modified;
      final additions = file.additions ?? 0;
      final deletions = file.deletions ?? 0;
      final changes = file.changes ?? 0;
      statusTextWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$additions',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '-$deletions',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      );
      subtitleText = '$changes changes';
    }

    final filename = file.filename ?? '';
    // In flat mode (depth 0), show full path. In tree mode, show just filename
    final displayName = depth == 0 && filename.contains('/')
        ? filename
        : filename.contains('/')
            ? filename.substring(filename.lastIndexOf('/') + 1)
            : filename;

    // Show path as subtitle in flat mode
    final showPath = depth == 0 && filename.contains('/');
    final pathParts = filename.split('/');
    final path = pathParts.length > 1
        ? pathParts.sublist(0, pathParts.length - 1).join('/')
        : '';

    return HighlightedContainer(
      highlightColor: statusColor,
      borderRadius: 8,
      child: Material(
        color: Color.lerp(
          context.colorScheme.surfaceContainer,
          Colors.black,
          0.1,
        ),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: file.patch != null && onFileTap != null
              ? () => onFileTap!(file)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 14,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: context.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (showPath && path.isNotEmpty)
                        Text(
                          path,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          subtitleText,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    statusTextWidget,
                    if (file.patch != null) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 12,
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper that animates sliver content using SizeTransition
class _AnimatedSliverWrapper extends StatefulWidget {
  const _AnimatedSliverWrapper({
    required this.expand,
    required this.child,
  });

  final bool expand;
  final Widget child;

  @override
  State<_AnimatedSliverWrapper> createState() => _AnimatedSliverWrapperState();
}

class _AnimatedSliverWrapperState extends State<_AnimatedSliverWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    if (widget.expand) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedSliverWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand != oldWidget.expand) {
      if (widget.expand) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For SliverToBoxAdapter, extract child and animate it
    if (widget.child is SliverToBoxAdapter) {
      final sliver = widget.child as SliverToBoxAdapter;
      return SliverToBoxAdapter(
        child: SizeTransition(
          sizeFactor: _animation,
          child: sliver.child,
        ),
      );
    } else {
      // For other slivers, return as-is (they'll be handled by their parent)
      return widget.child;
    }
  }
}

/// Expandable toolbar widget with icon-only compact mode and expanded view with labels
class _ExpandableToolbar extends StatefulWidget {
  const _ExpandableToolbar({
    required this.files,
    required this.state,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onViewModeChanged,
    required this.showTreeView,
  });

  final List<FileElement> files;
  final FileTreeViewState state;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final ValueChanged<bool> onViewModeChanged;
  final bool showTreeView;

  @override
  State<_ExpandableToolbar> createState() => _ExpandableToolbarState();
}

class _ExpandableToolbarState extends State<_ExpandableToolbar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HighlightedContainer(
      highlightColor: context.colorScheme.primary,
      borderRadius: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: 8 + (_widthAnimation.value * 8),
                vertical: 6 + (_heightAnimation.value * 4),
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main row with icons and prominent action
                  Row(
                    children: [
                      // File count icon
                      _ToolbarIconButton(
                        icon: Octicons.file_diff,
                        tooltip:
                            '${widget.files.length} ${widget.files.length == 1 ? 'file' : 'files'}',
                        onTap: () {},
                      ),
                      const SizedBox(width: 4),
                      // Expand All icon
                      _ToolbarIconButton(
                        icon: Icons.unfold_more_rounded,
                        tooltip: 'Expand All',
                        onTap: widget.onExpandAll,
                      ),
                      const SizedBox(width: 2),
                      // Collapse All icon
                      _ToolbarIconButton(
                        icon: Icons.unfold_less_rounded,
                        tooltip: 'Collapse All',
                        onTap: widget.onCollapseAll,
                      ),
                      const SizedBox(width: 2),
                      // View Mode Switch icon
                      _ToolbarIconButton(
                        icon: widget.showTreeView
                            ? Octicons.file_directory
                            : Icons.list,
                        tooltip:
                            widget.showTreeView ? 'Tree View' : 'List View',
                        onTap: () =>
                            widget.onViewModeChanged(!widget.showTreeView),
                      ),
                      const Spacer(),
                      // Expand/Collapse toggle button
                      _ToolbarIconButton(
                        icon: _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        onTap: _toggleExpanded,
                      ),
                      const SizedBox(width: 6),
                      // Prominent action (always visible)
                      _ProminentAction(
                        icon: Octicons.file_diff,
                        label: '${widget.files.length} files',
                        onTap: () {},
                      ),
                    ],
                  ),
                  // Expanded content with labels (vertical layout)
                  SizeTransition(
                    sizeFactor: _heightAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        // Divider
                        Container(
                          height: 1,
                          color: context.colorScheme.outlineVariant
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 6),
                        // Actions with labels (vertical stack)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionWithLabel(
                              icon: Octicons.file_diff,
                              label:
                                  '${widget.files.length} ${widget.files.length == 1 ? 'file' : 'files'}',
                              onTap: () {},
                            ),
                            _ActionWithLabel(
                              icon: Icons.unfold_more_rounded,
                              label: 'Expand All',
                              onTap: widget.onExpandAll,
                            ),
                            _ActionWithLabel(
                              icon: Icons.unfold_less_rounded,
                              label: 'Collapse All',
                              onTap: widget.onCollapseAll,
                            ),
                            _ActionWithLabel(
                              icon: widget.showTreeView
                                  ? Octicons.file_directory
                                  : Icons.list,
                              label: widget.showTreeView
                                  ? 'Tree View'
                                  : 'List View',
                              onTap: () => widget
                                  .onViewModeChanged(!widget.showTreeView),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Divider before prominent actions
                        Container(
                          height: 1,
                          color: context.colorScheme.outlineVariant
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 6),
                        // Prominent actions at bottom (vertical)
                        _ProminentAction(
                          icon: Octicons.file_diff,
                          label: '${widget.files.length} files',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Icon button for toolbar (compact mode)
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    // ignore: unused_element
    this.customColor, // For custom colors like Colors.green (issues) or Colors.purple (PRs)
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(BuildContext context) {
    final iconColor = customColor ??
        (color != null && color != context.colorScheme.primary
            ? color
            : context.colorScheme.onSurfaceVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(
              icon,
              size: 10,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Action with icon and label (expanded mode)
class _ActionWithLabel extends StatelessWidget {
  const _ActionWithLabel({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    // ignore: unused_element
    this.customColor, // For custom colors like Colors.green (issues) or Colors.purple (PRs)
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(BuildContext context) {
    final iconColor = customColor ??
        (color != null && color != context.colorScheme.primary
            ? color
            : context.colorScheme.onSurfaceVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 10,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent action with icon and text
class _ProminentAction extends StatelessWidget {
  const _ProminentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    // ignore: unused_element
    this.customColor, // For custom colors like Colors.green (issues) or Colors.purple (PRs)
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? context.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 10,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DirectoryNode {
  DirectoryNode(this.name);

  final String name;
  final Map<String, DirectoryNode> children = {};
  final List<FileElement> files = [];

  DirectoryNode getOrCreateChild(String name) {
    return children.putIfAbsent(name, () => DirectoryNode(name));
  }

  int get totalFileCount {
    int count = files.length;
    for (final child in children.values) {
      count += child.totalFileCount;
    }
    return count;
  }
}
