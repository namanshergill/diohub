import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/models/activity_timeline_progress.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_activity_timeline_provider.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section widget that displays user activity timeline grouped by month
class ActivityTimelineSection extends ConsumerWidget {
  const ActivityTimelineSection({
    required this.userName,
    required this.selectedYear,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    super.key,
  });

  final String userName;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;

  /// Builds typed provider key (same format as userContributionsProvider)
  ContributionQueryKey _getProviderKey() {
    if (useCustomRange && customFromDate != null && customToDate != null) {
      final from = DateTime(
        customFromDate!.year,
        customFromDate!.month,
        customFromDate!.day,
      );
      final to = DateTime(
        customToDate!.year,
        customToDate!.month,
        customToDate!.day,
      );
      return ContributionQueryKey.customRange(
        userName: userName,
        from: from,
        to: to,
      );
    }

    if (selectedYear == null) {
      return ContributionQueryKey.lastYear(userName);
    } else {
      return ContributionQueryKey.year(userName, selectedYear!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = _getProviderKey();
    final timelineAsync = ref.watch(userActivityTimelineProvider(providerKey));

    return timelineAsync.when(
      data: (state) {
        // Handle different states
        if (state is ActivityTimelineLoading) {
          return SliverToBoxAdapter(
            child: ActivityTimelineSectionProgress(
              phase: state.phase,
              current: state.current,
              total: state.total,
              message: state.message,
              progress: state.progress,
              eventCount: state.eventCount,
            ),
          );
        } else if (state is ActivityTimelineSuccess) {
          if (state.data.events.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return _buildTimelineContent(context, state.data);
        } else if (state is ActivityTimelineError) {
          return _buildErrorSliver(context, state, ref, providerKey);
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
      loading: () => const SliverToBoxAdapter(
        child: ActivityTimelineSectionLoading(),
      ),
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading activity timeline: $error');
          debugPrint('Stack trace: $stackTrace');
        }
        return _buildErrorSliver(
          context,
          ActivityTimelineError(message: error.toString(), error: error),
          ref,
          providerKey,
        );
      },
    );
  }

  Widget _buildTimelineContent(
    BuildContext context,
    UserActivityTimelineData timelineData,
  ) {
    // Use the flat events list directly - it's already sorted and has flags set
    final events = timelineData.events;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final eventWithFlags = events[index];
            final event = eventWithFlags.event;
            final isLast = index == events.length - 1;

            // Handle empty months
            if (eventWithFlags.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthHeader(
                    context,
                    eventWithFlags.monthHeader!.year,
                    eventWithFlags.monthHeader!.month,
                  ),
                  const SizedBox(height: 12),
                  _buildNoActivityPlaceholder(context),
                  if (!isLast) const SizedBox(height: 20),
                ],
              );
            }

            // Check if we need spacing after this event (between months)
            final needsSpacing = !isLast &&
                event != null &&
                events[index + 1].event != null &&
                _needsSpacingAfter(event, events[index + 1].event!);

            Widget item;

            // If event has monthHeader, render header + event together
            if (eventWithFlags.monthHeader != null) {
              item = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthHeader(
                    context,
                    eventWithFlags.monthHeader!.year,
                    eventWithFlags.monthHeader!.month,
                  ),
                  const SizedBox(height: 12),
                  ActivityTimelineItem(
                    event: event!,
                    userLogin: userName,
                    userAvatarUrl: null, // TODO: Get from userData if available
                    isFirst: eventWithFlags.isFirst,
                    isLast: eventWithFlags.isLast,
                  ),
                  if (needsSpacing) const SizedBox(height: 20),
                ],
              );
            } else {
              // Regular event
              item = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ActivityTimelineItem(
                    event: event!,
                    userLogin: userName,
                    userAvatarUrl: null, // TODO: Get from userData if available
                    isFirst: eventWithFlags.isFirst,
                    isLast: eventWithFlags.isLast,
                  ),
                  if (needsSpacing) const SizedBox(height: 20),
                ],
              );
            }

            // Wrap item with staggered animation
            return _StaggeredTimelineItem(
              index: index,
              child: item,
            );
          },
          childCount: events.length,
        ),
      ),
    );
  }

  /// Check if we need spacing between this event and the next one
  bool _needsSpacingAfter(
    ActivityTimelineEvent current,
    ActivityTimelineEvent next,
  ) {
    // Need spacing if we're moving to a different month/year
    return current.date.year != next.date.year ||
        current.date.month != next.date.month;
  }

  /// Build placeholder widget for months with no activity
  Widget _buildNoActivityPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 40), // Align with timeline items
      child: Text(
        'No activity',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, int year, int month) {
    final theme = Theme.of(context);
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${monthNames[month - 1]} $year',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildErrorSliver(
    BuildContext context,
    ActivityTimelineError errorState,
    WidgetRef ref,
    ContributionQueryKey providerKey,
  ) {
    return SliverToBoxAdapter(
      child: _buildErrorWidget(context, errorState, ref, providerKey),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    ActivityTimelineError errorState,
    WidgetRef ref,
    ContributionQueryKey providerKey,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorState.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (kDebugMode && errorState.stackTrace != null) ...[
            const SizedBox(height: 8),
            Text(
              errorState.stackTrace.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Button(
            onTap: () {
              ref.invalidate(userActivityTimelineProvider(providerKey));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Progress widget showing loading bar and status
class ActivityTimelineSectionProgress extends StatefulWidget {
  const ActivityTimelineSectionProgress({
    required this.phase,
    required this.current,
    required this.total,
    required this.message,
    required this.progress,
    required this.eventCount,
    super.key,
  });

  final String phase;
  final int current;
  final int total;
  final String message;
  final double progress;
  final int eventCount;

  @override
  State<ActivityTimelineSectionProgress> createState() =>
      _ActivityTimelineSectionProgressState();
}

class _ActivityTimelineSectionProgressState
    extends State<ActivityTimelineSectionProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _previousProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ActivityTimelineSectionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Large circular progress with centered percentage
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: _animation.value,
                          strokeWidth: 6,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final percentage = (_animation.value * 100).round();
                      return Text(
                        '$percentage%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Title and subtitle column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.eventCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.eventCount} event${widget.eventCount == 1 ? '' : 's'} fetched',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state for activity timeline section
class ActivityTimelineSectionLoading extends StatelessWidget {
  const ActivityTimelineSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.container(
              height: 60,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget that provides staggered fade and slide animation for timeline items
class _StaggeredTimelineItem extends StatefulWidget {
  const _StaggeredTimelineItem({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_StaggeredTimelineItem> createState() => _StaggeredTimelineItemState();
}

class _StaggeredTimelineItemState extends State<_StaggeredTimelineItem>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Stagger delay: 30ms per item, max delay of 300ms
  static const _baseDelay = 30;
  static const _maxDelay = 300;
  static const _animationDuration = Duration(milliseconds: 400);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation after staggered delay
    // With AutomaticKeepAliveClientMixin, initState only runs once,
    // so animation won't restart when scrolling back up
    final delay = Duration(
      milliseconds: (_baseDelay * widget.index).clamp(0, _maxDelay),
    );
    Future.delayed(delay, () {
      if (mounted && _controller.status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
