import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get formatted => DateFormat('MMM d, yyyy').format(this);
  String get formattedWithTime => DateFormat('MMM d, yyyy • h:mm a').format(this);
  String get dayMonth => DateFormat('d MMM').format(this);
  String get timeOnly => DateFormat('h:mm a').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isPast => isBefore(DateTime.now());

  String get relative {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    final diff = difference(DateTime.now()).inDays;
    if (diff < 0) return '${diff.abs()}d ago';
    return 'In ${diff}d';
  }
}
