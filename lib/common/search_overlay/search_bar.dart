import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/string_compare.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    required this.onSubmit,
    required this.heroTag,
    this.message,
    final String? prompt,
    this.quickOptions,
    this.searchData,
    this.trailing,
    this.quickFilters,
    this.updateBarOnChange = true,
    this.isPinned = false,
    this.onSortChanged,
    this.backgroundColor,
    super.key,
  }) : _prompt = prompt ?? 'Search or Jump to...';
  final String? message;
  final String _prompt;
  final SearchData? searchData;
  final bool updateBarOnChange;
  final ValueChanged<SearchData> onSubmit;
  final Color? backgroundColor;
  final String heroTag;
  final Map<String, String>? quickFilters;
  final Map<String, String>? quickOptions;
  final ValueChanged<String>? onSortChanged;
  final bool isPinned;
  final Widget? trailing;

  @override
  AppSearchBarState createState() => AppSearchBarState();
}

class AppSearchBarState extends State<AppSearchBar> {
  SearchData? searchData;

  @override
  void initState() {
    searchData = widget.searchData;
    if (searchData?.searchFilters != null && widget.quickFilters != null) {
      quickActionsAnim = true;
    }
    if (widget.quickFilters != null) {
      searchData = searchData?.copyWith(
        quickFilters: widget.quickFilters?.keys.toList(),
      );
    }
    quickActionsVisible = widget.quickOptions == null;
    super.initState();
  }

  Map<String, String> getWithoutValue(
    final String? exclude,
    final Map<String, String> map,
  ) {
    final Map<String, String> tMap = <String, String>{};
    map.forEach((final String key, final String value) {
      if (key != exclude) {
        tMap.addAll(<String, String>{key: value});
      }
    });
    return tMap;
  }

  String getQuickFilterTitle(
    final Map<String, String> qFilters,
    final String? activeFilter,
  ) {
    String qFilter = 'Quick Filters';

    qFilters.forEach((final String key, final String value) {
      if (StringFunctions(key).isStringEqual(activeFilter)) {
        qFilter = qFilters[key]!;
      }
    });
    return qFilter;
  }

  void changeSortExpanded({final bool? expand}) {
    if (expand != null) {
      setState(() {
        sortExpanded = expand;
      });
    } else {
      setState(() {
        sortExpanded = !sortExpanded;
      });
    }
  }

  void changeQuickFiltersExpanded({final bool? expand}) {
    if (expand != null) {
      setState(() {
        quickFiltersExpanded = expand;
      });
    } else {
      setState(() {
        quickFiltersExpanded = !quickFiltersExpanded;
      });
    }
  }

  @override
  void didUpdateWidget(final AppSearchBar oldWidget) {
    searchData = widget.searchData;
    super.didUpdateWidget(oldWidget);
  }

  bool quickActionsAnim = false;
  late bool quickActionsVisible;
  bool sortExpanded = false;
  bool quickFiltersExpanded = false;

  @override
  Widget build(final BuildContext context) {
    final bool hasActiveSearch =
        searchData != null && (searchData?.isActive ?? false);
    final bool hasFilters =
        (searchData?.searchFilters != null || widget.quickFilters != null) &&
            !widget.isPinned;

    return Material(
      elevation: 0,
      color: widget.backgroundColor != null &&
              widget.backgroundColor == context.colorScheme.background
          ? context.colorScheme.surfaceContainerLow
          : (widget.backgroundColor ?? context.colorScheme.surfaceContainerLow),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Search input area
          InkPot(
            onTap: () async {
              await AutoRouter.of(context).push(
                SearchOverlayRoute(
                  message: widget.message,
                  multiHero: widget.updateBarOnChange,
                  searchData: searchData != null ? searchData! : SearchData(),
                  heroTag: widget.heroTag,
                  onSubmit: (final SearchData data) {
                    if (widget.updateBarOnChange) {
                      setState(() {
                        searchData = data;
                      });
                    }
                    widget.onSubmit(data);
                  },
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Inactive search state
                SizeExpandedSection(
                  expand: !hasActiveSearch,
                  child: Hero(
                    tag: widget.updateBarOnChange
                        ? '${widget.heroTag}false'
                        : widget.heroTag,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget._prompt,
                              style: context.textTheme.bodyMedium?.asHint(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Active search state
                if (hasActiveSearch)
                  SizeExpandedSection(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Hero(
                        tag: '${widget.heroTag}true',
                        child: _ActiveSearch(
                          searchData: searchData!,
                          trailing: widget.trailing,
                          onSubmit: (final SearchData data) {
                            setState(() {
                              searchData = data;
                            });
                            widget.onSubmit(searchData!);
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Filter controls section
          if (hasFilters) _buildFilterControls(context),
        ],
      ),
    );
  }

  Widget _buildFilterControls(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(
            height: 1,
            thickness: 1,
            color: context.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          SizeSwitch(
            visible: quickActionsVisible,
            replacement: _buildCollapsedFilters(context),
            child: _buildExpandedFilters(context),
          ),
        ],
      );

  Widget _buildCollapsedFilters(final BuildContext context) => InkWell(
        onTap: () {
          setState(() {
            quickActionsVisible = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.colorScheme.onSurfaceVariant.asHint(),
              ),
            ],
          ),
        ),
      );

  Widget _buildExpandedFilters(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sort and Quick Filter buttons row
            Row(
              children: <Widget>[
                if (searchData?.searchFilters != null)
                  Expanded(
                    child: _buildFilterButton(
                      context,
                      icon: Icons.sort_rounded,
                      label: searchData!
                              .searchFilters!.sortOptions[searchData!.sort] ??
                          'Best Match',
                      isActive: sortExpanded,
                      onTap: () => changeSortExpanded(),
                    ),
                  ),
                if (searchData?.searchFilters != null &&
                    widget.quickFilters != null)
                  const SizedBox(width: 8),
                if (widget.quickFilters != null)
                  Expanded(
                    child: _buildFilterButton(
                      context,
                      icon: Icons.filter_list_rounded,
                      label: searchData?.activeQuickFilter != null
                          ? getQuickFilterTitle(
                              widget.quickFilters!,
                              searchData!.activeQuickFilter,
                            )
                          : 'Quick Filters',
                      isActive: quickFiltersExpanded ||
                          searchData?.activeQuickFilter != null,
                      onTap: () => changeQuickFiltersExpanded(),
                    ),
                  ),
              ],
            ),
            // Sort options dropdown
            if (searchData?.searchFilters != null)
              SizeExpandedSection(
                expand: sortExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _buildSortOptions(context),
                ),
              ),
            // Quick filter options dropdown
            if (widget.quickFilters != null)
              SizeExpandedSection(
                expand: quickFiltersExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _buildQuickFilterOptions(context),
                ),
              ),
            // Quick options checkboxes
            if (widget.quickOptions != null)
              SizeExpandedSection(
                expand: !quickFiltersExpanded && !sortExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _buildQuickOptions(context),
                ),
              ),
          ],
        ),
      );

  Widget _buildFilterButton(
    final BuildContext context, {
    required final IconData icon,
    required final String label,
    required final bool isActive,
    required final VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? context.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? null
                : Border.all(
                    color: context.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isActive
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.primary,
              ),
            ],
          ),
        ),
      );

  Widget _buildSortOptions(final BuildContext context) => Material(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ...getWithoutValue(
              searchData!.sort,
              widget.searchData!.searchFilters!.sortOptions,
            ).entries.map((final MapEntry<String, String> entry) {
              final bool isSelected = entry.key == searchData!.sort;
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                selected: isSelected,
                selectedTileColor: context.colorScheme.primary,
                title: Text(
                  entry.value,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: context.colorScheme.onPrimary,
                      )
                    : null,
                onTap: () {
                  changeSortExpanded(expand: false);
                  setState(() {
                    searchData = searchData!.copyWith(sort: entry.key);
                  });
                  widget.onSubmit(searchData!);
                },
              );
            }),
          ],
        ),
      );

  Widget _buildQuickFilterOptions(final BuildContext context) => Material(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Show currently selected filter first
            if (searchData!.activeQuickFilter != null)
              ...widget.quickFilters!.entries
                  .where((final MapEntry entry) =>
                      StringFunctions(entry.key as String)
                          .isStringEqual(searchData!.activeQuickFilter))
                  .map((final MapEntry<String, String> entry) {
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  selected: true,
                  selectedTileColor: context.colorScheme.primary,
                  title: Text(
                    entry.value,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: context.colorScheme.onPrimary,
                  ),
                  onTap: () {
                    changeQuickFiltersExpanded(expand: false);
                  },
                );
              }),
            // Show other options
            ...getWithoutValue(
              searchData!.activeQuickFilter,
              widget.quickFilters!,
            ).entries.map((final MapEntry<String, String> entry) {
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                selected: false,
                title: Text(
                  entry.value,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () {
                  changeQuickFiltersExpanded(expand: false);
                  setState(() {
                    searchData = searchData!.copyWith(quickFilter: entry.key);
                  });
                  widget.onSubmit(searchData!);
                },
              );
            }),
          ],
        ),
      );

  Widget _buildQuickOptions(final BuildContext context) => Material(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ...widget.quickOptions!.entries.map((final MapEntry entry) {
              final bool isSelected =
                  searchData!.filterStrings.contains(entry.key);
              return CheckboxListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                selected: isSelected,
                selectedTileColor: isSelected
                    ? context.colorScheme.primary.withOpacity(0.1)
                    : null,
                title: Text(
                  entry.value,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                value: isSelected,
                activeColor: context.colorScheme.primary,
                onChanged: (final bool? value) {
                  final List<String> filters =
                      searchData!.visibleStrings.toList();
                  if (value!) {
                    filters.add(entry.key);
                  } else {
                    filters.remove(entry.key);
                  }
                  setState(() {
                    searchData = searchData!.copyWith(filterStrings: filters);
                  });
                  widget.onSubmit(searchData!);
                },
              );
            }),
          ],
        ),
      );
}

class _ActiveSearch extends StatelessWidget {
  const _ActiveSearch({
    required this.searchData,
    required this.onSubmit,
    this.trailing,
  });

  final SearchData searchData;
  final Widget? trailing;
  final ValueChanged<SearchData> onSubmit;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Search query display
                    if (searchData.query.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: context.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                searchData.query.trim(),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Active filters as chips
                    if (searchData.visibleStrings.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List<Widget>.generate(
                          searchData.visibleStrings.length,
                          (final int index) {
                            final String filterString =
                                searchData.visibleStrings[index];
                            final String key = filterString
                                .trim()
                                .replaceAll('"', '')
                                .split(':')
                                .first;
                            final String value = filterString
                                .trim()
                                .replaceAll('"', '')
                                .split(':')
                                .last;

                            return _FilterChip(
                              label: key,
                              value: value,
                              onRemove: () {
                                final List<String> newFilters =
                                    List<String>.from(
                                  searchData.visibleStrings,
                                );
                                newFilters.removeAt(index);
                                onSubmit(
                                  searchData.copyWith(
                                    filterStrings: newFilters,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      onSubmit(searchData.cleared);
                    },
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
            ],
          ),
        ],
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onRemove,
  });

  final String label;
  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) => InputChip(
        label: Text.rich(
          TextSpan(
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onPrimary,
            ),
            children: <InlineSpan>[
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
        onDeleted: onRemove,
        deleteIcon: Icon(
          Icons.close_rounded,
          size: 16,
          color: context.colorScheme.onPrimary,
        ),
        backgroundColor: context.colorScheme.primary,
        selectedColor: context.colorScheme.primary,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
}
