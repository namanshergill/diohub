import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/utils/markdown_to_html.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class TrimmableMarkdownContent extends StatelessWidget {
  const TrimmableMarkdownContent({
    required this.text,
    this.textHtml,
    this.repo,
    this.maxLengthForIndicator = 400,
    super.key,
  });

  final String? text;
  final String? textHtml;
  final String? repo;
  final int maxLengthForIndicator;

  /// Strips HTML comments and other invisible markdown content
  /// to calculate truncation based on visible content length
  static String _stripInvisibleContent(String markdown) {
    // Remove HTML comments (<!-- ... -->)
    String cleaned = markdown.replaceAll(
      RegExp(r'<!--[\s\S]*?-->', multiLine: true),
      '',
    );

    // Remove HTML directives like [//]: # (comment)
    cleaned = cleaned.replaceAll(
      RegExp(r'\[//\]:\s*#\s*\([^)]*\)', multiLine: true),
      '',
    );

    return cleaned;
  }

  @override
  Widget build(final BuildContext context) {
    if (text == null) {
      return const SizedBox.shrink();
    }

    // Strip invisible content to calculate truncation based on visible length
    final String cleanedText = _stripInvisibleContent(text!);
    final bool shouldTruncate = cleanedText.length > maxLengthForIndicator;

    String? content;
    if (shouldTruncate) {
      // Truncate the cleaned text (visible content) at maxLengthForIndicator
      String textToConvert = cleanedText.substring(0, maxLengthForIndicator);
      textToConvert = '${textToConvert.trim()}...';
      content = mdToHtml(textToConvert, repo: repo);
    } else {
      // No truncation needed, use original text (with comments, they won't render anyway)
      content = mdToHtml(text!, repo: repo);
    }

    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarkdownBody(
          content,
          buildAsync: false,
          style: MarkdownBodyStyle(
            codeBlockStyle: MarkdownBodyCodeBlockStyle(
              elevation: 0,
            ),
          ),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.8),
                height: 1.35,
                fontSize: 13,
              ),
        ),
//         if (shouldTruncate)
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Text(
//               'Read more...',
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
// color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),                fontWeight: FontWeight.w500,                    fontSize: 11,
//                   ),
//             ),
//           ),
      ],
    );
  }
}
