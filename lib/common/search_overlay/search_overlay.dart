import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/custom_expand_tile.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/overlay_menu_widget.dart';
import 'package:diohub/common/misc/user_search_dropdown.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/range_picker.dart';
import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/style/text_field_themes.dart';
import 'package:diohub/utils/string_compare.dart';
import 'package:diohub/utils/utils.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:intl/intl.dart';

@RoutePage()
class SearchOverlayScreen extends StatefulWidget {
  const SearchOverlayScreen(
    this.searchData, {
    required this.multiHero,
    required this.onSubmit,
    this.message,
    this.heroTag = 'search_bar',
    super.key,
  });

  final String? message;
  final ValueChanged<SearchData> onSubmit;
  final String heroTag;
  final SearchData searchData;
  final bool multiHero;

  @override
  SearchOverlayScreenState createState() => SearchOverlayScreenState();
}

class SearchOverlayScreenState extends State<SearchOverlayScreen> {
  late SearchData searchData;
  final OverlayController infoOverlay = OverlayController();

  @override
  void initState() {
    searchData = widget.searchData;
    if (searchData.searchFilters == null) {
      searchData =
          searchData.copyWith(searchFilters: SearchFilters.repositories());
    }
    super.initState();
  }

  bool get isEmpty =>
      searchData.query.trim().isEmpty && searchData.visibleStrings.isEmpty;

  bool get isValid {
    bool isValid = false;
    for (final String element in searchData.visibleStrings) {
      final SearchQuery query =
          searchData.searchFilters!.queryFromString(element.split(':').first)!;
      if (query.qualifierQuery) {
        isValid = true;
      }
    }
    int numberOfAndOrNot = 0;
    searchData.query.splitMapJoin(
      RegExp(
        '${SearchFilters.notOperatorRegExp.pattern}|${SearchFilters.andOperatorRegExp.pattern}|${SearchFilters.orOperatorRegExp.pattern}',
      ),
      onMatch: (final Match m) {
        numberOfAndOrNot++;
        return '';
      },
    );
    return (isValid || searchData.query.trim().isNotEmpty) &&
        numberOfAndOrNot <= 5;
  }

  SearchFilters getFilters(final SearchType type) {
    switch (type) {
      case SearchType.repositories:
        return SearchFilters.repositories();
      case SearchType.issuesPulls:
        return SearchFilters.issuesPulls();
      case SearchType.users:
        return SearchFilters.users();
    }
  }

  bool expanded = false;

  @override
  Widget build(final BuildContext context) => Portal(
        child: SafeArea(
          child: Scaffold(
            // backgroundColor:
            //     Provider.of<PaletteSettings>(context, listen: false)
            //         .currentSetting
            //         .primary,
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: _SearchBar(
                            searchData,
                            multiHero: widget.multiHero,
                            heroTag: widget.heroTag,
                            onSubmit: () {
                              if (isValid) {
                                Navigator.pop(context);
                                widget.onSubmit(searchData);
                              }
                            },
                            onChanged: (final SearchData data) {
                              setState(() {
                                searchData = data;
                              });
                            },
                            message: widget.message,
                          ),
                        ),
                      ),
                      if (widget.searchData.multiType)
                        const Divider(
                          height: 0,
                        ),
                      if (widget.searchData.multiType)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: CustomExpandTile(
                            title: Text(
                              'Searching in ${searchTypeValues.reverse![searchData.searchFilters!.searchType]}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                expanded = !expanded;
                              });
                            },
                            expanded: expanded,
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (
                                final BuildContext context,
                                final int index,
                              ) =>
                                  RadioListTile<SearchType>.adaptive(
                                // activeColor: Provider.of<PaletteSettings>(
                                //   context,
                                //   listen: false,
                                // ).currentSetting.accent,
                                groupValue:
                                    searchData.searchFilters!.searchType,
                                value:
                                    searchTypeValues.map.values.toList()[index],
                                onChanged: (final SearchType? value) {
                                  setState(() {
                                    searchData = searchData.copyWith(
                                      searchFilters: getFilters(
                                        searchTypeValues.map.values
                                            .toList()[index],
                                      ),
                                    );
                                    expanded = !expanded;
                                  });
                                },
                                title: Text(
                                  searchTypeValues.map.keys.toList()[index],
                                ),
                              ),
                              separatorBuilder: (
                                final BuildContext context,
                                final int index,
                              ) =>
                                  const Divider(),
                              itemCount: searchTypeValues.map.keys.length,
                            ),
                          ),
                        ),
                      const SizedBox(
                        height: 250,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: KeyboardVisibilityBuilder(
                    builder: (
                      final BuildContext context,
                      final bool isKeyboardVisible,
                    ) =>
                        OverlayMenuWidget(
                      controller: infoOverlay,
                      heightMultiplier: isKeyboardVisible ? 0.3 : 0.5,
                      childAnchor: Alignment.topCenter,
                      portalAnchor: Alignment.bottomCenter,
                      overlay: Card(
                        // color:
                        //     Provider.of<PaletteSettings>(context, listen: false)
                        //         .currentSetting
                        //         .secondary,
                        // borderRadius: medBorderRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ListView(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              children: <Widget>[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        'How to format your filters',
                                        style: context.textTheme.bodyLarge
                                            ?.asBold(),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text.rich(
                                        TextSpan(
                                          children: <InlineSpan>[
                                            TextSpan(
                                              text:
                                                  'Search filters should be in the format ',
                                            ),
                                            TextSpan(
                                              text: 'filter:data',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '.\n'),
                                            TextSpan(
                                              text:
                                                  'Example, label:enhancement will include all results with a label named enhancement.',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(),
                                      Text.rich(
                                        TextSpan(
                                          children: <InlineSpan>[
                                            TextSpan(text: 'Add a '),
                                            TextSpan(
                                              text: 'minus (-)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' before a search filter to exclude it from the results.\n',
                                            ),
                                            TextSpan(
                                              text:
                                                  'Example, -label:enhancement will exclude all results with a label named enhancement.',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(),
                                      Text.rich(
                                        TextSpan(
                                          children: <InlineSpan>[
                                            TextSpan(text: 'You can use '),
                                            TextSpan(
                                              text: 'AND, OR, NOT',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' operators in your query ',
                                            ),
                                            TextSpan(
                                              text:
                                                  '(upto a maximum of 5 times)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '.\n'),
                                            TextSpan(
                                              text:
                                                  'Example, "jquery NOT bootstrap" matches results that do contain the word "jquery" but not "bootstrap".',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(),
                                      Text.rich(
                                        TextSpan(
                                          children: <InlineSpan>[
                                            TextSpan(
                                              text:
                                                  'Data containing whitespaces must be wrapped in quotes like ',
                                            ),
                                            TextSpan(
                                              text: 'filter:"filter info"',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '.\n'),
                                            TextSpan(
                                              text:
                                                  'Example, label:"bug fix" will include all results with a label named bug fix.',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Material(
                                  elevation: 2,
                                  type: MaterialType.circle,
                                  color: context.colorScheme.surface,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: IconButton(
                                      iconSize: 20,
                                      onPressed: () {
                                        infoOverlay.tapped();
                                      },
                                      icon: const Icon(MdiIcons.information),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Hero(
                              tag: 'homeNavButton',
                              child: MaterialButton(
                                elevation: 2,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                // color: Provider.of<PaletteSettings>(
                                //   context,
                                //   listen: false,
                                // ).currentSetting.secondary,
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text('Back'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Hero(
                              tag: 'searchNavButton',
                              child: MaterialButton(
                                elevation: 2,
                                onPressed: isValid || isEmpty
                                    ? () {
                                        Navigator.pop(context);
                                        widget.onSubmit(searchData);
                                      }
                                    : null,
                                // color: Provider.of<PaletteSettings>(
                                //   context,
                                //   listen: false,
                                // ).currentSetting.secondary,
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text('Search'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SearchBar extends StatefulWidget {
  const _SearchBar(
    this.searchData, {
    required this.multiHero,
    required this.onChanged,
    required this.onSubmit,
    required this.heroTag,
    this.message,
  });

  final SearchData searchData;
  final String heroTag;
  final String? message;
  final ValueChanged<SearchData> onChanged;
  final VoidCallback onSubmit;
  final bool multiHero;

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  FocusNode searchNode = FocusNode();
  late TextEditingController controller;
  late SearchData searchData;
  OverlayController suggestionsOverlayController = OverlayController();
  Widget overlayWidget = Container();

  @override
  void initState() {
    searchData = widget.searchData;
    controller = TextEditingController(
      text: widget.searchData.toString().trim().isNotEmpty
          ? '${widget.searchData.toString().trim()} '
          : '',
    );
    unawaited(getFocus());
    searchNode.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant final _SearchBar oldWidget) {
    searchData = widget.searchData;
    super.didUpdateWidget(oldWidget);
  }

  bool expanded = false;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: <Widget>[
            OverlayMenuWidget(
              controller: suggestionsOverlayController,
              overlay: overlayWidget,
              child: Hero(
                tag: widget.multiHero
                    ? '${widget.heroTag}true'
                    : widget.heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: ExtendedTextField(
                    controller: controller,
                    maxLines: 10,
                    focusNode: searchNode,
                    minLines: 1,
                    onChanged: (final String pattern) {
                      // Handle cases for when the enter key is pressed.
                      if (pattern.contains('\n')) {
                        // Don't let {\n} enter the text.
                        controller.text = controller.text.replaceAll('\n', '');
                        // If the last char is not a space, enter a space.
                        if (!controller.text.endsWith(' ')) {
                          controller.text = '${controller.text} ';
                        } else {
                          _parseQuery(pattern);
                          widget.onSubmit();
                        }
                        // Move the text controller to end.
                        _moveControllerToEnd();
                      }
                      // Trim any white spaces.
                      if (pattern.trim().isEmpty) {
                        controller.text = controller.text.trim();
                      }
                      // Parse query for filters.
                      _parseQuery(pattern);
                      // Show suggestions to the user.
                      _suggestions(pattern);
                    },
                    specialTextSpanBuilder: _TextSpanBuilder(
                      widget.searchData.searchFilters!,
                      controller,
                      context: context,
                      onChanged: (final String string) {
                        controller.text = string;
                        _parseQuery(string);
                      },
                    ),
                    decoration: inputDecoration(
                      hintText: widget.message,
                      context: context,
                      labelText: 'Searching For',
                      focusNode: searchNode,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CustomExpandTile(
                title: const Text(
                  'All Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                expanded: expanded,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (final BuildContext context, final int index) =>
                      ListTile(
                    onTap: () {
                      addString(
                        '${widget.searchData.searchFilters!.whiteListedQueries[index].query}:',
                        addSpaceAtEnd: false,
                        spaceAtStart: true,
                      );
                      setState(() {
                        expanded = false;
                      });
                      searchNode.requestFocus();
                    },
                    title: Text(
                      widget.searchData.searchFilters!.whiteListedQueries[index]
                          .query,
                      // style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  separatorBuilder:
                      (final BuildContext context, final int index) =>
                          const Divider(),
                  itemCount: widget
                      .searchData.searchFilters!.whiteListedQueries.length,
                ),
              ),
            ),
            SizeExpandedSection(
              expand: controller.text.trim().isNotEmpty,
              child: Column(
                children: <Widget>[
                  const Divider(
                    height: 8,
                    endIndent: 8,
                    indent: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: MaterialButton(
                      // color:
                      //     Provider.of<PaletteSettings>(context, listen: false)
                      //         .currentSetting
                      //         .secondary,
                      onPressed: () {
                        setState(() {
                          controller.text = '';
                        });
                        widget.onChanged(searchData.cleared);
                      },
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Tap to Clear'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> getFocus() async {
    // TODO(namanshergill): Try new speed here.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        searchNode.requestFocus();
      });
    }
  }

  void addString(
    final String data, {
    final bool addSpaceAtEnd = true,
    final bool spaceAtStart = false,
    final bool addQuotesAtEnd = false,
    final bool addQuotesAround = false,
    final String remove = '',
  }) {
    // Remove the last [remove.length] numbers of chars.
    controller
      ..text =
          controller.text.substring(0, controller.text.length - remove.length)
      // Add new text according to the parameters.
      ..text =
          '${controller.text}${'${spaceAtStart ? ' ' : ''}${addQuotesAround ? '"' : ''}$data${addQuotesAround ? '"' : ''}${addSpaceAtEnd ? ' ' : ''}'}${addQuotesAtEnd ? '""' : ''}';
    // Move controller to end, or end-1 if quotes were added.
    _moveControllerToEnd(addQuotesAtEnd ? 1 : 0);
    searchNode.requestFocus();
    _parseQuery(controller.text);
    _suggestions(controller.text);
  }

  void _moveControllerToEnd([final int offset = 0]) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length - offset),
    );
  }

  // Is the end the same as the given string.
  bool isEndSame(final String initial, final String part) =>
      initial.substring(initial.length - part.length) == part;

  // Get all matches in a string from a certain Regexp.
  List<String> getMatches(final RegExp regexp, final String pattern) {
    final List<String> matches = <String>[];
    pattern.splitMapJoin(
      regexp,
      onMatch: (final Match m) {
        matches.add(m.group(0)!);
        return m.group(0)!;
      },
    );
    return matches;
  }

  // Show a list dropdown for suggestions.
  Widget list(
    final int length,
    final IndexedWidgetBuilder builder, {
    final Key? key,
  }) =>
      SizeExpandedSection(
        key: key,
        child: Card(
          // color: Provider.of<PaletteSettings>(context, listen: false)
          //     .currentSetting
          //     .secondary,
          // borderRadius: medBorderRadius,
          // elevation: 8,
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: builder,
            separatorBuilder: (final BuildContext context, final int index) =>
                const Divider(
              height: 0,
            ),
            itemCount: length,
          ),
        ),
      );

  void _showOverlay(final Widget widget) {
    setState(() {
      overlayWidget = widget;
      suggestionsOverlayController.open();
    });
  }

  void _closeOverlay() {
    setState(() {
      overlayWidget = Container();
      suggestionsOverlayController.close();
    });
  }

  /// Parses the query from the entered pattern.
  void _parseQuery(final String pattern) {
    // Copy the original pattern.
    String str = pattern;
    // Lists to store filter-related strings and corresponding filters.
    final List<String> filterStrings = <String>[];
    final List<SearchQuery> filters = <SearchQuery>[];

    // Handle case of number and date ranges with the bigger value before.
    str.splitMapJoin(
      widget.searchData.searchFilters!.allValidQueriesRegexp,
      onMatch: (final Match m) {
        // Extract the matched string.
        String string = m[0]!;

        // Check if it's a date query.
        if (widget.searchData.searchFilters!.dateQRegExp!.hasMatch(string)) {
          // Process the date query.
          string = m[0]!.splitMapJoin(
            widget.searchData.searchFilters!.dateQRegExp!,
            onMatch: (final Match m) {
              // Extract and format the date range.
              final String data = m[0]!.splitMapJoin(
                RegExp(
                  '((([12]\\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])))([.][.])(([12]\\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01]))))',
                ),
                onMatch: (final Match m) {
                  String date(final DateTime dateTime) =>
                      DateFormat('yyyy-MM-dd').format(dateTime);

                  final String data = m[0]!;
                  final DateTime one = DateTime.parse(data.split('..').first);
                  final DateTime two = DateTime.parse(data.split('..').last);
                  if (one.isAfter(two)) {
                    return '${date(two)}..${date(one)}';
                  }
                  return '${date(one)}..${date(two)}';
                },
              );
              return data;
            },
          );
        }
        // Check if it's a number query.
        else if (widget.searchData.searchFilters!.numberQRegExp!
            .hasMatch(string)) {
          // Process the number query.
          string = string.splitMapJoin(
            widget.searchData.searchFilters!.numberQRegExp!,
            onMatch: (final Match m) {
              // Extract and format the number range.
              final String data = m[0]!.splitMapJoin(
                RegExp('((([0-9]+))([.][.])(([0-9]+)))'),
                onMatch: (final Match m) {
                  final String data = m[0]!;
                  final int one = int.parse(data.split('..').first);
                  final int two = int.parse(data.split('..').last);
                  if (one > two) {
                    return '$two..$one';
                  }
                  return '$one..$two';
                },
              );
              return data;
            },
          );
        }

        // Add the filter-related strings and filters to the lists.
        filterStrings.add(string);
        filters.add(
          widget.searchData.searchFilters!
              .queryFromString(string.split(':').first)!,
        );

        // Return an empty string to replace the matched part.
        return '';
      },
    );

    // Remove all invalid queries from the string.
    str = str.replaceAll(
      widget.searchData.searchFilters!.allInvalidQueriesRegExp,
      '',
    );

    // Convert all extra spaces to just a single space.
    str = str.replaceAll(RegExp('(\\s+)'), ' ');

    // Send the new [SearchData] back.
    widget.onChanged(
      searchData.copyWith(
        query: str,
        filterStrings: filterStrings,
      ),
    );
  }

  /// Displays suggestions based on the entered pattern.
  void _suggestions(final String pattern) {
    // Close any previous overlays.
    _closeOverlay();

    // Check if the cursor is at the end of the text.
    if (controller.selection.baseOffset == controller.text.length) {
      // Get all valid and invalid queries in the entered pattern.
      final List<String> matches = getMatches(
        RegExp(
          '${widget.searchData.searchFilters!.allValidQueriesRegexp.pattern}|${widget.searchData.searchFilters!.allInvalidQueriesRegExp.pattern}',
        ),
        pattern,
      );

      // Variables to store information about the current typed data and query.
      String typedData = '';
      SearchQuery? query;

      // Check if any of the matches are the query currently being typed.
      for (final String element in matches) {
        if (isEndSame(pattern, element)) {
          // Extract typed data and query information.
          typedData = element.substring(0).split(':')[1];
          String queryString = element.split(':').first;
          if (queryString.startsWith('-')) {
            queryString = queryString.substring(1);
          }
          query = widget.searchData.searchFilters!.queryFromString(queryString);
        }
      }

      // Get all completed valid queries.
      final List<String?> completedQueries = getMatches(
        RegExp(
          '${widget.searchData.searchFilters!.validSensitiveQueriesRegExp.pattern}|${widget.searchData.searchFilters!.invalidSensitiveQueriesRegExp.pattern}|${widget.searchData.searchFilters!.validBasicQueriesRegExp.pattern}',
        ),
        pattern,
      );

      // Check if the last query has been completed.
      final bool isLastQueryComplete = completedQueries.isNotEmpty &&
          isEndSame(pattern, completedQueries.last!);

      // Show filter suggestions if the last filter was not complete.
      if (!isLastQueryComplete) {
        final List<String> filteredOptions = <String>[];

        // Last filter being typed.
        typedData = pattern.split(' ').last;

        // Remove the '-' from the case.
        if (typedData.startsWith('-')) {
          typedData = typedData.substring(1);
        }

        if (typedData.isNotEmpty) {
          // Filter options based on the typed data.
          for (final String element
              in widget.searchData.searchFilters!.whiteListedQueriesStrings) {
            if (element.startsWith(typedData)) {
              filteredOptions.add(element);
            }
          }

          // Show overlay with the filtered options.
          _showOverlay(
            list(
              filteredOptions.length,
              (final BuildContext context, final int index) => ListTile(
                onTap: () {
                  // Get query info from the string.
                  final SearchQuery query = widget.searchData.searchFilters!
                      .queryFromString(filteredOptions[index])!;

                  // Add string to text on tap, with quotes at the end if it is
                  // a spaced string with no auto-complete options.
                  addString(
                    '${filteredOptions[index]}:',
                    addQuotesAtEnd: query.options == null &&
                        query.type == QueryType.spacedString,
                    addSpaceAtEnd: false,
                    remove: typedData,
                  );
                },
                title: Text(
                  filteredOptions[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              key: ValueKey<String>(typedData),
            ),
          );
        }
      } else if ((query?.type == QueryType.number ||
              query?.type == QueryType.date) &&
          (typedData.isEmpty)) {
        // Show overlay for number or date range picker.
        _showOverlay(RangePicker(onAdded: addString, queryType: query!.type));
      } else if ((query?.type == QueryType.user ||
              query?.type == QueryType.org) &&
          !typedData.endsWith(' ')) {
        // Show overlay for user or organization search dropdown.
        _showOverlay(
          SizeExpandedSection(
            child: UserSearchDropdown(
              typedData,
              onSelected: (final String data) {
                addString(data, remove: typedData);
              },
              type: query!.type,
            ),
          ),
        );
      } else if (query?.options?.keys != null) {
        // Show overlay with filtered options based on the typed data.
        final List<String> filteredOptions = <String>[];
        query!.options?.keys.toList().forEach(
          (final String element) {
            if (element.startsWith(typedData)) {
              filteredOptions.add(element);
            }
          },
        );
        _showOverlay(
          list(
            filteredOptions.length,
            (final BuildContext context, final int index) => ListTile(
              onTap: () {
                addString(
                  filteredOptions[index],
                  remove: typedData,
                );
              },
              title: Text(filteredOptions[index]),
            ),
            key: ValueKey<String>(typedData),
          ),
        );
      }
    }
  }
}

class _TextSpanBuilder extends SpecialTextSpanBuilder {
  _TextSpanBuilder(
    this.searchFilters,
    this.controller, {
    required this.onChanged,
    required this.context,
  })  : patternMap = <RegExp, TextStyle>{
          searchFilters.validSensitiveQueriesRegExp: TextStyle(
            color: context.colorScheme.onPrimary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          searchFilters.validBasicQueriesRegExp: TextStyle(
            color: context.colorScheme.onPrimary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
        },
        blacklistPatternMap = <RegExp, TextStyle>{
          searchFilters.invalidSensitiveQueriesRegExp: TextStyle(
            color: context.colorScheme.onSurface,
            decoration: TextDecoration.combine(
              <TextDecoration>[TextDecoration.lineThrough],
            ),
          ),
          searchFilters.invalidBasicQueriesRegExp: TextStyle(
            color: context.colorScheme.onSurface,
            decoration: TextDecoration.combine(
              <TextDecoration>[TextDecoration.lineThrough],
            ),
          ),
          searchFilters.blacklistRegExp: TextStyle(
            color: context.colorScheme.error,
            decoration: TextDecoration.combine(
              <TextDecoration>[TextDecoration.lineThrough],
            ),
          ),
        };
  final BuildContext context;
  final SearchFilters searchFilters;
  final Map<RegExp, TextStyle> patternMap;
  final Map<RegExp, TextStyle> blacklistPatternMap;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  TextSpan build(
    final String data, {
    final TextStyle? textStyle,
    final SpecialTextGestureTapCallback? onTap,
  }) {
    if (data == '') {
      return const TextSpan(text: '');
    }
    final List<InlineSpan> inlineList = <InlineSpan>[];
    if (data.isNotEmpty) {
      data.splitMapJoin(
        RegExp(
          searchFilters.allValidQueriesRegexp.pattern,
        ),
        onMatch: (final Match m) {
          inlineList.add(
            _ValidQuery(
              m[0]!,
              controller,
              textStyle,
              context: context,
              onChanged: onChanged,
            ).finishText(),
          );
          return '';
        },
        onNonMatch: (final String string) {
          string.splitMapJoin(
            RegExp(
              '${SearchFilters.notOperatorRegExp.pattern}|${SearchFilters.andOperatorRegExp.pattern}|${SearchFilters.orOperatorRegExp.pattern}',
            ),
            onMatch: (final Match m) {
              TextStyle baseTextStyle = textStyle!;
              if (SearchFilters.notOperatorRegExp.hasMatch(m[0]!)) {
                baseTextStyle = baseTextStyle.copyWith(
                  color: context.colorScheme.error,
                );
              } else if (SearchFilters.orOperatorRegExp.hasMatch(m[0]!)) {
                baseTextStyle = baseTextStyle.copyWith(
                  color: context.colorScheme.secondary,
                );
              } else if (SearchFilters.andOperatorRegExp.hasMatch(m[0]!)) {
                baseTextStyle = baseTextStyle.copyWith(
                  color: context.colorScheme.primary,
                );
              }
              inlineList.add(
                getSpan(
                  m[0]!,
                  baseTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              );
              return '';
            },
            onNonMatch: (final String string) {
              inlineList.add(getSpan(string, textStyle));
              return '';
            },
          );
          return '';
        },
      );
    } else {
      inlineList.add(TextSpan(text: data, style: textStyle));
    }
    return TextSpan(children: inlineList, style: textStyle);
  }

  TextSpan getSpan(final String text, final TextStyle? style) {
    final List<TextSpan> children = <TextSpan>[];
    final List<String> matches = <String>[];
    RegExp? allRegex;
    final String wlRegex =
        patternMap.keys.map((final RegExp e) => e.pattern).join('|');
    final String blRegex =
        blacklistPatternMap.keys.map((final RegExp e) => e.pattern).join('|');
    final Map<RegExp, TextStyle> combinedMap = <RegExp, TextStyle>{}
      ..addAll(patternMap)
      ..addAll(blacklistPatternMap);
    allRegex = RegExp('$wlRegex|$blRegex');
    text.splitMapJoin(
      allRegex,
      onMatch: (final Match m) {
        if (!matches.contains(m[0])) {
          matches.add(m[0]!);
        }
        final RegExp k = combinedMap.entries
            .firstWhere(
              (final MapEntry<RegExp, TextStyle> element) =>
                  element.key.allMatches(m[0]!).isNotEmpty,
            )
            .key;
        children.add(
          TextSpan(
            text: m[0],
            style: combinedMap[k],
          ),
        );
        return '';
      },
      onNonMatch: (final String span) {
        children.add(TextSpan(text: span, style: style));
        return span;
      },
    );
    return TextSpan(style: style, children: children);
  }

  @override
  SpecialText? createSpecialText(
    final String flag, {
    required final int index,
    final TextStyle? textStyle,
    final SpecialTextGestureTapCallback? onTap,
  }) =>
      null;
}

class _ValidQuery extends SpecialText {
  _ValidQuery(
    final String startFlag,
    this.controller,
    final TextStyle? textStyle, {
    required this.onChanged,
    required this.context,
  }) : super(
          startFlag,
          '',
          textStyle ?? const TextStyle(),
        );
  final BuildContext context;

  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  @override
  InlineSpan finishText() => ExtendedWidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Material(
          borderRadius: context.themeData.borderRadiusTheme?.medBorderRadius,
          color: toString().startsWith('-')
              ? context.colorScheme.error
              : context.colorScheme.primary,
          child: InkPot(
            onTap: () async {
              if (!toString().trim().startsWith('-')) {
                onChanged(
                  controller.text.replaceFirst(
                    RegExp('(?!-)(?:(${toString().trim()}))'),
                    '',
                  ),
                );
              } else {
                onChanged(controller.text.replaceFirst(toString().trim(), ''));
              }

              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              if (controller.text.trim().isEmpty) {
                onChanged(controller.text.trim());
              }
              await HapticFeedback.vibrate();
            },
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 4, left: 6, right: 6, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text:
                                '${toString().trim().replaceAll('"', '').split(':').first} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: toString()
                                .trim()
                                .replaceAll('"', '')
                                .split(':')
                                .last,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  ClipOval(
                    child: ColoredBox(
                      color: context.colorScheme.onPrimary,
                      child: Icon(
                        Icons.close_rounded,
                        color: toString().startsWith('-')
                            ? context.colorScheme.error
                            : context.colorScheme.primary,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actualText: toString(),
        deleteAll: false,
      );
}

class SearchData {
  SearchData({
    this.query = '',
    this.quickFilters = const <String>[],
    this.filterStrings = const <String>[],
    this.searchFilters,
    this.sort = 'best',
    final bool multiType = false,
    final List<String> defaultHiddenFilters = const <String>[],
  })  : _defaultFilters = defaultHiddenFilters,
        multiType = searchFilters == null || multiType;

  /// Current query info without filters.
  final String query;

  /// List of all applied filters.
  final List<String> filterStrings;

  /// Info about the kind of [SearchFilters] this data associates with.
  final SearchFilters? searchFilters;

  /// Default filters that will be applied to the query without being visible.
  final List<String> _defaultFilters;

  /// Quick filters to show on the search bar.
  final List<String> quickFilters;

  /// Multi type query for universal search bars.
  final bool multiType;

  /// Current sort setting, defaults to 'best', which returns null on being queried.
  final String sort;

  /// Return string of the query without the default filters.
  @override
  String toString() => '${query.trim()} ${filterStrings.join(' ').trim()} ';

  /// Return string of the query with the default filters.
  String get toQuery =>
      '${query.trim()} ${_defaultFilters.join(' ').trim()} ${filterStrings.join(' ').trim()}';

  /// Get current sort setting. Returns null if it is "best".
  String? get getSort => sort != 'best' ? sort.split('-').first : null;

  /// Is sort setting ascending.
  bool? get isSortAsc => sort != 'best' ? sort.split('-').last == 'asc' : null;

  /// If search is active, i.e., [toString()] is not empty.
  bool get isActive => toString().trim().isNotEmpty;

  /// All current filter strings.
  List<String> get visibleStrings => filterStrings;

  /// Get if a quick filter is currently in the filters.
  String? get activeQuickFilter {
    final List<String> active = <String>[];
    for (final String element in filterStrings) {
      // print(filterStrings);
      // print(quickFilters);
      for (final String e in quickFilters) {
        // print(e.toString() + 'kjsdbnhj');
        // print(element);
        if (StringFunctions(e).isStringEqual(element)) {
          active.add(element);
        }
      }
    }
    // print(active);
    // Return null if more than one.
    if (active.length == 1) {
      return active.first;
    }
    return null;
  }

  /// If current query is valid.
  bool get isValid => toQuery.trim().isNotEmpty;

  /// Clear all search related data.
  SearchData get cleared => copyWith(
        query: '',
        filterStrings: <String>[],
        sort: 'best',
        searchFilters: multiType ? null : searchFilters,
      );

  /// Replace the quick filters in all the filters and add a new one.
  List<String> _quickFilterChange(
    final String quickFilter,
    final List<String> allFilters,
  ) {
    final List<String> filters = allFilters.toList();
    return filters
      ..removeWhere((final String element) {
        bool exists = false;
        for (final String e in quickFilters) {
          if (StringFunctions(e).isStringEqual(element)) {
            exists = true;
          }
        }
        return exists;
      })
      ..add(quickFilter);
  }

  /// Copy search data with custom data.
  SearchData copyWith({
    final String? query,
    final List<String>? filterStrings,
    final List<String>? quickFilters,
    final String? quickFilter,
    final SearchFilters? searchFilters,
    final String? sort,
  }) {
    List<String> filters = filterStrings ?? this.filterStrings;
    // If a new quick filter is supplied, replace all current ones in the filters.
    if (quickFilter != null) {
      filters = _quickFilterChange(quickFilter, filters);
    }
    return SearchData(
      query: query ?? this.query,
      filterStrings: filters,
      defaultHiddenFilters: _defaultFilters,
      multiType: multiType,
      quickFilters: quickFilters ?? this.quickFilters,
      sort: sort ?? this.sort,
      searchFilters: searchFilters ?? this.searchFilters,
    );
  }
}
