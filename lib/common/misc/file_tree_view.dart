import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A standalone widget for displaying files in a tree view structure.
///
/// Supports nested directory paths and provides visual indicators for hierarchy.
class FileTreeView extends StatelessWidget {
  const FileTreeView({
    required this.files,
    required this.onFileTap,
    super.key,
  });

  final List<FileElement> files;
  final void Function(FileElement file)? onFileTap;

  @override
  Widget build(BuildContext context) {
    // Build nested directory structure
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

    return Column(
      children: _buildDirectoryNode(context, root, 0, []),
    );
  }

  List<Widget> _buildDirectoryNode(
    BuildContext context,
    DirectoryNode node,
    int depth,
    List<bool> isLastPath,
  ) {
    final List<Widget> widgets = [];

    // Sort children directories
    final sortedDirs = node.children.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Add directories
    for (int i = 0; i < sortedDirs.length; i++) {
      final dir = sortedDirs[i];
      final isLast = i == sortedDirs.length - 1 && node.files.isEmpty;
      widgets.add(
        _DirectorySection(
          directory: dir.name,
          node: dir,
          depth: depth,
          isLastPath: [...isLastPath, isLast],
          buildFileCard: (file, depth, isLastPath) =>
              _buildFileCard(context, file, depth, isLastPath),
          buildDirectoryNode: (node, depth, isLastPath) =>
              _buildDirectoryNode(context, node, depth, isLastPath),
        ),
      );
    }

    // Add files in this directory
    final sortedFiles = node.files.toList()
      ..sort((a, b) => (a.filename ?? '').compareTo(b.filename ?? ''));
    for (int i = 0; i < sortedFiles.length; i++) {
      final file = sortedFiles[i];
      final isLast = i == sortedFiles.length - 1;
      widgets.add(_buildFileCard(context, file, depth, [...isLastPath, isLast]));
    }

    return widgets;
  }

  Widget _buildFileCard(
    BuildContext context,
    FileElement file,
    int depth,
    List<bool> isLastPath,
  ) {
    final status = file.status;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String subtitleText;

    if (status == CommitStatus.ADDED) {
      statusColor = Colors.green.shade400;
      statusIcon = Octicons.diff_added;
      statusText = '+${file.additions ?? 0}';
      subtitleText = 'File added';
    } else if (status == CommitStatus.REMOVED) {
      statusColor = Colors.red.shade400;
      statusIcon = Octicons.diff_removed;
      statusText = '-${file.deletions ?? 0}';
      subtitleText = 'File removed';
    } else {
      statusColor = context.colorScheme.primary;
      statusIcon = Octicons.diff_modified;
      final additions = file.additions ?? 0;
      final deletions = file.deletions ?? 0;
      final changes = file.changes ?? 0;
      statusText = '+$additions -$deletions';
      subtitleText = '$changes changes';
    }

    final filename = file.filename ?? '';
    final displayName = filename.contains('/')
        ? filename.substring(filename.lastIndexOf('/') + 1)
        : filename;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Color.lerp(
          context.colorScheme.surfaceContainer,
          Colors.black,
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: file.patch != null && onFileTap != null
              ? () => onFileTap!(file)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Tree connector indicators
                if (depth > 0) ...[
                  SizedBox(
                    width: depth * 24.0,
                    child: CustomPaint(
                      painter: _TreeConnectorPainter(
                        isLastPath: isLastPath,
                        color: context.colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                      size: Size(depth * 24.0, 40),
                    ),
                  ),
                ],
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statusText,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (file.patch != null) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
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

class _DirectorySection extends StatefulWidget {
  const _DirectorySection({
    required this.directory,
    required this.node,
    required this.depth,
    required this.isLastPath,
    required this.buildFileCard,
    required this.buildDirectoryNode,
  });

  final String directory;
  final DirectoryNode node;
  final int depth;
  final List<bool> isLastPath;
  final Widget Function(FileElement, int, List<bool>) buildFileCard;
  final List<Widget> Function(DirectoryNode, int, List<bool>) buildDirectoryNode;

  @override
  State<_DirectorySection> createState() => _DirectorySectionState();
}

class _DirectorySectionState extends State<_DirectorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final totalFiles = widget.node.totalFileCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.depth * 24.0,
                top: 8,
                bottom: 8,
                right: 4,
              ),
              child: Row(
                children: [
                  // Tree connector indicators
                  if (widget.depth > 0) ...[
                    SizedBox(
                      width: widget.depth * 24.0,
                      child: CustomPaint(
                        painter: _TreeConnectorPainter(
                          isLastPath: widget.isLastPath,
                          color: context.colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                        size: Size(widget.depth * 24.0, 24),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.folder_rounded,
                    size: 16,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.directory,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '$totalFiles ${totalFiles == 1 ? 'file' : 'files'}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Column(
            children: [
              ...widget.buildDirectoryNode(
                widget.node,
                widget.depth + 1,
                widget.isLastPath,
              ),
            ],
          ),
      ],
    );
  }
}

class _TreeConnectorPainter extends CustomPainter {
  _TreeConnectorPainter({
    required this.isLastPath,
    required this.color,
  });

  final List<bool> isLastPath;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double indentWidth = 24.0;
    final double centerY = size.height / 2;

    // Draw vertical lines and connectors
    for (int i = 0; i < isLastPath.length - 1; i++) {
      final double x = i * indentWidth + indentWidth / 2;
      final bool isLast = isLastPath[i];

      // Draw vertical line (skip if this is the last item in its level)
      if (!isLast) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          paint,
        );
      }
    }

    // Draw horizontal connector for the last level
    if (isLastPath.isNotEmpty) {
      final int lastIndex = isLastPath.length - 1;
      final double startX = lastIndex * indentWidth + indentWidth / 2;
      final double endX = lastIndex * indentWidth + indentWidth;
      final bool isLast = isLastPath[lastIndex];

      // Draw horizontal line
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        paint,
      );

      // Draw vertical line (skip if this is the last item)
      if (!isLast) {
        canvas.drawLine(
          Offset(startX, centerY),
          Offset(startX, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TreeConnectorPainter oldDelegate) {
    return oldDelegate.isLastPath != isLastPath ||
        oldDelegate.color != color;
  }
}

