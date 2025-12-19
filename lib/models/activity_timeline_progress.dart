import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';

/// Sealed class representing the state of activity timeline loading
sealed class ActivityTimelineState {}

/// Loading state with progress information
class ActivityTimelineLoading extends ActivityTimelineState {
  final String phase;
  final int current;
  final int total;
  final String message;
  final int eventCount;

  ActivityTimelineLoading({
    required this.phase,
    required this.current,
    required this.total,
    required this.message,
    this.eventCount = 0,
  });

  double get progress => total > 0 ? current / total : 0.0;
}

/// Success state with timeline data
class ActivityTimelineSuccess extends ActivityTimelineState {
  final UserActivityTimelineData data;

  ActivityTimelineSuccess(this.data);
}

/// Error state
class ActivityTimelineError extends ActivityTimelineState {
  final String message;
  final Object error;
  final StackTrace? stackTrace;

  ActivityTimelineError({
    required this.message,
    required this.error,
    this.stackTrace,
  });
}

