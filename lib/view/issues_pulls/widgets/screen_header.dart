import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/editable_text.dart';
import 'package:diohub/common/wrappers/editing_wrapper.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/utils/markdown_to_html.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_info_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.widget,
    required this.titleEditingController,
    required this.labelsEditingController,
    super.key,
  });

  final IssuePullInfoTemplate widget;
  final EditingController<String> titleEditingController;
  final EditingController<List<Glabel?>> labelsEditingController;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                if (widget.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Octicons.pin,
                            size: 14,
                            color: context.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pinned',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                EditableTextItem(
                  titleEditingController,
                  builder:
                      (final BuildContext context, final String? newValue) =>
                          MarkdownBody(
                    newValue != null ? mdToHtml(newValue) : widget.title,
                    textStyle: context.textTheme.headlineSmall,
                  ),
                ),
                buildLabelsWidget(),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        ],
      );

  EditWidget<List<Glabel?>> buildLabelsWidget() => EditWidget<List<Glabel?>>(
        editingController: labelsEditingController,
        builder: (
          final BuildContext context,
          final EditingData<List<Glabel?>> data,
        ) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: <Widget>[
                if (data.editingController.currentValue.isEmpty)
                  Text(
                    'No Labels',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: data.editingController.currentValue
                          .map(
                            (final Glabel? e) => IssueLabel.gql(e!),
                          )
                          .toList(),
                    ),
                  ),
                data.tools,
              ],
            ),
          );
        },
      );
}

