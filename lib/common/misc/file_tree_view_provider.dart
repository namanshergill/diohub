import 'package:diohub/models/commits/commit_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for FileTreeView widget
class FileTreeViewState {
  const FileTreeViewState({
    required this.expandedPaths,
    required this.showTreeView,
    required this.files,
  });

  final Set<String> expandedPaths;
  final bool showTreeView;
  final List<FileElement> files;

  FileTreeViewState copyWith({
    Set<String>? expandedPaths,
    bool? showTreeView,
    List<FileElement>? files,
  }) {
    return FileTreeViewState(
      expandedPaths: expandedPaths ?? this.expandedPaths,
      showTreeView: showTreeView ?? this.showTreeView,
      files: files ?? this.files,
    );
  }
}

/// Notifier for managing FileTreeView state
class FileTreeViewNotifier extends Notifier<FileTreeViewState> {
  List<FileElement>? _initialFiles;

  FileTreeViewNotifier([this._initialFiles]);

  @override
  FileTreeViewState build() {
    // Initialize with files if provided, otherwise empty state
    if (_initialFiles != null && _initialFiles!.isNotEmpty) {
      final expandedPaths = _getAllDirectoryPaths(_initialFiles!);
      return FileTreeViewState(
        expandedPaths: expandedPaths,
        showTreeView: true,
        files: _initialFiles!,
      );
    }
    return const FileTreeViewState(
      expandedPaths: {},
      showTreeView: true,
      files: [],
    );
  }

  /// Initialize with files and expand all directories by default
  void initializeFiles(List<FileElement> files) {
    final expandedPaths = _getAllDirectoryPaths(files);
    state = state.copyWith(
      files: files,
      expandedPaths: expandedPaths,
    );
  }

  /// Get all directory paths from files
  Set<String> _getAllDirectoryPaths(List<FileElement> files) {
    final paths = <String>{};
    final root = _buildDirectoryTree(files);
    _collectAllPaths(root, '', paths);
    return paths;
  }

  /// Build directory tree structure
  Map<String, dynamic> _buildDirectoryTree(List<FileElement> files) {
    final root = <String, dynamic>{};
    
    for (final file in files) {
      final filename = file.filename ?? '';
      final pathParts = filename.split('/');
      
      if (pathParts.length == 1) {
        // Root level file - skip
        continue;
      }
      
      // File in a directory
      Map<String, dynamic> current = root;
      for (int i = 0; i < pathParts.length - 1; i++) {
        final dirName = pathParts[i];
        current = current.putIfAbsent(dirName, () => <String, dynamic>{}) as Map<String, dynamic>;
      }
    }
    
    return root;
  }

  /// Collect all directory paths recursively
  void _collectAllPaths(Map<String, dynamic> node, String currentPath, Set<String> paths) {
    for (final entry in node.entries) {
      final newPath = currentPath.isEmpty ? entry.key : '$currentPath/${entry.key}';
      paths.add(newPath);
      if (entry.value is Map) {
        _collectAllPaths(entry.value as Map<String, dynamic>, newPath, paths);
      }
    }
  }

  /// Toggle a single directory's expanded state
  void toggleDirectory(String path) {
    final newExpandedPaths = Set<String>.from(state.expandedPaths);
    if (newExpandedPaths.contains(path)) {
      newExpandedPaths.remove(path);
    } else {
      newExpandedPaths.add(path);
    }
    state = state.copyWith(expandedPaths: newExpandedPaths);
  }

  /// Expand all directories
  void expandAll() {
    final expandedPaths = _getAllDirectoryPaths(state.files);
    state = state.copyWith(expandedPaths: expandedPaths);
  }

  /// Collapse all directories
  void collapseAll() {
    state = state.copyWith(expandedPaths: {});
  }

  /// Set view mode (tree vs flat)
  void setViewMode(bool showTreeView) {
    state = state.copyWith(showTreeView: showTreeView);
  }
}

/// Provider for FileTreeView state
/// Uses a family provider keyed by files list identity
final fileTreeViewProvider = NotifierProvider.family<FileTreeViewNotifier, FileTreeViewState, List<FileElement>>(
  (List<FileElement> files) => FileTreeViewNotifier(files),
);

