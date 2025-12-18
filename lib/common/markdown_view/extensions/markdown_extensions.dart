import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub/common/misc/image_loader.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/utils/copy_to_clipboard.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:pull_down_button/pull_down_button.dart';

part 'a_extension.dart';
part 'code_extension.dart';
part 'div_extension.dart';
part 'img_extension.dart';
part 'pre_extension.dart';

extension Tag on dom.Element {
  bool isTag(final String tag) => localName == tag;
}

extension on BuildTree {
  bool isTag(final String tag) => element.localName == tag;

  void wrapTaggedWidget({
    required final String tag,
    required final Widget? Function(
      BuildContext context,
      Widget child,
      BuildTree tree,
    ) newWidgetBuilder,
  }) {
    if (isTag(tag)) {
      register(
        BuildOp.inline(
          onRenderInlineBlock: (
            final BuildTree tree,
            final Widget child,
          ) =>
              Builder(
            builder: (final BuildContext context) =>
                newWidgetBuilder.call(
                  context,
                  child,
                  tree,
                ) ??
                child,
          ),
        ),
      );
    }
  }
}

// extension BuildTreeCopyWith on BuildTree {
//   BuildTree copyWith({
//     dom.Element? element,
//     InheritanceResolvers? inheritanceResolvers,
//     List<BuildBit>? children,
//     List<dynamic>? nonInherited,
//     LockableList<css.Declaration>? styles,
//   }) {
//     return BuildTree(
//       element: element ?? this.element,
//       inheritanceResolvers: inheritanceResolvers ?? this.inheritanceResolvers,
//       _children: children ?? this._children,
//       _nonInherited: nonInherited ?? this._nonInherited,
//       styles: styles ?? this.styles,
//     );
//   }
// }

// extension on BuildTree {
//   // ... (rest of your class)
//
//   /// Creates a copy of the current BuildTree with optional parameter overrides.
//   BuildTree copyWith({
//     dom.Element? element,
//     InheritanceResolvers? inheritanceResolvers,
//     List<BuildBit>? children,
//     List<dynamic>? nonInherited,
//     LockableList<css.Declaration>? styles,
//   }) {
//     return BuildTree(
//       element: element ?? this.element,
//       inheritanceResolvers: inheritanceResolvers ?? this.inheritanceResolvers,
//       _children: children ?? this._children,
//       _nonInherited: nonInherited ?? this._nonInherited,
//       styles: styles ?? this.styles,
//     );
//   }
// }

class MyWidgetFactory extends WidgetFactory {
  MyWidgetFactory({
    required this.fetchState,
    // required this.codeBlockStyle,
  });

  // final MarkdownBodyCodeBlockStyle? codeBlockStyle;
  final HtmlWidgetState? Function() fetchState;

  @override
  void parse(final BuildTree meta) {
    meta
      ..wrapTaggedWidget(
        tag: 'code',
        newWidgetBuilder: (
          final BuildContext context,
          final Widget child,
          final BuildTree tree,
        ) {
          Future<void> onPress() async => showActionsMenu(
                <PullDownMenuEntry>[
                  PullDownMenuTitle(
                    title: Text(
                      tree.element.text,
                    ),
                  ),
                  PullDownMenuItem(
                    onTap: () => copyToClipboard(tree.element.text),
                    title: 'Copy',
                    icon: MdiIcons.contentCopy,
                  ),
                ],
                context,
              );
          return GestureDetector(
            onLongPress: onPress,
            onTap: onPress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceVariant,
                borderRadius: context.themeData
                    .extension<BorderRadiusTheme>()
                    ?.medBorderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      )
      ..wrapTaggedWidget(
        tag: 'a',
        newWidgetBuilder: (
          final BuildContext context,
          final Widget child,
          final BuildTree tree,
        ) {
          final String link = tree.element.attributes['href'] ?? '';
          print(link);
          if (link.startsWith('#')) {
            return InkPot(
              onTap: () async => fetchState()?.scrollToAnchor(
                link.replaceAll('#', ''),
              ),
              child: child,
            );
          }
          final URLActions urlActions = URLActions(
            uri: Uri.parse(link),
          );
          return InkPot(
            onTap: () async => urlActions.launchURL(),
            onLongPress: () async => urlActions.showMenu(context),
            child: child,
          );
        },
      )
      ..wrapTaggedWidget(
        tag: 'blockquote',
        newWidgetBuilder: (final BuildContext context, final Widget child,
                final BuildTree tree) =>
            DecoratedBox(
          decoration: BoxDecoration(
            // color: context.colorScheme.surface.,
            border: Border(
              left: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),

            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: child,
          ),
        ),
      );
    // ..wrapTaggedWidget(
    //   tag: 'img',
    //   newWidgetBuilder: (context, child, tree) => buildImageTag(
    //     tree.element,
    //     imgSrcModifiers: null,
    //   ),
    // );
    super.parse(meta);
  }
}

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

// List<HtmlExtension> markdownTagExtensionsTagExtensions(
//   final BuildContext context, {
//   required final List<MarkdownImgSrcModifiers>? imgSrcModifiers,
// }) =>
//     <HtmlExtension>[
//       ..._tagWrapExtensions(context),
//       ..._tagExtensions(
//         context,
//         imgSrcModifiers: imgSrcModifiers,
//       ),
//     ];

// List<TagExtension> _tagExtensions(
//   final BuildContext context, {
//   required final List<MarkdownImgSrcModifiers>? imgSrcModifiers,
// }) =>
//     <TagExtension>[
//       // _divExtension(context).extension,
//       // _imgExtension(
//       //   context,
//       //   imgSrcModifiers: imgSrcModifiers ?? <MarkdownImgSrcModifiers>[],
//       // ).extension,
//       // _preExtension(context).extension,
//       // _aExtension(context).extension,
//       // _codeExtension(context).extension,
//       // TagExtension(tagsToExtend: {'li'}, child: Placeholder()),
//     ];

// List<TagExtension> _tagWrapExtensions(final BuildContext context) =>
//     <TagExtension>[
//       TagExtension(
//         tagsToExtend: <String>{
//           'blockquote',
//         },
//         builder: (final ExtensionContext p0) => DecoratedBox(
//           // padding: const EdgeInsets.only(bottom: 40),

// child: Padding(
//   padding: const EdgeInsets.only(left: 4),
//   child: p0.child,
// ),
//         ),
//       ),
//       // TagExtension(
//       //   tagsToExtend: <String>{
//       //     'code',
//       //   },
//       //   builder: (final ExtensionContext child) => Padding(
//       //     padding: const EdgeInsets.symmetric(vertical: 1),
//       //     child: DecoratedBox(
//       //       decoration: BoxDecoration(
//       //         // color: context.palette.faded1,
//       //         borderRadius: smallBorderRadius,
//       //       ),
//       //       child: Padding(
//       //         padding: const EdgeInsets.symmetric(horizontal: 4),
//       //         child: child.child,
//       //       ),
//       //     ),
//       //   ),
//       // ),
//     ];

class CodeView extends StatefulWidget {
  const CodeView(
    this.data, {
    super.key,
    this.language,
    this.codeBlockStyle,
  });

  final String data;
  final String? language;
  final MarkdownBodyCodeBlockStyle? codeBlockStyle;

  @override
  _CodeViewState createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  bool wrapText = false;

  @override
  Widget build(final BuildContext context) {
    final Widget child = Padding(
      padding: const EdgeInsets.all(8),
      child: CodeBlockView(
        widget.data,
        language: widget.language,
      ),
    );

    return MenuInfoCard(
      title: widget.language ?? 'Code',
      elevation: widget.codeBlockStyle?.elevation,
      headerColor: widget.codeBlockStyle?.headerColor,
      leading: Container(
        decoration: BoxDecoration(
          color: Color(
            getLangColor(widget.language),
          ),
          shape: BoxShape.circle,
        ),
        height: 10,
        width: 10,
      ),
      menuBuilder: (final BuildContext context) => <PullDownMenuEntry>[
        PullDownMenuItem.selectable(
          onTap: () {
            setState(() {
              wrapText = !wrapText;
            });
          },
          selected: wrapText,
          title: 'Wrap',
          icon: MdiIcons.wrap,
        ),
        PullDownMenuActionsRow.medium(
          items: <PullDownMenuItem>[
            PullDownMenuItem(
              onTap: () async {
                await copyToClipboard(widget.data);
              },
              title: 'Copy',
              icon: MdiIcons.contentCopy,
            ),
            PullDownMenuItem(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (final BuildContext cxt) => SelectAndCopy(
                    widget.data,
                    // onQuote: widget.onQuote,
                  ),
                );
              },
              title: 'Select',
              icon: MdiIcons.cursorText,
            ),
          ],
        ),
      ],
      child: wrapText
          ? child
          : Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              ),
            ),
    );
  }
}

// abstract class _ExtensionWidget extends StatelessWidget {
//   const _ExtensionWidget(
//     this.extensionContext,
//   );
//
//   final ExtensionContext extensionContext;
//
//   String? get divClass => extensionContext.elementName;
//
//   LinkedHashMap<Object, String>? get attributes =>
//       extensionContext.element?.attributes;
//
//   Widget get defaultChild => extensionContext.child;
// }

class _MarkdownExtension {
  // _MarkdownExtension({
  //   required this.tag,
  //   this.child,
  //   this.builder,
  // }) : assert(
  //         (child != null) || (builder != null),
  //         'Either child or builder needs to be provided to TagExtension',
  //       );
  //
  // final String tag;
  // final Widget? child;
  // final _ExtensionWidget Function(ExtensionContext extensionContext)? builder;
  //
  // TagExtension get extension => TagExtension(
  //       tagsToExtend: <String>{
  //         tag,
  //       },
  //       builder: builder,
  //       child: child,
  //     );
}

// class FixedTagWrap extends TagWrapExtension {
//   FixedTagWrap({required super.tagsToWrap, required super.builder});
//
//   @override
//   InlineSpan build(ExtensionContext context) {
//     final child = CssBoxWidget.withInlineSpanChildren(
//       children: context.inlineSpanChildren!,
//       style: context.style!,
//     );
//
//     return child;
//   }
// }

