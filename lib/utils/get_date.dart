import 'package:intl/intl.dart';

String getDate(final String date, {final bool shorten = true}) {
  final DateTime dateTime = DateTime.parse(date);
  final DateTime now = DateTime.now();
  final Duration difference = now.difference(dateTime);

  // Handle future dates (shouldn't happen but just in case)
  if (difference.isNegative) {
    return shorten
        ? DateFormat('d MMM yy').format(dateTime)
        : DateFormat('MMM d, yyyy').format(dateTime);
  }

  // Very recent (less than a minute)
  if (difference.inSeconds < 60) {
    return shorten ? 'now' : 'just now';
  }

  // Minutes ago
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    if (shorten) {
      return '${minutes}m';
    }
    return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
  }

  // Hours ago
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    if (shorten) {
      return '${hours}h';
    }
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }

  // Days ago
  final days = difference.inDays;
  if (days == 1) {
    return shorten ? '1d' : 'yesterday';
  }

  if (days < 7) {
    return shorten ? '${days}d' : '$days days ago';
  }

  // Weeks ago
  final weeks = (days / 7).floor();
  if (weeks < 4) {
    if (shorten) {
      return '${weeks}w';
    }
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }

  // Months ago
  final months = (days / 30).floor();
  if (months < 12) {
    if (shorten) {
      return '${months}mo';
    }
    return months == 1 ? '1 month ago' : '$months months ago';
  }

  // Years ago
  final years = (days / 365).floor();
  if (years < 2) {
    return shorten ? '1y' : '1 year ago';
  }

  // For dates older than 1 year, show formatted date
  if (shorten) {
    // Check if it's the current year
    if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    }
    return DateFormat('MMM d, yy').format(dateTime);
  } else {
    // Full date format: "January 15, 2024"
    // Check if it's the current year to optionally omit year
    if (dateTime.year == now.year) {
      return DateFormat('MMMM d').format(dateTime);
    }
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }
}
