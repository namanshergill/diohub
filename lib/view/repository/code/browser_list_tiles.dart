import 'package:auto_route/auto_route.dart';
import 'package:diohub/models/repositories/code_tree_model.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

class BrowserListTile extends StatelessWidget {
  const BrowserListTile(this.tree, this.repoURL, this.index, {super.key});

  final Tree tree;
  final String? repoURL;
  final int index;

  String _formatFileSize(int? sizeInBytes) {
    if (sizeInBytes == null) return '';
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isFile = tree.type == Type.BLOB;
    final isFolder = tree.type == Type.TREE;

    IconData getIconData() {
      switch (tree.type) {
        case Type.TREE:
          return Icons.folder_rounded;
        case Type.BLOB:
          return MdiIcons.file;
        case null:
          return MdiIcons.emoticonConfused;
      }
    }

    Color getIconColor() {
      if (isFolder) {
        return context.colorScheme.primary;
      }
      return context.colorScheme.onSurfaceVariant;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (isFolder) {
            Provider.of<CodeProvider>(context, listen: false)
                .pushTree(tree.sha!, index);
          } else if (isFile) {
            await AutoRouter.of(context).push(
              FileViewerAPI(
                repoURL: repoURL,
                sha: tree.sha,
                fileName: tree.path,
                branch: Provider.of<RepoBranchProvider>(context, listen: false)
                    .currentSHA,
                repoName:
                    Provider.of<RepositoryProvider>(context, listen: false)
                        .data
                        .name ,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              // Icon with circle background
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFolder
                      ? context.colorScheme.primary.withOpacity(0.1)
                      : context.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getIconData(),
                  size: 18,
                  color: getIconColor(),
                ),
              ),
              const SizedBox(width: 12),
              // File/folder name
              Expanded(
                child: Text(
                  tree.path ?? '',
                  style: context.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Size and chevron
              if (isFile && tree.size != null) ...[
                Text(
                  _formatFileSize(tree.size),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
