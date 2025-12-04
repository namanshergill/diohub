import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/providers/repository/code_provider.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class CommitInfoButton extends StatelessWidget {
  const CommitInfoButton({super.key});
  @override
  Widget build(final BuildContext context) => Consumer<CodeProvider>(
        builder:
            (final BuildContext context, final CodeProvider value, final _) {
          final commit = value.tree.last.commit!;
          final commitMessage = commit.commit!.message ?? '';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Main content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Commit message
                    Text(
                      commitMessage,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Author and date row
                    Row(
                      children: <Widget>[
                        ProfileTile.avatar(
                          avatarUrl: commit.author?.avatarUrl ?? '',
                          size: 14,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commit.author?.login ?? 'N/A',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getDate(
                            commit.commit!.committer!.date.toString(),
                            shorten: true,
                          ),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // SHA badge - centered vertically
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Octicons.git_commit,
                      size: 13,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      commit.sha!.substring(0, 7),
                      style: context.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown arrow indicating bottom sheet
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          );
        },
      );
}
