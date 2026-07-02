import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String timeStr(TimeOfDay tod) =>
    '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTod(String hhmm) {
  final p = hhmm.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String displayTime(String hhmm) {
  final tod = parseTod(hhmm);
  final h = tod.hour % 12 == 0 ? 12 : tod.hour % 12;
  final m = tod.minute.toString().padLeft(2, '0');
  return '$h:$m ${tod.hour >= 12 ? 'PM' : 'AM'}';
}

String displayDuration(String start, String end) {
  final s = parseTod(start);
  final e = parseTod(end);
  final mins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
  if (mins <= 0) return '';
  if (mins < 60) return '${mins}m';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

int minutesLeft(String endTime) {
  final now = TimeOfDay.now();
  final e = parseTod(endTime);
  return (e.hour * 60 + e.minute) - (now.hour * 60 + now.minute);
}

bool isActiveNow(String startTime, String endTime) {
  final now = TimeOfDay.now();
  final nowMins = now.hour * 60 + now.minute;
  final s = parseTod(startTime);
  final e = parseTod(endTime);
  return nowMins >= s.hour * 60 + s.minute && nowMins < e.hour * 60 + e.minute;
}

final _styles = <String, (Color, IconData)>{
  'Work': (AppColors.blue, Icons.laptop_rounded),
  'Meeting': (AppColors.primary, Icons.people_rounded),
  'Health': (AppColors.green, Icons.favorite_rounded),
  'Exercise': (AppColors.green, Icons.directions_run_rounded),
  'Meals': (AppColors.orange, Icons.restaurant_rounded),
  'Learning': (AppColors.amber, Icons.school_rounded),
  'Sleep': (Color(0xFF6366F1), Icons.bedtime_rounded),
  'Leisure': (AppColors.pink, Icons.movie_rounded),
  'Personal': (AppColors.primary, Icons.person_rounded),
  'Habit': (AppColors.teal, Icons.loop_rounded),
  'Event': (AppColors.teal, Icons.event_rounded),
};

(Color, IconData) categoryStyle(String category) =>
    _styles[category] ?? (AppColors.textMuted, Icons.circle_rounded);

const kCategories = [
  'Work',
  'Meeting',
  'Health',
  'Exercise',
  'Meals',
  'Learning',
  'Sleep',
  'Leisure',
  'Personal',
  'Habit',
  'Event',
];
