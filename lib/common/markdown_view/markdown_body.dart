import 'package:diohub/common/markdown_view/extensions/markdown_extensions.dart';
import 'package:diohub/common/misc/image_loader.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/services/markdown/markdown_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

class MarkdownRenderAPI extends StatelessWidget {
  const MarkdownRenderAPI(
    this.data, {
    super.key,
    this.repoContext,
    this.branch,
    this.style,
    this.buildAsync,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
    this.markdownBodyKey,
  });

  final String data;
  final String? repoContext;
  final String? branch;
  final bool? buildAsync;
  final MarkdownBodyStyle? style;
  final void Function(List<({String text, String id, int level})> headings)?
      onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;
  final Key? markdownBodyKey;

  List<MarkdownImgSrcModifiers> get _repoMarkdownImgSrcModifiers =>
      <MarkdownImgSrcModifiers>[
        (final MarkdownImgSrcData srcData) {
          String src = srcData.src;
          if (!srcData.isHttp && branch != null) {
            src = 'https://raw.githubusercontent.com/$repoContext/$branch/$src';
          } else if (repoContext != null &&
              srcData.isInRepoContext(repoContext!)) {
            src = src.replaceFirst(
              'https://github.com/$repoContext/blob/',
              'https://raw.githubusercontent.com/$repoContext/',
            );
          }
          return src;
        },
      ];

  @override
  Widget build(final BuildContext context) => APIWrapper<String>.deferred(
        apiCall: ({
          required final bool refresh,
        }) async =>
            MarkdownService.renderMarkdown(data, context: repoContext),
        loadingBuilder: (final BuildContext context) => const Center(
          child: LoadingIndicator(),
        ),
        builder: (final BuildContext context, final String data) =>
            MarkdownBody(
          data,
          key: markdownBodyKey,
          buildAsync: buildAsync,
          imgSrcModifiers: _repoMarkdownImgSrcModifiers,
          style: style,
          onHeadingsExtracted: onHeadingsExtracted,
          onScrollToAnchor: onScrollToAnchor,
        ),
      );
}

class MarkdownBody extends StatefulWidget {
  const MarkdownBody(
    this.content, {
    super.key,
    this.imgSrcModifiers,
    this.style,
    this.buildAsync,
    this.textStyle,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
    // this.defaultBodyStyle,
  });

  final MarkdownBodyStyle? style;
  final bool? buildAsync;
  final String content;
  final List<MarkdownImgSrcModifiers>? imgSrcModifiers;
  final TextStyle? textStyle;
  final void Function(List<({String text, String id, int level})> headings)?
      onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;

  // final Style? defaultBodyStyle;

  @override
  MarkdownBodyState createState() => MarkdownBodyState();
}

class MarkdownBodyState extends State<MarkdownBody> {
  // late String content;
  late dom.Document doc;

  @override
  void initState() {
    updateData(widget.content);
    _scrollCallback = widget.onScrollToAnchor;
    super.initState();
  }

  void updateData(final String data) {
    final dom.Document document = parse(data);
    // The list of tags to perform modifications on.
    final List<String> tags = <String>['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

    // Collect all heading elements first (for modifications)
    for (final String element in tags) {
      final List<dom.Element> elements = document.getElementsByTagName(element);
      performModifications(elements);
    }

    // Extract headings in document order by querying all at once
    final headings = <({String text, String id, int level})>[];
    final allHeadingElements =
        document.querySelectorAll('h1, h2, h3, h4, h5, h6');

    for (final dom.Element headingElement in allHeadingElements) {
      final text = headingElement.text.trim();
      if (text.isNotEmpty) {
        final id = headingElement.attributes['id'] ?? '';
        // Extract level from tag name (h1 = 1, h2 = 2, etc.)
        final level = int.parse(headingElement.localName!.substring(1));

        print(
            '[MarkdownBody] Extracted heading: text="$text", id="$id", level=$level');
        print(
            '[MarkdownBody] Heading element attributes: ${headingElement.attributes}');

        headings.add((text: text, id: id, level: level));
      }
    }

    doc = document;

    // Notify about extracted headings - defer to avoid setState during build
    if (widget.onHeadingsExtracted != null && headings.isNotEmpty) {
      widget.onHeadingsExtracted!(headings);
    }
  }

  @override
  void didUpdateWidget(covariant final MarkdownBody oldWidget) {
    if (oldWidget.content != widget.content) {
      updateData(widget.content);
    }
    // Update scroll callback if changed
    if (oldWidget.onScrollToAnchor != widget.onScrollToAnchor) {
      // Store scroll callback for later use
      _scrollCallback = widget.onScrollToAnchor;
    }
    super.didUpdateWidget(oldWidget);
  }

  void Function(String anchorId)? _scrollCallback;

  void performModifications(final List<dom.Element> elements) {
    for (final dom.Element node in elements) {
      node.attributes.addAll(
        <Object, String>{
          'id': node.text
              .toLowerCase()
              .replaceAll(' ', '-')
              .replaceAll(RegExp(r'[^0-9a-zA-Z-]+'), ''),
        },
      );
    }
  }

  final GlobalKey<HtmlWidgetState> htmlWidgetKey = GlobalKey<HtmlWidgetState>();

  HtmlWidgetState? get currentMarkdownState => htmlWidgetKey.currentState;

  void scrollToAnchor(String anchorId) {
    print('[MarkdownBodyState] ====== scrollToAnchor CALLED ======');
    print('[MarkdownBodyState] anchorId: "$anchorId"');
    print('[MarkdownBodyState] htmlWidgetKey: ${htmlWidgetKey.toString()}');
    print(
        '[MarkdownBodyState] currentMarkdownState (HtmlWidgetState) is ${currentMarkdownState != null ? "not null" : "null"}');
    if (currentMarkdownState != null) {
      print('[MarkdownBodyState] ✓ HtmlWidgetState found');
      print(
          '[MarkdownBodyState] HtmlWidgetState type: ${currentMarkdownState.runtimeType}');
      print(
          '[MarkdownBodyState] Calling currentMarkdownState.scrollToAnchor("$anchorId")');
      try {
        currentMarkdownState!.scrollToAnchor(anchorId);
        print(
            '[MarkdownBodyState] ✓ scrollToAnchor call to HtmlWidgetState completed successfully');
      } catch (e, stackTrace) {
        print('[MarkdownBodyState] ✗ ERROR calling scrollToAnchor: $e');
        print('[MarkdownBodyState] Stack trace: $stackTrace');
      }
    } else {
      print(
          '[MarkdownBodyState] ✗ ERROR: currentMarkdownState is null, cannot scroll');
      print(
          '[MarkdownBodyState] This means HtmlWidget may not be mounted yet or htmlWidgetKey is not attached');
    }
    // Also call callback if provided
    if (_scrollCallback != null) {
      print(
          '[MarkdownBodyState] Calling _scrollCallback with anchorId: "$anchorId"');
      _scrollCallback!.call(anchorId);
    } else {
      print('[MarkdownBodyState] No _scrollCallback provided');
    }
  }

  @override
  Widget build(final BuildContext context) => HtmlWidget(
        doc.outerHtml, key: htmlWidgetKey,
        buildAsync: widget.buildAsync,
        factoryBuilder: () => MyWidgetFactory(
          fetchState: () => currentMarkdownState,
          // codeBlockStyle: widget.style?.codeBlockStyle,
        ),
        textStyle: widget.textStyle,
        // onTapUrl: (final String url) async {
        //   await URLActions(
        //     uri: Uri.parse(url),
        //   ).showMenu(context);
        //   return true;
        // },
        onLoadingBuilder: (
          final BuildContext context,
          final dom.Element element,
          final double? loadingProgress,
        ) =>
            const LoadingIndicator(),

        customStylesBuilder: (final dom.Element element) {
          // print(element.localName);
          return switch (element.localName) {
            'a' => <String, String>{
                'text-decoration': 'none',
              },
            'blockquote' => <String, String>{
                'margin': '0',
                // 'padding': '0',
              },
            'ol' => {
                'margin': '16',
                // 'padding': '16',
              },
            'ul' => {
                'margin': '16',
                // 'padding': '16',
              },
            _ => null,
          };
        },
        // rende
        // rMode: RenderMode.sliverList,

        customWidgetBuilder: (final dom.Element element) {
          if (element.children.isNotEmpty) {
            if (element.children.first.isTag('pre')) {
              return CodeView(
                element.text,
                language: element.attributes['class']
                    ?.replaceAll('highlight highlight-source-', '')
                    .split(' ')
                    .first,
                codeBlockStyle: widget.style?.codeBlockStyle,
              );
            }
          }

          // if (element.isTag('table')) {
          //   return Container();
          // }
          if (element.isTag('img')) {
            return buildImageTag(
              element,
              imgSrcModifiers: widget.imgSrcModifiers,
            );
          }
          return null;
        },
      );

  Widget buildImageTag(
    final dom.Element element, {
    required final Iterable<MarkdownImgSrcModifiers>? imgSrcModifiers,
  }) {
    String src = element.attributes['src']!;
    for (final MarkdownImgSrcModifiers modifier
        in imgSrcModifiers ?? <MarkdownImgSrcModifiers>[]) {
      src = modifier.call(
        MarkdownImgSrcData(src),
      );
    }
    if (src.split('.').last.contains('svg')) {
      return SvgPicture.network(
        src,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ImageLoader(
        src,
        height: double.tryParse(
          element.attributes['height'] ?? '',
        ),
        width: double.tryParse(
          element.attributes['width'] ?? '',
        ),
        // Some SVGs don't have svg in their URL so will miss the
        // if check above. They will fail in the image loader
        // so will build here.
        errorBuilder: (final BuildContext context) => SvgPicture.network(
          src,
        ),
      ),
    );
  }
}

class MarkdownBodyStyle {
  MarkdownBodyStyle({
    this.codeBlockStyle,
  });

  final MarkdownBodyCodeBlockStyle? codeBlockStyle;
}

class MarkdownBodyCodeBlockStyle {
  MarkdownBodyCodeBlockStyle({
    this.headerColor,
    this.elevation,
  });

  final Color? headerColor;
  final double? elevation;
}

//     return Html.fromDom(
//       document: doc,
//       // onLinkTap: (String? url, RenderContext rContext,
//       //     Map<String, String> attributes, data) {
//       //   return linkHandler(context, url);
//       // },
//       extensions: markdownTagExtensions(
//         context,
//         imgSrcModifiers: widget.imgSrcModifiers,
//       )..addAll(<HtmlExtension>[
//           const TableHtmlExtension(),
//         ]),
//       // tagsList: Html.tags
//       //   ..addAll(
//       //     ['g-emoji'],
//       //   ),
//       style: <String, Style>{
//         'a': Style(
//           textDecoration: TextDecoration.none,
//           color: Colors.blueAccent,
//         ),
//         'blockquote': Style(
//           padding: HtmlPaddings.zero,
//           margin: Margins.all(4),
//         ),
//         if (widget.defaultBodyStyle != null) 'body': widget.defaultBodyStyle!,
//         'p': Style(
//           padding: HtmlPaddings.zero,
//           margin: Margins.symmetric(vertical: 8),
//         ),
//         'table': Style(
//           border: Border.all(
//             // color: context.palette.faded3,
//             width: 0.2,
//           ),
//         ),
//         'td': Style(
//           border: Border.all(
//             // color: context.palette.faded3,
//             width: 0.2,
//           ),
//           padding: HtmlPaddings.symmetric(horizontal: 8, vertical: 4),
//         ),
//         'th': Style(
//           border: Border.all(
//             // color: context.palette.faded3,
//             width: 0.2,
//           ),
//           padding: HtmlPaddings.symmetric(horizontal: 8, vertical: 4),
//         ),
//         'ul': Style(
//           padding: HtmlPaddings(
//             inlineStart: HtmlPadding(16),
//             // top: HtmlPadding(0),
//             // inlineEnd: HtmlPadding(0),
//           ),
//         ),
//         // 'li': Style(
//         //   padding: HtmlPaddings(
//         //     bottom: HtmlPadding(0),
//         //   ),
//         // )
//       },
//       onLinkTap: (
//         final String? url,
//         final Map<String, String> attributes,
//         final dom.Element? element,
//       ) async =>
//           URLActions(
//         uri: Uri.parse(url!),
//       ).showMenu(context),
// //         customRender:  {
// //           // 'a': (final renderContext, final child) {
// //           //   if (renderContext.tree.attributes['href']?.startsWith('#') ==
// //           //       true) {
// //           //     return null;
// //           //   }
// //           //   return GestureDetector(
// //           //     onTap: () => linkHandler(
// //           //       context,
// //           //       renderContext.tree.attributes['href'],
// //           //     ),
// //           //     onLongPress: () => linkHandler(
// //           //       context,
// //           //       renderContext.tree.attributes['href'],
// //           //       showSheetOnDeepLink: true,
// //           //     ),
// //           //     child: child,
// //           //   );
// //           // },
// //           //TODO: not implemented in new API.
// //        //   'li': (final context, final child) {},
// //           // 'blockquote': (final context, final child) => Container(
// //           //       padding: const EdgeInsets.only(left: 12),
// //           //       decoration: BoxDecoration(
// //           //         border: Border(
// //           //           left: BorderSide(color: grey.shade400, width: 2),
// //           //         ),
// //           //       ),
// //           //       child: child,
// //           //     ),
// //           // 'code': (final rdrCtx, final child) => DecoratedBox(
// //           //       decoration: BoxDecoration(
// //           //         color: Provider.of<PaletteSettings>(context)
// //           //             .currentSetting
// //           //             .faded1,
// //           //         borderRadius: smallBorderRadius,
// //           //       ),
// //           //       child: Padding(
// //           //         padding: const EdgeInsets.symmetric(horizontal: 6),
// //           //         child: child,
// //           //       ),
// //           //     ),
// //           // 'div': (final rdr, final child) {
// //           //   final divClass = rdr.tree.attributes['class'];
// //           //   if (divClass == 'border rounded-1 my-2') {
// //           //     return DecoratedBox(
// //           //       decoration: BoxDecoration(
// //           //         border: Border.all(
// //           //           color: Provider.of<PaletteSettings>(context)
// //           //               .currentSetting
// //           //               .faded3,
// //           //           width: 0.3,
// //           //         ),
// //           //         borderRadius: smallBorderRadius,
// //           //       ),
// //           //       child: Padding(
// //           //         padding: const EdgeInsets.symmetric(horizontal: 8),
// //           //         child: child,
// //           //       ),
// //           //     );
// //           //   } else if (divClass == 'blob-wrapper blob-wrapper-embedded data') {
// //           //     // return Html(data: context.tree.element!.outerHtml);
// //           //   } else if (rdr.tree.children.isNotEmpty) {
// //           //     if (rdr.tree.children.first.name == 'pre') {
// //           //       return _CodeView(
// //           //         rdr.tree.children.first.element!.text,
// //           //         language: rdr.tree.element?.attributes['class']
// //           //             ?.replaceAll('highlight highlight-source-', '')
// //           //             .split(' ')
// //           //             .first,
// //           //       );
// //           //     }
// //           //   }
// //           //   return child;
// //           // },
// //           //TODO: not implemented in new API.
// //
// // //          'g-emoji': (final renderContext, final child) => child,
// //           // 'img': (final renderContext, final child) {
// //           //   var src = renderContext.tree.element!.attributes['src'];
// //           //   if (!src.startsWith('https://') && !src.startsWith('http://')) {
// //           //     src =
// //           //         'https://raw.githubusercontent.com/${widget.context}/${widget.branch}/$src';
// //           //   } else if (src
// //           //       .startsWith('https://github.com/${widget.context}/blob/')) {
// //           //     src = src.replaceFirst(
// //           //       'https://github.com/${widget.context}/blob/',
// //           //       'https://raw.githubusercontent.com/${widget.context}/',
// //           //     );
// //           //   }
// //           //   if (src.split('.').last.contains('svg')) {
// //           //     return SvgPicture.network(src);
// //           //   }
// //           //   return Padding(
// //           //     padding: const EdgeInsets.all(4),
// //           //     child: ImageLoader(
// //           //       src,
// //           //       height: double.tryParse(
// //           //         renderContext.tree.element?.attributes['height'] ?? '',
// //           //       ),
// //           //       width: double.tryParse(
// //           //         renderContext.tree.element?.attributes['width'] ?? '',
// //           //       ),
// //           //       // Some SVGs don't have svg in their URL so will miss the
// //           //       // if check above. They will fail in the image loader
// //           //       // so will build here.
// //           //       errorBuilder: (final context) => SvgPicture.network(src),
// //           //     ),
// //           //   );
// //           // },
// //           // 'p': (RenderContext renderContext, Widget child) {
// //           //   final String? pClass = renderContext.tree.attributes['class'];
// //           //   if (pClass == 'mb-0 color-text-tertiary') {
// //           //     return DefaultTextStyle(
// //           //       style: renderContext.style
// //           //           .generateTextStyle()
// //           //           .copyWith(color: context.palette.grey3),
// //           //       child: child,
// //           //     );
// //           //   }
// //           //   return child;
// //           // },
// //           // 'pre': (final renderContext, final child) {
// //           //   if (renderContext.tree.children.first.name == 'code') {
// //           //     return _CodeView(renderContext.tree.element!.text);
// //           //   }
// //           //   return child;
// //           // },
// //           //TODO: not implemented in new API.
// //
// //           // 'table': (final renderContext, final child) => SingleChildScrollView(
// //           //       scrollDirection: Axis.horizontal,
// //           //       child: (renderContext.tree as TableLayoutElement)
// //           //           .toWidget(renderContext),
// //           //     ),
// //           // 'td': (renderContext, child) {
// //           //   return Row(
// //           //     children: [
// //           //       Expanded(
// //           //         child: Container(
// //           //           decoration: BoxDecoration(
// //           //             border: Border.all(
// //           //                 color: Provider.of<PaletteSettings>(context)
// //           //                     .currentSetting
// //           //                     .faded3,
// //           //                 width: 0.3),
// //           //           ),
// //           //           child: Padding(
// //           //             padding: const EdgeInsets.all(8.0),
// //           //             child: child,
// //           //           ),
// //           //         ),
// //           //       ),
// //           //     ],
// //           //   );
// //           // },
// //           // 'th': (renderContext, child) {
// //           //   return Row(
// //           //     children: [
// //           //       Expanded(
// //           //         child: Container(
// //           //           decoration: BoxDecoration(
// //           //             border: Border.all(
// //           //                 color: Provider.of<PaletteSettings>(context)
// //           //                     .currentSetting
// //           //                     .faded3,
// //           //                 width: 0.3),
// //           //           ),
// //           //           child: Padding(
// //           //             padding: const EdgeInsets.all(8.0),
// //           //             child: child,
// //           //           ),
// //           //         ),
// //           //       ),
// //           //     ],
// //           //   );
// //           // },
// //         },
//     );
